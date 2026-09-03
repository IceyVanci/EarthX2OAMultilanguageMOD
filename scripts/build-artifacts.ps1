# build-artifacts.ps1 - Release builder for the EarthX2OAMultilanguageMOD project (multi-language).
# Produces (per language, -Lang CHS|DEU|JPN):
#   release\<LANG>-<ZipMod>_v<ver>.zip          (patch only)
#   release\<LANG>-<ZipMod>_v<ver>.zip.sha256
#   release\<LANG>-<ZipMod>_v<ver>_full.zip     (patch + unmodified BepInEx/Doorstop framework, LGPL-2.1)
#   release\<LANG>-<ZipMod>_v<ver>_full.zip.sha256
#   release\<LANG>-latest.json  + release\_build_report_<LANG>.txt
# Workflow:
#   CHS: refresh publish repo tree from workspace -> hard gate (verify.ps1) -> stage zips FROM the repo tree.
#   DEU: offline-authored repo tree (no workspace refresh) -> hard gate -> stage zips FROM the repo tree.
#   JPN: offline-authored repo tree (no workspace refresh) -> hard gate -> stage zips FROM the repo tree.
# Distribution is repo-file based: zips + sha256 + <LANG>-latest.json live in release\ and are
# committed to git (no GitHub Releases). URLs point at raw.githubusercontent.com/{REPO}/main/...;
# replace {REPO} with 用户名/仓库名 before first push.
param(
    [string]$GameRoot = "",
    [string]$Lang = "CHS",
    [string]$Version = "",
    [switch]$SkipFull
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$game = if ($GameRoot -ne "") { $GameRoot } else { "F:\EarthX 2 Open Alpha (Windows)" }
$publish = "$game\publish"
if ($Version -eq "") { $Version = ([IO.File]::ReadAllText("$publish\VERSION", [Text.Encoding]::UTF8)).Trim() }
$distrib = "$publish\release"

# ---- language profiles ----
$profiles = @{
    "CHS" = @{
        Prefix        = "zh"
        TargetLang    = "Chinese"
        PlugDirName   = "EarthX2Chinese"
        JsonDirName   = "Chinese"
        FromWorkspace = $true
        ZipMod        = "EarthX2OAChineseMOD"
        EmbeddedFonts = $true
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG (DISPLAY 386, AUTO 205); baked 299; JSON 64 files; embedded font Source Han Sans CN (OFL 1.1)"
    }
    "DEU" = @{
        Prefix        = "de"
        TargetLang    = "German"
        PlugDirName   = "EarthX2German"
        JsonDirName   = "German"
        FromWorkspace = $false
        ZipMod        = "EarthX2OAGermanMOD"
        EmbeddedFonts = $false
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; game-embedded font (no font files shipped)"
    }
    "JPN" = @{
        Prefix        = "ja"
        TargetLang    = "Japanese"
        PlugDirName   = "EarthX2Japanese"
        JsonDirName   = "Japanese"
        FromWorkspace = $false
        ZipMod        = "EarthX2OAJapaneseMOD"
        EmbeddedFonts = $true
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; embedded font Source Han Sans JP (OFL 1.1)"
    }
    "FRA" = @{
        Prefix        = "fr"
        TargetLang    = "French"
        PlugDirName   = "EarthX2French"
        JsonDirName   = "French"
        FromWorkspace = $false
        ZipMod        = "EarthX2OAFrenchMOD"
        EmbeddedFonts = $false
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; game-embedded font (no font files shipped)"
    }
    "POR" = @{
        Prefix        = "pt"
        TargetLang    = "Portuguese"
        PlugDirName   = "EarthX2Portuguese"
        JsonDirName   = "Portuguese"
        FromWorkspace = $false
        ZipMod        = "EarthX2OAPortugueseMOD"
        EmbeddedFonts = $false
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; game-embedded font (no font files shipped)"
    }
    "ESP" = @{
        Prefix        = "es"
        TargetLang    = "Spanish"
        PlugDirName   = "EarthX2Spanish"
        JsonDirName   = "Spanish"
        FromWorkspace = $false
        ZipMod        = "EarthX2OASpanishMOD"
        EmbeddedFonts = $false
        UniqueOrig    = 580
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; game-embedded font (no font files shipped)"
    }
    "KOR" = @{
        Prefix        = "ko"
        TargetLang    = "Korean"
        PlugDirName   = "EarthX2Korean"
        JsonDirName   = "Korean"
        FromWorkspace = $false
        ZipMod        = "EarthX2OAKoreanMOD"
        EmbeddedFonts = $true
        UniqueOrig    = 580
        FontLicense   = "SourceHanSansK-LICENSE.txt"
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; embedded font Source Han Sans K (OFL 1.1)"
    }
}
if (-not $profiles.ContainsKey($Lang)) { throw "unknown Lang '$Lang' (expected CHS, DEU, JPN, FRA or POR)" }
$P = $profiles[$Lang]
$prefix = $P.Prefix

$zhSrc = "$game\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
$plug = "$game\BepInEx\plugins\$($P.PlugDirName)"
$langTree = "$publish\$Lang\EarthX 2 Open Alpha"
$repoZh = "$langTree\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
$repoPlug = "$langTree\BepInEx\plugins\$($P.PlugDirName)"
$zipName = "${Lang}-$($P.ZipMod)_v$Version"

Write-Host "=== EarthX2$($P.TargetLang) build v$Version [$Lang] ==="
New-Item -ItemType Directory -Path $distrib -Force | Out-Null

# ---------- 1. refresh repo tree from workspace (CHS only; DEU is authored in-tree) ----------
if ($P.FromWorkspace) {
    Write-Host "[1/7] refreshing publish repo tree ($Lang) from workspace ..."
    # language JSON (exclude junk)
    New-Item -ItemType Directory -Path $repoZh -Force | Out-Null
    Get-ChildItem -LiteralPath $zhSrc -Recurse -File | Where-Object { $_.Name -notin @('.DS_Store','Thumbs.db') } | ForEach-Object {
        $rel = $_.FullName.Substring($zhSrc.Length).TrimStart('\')
        $d = Split-Path -Parent (Join-Path $repoZh $rel)
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $repoZh $rel) -Force
    }
    # plugin whitelist
    New-Item -ItemType Directory -Path $repoPlug -Force | Out-Null
    Copy-Item -LiteralPath "$plug\$($P.PlugDirName).dll" -Destination $repoPlug -Force
    Copy-Item -LiteralPath "$plug\README.md" -Destination $repoPlug -Force
    Get-ChildItem -LiteralPath $plug -Filter "$($prefix)-*.tsv" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $repoPlug -Force }
    New-Item -ItemType Directory -Path "$repoPlug\src" -Force | Out-Null
    Get-ChildItem -LiteralPath "$plug\src" -Filter '*.cs' -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$repoPlug\src" -Force }
    if ($P.EmbeddedFonts -and (Test-Path -LiteralPath "$plug\fonts")) {
        New-Item -ItemType Directory -Path "$repoPlug\fonts" -Force | Out-Null
        Get-ChildItem -LiteralPath "$plug\fonts" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$repoPlug\fonts" -Force }
    }
} else {
    Write-Host "[1/7] offline-authored language ($Lang): repo tree is the source, skipping workspace refresh"
    if (-not (Test-Path -LiteralPath $repoPlug)) { throw "repo plug tree missing: $repoPlug (author DEU content first)" }
    if (-not (Test-Path -LiteralPath $repoZh))   { throw "repo language tree missing: $repoZh (author DEU content first)" }
}
[IO.File]::WriteAllText("$repoPlug\version.txt", "$Version`n", (New-Object System.Text.UTF8Encoding($false)))
$repoZhCount = (Get-ChildItem $repoZh -Recurse -Filter '*.json').Count
$repoPlugCount = (Get-ChildItem $repoPlug -Recurse -File).Count
Write-Host "    repo tree: $($P.JsonDirName) JSON $repoZhCount | plugin files $repoPlugCount"

