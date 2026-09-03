# verify.ps1 - Release quality gate (wrapper). Exits 0 = PASS, 1 = FAIL.
# Checks per language profile (-Lang CHS|DEU|JPN):
#   CHS (workspace-sourced): validate_loc (JSON layer), check_tsv (TSV layer incl. FLAG gate),
#         unique ORIG baseline, Chinese JSON count, forbidden-file scan, repo-tree == workspace sync.
#   DEU (offline-authored): German JSON vs English parity (repo tree), check_tsv -Prefix de,
#         unique ORIG baseline, ORIG set equality vs CHS (inheritance gate),
#         German JSON count, forbidden-file scan (incl. no fonts\ for DEU).
param(
    [string]$GameRoot = "",
    [string]$Lang = "CHS"
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$game = if ($GameRoot -ne "") { $GameRoot } else { "F:\EarthX 2 Open Alpha (Windows)" }
$publish = "$game\publish"

# ---- language profiles ----
$profiles = @{
    "CHS" = @{
        Prefix        = "zh"
        TargetLang    = "Chinese"
        PlugDirName   = "EarthX2Chinese"
        JsonDirName   = "Chinese"
        FromWorkspace = $true
        EmbeddedFonts = $true
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "DEU" = @{
        Prefix        = "de"
        TargetLang    = "German"
        PlugDirName   = "EarthX2German"
        JsonDirName   = "German"
        FromWorkspace = $false
        EmbeddedFonts = $false
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "JPN" = @{
        Prefix        = "ja"
        TargetLang    = "Japanese"
        PlugDirName   = "EarthX2Japanese"
        JsonDirName   = "Japanese"
        FromWorkspace = $false
        EmbeddedFonts = $true
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "FRA" = @{
        Prefix        = "fr"
        TargetLang    = "French"
        PlugDirName   = "EarthX2French"
        JsonDirName   = "French"
        FromWorkspace = $false
        EmbeddedFonts = $false
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "POR" = @{
        Prefix        = "pt"
        TargetLang    = "Portuguese"
        PlugDirName   = "EarthX2Portuguese"
        JsonDirName   = "Portuguese"
        FromWorkspace = $false
        EmbeddedFonts = $false
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "ESP" = @{
        Prefix        = "es"
        TargetLang    = "Spanish"
        PlugDirName   = "EarthX2Spanish"
        JsonDirName   = "Spanish"
        FromWorkspace = $false
        EmbeddedFonts = $false
        UniqueOrig    = 580
        JsonCount     = 64
    }
    "KOR" = @{
        Prefix        = "ko"
        TargetLang    = "Korean"
        PlugDirName   = "EarthX2Korean"
        JsonDirName   = "Korean"
        FromWorkspace = $false
        EmbeddedFonts = $true
        UniqueOrig    = 580
        JsonCount     = 64
    }
}
if (-not $profiles.ContainsKey($Lang)) { Write-Host "FAIL: unknown Lang '$Lang'"; exit 1 }
$p = $profiles[$Lang]
$prefix = $p.Prefix
$targetLang = $p.TargetLang

$fail = 0
function Fail([string]$msg) { Write-Host "FAIL: $msg"; $script:fail++ }
function Pass([string]$msg) { Write-Host "PASS: $msg" }

$repoTree = "$publish\$Lang\EarthX 2 Open Alpha"
$repoPlug = "$repoTree\BepInEx\plugins\$($p.PlugDirName)"
$repoLang = "$repoTree\EarthX_Data\StreamingAssets\Localization\$($p.JsonDirName)"

if ($p.FromWorkspace) {
    $plug = "$game\BepInEx\plugins\$($p.PlugDirName)"
    $langDir = "$game\EarthX_Data\StreamingAssets\Localization\$($p.JsonDirName)"
} else {
    $plug = $repoPlug
    $langDir = $repoLang
}

# 1. JSON layer (official localization) vs English
$validate = "$game\handoff\scripts\validate_loc.ps1"
if (Test-Path -LiteralPath $validate) {
    $vArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $validate, '-GameRoot', $game, '-SkipRuntime',
               '-TargetLang', $targetLang, '-Prefix', $prefix, '-PluginDir', $plug, '-LangDir', $langDir)
    $out = & powershell @vArgs
    $last = $LASTEXITCODE
    $out | Where-Object { $_ -match 'FAIL' } | Write-Host
    if ($last -ne 0) { Fail "validate_loc.ps1 exit=$last" } else { Pass "validate_loc.ps1 (JSON layer: English vs $targetLang)" }
} else { Fail "validate_loc.ps1 not found at $validate" }

# 2. TSV layer (check_tsv incl. FLAG gate). Output parsed.
$checkTsv = "$game\handoff\check_tsv.ps1"
if (-not (Test-Path -LiteralPath $checkTsv)) { Fail "check_tsv.ps1 not found" }
$tsvOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $checkTsv -TargetDir $plug -Prefix $prefix
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

# 3. Unique ORIG baseline + rule line count + (DEU) ORIG set equality vs CHS
$set = @{}
$flagCounts = @{}
foreach ($f in (Get-ChildItem "$plug\$($prefix)-strings*.tsv" -ErrorAction SilentlyContinue)) {
    foreach ($raw in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
        $t = $raw.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $pp = $t.Split(@('^^^'), [StringSplitOptions]::None)
        if ($pp.Length -lt 3) { continue }
        $set[$pp[1]] = 1
        if ($pp.Length -ge 4) { $k = $pp[3]; if (-not $flagCounts.ContainsKey($k)) { $flagCounts[$k] = 0 }; $flagCounts[$k]++ }
    }
}
if ($set.Count -ne $p.UniqueOrig) { Fail "unique ORIG = $($set.Count), expected $($p.UniqueOrig)" } else { Pass "unique ORIG baseline = $($p.UniqueOrig)" }
Write-Host ("INFO: FLAG distribution: " + (($flagCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '))

if (-not $p.FromWorkspace) {
    # DEU inheritance gate: ORIG set must equal the CHS baseline set exactly
    $chsSet = @{}
    foreach ($f in (Get-ChildItem "$game\BepInEx\plugins\EarthX2Chinese\zh-strings*.tsv" -ErrorAction SilentlyContinue)) {
        foreach ($raw in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
            $t = $raw.Trim()
            if ($t -eq '' -or $t.StartsWith('#')) { continue }
            $pp = $t.Split(@('^^^'), [StringSplitOptions]::None)
            if ($pp.Length -ge 3) { $chsSet[$pp[1]] = 1 }
        }
    }
    $missing = @($chsSet.Keys | Where-Object { -not $set.ContainsKey($_) })
    $extra   = @($set.Keys | Where-Object { -not $chsSet.ContainsKey($_) })
    if ($missing.Count -eq 0 -and $extra.Count -eq 0) { Pass "ORIG set identical to CHS baseline ($($chsSet.Count) ORIGs, inheritance OK)" }
    else {
        if ($missing.Count -gt 0) { Write-Host "  missing vs CHS: $($missing | Select-Object -First 5 | ForEach-Object { $_ -replace "`n",'\n' })" }
        if ($extra.Count -gt 0)   { Write-Host "  extra vs CHS: $($extra | Select-Object -First 5 | ForEach-Object { $_ -replace "`n",'\n' })" }
        Fail "ORIG set differs from CHS baseline (missing=$($missing.Count), extra=$($extra.Count)) - re-derive de-strings*.tsv from zh-strings*.tsv"
    }
}

# 4. Language JSON count (patch content)
if (-not (Test-Path -LiteralPath $langDir)) { Fail "$($p.JsonDirName) dir missing: $langDir" }
else {
    $n = (Get-ChildItem $langDir -Recurse -Filter '*.json' | Measure-Object).Count
    if ($n -ne $p.JsonCount) { Fail "$($p.JsonDirName) JSON count = $n, expected $($p.JsonCount)" } else { Pass "$($p.JsonDirName) JSON = $($p.JsonCount) files" }
    $junk = Get-ChildItem $langDir -Recurse -File | Where-Object { $_.Name -in @('.DS_Store','Thumbs.db') }
    if ($junk) { $junk | ForEach-Object { Write-Host "  junk: $($_.FullName)" }; Fail "junk files inside $($p.JsonDirName) dir" } else { Pass "no junk files in $($p.JsonDirName) dir" }
    # Strict JSON syntax gate: every file must parse with a strict parser (catches unescaped
    # quotes etc. that break Newtonsoft.Json at runtime - validate_loc's flat parser misses them).
    try { Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop | Out-Null } catch { }
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $jsonBad = @()
    foreach ($jf in (Get-ChildItem $langDir -Recurse -Filter '*.json')) {
        try { $null = $ser.DeserializeObject([IO.File]::ReadAllText($jf.FullName)) }
        catch { $jsonBad += ($jf.Name + ': ' + $_.Exception.Message) }
    }
    if ($jsonBad.Count -gt 0) {
        $jsonBad | Select-Object -First 10 | ForEach-Object { Write-Host "  JSON syntax error: $_" }
        Fail "strict JSON syntax check: $($jsonBad.Count) file(s) do not parse"
    } else { Pass "strict JSON syntax check ($($n) files parse OK)" }
}

# 5. Plugin dir: junk files; forbidden content
#    (workspace mode: rules_backup* history dirs are allowed and excluded by build whitelist;
#     offline mode: nothing under the repo plug tree may contain them)
$fbPattern = if ($p.FromWorkspace) { '__MACOSX' } else { 'rules_backup|__MACOSX' }
$forbidden = Get-ChildItem -LiteralPath $plug -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -match $fbPattern -or $_.Name -in @('.DS_Store','Thumbs.db') -or $_.Extension -eq '.log'
}
if ($forbidden) { $forbidden | Select-Object -First 5 | ForEach-Object { Write-Host "  forbidden: $($_.FullName)" }; Fail "forbidden files under plugin dir ($($forbidden.Count))" }
else { Pass "no forbidden files under plugin dir" }
if (-not $p.FromWorkspace -and -not $p.EmbeddedFonts) {
    # no-fonts languages (DEU) ship no fonts\ (uses game-embedded LiberationSans SDF) - assert absence
    if (Test-Path -LiteralPath "$plug\fonts") { Fail "$Lang plugin must not ship fonts\ (game font is used)" }
    else { Pass "no fonts\ dir ($Lang uses game-embedded font)" }
}
if ($p.EmbeddedFonts) {
    # embedded-font languages must actually ship fonts\
    if (-not (Test-Path -LiteralPath "$plug\fonts")) { Fail "$Lang must ship fonts\ (embedded font policy)" }
    else { Pass "fonts\ dir present ($Lang ships embedded font)" }
}

# 6. Repo tree checks
$repoZh = $repoLang
$repoPlug2 = $repoPlug

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

if (-not (Test-Path -LiteralPath $repoZh) -or -not (Test-Path -LiteralPath $repoPlug2)) {
    Fail "repo tree not built yet at $publish (run build-artifacts.ps1 first)"
} else {
    if ($p.FromWorkspace) {
        Test-TreeSync $p.JsonDirName $langDir $repoZh
        # plugin whitelist = what build-artifacts.ps1 ships. Exclude rules_backup* history dirs
        # (present in workspace only) and version.txt (generated, checked separately below).
        $plugSrcF = { param($f) $f.FullName -notmatch '\\rules_backup' -and $f.Name -ne 'version.txt' }
        $plugRepF = { param($f) $f.Name -ne 'version.txt' }
        Test-TreeSync "plugin" $plug $repoPlug2 $plugSrcF $plugRepF
    } else {
        Pass "repo tree is authoring source (offline mode, no workspace sync check)"
    }
    # version.txt is generated from publish\VERSION - assert it matches
    $vRepo = Get-Content -LiteralPath "$repoPlug2\version.txt" -Raw -Encoding UTF8
    $vWant = (Get-Content -LiteralPath "$publish\VERSION" -Raw -Encoding UTF8).Trim()
    if ($vRepo.Trim() -eq $vWant) { Pass "repo version.txt = $vWant" } else { Fail "repo version.txt = '$($vRepo.Trim())', expected '$vWant'" }
}

Write-Host ""
if ($fail -gt 0) { Write-Host "VERIFY RESULT: FAIL ($fail gate items)"; exit 1 }
Write-Host "VERIFY RESULT: ALL PASS"
exit 0
