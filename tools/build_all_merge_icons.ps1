Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'assets/items/source'
$itemRoot = Join-Path $repoRoot 'assets/items'
$outputSize = 256
$safeSize = 210
$baseline = 233
$cellGuard = 32
$chains = [ordered]@{
    tool = @{ Count = 8; Producer = $true }
    food = @{ Count = 8; Producer = $true }
    medical = @{ Count = 8; Producer = $true }
    trap = @{ Count = 8; Producer = $true }
    fuel = @{ Count = 8; Producer = $true }
    vehicle_parts = @{ Count = 8; Producer = $true }
    electronics = @{ Count = 8; Producer = $true }
    clothing = @{ Count = 8; Producer = $true }
    coin_reward = @{ Count = 7; Producer = $false }
    token_reward = @{ Count = 7; Producer = $false }
    xp_reward = @{ Count = 7; Producer = $false }
    energy_reward = @{ Count = 7; Producer = $false }
}

function Export-Cell([System.Drawing.Bitmap]$sheet, [int]$index, [string]$outputPath) {
    $cellWidth = [int]($sheet.Width / 4)
    $cellHeight = [int]($sheet.Height / 2)
    $column = $index % 4
    $row = [int][Math]::Floor($index / 4)
    $sourceRect = [System.Drawing.Rectangle]::new($column * $cellWidth, $row * $cellHeight, $cellWidth, $cellHeight)
    $cell = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cellGraphics = [System.Drawing.Graphics]::FromImage($cell)
    try {
        $cellGraphics.DrawImage($sheet, [System.Drawing.Rectangle]::new(0, 0, $cellWidth, $cellHeight), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    } finally { $cellGraphics.Dispose() }
    try {
        $matte = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $minX = $cellWidth; $minY = $cellHeight; $maxX = -1; $maxY = -1
        for ($y = 0; $y -lt $cellHeight; $y++) {
            for ($x = 0; $x -lt $cellWidth; $x++) {
                $color = $cell.GetPixel($x, $y)
                $distance = [Math]::Sqrt([Math]::Pow(255 - $color.R, 2) + [Math]::Pow($color.G, 2) + [Math]::Pow(255 - $color.B, 2))
                # Generated contact sheets can bleed a sliver of the adjacent
                # subject across an inferred cell boundary. The prompt keeps
                # every intended subject well inside this guard band.
                if ($x -lt $cellGuard -or $x -ge $cellWidth - $cellGuard -or $y -lt $cellGuard -or $y -ge $cellHeight - $cellGuard) { $alpha = 0 }
                elseif ($distance -le 28) { $alpha = 0 }
                elseif ($distance -lt 125) { $alpha = [int](255.0 * ($distance - 28.0) / 97.0) }
                else { $alpha = 255 }
                if ($alpha -gt 0) {
                    # Remove residual magenta spill from antialiased edges.
                    $red = [int]$color.R
                    $blue = [int]$color.B
                    # Generated chrome and shadows can reflect the key colour
                    # as apparently opaque magenta. Remove its common red/blue
                    # component without affecting normal rust-red or blue gear.
                    if ($red -gt $color.G + 35 -and $blue -gt $color.G + 35) {
                        $spill = [Math]::Min($red, $blue) - $color.G
                        $red = [Math]::Max(0, $red - $spill)
                        $blue = [Math]::Max(0, $blue - $spill)
                    }
                    $matte.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $red, $color.G, $blue))
                    if ($alpha -gt 24) {
                        $minX = [Math]::Min($minX, $x); $minY = [Math]::Min($minY, $y)
                        $maxX = [Math]::Max($maxX, $x); $maxY = [Math]::Max($maxY, $y)
                    }
                }
            }
        }
        if ($maxX -lt $minX -or $maxY -lt $minY) { throw "No subject found in cell $index for $outputPath" }
        $padding = 3
        $minX = [Math]::Max(0, $minX - $padding); $minY = [Math]::Max(0, $minY - $padding)
        $maxX = [Math]::Min($cellWidth - 1, $maxX + $padding); $maxY = [Math]::Min($cellHeight - 1, $maxY + $padding)
        $subjectWidth = $maxX - $minX + 1; $subjectHeight = $maxY - $minY + 1
        $scale = [Math]::Min($safeSize / [double]$subjectWidth, $safeSize / [double]$subjectHeight)
        $drawWidth = [int]($subjectWidth * $scale); $drawHeight = [int]($subjectHeight * $scale)
        $drawX = [int](($outputSize - $drawWidth) / 2)
        $drawY = $baseline - $drawHeight
        $output = [System.Drawing.Bitmap]::new($outputSize, $outputSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($output)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($matte, [System.Drawing.Rectangle]::new($drawX, $drawY, $drawWidth, $drawHeight), [System.Drawing.Rectangle]::new($minX, $minY, $subjectWidth, $subjectHeight), [System.Drawing.GraphicsUnit]::Pixel)
        } finally { $graphics.Dispose() }
        $output.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $output.Dispose(); $matte.Dispose()
    } finally { $cell.Dispose() }
}

$written = 0
foreach ($entry in $chains.GetEnumerator()) {
    $chainId = $entry.Key
    $config = $entry.Value
    $sheetPath = Join-Path $sourceRoot "${chainId}_sheet.png"
    $outputDir = Join-Path $itemRoot $chainId
    [System.IO.Directory]::CreateDirectory($outputDir) | Out-Null
    $sheet = [System.Drawing.Bitmap]::FromFile($sheetPath)
    try {
        for ($index = 0; $index -lt $config.Count; $index++) {
            $filename = if ($config.Producer -and $index -eq 7) { 'producer.png' } else { "level_$($index + 1).png" }
            Export-Cell $sheet $index (Join-Path $outputDir $filename)
            $written++
        }
    } finally { $sheet.Dispose() }
}
Write-Output "MERGE_ICONS_BUILT count=$written"