# ---------- 2. quality gate ----------
Write-Host "[2/7] quality gate (verify.ps1 -Lang $Lang) ..."
$verifyOut = & powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\verify.ps1" -GameRoot $game -Lang $Lang
$verifyOut | Write-Host
if ($LASTEXITCODE -ne 0) { throw "verify.ps1 FAILED - build aborted." }

# ---------- 3. patch staging (FROM repo tree) ----------
Write-Host "[3/7] staging patch content from repo tree ..."
$staging = "$publish\_staging_patch"
if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

# language JSON
$dstZh = "$staging\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
New-Item -ItemType Directory -Path $dstZh -Force | Out-Null
Get-ChildItem -LiteralPath $repoZh -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($repoZh.Length).TrimStart('\')
    $d = Split-Path -Parent (Join-Path $dstZh $rel)
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstZh $rel) -Force
}
$zhCount = (Get-ChildItem $dstZh -Recurse -Filter '*.json').Count

# plugin whitelist (incl. fonts when profile has them)
$dstPlug = "$staging\BepInEx\plugins\$($P.PlugDirName)"
New-Item -ItemType Directory -Path $dstPlug -Force | Out-Null
Copy-Item -LiteralPath "$repoPlug\$($P.PlugDirName).dll" -Destination $dstPlug -Force
Copy-Item -LiteralPath "$repoPlug\README.md" -Destination $dstPlug -Force
Get-ChildItem -LiteralPath $repoPlug -Filter "$($prefix)-*.tsv" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dstPlug -Force }
New-Item -ItemType Directory -Path "$dstPlug\src" -Force | Out-Null
Get-ChildItem -LiteralPath "$repoPlug\src" -Filter '*.cs' -File -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$dstPlug\src" -Force }
Copy-Item -LiteralPath "$repoPlug\version.txt" -Destination $dstPlug -Force
if ($P.EmbeddedFonts -and (Test-Path -LiteralPath "$repoPlug\fonts")) {
    New-Item -ItemType Directory -Path "$dstPlug\fonts" -Force | Out-Null
    Get-ChildItem -LiteralPath "$repoPlug\fonts" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$dstPlug\fonts" -Force }
}
$plugCount = (Get-ChildItem $dstPlug -Recurse -File).Count

