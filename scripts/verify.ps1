# verify.ps1 - Release quality gate (wrapper). Exits 0 = PASS, 1 = FAIL.
# Checks: validate_loc (JSON layer), check_tsv (TSV layer incl. FLAG gate),
#         unique ORIG baseline, Chinese JSON count, forbidden-file scan.
param(
    [string]$GameRoot = "",
    [string]$Lang = "CHS"
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$game = if ($GameRoot -ne "") { $GameRoot } else { "F:\EarthX 2 Open Alpha (Windows)" }
$plug = "$game\BepInEx\plugins\EarthX2Chinese"
$zhDir = "$game\EarthX_Data\StreamingAssets\Localization\Chinese"
$fail = 0

function Fail([string]$msg) { Write-Host "FAIL: $msg"; $script:fail++ }
function Pass([string]$msg) { Write-Host "PASS: $msg" }

# 1. JSON layer (official localization)
$validate = "$game\handoff\scripts\validate_loc.ps1"
if (Test-Path -LiteralPath $validate) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $validate -GameRoot $game -SkipRuntime
    $last = $LASTEXITCODE
    $out | Where-Object { $_ -match 'FAIL' } | Write-Host
    if ($last -ne 0) { Fail "validate_loc.ps1 exit=$last" } else { Pass "validate_loc.ps1 (JSON layer)" }
} else { Fail "validate_loc.ps1 not found at $validate" }

# 2. TSV layer (fixed check_tsv, includes FLAG gate). Output parsed.
$checkTsv = "$game\handoff\check_tsv.ps1"
if (-not (Test-Path -LiteralPath $checkTsv)) { Fail "check_tsv.ps1 not found" }
$tsvOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $checkTsv -TargetDir $plug
$tsvOut | Out-File -LiteralPath "$game\handoff\qa-check-log.txt" -Encoding UTF8
$realFail = @($tsvOut | Where-Object { $_ -match '^\s+FAIL:' -and $_ -notmatch 'ORIG not in baked-level0/full' })
$bakedFail = @($tsvOut | Where-Object { $_ -match 'ORIG not in baked-level0/full' })
$conflict = @($tsvOut | Where-Object { $_ -cmatch '^\s+CONFLICT ' })   # case-sensitive: avoid matching "OK: no ... conflicts"
$invalidFlag = @($tsvOut | Where-Object { $_ -match 'invalid FLAG' })
if ($realFail.Count -gt 0) { $realFail | Write-Host; Fail "strings/baked structural FAILs: $($realFail.Count)" } else { Pass "TSV structural checks (0 FAIL)" }
if ($conflict.Count -gt 0) { Fail "duplicate ORIG conflicts: $($conflict.Count)" } else { Pass "no duplicate ORIG conflicts" }
if ($invalidFlag.Count -gt 0) { Fail "invalid FLAG entries: $($invalidFlag.Count)" } else { Pass "FLAG column valid (DISPLAY/MIXED/AUTO)" }
Write-Host ("INFO: baked no-op baseline misses (documented, allowed): " + $bakedFail.Count)
if ($bakedFail.Count -gt 120) { Fail "baked baseline misses rose to $($bakedFail.Count) (>120)" }

