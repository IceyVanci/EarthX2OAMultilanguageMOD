# build-artifacts.ps1 - Release builder for the EarthX2OAMultilanguageMOD project (multi-language).
# Produces (per language, -Lang CHS|DEU|JPN|FRA|POR|ESP|KOR):
#   release\<LANG>-<ZipMod>_v<ver>.zip          (patch only: language JSON + plugin + <LANG>-NOTES + font license)
#   release\<LANG>-<ZipMod>_v<ver>.zip.sha256
#   release\<LANG>-<ZipMod>_v<ver>_full.zip     (patch + unmodified BepInEx/Doorstop framework, LGPL-2.1)
#   release\<LANG>-<ZipMod>_v<ver>_full.zip.sha256
#   release\<LANG>-latest.json  + release\_build_report_<LANG>.txt
#   release\_manifest_<LANG>.json               (incremental-build manifest, tracked in git)
# Decoupled packaging (2026-09-03):
#   - Patch zips contain ONLY language content (no shared root docs, no other languages' docs).
#     Shared docs (README/README_CN/AI-PATCH-GUIDE + docs\*) live in the repo root only.
#   - Incremental skip: if langHash / frameworkHash / version are unchanged and the artifacts
#     already exist, the build is skipped (SKIP) without touching zip/sha/latest.json/manifest.
#     Use -Force to rebuild regardless.
#   - -All builds every released language (whitelist below), each with its own skip logic.
# Workflow:
#   CHS: refresh publish repo tree from workspace -> hard gate (verify.ps1) -> stage zips FROM the repo tree.
#   Others: offline-authored repo tree (no workspace refresh) -> hard gate -> stage zips FROM the repo tree.
# Distribution is repo-file based: zips + sha256 + <LANG>-latest.json live in release\ and are
# committed to git (no GitHub Releases). URLs point at raw.githubusercontent.com/{REPO}/main/...;
# replace {REPO} with 用户名/仓库名 before first push.
param(
    [string]$GameRoot = "",
    [string]$Lang = "CHS",
    [string]$Version = "",
    [switch]$SkipFull,
    [switch]$Force,
    [switch]$All
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
        Released      = $true
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
        Released      = $true
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
        Released      = $true
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
        Released      = $false
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
        Released      = $false
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
        Released      = $true
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
        Released      = $true
        RulesNote     = "591 lines / 580 unique ORIG; baked 299; JSON 64 files; embedded font Source Han Sans K (OFL 1.1)"
    }
}
if (-not $profiles.ContainsKey($Lang)) { throw "unknown Lang '$Lang' (expected CHS, DEU, JPN, FRA, POR, ESP or KOR)" }

# ---- hash helpers (content-based, deterministic) ----
function Get-TreeHash([string]$root) {
    if (-not (Test-Path -LiteralPath $root)) { return "" }
    $base = $root.TrimEnd('\').Length + 1
    $sb = New-Object System.Text.StringBuilder
    Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object {
        $rel = $_.FullName.Substring($base)
        $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        [void]$sb.AppendLine($rel + "=" + $h)
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hb = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($sb.ToString())) }
    finally { $sha.Dispose() }
    return (([BitConverter]::ToString($hb)) -replace '-','').ToLower()
}

function Get-FilesHash([string[]]$paths) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($p in ($paths | Sort-Object)) {
        if (Test-Path -LiteralPath $p) {
            $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            [void]$sb.AppendLine($p + "=" + $h)
        }
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hb = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($sb.ToString())) }
    finally { $sha.Dispose() }
    return (([BitConverter]::ToString($hb)) -replace '-','').ToLower()
}

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