# root docs (ASCII filenames only - zip-safe) + docs\ + font license (CHS only)
Copy-Item -LiteralPath "$publish\README.md" -Destination $staging -Force
Copy-Item -LiteralPath "$publish\README_CN.md" -Destination $staging -Force
Copy-Item -LiteralPath "$publish\AI-PATCH-GUIDE.md" -Destination $staging -Force
New-Item -ItemType Directory -Path "$staging\docs" -Force | Out-Null
Copy-Item -Path "$publish\docs\*" -Destination "$staging\docs" -Force
New-Item -ItemType Directory -Path "$staging\licenses" -Force | Out-Null
if ($P.EmbeddedFonts) {
    $fontLic = if ($P.FontLicense) { $P.FontLicense } else { 'SourceHanSansCN-LICENSE.txt' }
    Copy-Item -LiteralPath "$publish\licenses\$fontLic" -Destination "$staging\licenses" -Force
}

# forbidden-content assertions inside patch staging
$forbidden = Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object {
    $_.FullName -match 'rules_backup|__MACOSX' -or
    $_.Name -in @('.DS_Store','Thumbs.db','winhttp.dll','doorstop_config.ini','update.ps1','manifest.txt') -or
    $_.FullName -match '\\English\\' -or $_.FullName -match 'BepInEx\\core\\' -or $_.Extension -eq '.log'
}
if ($forbidden) { $forbidden | Select-Object -First 8 | ForEach-Object { Write-Host "  FORBIDDEN: $($_.FullName)" }; throw "forbidden files inside patch staging" }
if (-not $P.EmbeddedFonts -and (Test-Path -LiteralPath "$dstPlug\fonts")) { throw "$Lang must not ship fonts\ (game-embedded font policy)" }
Write-Host "    $($P.JsonDirName) JSON: $zhCount | plugin files: $plugCount | docs staged"

# ---------- 4. zip helper ----------
function New-ZipUtf8([string]$stageDir, [string]$zipPath) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    $tmp = "$zipPath.tmp"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    $enc = New-Object System.Text.UTF8Encoding($false)
    $zip = [System.IO.Compression.ZipFile]::Open($tmp, [System.IO.Compression.ZipArchiveMode]::Create, $enc)
    try {
        $b = $stageDir.TrimEnd('\'); $bl = $b.Length + 1
        Get-ChildItem -LiteralPath $stageDir -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($bl) -replace '\\','/'
            $entry = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $_.LastWriteTime
            $s = $entry.Open()
            try { $fs = [IO.File]::OpenRead($_.FullName); $fs.CopyTo($s); $fs.Close() } finally { if ($s) { $s.Dispose() } }
        }
    } finally { $zip.Dispose() }
    Move-Item -LiteralPath $tmp -Destination $zipPath -Force
}

Write-Host "[4/7] packing patch zip ..."
$zipPatch = "$distrib\$zipName.zip"
New-ZipUtf8 $staging $zipPatch
$shaPatch = (Get-FileHash -LiteralPath $zipPatch -Algorithm SHA256).Hash.ToLower()
[IO.File]::WriteAllText("$zipPatch.sha256", "$shaPatch  $(Split-Path -Leaf $zipPatch)`n", (New-Object System.Text.UTF8Encoding($false)))