# 3. Unique ORIG baseline (expected 580) + rule line count
$set = @{}
$flagCounts = @{}
foreach ($f in (Get-ChildItem "$plug\zh-strings*.tsv")) {
    foreach ($raw in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
        $t = $raw.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $p = $t.Split(@('^^^'), [StringSplitOptions]::None)
        if ($p.Length -lt 3) { continue }
        $set[$p[1]] = 1
        if ($p.Length -ge 4) { $k = $p[3]; if (-not $flagCounts.ContainsKey($k)) { $flagCounts[$k] = 0 }; $flagCounts[$k]++ }
    }
}
if ($set.Count -ne 580) { Fail "unique ORIG = $($set.Count), expected 580" } else { Pass "unique ORIG baseline = 580" }
Write-Host ("INFO: FLAG distribution: " + (($flagCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '))

# 4. Chinese JSON count (patch content, expected 64)
if (-not (Test-Path -LiteralPath $zhDir)) { Fail "Chinese dir missing: $zhDir" }
else {
    $n = (Get-ChildItem $zhDir -Recurse -Filter '*.json' | Measure-Object).Count
    if ($n -ne 64) { Fail "Chinese JSON count = $n, expected 64" } else { Pass "Chinese JSON = 64 files" }
    $junk = Get-ChildItem $zhDir -Recurse -File | Where-Object { $_.Name -in @('.DS_Store','Thumbs.db') }
    if ($junk) { $junk | ForEach-Object { Write-Host "  junk: $($_.FullName)" }; Fail "junk files inside Chinese dir" } else { Pass "no junk files in Chinese dir" }
}

# 5. Plugin dir: junk files at top level; rules_backup* is allowed workspace history (build whitelist excludes it)
$forbidden = Get-ChildItem -LiteralPath $plug -File | Where-Object { $_.Name -in @('.DS_Store','Thumbs.db') -or $_.Extension -eq '.log' }
if ($forbidden) { $forbidden | ForEach-Object { Write-Host "  forbidden: $($_.Name)" }; Fail "junk/log files at plugin dir top level" }
else { Pass "no junk/log files at plugin dir top level (rules_backup* allowed in workspace, excluded by build whitelist)" }

# 6. Repo tree (publish) == workspace sync check. The repo root is the patch file tree that
#    gets committed to GitHub and staged into the zips, so it MUST be byte-identical to the
#    workspace for the shipped content. Any drift -> FAIL (run build-artifacts.ps1 to refresh).
$publish = "$game\publish"
$langTree = "$publish\$Lang\EarthX 2 Open Alpha"
$repoZh = "$langTree\EarthX_Data\StreamingAssets\Localization\Chinese"
$repoPlug = "$langTree\BepInEx\plugins\EarthX2Chinese"

function Get-TreeMd5Map([string]$root, [scriptblock]$include = $null) {
    $map = @{}
    $base = $root.TrimEnd('\').Length + 1
    foreach ($f in (Get-ChildItem -LiteralPath $root -Recurse -File)) {
        if ($include -and -not (& $include $f)) { continue }
        $rel = $f.FullName.Substring($base)
        $map[$rel] = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash
    }
    return $map
}
function Test-TreeSync([string]$name, [string]$src, [string]$repo, [scriptblock]$srcFilter = $null, [scriptblock]$repoFilter = $null) {
    if (-not (Test-Path -LiteralPath $repo)) { Fail "repo tree missing for $name`: $repo (run build-artifacts.ps1)"; return }
    $srcMap = Get-TreeMd5Map $src $srcFilter
    $repoMap = Get-TreeMd5Map $repo $repoFilter
    if ($repoMap.Count -eq 0) { Fail "repo tree empty for $name (run build-artifacts.ps1)"; return }
    $sync = $true
    foreach ($rel in ($repoMap.Keys | Sort-Object)) {
        if (-not $srcMap.ContainsKey($rel)) { Write-Host "  repo-only: $rel"; $sync = $false; continue }
        if ($srcMap[$rel] -ne $repoMap[$rel]) { Write-Host "  MD5 mismatch: $rel"; $sync = $false }
    }
    foreach ($rel in ($srcMap.Keys | Sort-Object)) {
        if (-not $repoMap.ContainsKey($rel)) { Write-Host "  missing-in-repo: $rel"; $sync = $false }
    }
    if ($sync) { Pass "repo tree sync OK ($name`: $($repoMap.Count) files)" } else { Fail "repo tree out of sync ($name) - run build-artifacts.ps1 to refresh" }
}

if (-not (Test-Path -LiteralPath $repoZh) -or -not (Test-Path -LiteralPath $repoPlug)) {
    Fail "repo tree not built yet at $publish (run build-artifacts.ps1 first)"
} else {
    Test-TreeSync "Chinese" $zhDir $repoZh
    # plugin whitelist = what build-artifacts.ps1 ships. Exclude rules_backup* history dirs
    # (present in workspace only) and version.txt (generated, checked separately below).
    $plugSrcF = { param($f) $f.FullName -notmatch '\\rules_backup' -and $f.Name -ne 'version.txt' }
    $plugRepF = { param($f) $f.Name -ne 'version.txt' }
    Test-TreeSync "plugin" $plug $repoPlug $plugSrcF $plugRepF
    # version.txt is generated from publish\VERSION - assert it matches
    $vRepo = Get-Content -LiteralPath "$repoPlug\version.txt" -Raw -Encoding UTF8
    $vWant = (Get-Content -LiteralPath "$publish\VERSION" -Raw -Encoding UTF8).Trim()
    if ($vRepo.Trim() -eq $vWant) { Pass "repo version.txt = $vWant" } else { Fail "repo version.txt = '$($vRepo.Trim())', expected '$vWant'" }
}

Write-Host ""
if ($fail -gt 0) { Write-Host "VERIFY RESULT: FAIL ($fail gate items)"; exit 1 }
Write-Host "VERIFY RESULT: ALL PASS"
exit 0
