param(
    [string]$Rel = ""
)
$enRoot = "F:\EarthX 2 Open Alpha (Windows)\EarthX_Data\StreamingAssets\Localization\English"
function Get-Keys($path) {
    $keys = @()
    foreach ($line in [IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8)) {
        if ($line -match '^\s*"([^"]+)"\s*:') { $keys += $Matches[1] }
    }
    return $keys
}
$targets = @(
    @{ L='ESP'; D='Spanish' },
    @{ L='KOR'; D='Korean' }
)
$files = if ($Rel) { @($Rel) } else {
    Get-ChildItem -LiteralPath $enRoot -Recurse -Filter *.json | ForEach-Object {
        $_.FullName.Substring($enRoot.Length).TrimStart('\','/').Replace('\','/')
    }
}
$bad = 0
foreach ($rel in ($files | Sort-Object)) {
    $enPath = Join-Path $enRoot ($rel -replace '/','\')
    $enKeys = Get-Keys $enPath
    foreach ($t in $targets) {
        $tp = "F:\EarthX 2 Open Alpha (Windows)\publish\$($t.L)\EarthX 2 Open Alpha\EarthX_Data\StreamingAssets\Localization\$($t.D)\$($rel -replace '/','\')"
        if (-not (Test-Path -LiteralPath $tp)) { Write-Host "MISSING $($t.L): $rel"; $bad++; continue }
        $tKeys = Get-Keys $tp
        $miss = @($enKeys | Where-Object { $_ -notin $tKeys })
        $extra = @($tKeys | Where-Object { $_ -notin $enKeys })
        if ($miss.Count -gt 0 -or $extra.Count -gt 0) {
            Write-Host "KEYDIFF $($t.L) $rel : miss=$($miss -join ',') extra=$($extra -join ',')"
            $bad++
        }
    }
}
if ($bad -eq 0) { Write-Host "ALL KEY PARITY OK ($($files.Count) files)" } else { Write-Host "KEY PARITY FAILURES: $bad" }