# ---------- 5. full package ----------
$zipFull = $null; $shaFull = $null; $fullNote = 'patch-only build (-SkipFull)'
if (-not $SkipFull) {
    Write-Host "[5/7] staging full package (framework + licenses) ..."
    $stagingF = "$publish\_staging_full"
    if (Test-Path -LiteralPath $stagingF) { Remove-Item -LiteralPath $stagingF -Recurse -Force }
    Copy-Item -LiteralPath $staging -Destination $stagingF -Recurse
    # framework whitelist (unmodified binaries, LGPL-2.1)
    Copy-Item -LiteralPath "$game\winhttp.dll" -Destination $stagingF -Force
    Copy-Item -LiteralPath "$game\doorstop_config.ini" -Destination $stagingF -Force
    Copy-Item -LiteralPath "$game\.doorstop_version" -Destination $stagingF -Force
    New-Item -ItemType Directory -Path "$stagingF\BepInEx\core" -Force | Out-Null
    Copy-Item -Path "$game\BepInEx\core\*" -Destination "$stagingF\BepInEx\core" -Force
    # license texts (framework + font)
    New-Item -ItemType Directory -Path "$stagingF\licenses" -Force | Out-Null
    Copy-Item -Path "$publish\licenses\*" -Destination "$stagingF\licenses" -Force
    $fullNote = "full package: framework + licenses (LGPL + OFL) included"
    Write-Host "    $fullNote"
    $zipFull = "$distrib\${zipName}_full.zip"
    New-ZipUtf8 $stagingF $zipFull
    $shaFull = (Get-FileHash -LiteralPath $zipFull -Algorithm SHA256).Hash.ToLower()
    [IO.File]::WriteAllText("$zipFull.sha256", "$shaFull  $(Split-Path -Leaf $zipFull)`n", (New-Object System.Text.UTF8Encoding($false)))
}

# ---------- 6. per-language latest.json (repo-file distribution) ----------
Write-Host "[6/7] writing release\$Lang-latest.json ..."
$latest = [ordered]@{
    lang     = $Lang
    language = $P.TargetLang
    version  = $Version
    date     = (Get-Date -Format 'yyyy-MM-dd')
    zipUrl     = "https://raw.githubusercontent.com/{REPO}/main/release/${zipName}.zip"
    zipFullUrl = "https://raw.githubusercontent.com/{REPO}/main/release/${zipName}_full.zip"
    sha256     = $shaPatch
    sha256Full = $shaFull
    rules      = $P.RulesNote
    notes      = "https://raw.githubusercontent.com/{REPO}/main/CHANGELOG.md"
}
if ($null -eq $shaFull) { $latest.Remove('sha256Full') }
[IO.File]::WriteAllText("$distrib\${Lang}-latest.json", ($latest | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))

# ---------- 7. build report ----------
Write-Host "[7/7] writing build report ..."
$sizePatch = [math]::Round((Get-Item $zipPatch).Length / 1KB, 1)
$sizeFull = if ($zipFull) { [math]::Round((Get-Item $zipFull).Length / 1KB, 1) } else { '-' }
$fontsNote = if ($P.EmbeddedFonts) { "fonts x3" } else { "no fonts (game-embedded font)" }
$report = @()
$report += "EarthX2$($P.TargetLang) build report"
$report += "date:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "version:   $Version (lang: $Lang)"
$report += "gate:      verify.ps1 PASS (strings 0 FAIL, unique ORIG $($P.UniqueOrig), FLAG valid, no conflicts)"
$report += "$($P.JsonDirName.ToLower()):   $zhCount JSON files"
$report += "plugin:    $plugCount files (dll + tsv + README + src + version.txt + $fontsNote)"
$report += "zip patch: $(Split-Path -Leaf $zipPatch) ($sizePatch KB) sha256=$shaPatch"
if ($zipFull) { $report += "zip full:  $(Split-Path -Leaf $zipFull) ($sizeFull KB) sha256=$shaFull" }
$report += "note:      $fullNote"
$report | Set-Content -LiteralPath "$distrib\_build_report_$Lang.txt" -Encoding UTF8
$report | Write-Host

# cleanup staging
Remove-Item -LiteralPath $staging -Recurse -Force
if ((-not $SkipFull) -and (Test-Path -LiteralPath "$publish\_staging_full")) { Remove-Item -LiteralPath "$publish\_staging_full" -Recurse -Force }
Write-Host "BUILD OK -> $distrib"
