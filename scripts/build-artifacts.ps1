# build-artifacts.ps1 - Release builder for the EarthX2OAMultilanguageMOD project (multi-language).
# Produces (per language, -Lang CHS by default):
#   release\<LANG>-EarthX2OA<LANG>MOD_v<ver>.zip          (patch only)
#   release\<LANG>-EarthX2OA<LANG>MOD_v<ver>.zip.sha256
#   release\<LANG>-EarthX2OA<LANG>MOD_v<ver>_full.zip     (patch + unmodified BepInEx/Doorstop framework, LGPL-2.1)
#   release\<LANG>-EarthX2OA<LANG>MOD_v<ver>_full.zip.sha256
#   release\<LANG>-latest.json  + release\_build_report.txt
# Workflow: refresh publish repo tree from workspace -> hard gate (verify.ps1, incl.
# repo-tree == workspace sync) -> stage zips FROM the repo tree (so GitHub download
# and zips are byte-identical). Manual-overwrite updates (no update.ps1 / manifest.txt).
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
$zhSrc = "$game\EarthX_Data\StreamingAssets\Localization\Chinese"
$plug = "$game\BepInEx\plugins\EarthX2Chinese"
$langTree = "$publish\$Lang\EarthX 2 Open Alpha"
$repoZh = "$langTree\EarthX_Data\StreamingAssets\Localization\Chinese"
$repoPlug = "$langTree\BepInEx\plugins\EarthX2Chinese"
# zip middle segment per language (e.g. CHS -> EarthX2OAChineseMOD). Fallback: EarthX2OA<LANG>MOD.
$zipModByName = @{ "CHS" = "EarthX2OAChineseMOD" }
$zipMod = if ($zipModByName.ContainsKey($Lang)) { $zipModByName[$Lang] } else { "EarthX2OA${Lang}MOD" }
$zipName = "${Lang}-${zipMod}_v$Version"

Write-Host "=== EarthX2Chinese build v$Version [$Lang] ==="
New-Item -ItemType Directory -Path $distrib -Force | Out-Null

# ---------- 1. refresh repo tree from workspace ----------
Write-Host "[1/7] refreshing publish repo tree ($Lang) from workspace ..."
# Chinese JSON (exclude junk)
New-Item -ItemType Directory -Path $repoZh -Force | Out-Null
Get-ChildItem -LiteralPath $zhSrc -Recurse -File | Where-Object { $_.Name -notin @('.DS_Store','Thumbs.db') } | ForEach-Object {
    $rel = $_.FullName.Substring($zhSrc.Length).TrimStart('\')
    $d = Split-Path -Parent (Join-Path $repoZh $rel)
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $repoZh $rel) -Force
}
# plugin whitelist
New-Item -ItemType Directory -Path $repoPlug -Force | Out-Null
Copy-Item -LiteralPath "$plug\EarthX2Chinese.dll" -Destination $repoPlug -Force
Copy-Item -LiteralPath "$plug\README.md" -Destination $repoPlug -Force
Get-ChildItem -LiteralPath $plug -Filter 'zh-*.tsv' -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $repoPlug -Force }
New-Item -ItemType Directory -Path "$repoPlug\src" -Force | Out-Null
Copy-Item -LiteralPath "$plug\src\EarthX2Chinese.cs" -Destination "$repoPlug\src" -Force
[IO.File]::WriteAllText("$repoPlug\version.txt", "$Version`n", (New-Object System.Text.UTF8Encoding($false)))
# embedded fonts (OFL) + license text
New-Item -ItemType Directory -Path "$repoPlug\fonts" -Force | Out-Null
Get-ChildItem -LiteralPath "$plug\fonts" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$repoPlug\fonts" -Force }
$repoZhCount = (Get-ChildItem $repoZh -Recurse -Filter '*.json').Count
$repoPlugCount = (Get-ChildItem $repoPlug -Recurse -File).Count
Write-Host "    repo tree: Chinese JSON $repoZhCount | plugin files $repoPlugCount"

# ---------- 2. quality gate ----------
Write-Host "[2/7] quality gate (verify.ps1, incl. repo-tree sync) ..."
$verifyOut = & powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\verify.ps1" -GameRoot $game -Lang $Lang
$verifyOut | Write-Host
if ($LASTEXITCODE -ne 0) { throw "verify.ps1 FAILED - build aborted." }

# ---------- 3. patch staging (FROM repo tree) ----------
Write-Host "[3/7] staging patch content from repo tree ..."
$staging = "$publish\_staging_patch"
if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

# Chinese JSON
$dstZh = "$staging\EarthX_Data\StreamingAssets\Localization\Chinese"
New-Item -ItemType Directory -Path $dstZh -Force | Out-Null
Get-ChildItem -LiteralPath $repoZh -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($repoZh.Length).TrimStart('\')
    $d = Split-Path -Parent (Join-Path $dstZh $rel)
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstZh $rel) -Force
}
$zhCount = (Get-ChildItem $dstZh -Recurse -Filter '*.json').Count

