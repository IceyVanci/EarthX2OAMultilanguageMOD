# generate-terms.ps1 - Generate TERMS-CHS.md (term glossary: ORIG + Chinese translation)
# for manual proofreading, from the published CHS plugin TSV files.
#
# Data source: publish\CHS\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese\
#   zh-strings*.tsv  : 4 columns per line -  scope::Method ^^^ ORIG ^^^ ZH ^^^ FLAG
#   zh-baked*.tsv    : 2 columns per line -  ORIG ^^^ ZH            (skip '#' comments)
#
# Output:      publish\TERMS-CHS.md (UTF-8, no BOM, ASCII script)
# Dedup:       by ORIG within the whole corpus (first occurrence wins).
# Grouping:    by source file (strings + baked each get their own section).
# Sorting:     within a file, by ORIG (ordinal).
#
# PowerShell 5.1 notes: script is pure ASCII so the 5.1 ANSI-parsing trap is avoided;
# output is written UTF-8 without BOM so the .md renders correctly.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$publish = Split-Path -Parent $PSScriptRoot
$plug = Join-Path $publish 'CHS\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese'
$out = Join-Path $publish 'TERMS-CHS.md'

if (-not (Test-Path -LiteralPath $plug)) { throw "plugin dir not found: $plug" }

# Escape special characters for a Markdown table cell.
function Esc-Cell([string]$s) {
    if ($null -eq $s) { return '' }
    $s = $s -replace '\r', '' -replace '`n', '<br>' -replace '`r', ''
    $s = $s -replace '\|', '\|'
    return $s.Trim()
}

# Gather rows. Each row: File, Kind, Orig, Zh, Scope, Flag.
$rows = @()

# --- strings (scope::method ^^^ ORIG ^^^ ZH ^^^ FLAG) ---
foreach ($f in (Get-ChildItem -LiteralPath $plug -Filter 'zh-strings*.tsv' | Sort-Object Name)) {
    foreach ($raw in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
        $t = $raw.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $p = $t.Split(@('^^^'), [StringSplitOptions]::None)
        if ($p.Length -lt 4) { continue }
        $rows += [pscustomobject]@{
            File  = $f.Name
            Kind  = 'IL string'
            Orig  = $p[1]
            Zh    = $p[2]
            Scope = $p[0]
            Flag  = $p[3]
        }
    }
}

# --- baked (ORIG ^^^ ZH), skip '#' comment lines ---
foreach ($f in (Get-ChildItem -LiteralPath $plug -Filter 'zh-baked*.tsv' | Sort-Object Name)) {
    foreach ($raw in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
        $t = $raw.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $p = $t.Split(@('^^^'), [StringSplitOptions]::None)
        if ($p.Length -lt 2) { continue }
        $rows += [pscustomobject]@{
            File  = $f.Name
            Kind  = 'Baked'
            Orig  = $p[0]
            Zh    = $p[1]
            Scope = ''
            Flag  = ''
        }
    }
}

# --- dedupe by ORIG (first occurrence wins), preserving file grouping ---
$seen = @{}
$uniq = @()
foreach ($r in $rows) {
    if ($seen.ContainsKey($r.Orig)) { continue }
    $seen[$r.Orig] = 1
    $uniq += $r
}

# --- build the Markdown document ---
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# CHS 术语对照表（原文 / 中文翻译，供人工校对）')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("> 生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm')  ")
[void]$sb.AppendLine("> 数据来源: `publish\CHS\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese\` 下的 TSV 文件  ")
[void]$sb.AppendLine("> 行格式: strings = `作用域::方法 ^^^ 原文 ^^^ 译文 ^^^ FLAG`；baked = `原文 ^^^ 译文`  ")
[void]$sb.AppendLine("> 共 $($rows.Count) 条（strings $((@($rows|?{$_.Kind -eq 'IL string'})).Count) + baked $((@($rows|?{$_.Kind -eq 'Baked'})).Count)），按原文去重后 $($uniq.Count) 条  ")
[void]$sb.AppendLine("> 说明: 逐条列出原文(ORIG)与译文(ZH)便于人工校对；重复原文仅保留首次出现。")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('')

foreach ($kind in @('IL string', 'Baked')) {
    $files = @($uniq | Where-Object { $_.Kind -eq $kind } | Select-Object -ExpandProperty File -Unique)
    foreach ($fn in $files) {
        $group = @($uniq | Where-Object { $_.File -eq $fn } | Sort-Object Orig)
        [void]$sb.AppendLine("## $fn  ($($group.Count) 条)")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| 原文 (ORIG) | 译文 (ZH) | 作用域 | FLAG |')
        [void]$sb.AppendLine('|---|---|---|---|')
        foreach ($r in $group) {
            [void]$sb.AppendLine("| $(Esc-Cell $r.Orig) | $(Esc-Cell $r.Zh) | $(Esc-Cell $r.Scope) | $(Esc-Cell $r.Flag) |")
        }
        [void]$sb.AppendLine('')
    }
}

[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote $out  (rows=$($rows.Count), unique=$($uniq.Count))"