# ---- per-language build ----
function Invoke-Build([string]$lang) {
    $P = $profiles[$lang]
    $prefix = $P.Prefix
    $langTree = "$publish\$lang\EarthX 2 Open Alpha"
    $repoZh = "$langTree\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
    $repoPlug = "$langTree\BepInEx\plugins\$($P.PlugDirName)"
    $zipName = "${lang}-$($P.ZipMod)_v$Version"
    $zipPatch = "$distrib\$zipName.zip"
    $zipFull = "$distrib\${zipName}_full.zip"
    $manifestPath = "$distrib\_manifest_${lang}.json"

    Write-Host ""
    Write-Host "=== EarthX2$($P.TargetLang) build v$Version [$lang] ==="
    New-Item -ItemType Directory -Path $distrib -Force | Out-Null

    # ---------- 1. refresh repo tree from workspace (CHS only) / existence checks ----------
    if ($P.FromWorkspace) {
        Write-Host "[1/7] refreshing publish repo tree ($lang) from workspace ..."
        $zhSrc = "$game\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
        $plug = "$game\BepInEx\plugins\$($P.PlugDirName)"
        New-Item -ItemType Directory -Path $repoZh -Force | Out-Null
        Get-ChildItem -LiteralPath $zhSrc -Recurse -File | Where-Object { $_.Name -notin @('.DS_Store','Thumbs.db') } | ForEach-Object {
            $rel = $_.FullName.Substring($zhSrc.Length).TrimStart('\')
            $d = Split-Path -Parent (Join-Path $repoZh $rel)
            if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $repoZh $rel) -Force
        }
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
        Write-Host "[1/7] offline-authored language ($lang): repo tree is the source, skipping workspace refresh"
        if (-not (Test-Path -LiteralPath $repoPlug)) { throw "repo plug tree missing: $repoPlug (author $lang content first)" }
        if (-not (Test-Path -LiteralPath $repoZh))   { throw "repo language tree missing: $repoZh (author $lang content first)" }
    }
    [IO.File]::WriteAllText("$repoPlug\version.txt", "$Version`n", (New-Object System.Text.UTF8Encoding($false)))
    $repoZhCount = (Get-ChildItem $repoZh -Recurse -Filter '*.json').Count
    $repoPlugCount = (Get-ChildItem $repoPlug -Recurse -File).Count
    Write-Host "    repo tree: $($P.JsonDirName) JSON $repoZhCount | plugin files $repoPlugCount"

    # ---------- 2. incremental skip decision (decoupled manifest) ----------
    $langHash = Get-TreeHash $langTree
    $frameworkFiles = @(
        "$game\winhttp.dll", "$game\doorstop_config.ini", "$game\.doorstop_version"
    ) + @(Get-ChildItem -Path "$game\BepInEx\core" -Filter '*.dll' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $frameworkHash = Get-FilesHash $frameworkFiles

    $manifest = $null
    if (Test-Path -LiteralPath $manifestPath) {
        try { $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $manifest = $null }
    }

    $skipPatch = (-not $Force) -and ($null -ne $manifest) -and
                 ($manifest.version -eq $Version) -and ($manifest.langHash -eq $langHash) -and
                 (Test-Path -LiteralPath $zipPatch)
    $skipFull  = $SkipFull -or ((-not $Force) -and ($null -ne $manifest) -and
                 ($manifest.version -eq $Version) -and ($manifest.langHash -eq $langHash) -and
                 ($manifest.frameworkHash -eq $frameworkHash) -and (Test-Path -LiteralPath $zipFull))

    if ($skipPatch -and $skipFull) {
        Write-Host "    SKIP (unchanged): langHash + frameworkHash + version identical, artifacts present"
        $report = @()
        $report += "EarthX2$($P.TargetLang) build report (SKIP)"
        $report += "date:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $report += "version:   $Version (lang: $lang)"
        $report += "result:    SKIP - no content change (langHash=$($langHash.Substring(0,8))..., frameworkHash=$($frameworkHash.Substring(0,8))...)"
        $report += "zip patch: $(Split-Path -Leaf $zipPatch) (exists, not rebuilt)"
        $report += "zip full:  $(Split-Path -Leaf $zipFull) (exists, not rebuilt)"
        $report | Set-Content -LiteralPath "$distrib\_build_report_$lang.txt" -Encoding UTF8
        $report | Write-Host
        return "SKIP"
    }

    # ---------- 3. quality gate ----------
    Write-Host "[2/7] quality gate (verify.ps1 -Lang $lang) ..."
    $verifyOut = & powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\verify.ps1" -GameRoot $game -Lang $lang
    $verifyOut | Write-Host
    if ($LASTEXITCODE -ne 0) { throw "verify.ps1 FAILED - build aborted." }

    # ---------- 4. patch staging (language content ONLY) ----------
    Write-Host "[3/7] staging patch content from repo tree (language-only, decoupled) ..."
    $staging = "$publish\_staging_patch"
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    New-Item -ItemType Directory -Path $staging -Force | Out-Null

    $dstZh = "$staging\EarthX_Data\StreamingAssets\Localization\$($P.JsonDirName)"
    New-Item -ItemType Directory -Path $dstZh -Force | Out-Null
    Get-ChildItem -LiteralPath $repoZh -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($repoZh.Length).TrimStart('\')
        $d = Split-Path -Parent (Join-Path $dstZh $rel)
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dstZh $rel) -Force
    }
    $zhCount = (Get-ChildItem $dstZh -Recurse -Filter '*.json').Count

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

    # language guide + font license ONLY (no shared root docs, no other languages' docs)
    $notesFile = "$publish\docs\${lang}-NOTES.md"
    if (Test-Path -LiteralPath $notesFile) {
        New-Item -ItemType Directory -Path "$staging\docs" -Force | Out-Null
        Copy-Item -LiteralPath $notesFile -Destination "$staging\docs" -Force
    }
    New-Item -ItemType Directory -Path "$staging\licenses" -Force | Out-Null
    if ($P.EmbeddedFonts) {
        $fontLic = if ($P.FontLicense) { $P.FontLicense } else { 'SourceHanSansCN-LICENSE.txt' }
        Copy-Item -LiteralPath "$publish\licenses\$fontLic" -Destination "$staging\licenses" -Force
    }

    $forbidden = Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object {
        $_.FullName -match 'rules_backup|__MACOSX' -or
        $_.Name -in @('.DS_Store','Thumbs.db','winhttp.dll','doorstop_config.ini','update.ps1','manifest.txt') -or
        $_.FullName -match '\\English\\' -or $_.FullName -match 'BepInEx\\core\\' -or $_.Extension -eq '.log'
    }
    if ($forbidden) { $forbidden | Select-Object -First 8 | ForEach-Object { Write-Host "  FORBIDDEN: $($_.FullName)" }; throw "forbidden files inside patch staging" }
    if (-not $P.EmbeddedFonts -and (Test-Path -LiteralPath "$dstPlug\fonts")) { throw "$lang must not ship fonts\ (game-embedded font policy)" }

    # decoupling assertion: patch zip must contain ONLY this language's content.
    # no shared root docs, no other languages' NOTES, no shared license set.
    foreach ($rootDoc in @('README.md','README_CN.md','AI-PATCH-GUIDE.md')) {
        if (Test-Path -LiteralPath "$staging\$rootDoc") { throw "decoupling violation: shared root doc $rootDoc leaked into $lang patch staging" }
    }
    if (Test-Path -LiteralPath "$staging\docs") {
        $docsLeak = Get-ChildItem -LiteralPath "$staging\docs" -File | Where-Object { $_.Name -ne "${lang}-NOTES.md" }
        if ($docsLeak) { $docsLeak | Select-Object -First 5 | ForEach-Object { Write-Host "  DOCS LEAK: $($_.Name)" }; throw "decoupling violation: non-$lang NOTES docs in $lang patch staging" }
    }
    $licExpected = if ($P.EmbeddedFonts) { @($fontLic) } else { @() }
    $licLeak = Get-ChildItem -LiteralPath "$staging\licenses" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $licExpected }
    if ($licLeak) { $licLeak | Select-Object -First 5 | ForEach-Object { Write-Host "  LIC LEAK: $($_.Name)" }; throw "decoupling violation: unexpected license file in $lang patch staging (only font license, if any; LGPL/NOTICE live in the full package)" }
    Write-Host "    $($P.JsonDirName) JSON: $zhCount | plugin files: $plugCount | docs: only ${lang}-NOTES.md | decoupling OK"

    # ---------- 5. pack patch (unless only framework changed) ----------
    $shaPatch = $null
    if (-not $skipPatch) {
        Write-Host "[4/7] packing patch zip ..."
        New-ZipUtf8 $staging $zipPatch
        $shaPatch = (Get-FileHash -LiteralPath $zipPatch -Algorithm SHA256).Hash.ToLower()
        [IO.File]::WriteAllText("$zipPatch.sha256", "$shaPatch  $(Split-Path -Leaf $zipPatch)`n", (New-Object System.Text.UTF8Encoding($false)))
    } else {
        Write-Host "[4/7] patch zip unchanged - SKIP (framework-only change detected)"
        $shaPatch = if ($manifest -and $manifest.shaPatch) { $manifest.shaPatch } else { (Get-FileHash -LiteralPath $zipPatch -Algorithm SHA256).Hash.ToLower() }
    }

    # ---------- 6. full package (framework + licenses) ----------
    $shaFull = $null; $fullNote = 'patch-only build (-SkipFull)'
    if (-not $SkipFull) {
        if (-not $skipFull) {
            Write-Host "[5/7] staging full package (framework + licenses) ..."
            $stagingF = "$publish\_staging_full"
            if (Test-Path -LiteralPath $stagingF) { Remove-Item -LiteralPath $stagingF -Recurse -Force }
            Copy-Item -LiteralPath $staging -Destination $stagingF -Recurse
            Copy-Item -LiteralPath "$game\winhttp.dll" -Destination $stagingF -Force
            Copy-Item -LiteralPath "$game\doorstop_config.ini" -Destination $stagingF -Force
            Copy-Item -LiteralPath "$game\.doorstop_version" -Destination $stagingF -Force
            New-Item -ItemType Directory -Path "$stagingF\BepInEx\core" -Force | Out-Null
            Copy-Item -Path "$game\BepInEx\core\*" -Destination "$stagingF\BepInEx\core" -Force
            New-Item -ItemType Directory -Path "$stagingF\licenses" -Force | Out-Null
            Copy-Item -Path "$publish\licenses\*" -Destination "$stagingF\licenses" -Force
            $fullNote = "full package: framework + licenses (LGPL + OFL) included"
            Write-Host "    $fullNote"
            New-ZipUtf8 $stagingF $zipFull
            $shaFull = (Get-FileHash -LiteralPath $zipFull -Algorithm SHA256).Hash.ToLower()
            [IO.File]::WriteAllText("$zipFull.sha256", "$shaFull  $(Split-Path -Leaf $zipFull)`n", (New-Object System.Text.UTF8Encoding($false)))
            Remove-Item -LiteralPath $stagingF -Recurse -Force
        } else {
            Write-Host "[5/7] full zip unchanged - SKIP"
            $shaFull = if ($manifest -and $manifest.shaFull) { $manifest.shaFull } else { (Get-FileHash -LiteralPath $zipFull -Algorithm SHA256).Hash.ToLower() }
            $fullNote = "full package (unchanged, not rebuilt)"
        }
    }

    # ---------- 7. per-language latest.json + manifest ----------
    Write-Host "[6/7] writing release\$lang-latest.json + _manifest_$lang.json ..."
    $latest = [ordered]@{
        lang     = $lang
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
    [IO.File]::WriteAllText("$distrib\${lang}-latest.json", ($latest | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))

    $manifestObj = [ordered]@{
        lang          = $lang
        version       = $Version
        date          = (Get-Date -Format 'yyyy-MM-dd')
        langHash      = $langHash
        frameworkHash = $frameworkHash
        shaPatch      = $shaPatch
        shaFull       = $shaFull
    }
    [IO.File]::WriteAllText($manifestPath, ($manifestObj | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))

    # ---------- 8. build report ----------
    Write-Host "[7/7] writing build report ..."
    $sizePatch = [math]::Round((Get-Item $zipPatch).Length / 1KB, 1)
    $sizeFull = if ($zipFull -and (Test-Path -LiteralPath $zipFull)) { [math]::Round((Get-Item $zipFull).Length / 1KB, 1) } else { '-' }
    $fontsNote = if ($P.EmbeddedFonts) { "fonts x3" } else { "no fonts (game-embedded font)" }
    $report = @()
    $report += "EarthX2$($P.TargetLang) build report"
    $report += "date:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "version:   $Version (lang: $lang)"
    $report += "gate:      verify.ps1 PASS (strings 0 FAIL, unique ORIG $($P.UniqueOrig), FLAG valid, no conflicts)"
    $report += "$($P.JsonDirName.ToLower()):   $zhCount JSON files"
    $report += "plugin:    $plugCount files (dll + tsv + README + src + version.txt + $fontsNote)"
    $report += "langHash:  $langHash"
    $report += "frameworkHash: $frameworkHash"
    $report += "zip patch: $(Split-Path -Leaf $zipPatch) ($sizePatch KB) sha256=$shaPatch"
    if ($zipFull -and (Test-Path -LiteralPath $zipFull)) { $report += "zip full:  $(Split-Path -Leaf $zipFull) ($sizeFull KB) sha256=$shaFull" }
    $report += "note:      $fullNote"
    $report | Set-Content -LiteralPath "$distrib\_build_report_$lang.txt" -Encoding UTF8
    $report | Write-Host

    # cleanup staging
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    Write-Host "BUILD OK -> $distrib"
    return "BUILT"
}

# ---- main ----
if ($All) {
    $summary = @()
    foreach ($lang in ($profiles.Keys | Where-Object { $profiles[$_].Released } | Sort-Object)) {
        try { $summary += [pscustomobject]@{ Lang = $lang; Result = (Invoke-Build $lang) } }
        catch { $summary += [pscustomobject]@{ Lang = $lang; Result = "FAILED: $($_.Exception.Message)" } }
    }
    Write-Host ""
    Write-Host "===== BATCH SUMMARY ====="
    $summary | ForEach-Object { Write-Host ("  {0,-4} {1}" -f $_.Lang, $_.Result) }
    $failed = @($summary | Where-Object { $_.Result -like 'FAILED*' })
    if ($failed.Count -gt 0) { exit 1 }
} else {
    $r = Invoke-Build $Lang
    if ($r -like 'FAILED*') { exit 1 }
}