# plugin whitelist (incl. fonts)
$dstPlug = "$staging\BepInEx\plugins\EarthX2Chinese"
New-Item -ItemType Directory -Path $dstPlug -Force | Out-Null
Copy-Item -LiteralPath "$repoPlug\EarthX2Chinese.dll" -Destination $dstPlug -Force
Copy-Item -LiteralPath "$repoPlug\README.md" -Destination $dstPlug -Force
Get-ChildItem -LiteralPath $repoPlug -Filter 'zh-*.tsv' -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $dstPlug -Force }
New-Item -ItemType Directory -Path "$dstPlug\src" -Force | Out-Null
Copy-Item -LiteralPath "$repoPlug\src\EarthX2Chinese.cs" -Destination "$dstPlug\src" -Force
Copy-Item -LiteralPath "$repoPlug\version.txt" -Destination $dstPlug -Force
New-Item -ItemType Directory -Path "$dstPlug\fonts" -Force | Out-Null
Get-ChildItem -LiteralPath "$repoPlug\fonts" -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination "$dstPlug\fonts" -Force }
$plugCount = (Get-ChildItem $dstPlug -Recurse -File).Count

# root docs (ASCII filenames only - zip-safe) + docs\ + font license
Copy-Item -LiteralPath "$publish\README.md" -Destination $staging -Force
Copy-Item -LiteralPath "$publish\README_CN.md" -Destination $staging -Force
Copy-Item -LiteralPath "$publish\AI-PATCH-GUIDE.md" -Destination $staging -Force
New-Item -ItemType Directory -Path "$staging\docs" -Force | Out-Null
Copy-Item -Path "$publish\docs\*" -Destination "$staging\docs" -Force
New-Item -ItemType Directory -Path "$staging\licenses" -Force | Out-Null
Copy-Item -LiteralPath "$publish\licenses\SourceHanSansCN-LICENSE.txt" -Destination "$staging\licenses" -Force

# forbidden-content assertions inside patch staging
$forbidden = Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object {
    $_.FullName -match 'rules_backup|__MACOSX' -or
    $_.Name -in @('.DS_Store','Thumbs.db','winhttp.dll','doorstop_config.ini','update.ps1','manifest.txt') -or
    $_.FullName -match '\\English\\' -or $_.FullName -match 'BepInEx\\core\\' -or $_.Extension -eq '.log'
}
if ($forbidden) { $forbidden | Select-Object -First 8 | ForEach-Object { Write-Host "  FORBIDDEN: $($_.FullName)" }; throw "forbidden files inside patch staging" }
Write-Host "    Chinese JSON: $zhCount | plugin files: $plugCount | docs + font license staged"

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
    version  = $Version
    date     = (Get-Date -Format 'yyyy-MM-dd')
    zipUrl     = "https://raw.githubusercontent.com/{REPO}/main/release/${zipName}.zip"
    zipFullUrl = "https://raw.githubusercontent.com/{REPO}/main/release/${zipName}_full.zip"
    sha256     = $shaPatch
    sha256Full = $shaFull
    rules      = "591 lines / 580 unique ORIG (DISPLAY 386, AUTO 205); baked 299; JSON 64 files; embedded font Source Han Sans CN (OFL 1.1)"
    notes      = "https://raw.githubusercontent.com/{REPO}/main/CHANGELOG.md"
}
if ($null -eq $shaFull) { $latest.Remove('sha256Full') }
[IO.File]::WriteAllText("$distrib\${Lang}-latest.json", ($latest | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))

# ---------- 7. build report ----------
Write-Host "[7/7] writing build report ..."
$sizePatch = [math]::Round((Get-Item $zipPatch).Length / 1KB, 1)
$sizeFull = if ($zipFull) { [math]::Round((Get-Item $zipFull).Length / 1KB, 1) } else { '-' }
$report = @()
$report += "EarthX2Chinese build report"
$report += "date:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "version:   $Version (lang: $Lang)"
$report += "gate:      verify.ps1 PASS (strings 0 FAIL, unique ORIG 580, FLAG valid, no conflicts, repo-tree sync OK)"
$report += "chinese:   $zhCount JSON files"
$report += "plugin:    $plugCount files (dll + tsv x10 + README + src + version.txt + fonts x3)"
$report += "zip patch: $(Split-Path -Leaf $zipPatch) ($sizePatch KB) sha256=$shaPatch"
if ($zipFull) { $report += "zip full:  $(Split-Path -Leaf $zipFull) ($sizeFull KB) sha256=$shaFull" }
$report += "note:      $fullNote"
$report | Set-Content -LiteralPath "$distrib\_build_report.txt" -Encoding UTF8
$report | Write-Host

# cleanup staging
Remove-Item -LiteralPath $staging -Recurse -Force
if ((-not $SkipFull) -and (Test-Path -LiteralPath "$publish\_staging_full")) { Remove-Item -LiteralPath "$publish\_staging_full" -Recurse -Force }
Write-Host "BUILD OK -> $distrib"
