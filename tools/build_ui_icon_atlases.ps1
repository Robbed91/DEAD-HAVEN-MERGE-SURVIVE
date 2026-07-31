Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'assets/ui/source'
$outputRoot = Join-Path $repoRoot 'assets/ui/icons/final'
$outputSize = 256
$safeSize = 216
$cellGuard = 32

$atlases = @(
    @{
        Source = 'core_icons_sheet.png'
        Names = @('energy', 'coin', 'token', 'bell', 'haven', 'merge', 'map', 'survivors', 'inventory', 'lock', 'loading', 'notification')
    },
    @{
        Source = 'map_action_icons_sheet.png'
        Names = @('farmhouse', 'fuel_station', 'school', 'hospital', 'prison', 'vehicle', 'scavenge', 'task', 'reward', 'construction', 'danger', 'focus')
    }
)

function Export-Icon([System.Drawing.Bitmap]$sheet, [int]$index, [string]$outputPath) {
    $cellWidth = [int]($sheet.Width / 4)
    $cellHeight = [int]($sheet.Height / 3)
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
                if ($x -lt $cellGuard -or $x -ge $cellWidth - $cellGuard -or $y -lt $cellGuard -or $y -ge $cellHeight - $cellGuard) { $alpha = 0 }
                elseif ($distance -le 30) { $alpha = 0 }
                elseif ($distance -lt 125) { $alpha = [int](255.0 * ($distance - 30.0) / 95.0) }
                else { $alpha = 255 }
                if ($alpha -le 0) { continue }

                $red = [int]$color.R
                $blue = [int]$color.B
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
        if ($maxX -lt $minX -or $maxY -lt $minY) { throw "No subject found for $outputPath" }
        $padding = 3
        $minX = [Math]::Max(0, $minX - $padding); $minY = [Math]::Max(0, $minY - $padding)
        $maxX = [Math]::Min($cellWidth - 1, $maxX + $padding); $maxY = [Math]::Min($cellHeight - 1, $maxY + $padding)
        $subjectWidth = $maxX - $minX + 1; $subjectHeight = $maxY - $minY + 1
        $scale = [Math]::Min($safeSize / [double]$subjectWidth, $safeSize / [double]$subjectHeight)
        $drawWidth = [int]($subjectWidth * $scale); $drawHeight = [int]($subjectHeight * $scale)
        $drawX = [int](($outputSize - $drawWidth) / 2); $drawY = [int](($outputSize - $drawHeight) / 2)
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

[System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null
$written = 0
foreach ($atlas in $atlases) {
    $sheet = [System.Drawing.Bitmap]::FromFile((Join-Path $sourceRoot $atlas.Source))
    try {
        for ($index = 0; $index -lt $atlas.Names.Count; $index++) {
            Export-Icon $sheet $index (Join-Path $outputRoot ("icon_{0}.png" -f $atlas.Names[$index]))
            $written++
        }
    } finally { $sheet.Dispose() }
}
Write-Output "UI_ICONS_BUILT count=$written"
