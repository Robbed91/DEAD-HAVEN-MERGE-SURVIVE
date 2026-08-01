param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourceDir = Join-Path $RepositoryRoot 'assets/branding/android/source'
$outputDir = Join-Path $RepositoryRoot 'assets/branding/android'
$evidenceDir = Join-Path $RepositoryRoot 'docs/android-launcher-captures'
$androidResDir = Join-Path $RepositoryRoot 'android/build/res'

New-Item -ItemType Directory -Force -Path $outputDir, $evidenceDir | Out-Null

function New-Bitmap([int]$width, [int]$height) {
    return [System.Drawing.Bitmap]::new(
        $width,
        $height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
}

function Open-Bitmap([string]$path) {
    $loaded = [System.Drawing.Image]::FromFile($path)
    try {
        $copy = New-Bitmap $loaded.Width $loaded.Height
        $graphics = [System.Drawing.Graphics]::FromImage($copy)
        try {
            $graphics.DrawImageUnscaled($loaded, 0, 0)
        }
        finally {
            $graphics.Dispose()
        }
        return $copy
    }
    finally {
        $loaded.Dispose()
    }
}

function Save-Png([System.Drawing.Bitmap]$bitmap, [string]$path) {
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Set-HighQuality([System.Drawing.Graphics]$graphics) {
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
}

function Resize-Square([System.Drawing.Bitmap]$source, [int]$size) {
    $output = New-Bitmap $size $size
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        Set-HighQuality $graphics
        $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $size, $size))
    }
    finally {
        $graphics.Dispose()
    }
    return $output
}

function Set-FullyOpaque([System.Drawing.Bitmap]$bitmap) {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -ne 255) {
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }
}

function Remove-Green-Key([System.Drawing.Bitmap]$source) {
    $output = New-Bitmap $source.Width $source.Height
    for ($y = 0; $y -lt $source.Height; $y++) {
        for ($x = 0; $x -lt $source.Width; $x++) {
            $pixel = $source.GetPixel($x, $y)
            # Generated chroma canvases can contain small luminance variations.
            # Key by green dominance instead of distance from one exact RGB value.
            $greenDominance = $pixel.G - [Math]::Max($pixel.R, $pixel.B)
            $alpha = [Math]::Max(0, [Math]::Min(255, [int]((42.0 - $greenDominance) * 255.0 / 34.0)))
            if ($alpha -eq 0) {
                $output.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                continue
            }

            # Suppress green spill only where green dominates both red and blue.
            $despilledGreen = $pixel.G
            $naturalLimit = [Math]::Max($pixel.R, $pixel.B)
            if ($despilledGreen -gt $naturalLimit) {
                $despilledGreen = $naturalLimit
            }
            $output.SetPixel(
                $x,
                $y,
                [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $despilledGreen, $pixel.B)
            )
        }
    }
    return $output
}

function Find-AlphaBounds([System.Drawing.Bitmap]$bitmap) {
    $left = $bitmap.Width
    $top = $bitmap.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            if ($bitmap.GetPixel($x, $y).A -gt 12) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        throw 'Foreground chroma removal produced no opaque subject.'
    }
    return [System.Drawing.Rectangle]::FromLTRB($left, $top, $right + 1, $bottom + 1)
}

function Place-In-Safe-Zone(
    [System.Drawing.Bitmap]$source,
    [System.Drawing.Rectangle]$bounds,
    [int]$canvasSize,
    [int]$safeDiameter
) {
    $scale = [Math]::Min($safeDiameter / $bounds.Width, $safeDiameter / $bounds.Height)
    $targetWidth = [Math]::Max(1, [int][Math]::Round($bounds.Width * $scale))
    $targetHeight = [Math]::Max(1, [int][Math]::Round($bounds.Height * $scale))
    $targetX = [int][Math]::Round(($canvasSize - $targetWidth) / 2.0)
    $targetY = [int][Math]::Round(($canvasSize - $targetHeight) / 2.0)
    $output = New-Bitmap $canvasSize $canvasSize
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        Set-HighQuality $graphics
        $graphics.DrawImage(
            $source,
            [System.Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight),
            $bounds,
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }
    finally {
        $graphics.Dispose()
    }
    return $output
}

function New-Monochrome([System.Drawing.Bitmap]$foreground) {
    # A literal alpha copy of the detailed gate reads like a letter at themed-
    # launcher size. Use an authored, safe-zone-contained fortified-doorway
    # silhouette instead: a heavy peaked frame plus a separated door slab.
    $output = New-Bitmap $foreground.Width $foreground.Height
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $framePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $doorPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    try {
        Set-HighQuality $graphics
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $framePath.AddPolygon([System.Drawing.Point[]]@(
            [System.Drawing.Point]::new(117, 326),
            [System.Drawing.Point]::new(117, 164),
            [System.Drawing.Point]::new(151, 164),
            [System.Drawing.Point]::new(216, 105),
            [System.Drawing.Point]::new(281, 164),
            [System.Drawing.Point]::new(315, 164),
            [System.Drawing.Point]::new(315, 326),
            [System.Drawing.Point]::new(272, 326),
            [System.Drawing.Point]::new(272, 194),
            [System.Drawing.Point]::new(160, 194),
            [System.Drawing.Point]::new(160, 326)
        ))
        $doorPath.AddPolygon([System.Drawing.Point[]]@(
            [System.Drawing.Point]::new(176, 326),
            [System.Drawing.Point]::new(176, 226),
            [System.Drawing.Point]::new(216, 202),
            [System.Drawing.Point]::new(256, 226),
            [System.Drawing.Point]::new(256, 326)
        ))
        $graphics.FillPath($brush, $framePath)
        $graphics.FillPath($brush, $doorPath)
    }
    finally {
        $brush.Dispose()
        $doorPath.Dispose()
        $framePath.Dispose()
        $graphics.Dispose()
    }
    return $output
}

function New-RoundedRectanglePath([System.Drawing.RectangleF]$rectangle, [float]$radius) {
    $diameter = $radius * 2.0
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc($rectangle.Left, $rectangle.Top, $diameter, $diameter, 180, 90)
    $path.AddArc($rectangle.Right - $diameter, $rectangle.Top, $diameter, $diameter, 270, 90)
    $path.AddArc($rectangle.Right - $diameter, $rectangle.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($rectangle.Left, $rectangle.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-MaskPath([string]$mask, [System.Drawing.RectangleF]$rectangle) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    switch ($mask) {
        'circle' { $path.AddEllipse($rectangle) }
        'squircle' {
            $path.Dispose()
            return New-RoundedRectanglePath $rectangle ($rectangle.Width * 0.27)
        }
        'rounded' {
            $path.Dispose()
            return New-RoundedRectanglePath $rectangle ($rectangle.Width * 0.16)
        }
        default { $path.AddRectangle($rectangle) }
    }
    return $path
}

function New-ThemedComposite(
    [System.Drawing.Bitmap]$alphaSource,
    [System.Drawing.Color]$iconColor,
    [System.Drawing.Color]$surfaceColor
) {
    $output = New-Bitmap $alphaSource.Width $alphaSource.Height
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.Clear($surfaceColor)
    }
    finally {
        $graphics.Dispose()
    }
    for ($y = 0; $y -lt $alphaSource.Height; $y++) {
        for ($x = 0; $x -lt $alphaSource.Width; $x++) {
            $alpha = $alphaSource.GetPixel($x, $y).A
            if ($alpha -gt 0) {
                $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $iconColor))
            }
        }
    }
    return $output
}

function New-PreviewTile(
    [System.Drawing.Bitmap]$image,
    [string]$mask,
    [string]$label,
    [System.Drawing.Color]$surface
) {
    $tile = New-Bitmap 240 280
    $graphics = [System.Drawing.Graphics]::FromImage($tile)
    $path = $null
    $font = $null
    $brush = $null
    try {
        $graphics.Clear($surface)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $iconRect = [System.Drawing.RectangleF]::new(24, 24, 192, 192)
        $path = New-MaskPath $mask $iconRect
        $graphics.SetClip($path)
        $graphics.DrawImage($image, $iconRect)
        $graphics.ResetClip()
        $font = [System.Drawing.Font]::new('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 235, 235, 235))
        $format = [System.Drawing.StringFormat]::new()
        try {
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $graphics.DrawString($label, $font, $brush, [System.Drawing.RectangleF]::new(8, 230, 224, 36), $format)
        }
        finally {
            $format.Dispose()
        }
    }
    finally {
        if ($path) { $path.Dispose() }
        if ($font) { $font.Dispose() }
        if ($brush) { $brush.Dispose() }
        $graphics.Dispose()
    }
    return $tile
}

function New-MaskedIcon([System.Drawing.Bitmap]$image, [string]$mask, [int]$size) {
    $output = New-Bitmap $size $size
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    $path = $null
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $rectangle = [System.Drawing.RectangleF]::new(0, 0, $size, $size)
        $path = New-MaskPath $mask $rectangle
        $graphics.SetClip($path)
        $graphics.DrawImage($image, $rectangle)
        $graphics.ResetClip()
    }
    finally {
        if ($path) { $path.Dispose() }
        $graphics.Dispose()
    }
    return $output
}

$master = Open-Bitmap (Join-Path $sourceDir 'launcher_master_1024.png')
$backgroundMaster = Open-Bitmap (Join-Path $sourceDir 'adaptive_background_master_1024.png')
$foregroundChroma = Open-Bitmap (Join-Path $sourceDir 'adaptive_foreground_chroma_1024.png')

try {
    $launcher = Resize-Square $master 512
    $background = Resize-Square $backgroundMaster 432
    Set-FullyOpaque $launcher
    Set-FullyOpaque $background
    $foregroundCutout = Remove-Green-Key $foregroundChroma
    try {
        $alphaBounds = Find-AlphaBounds $foregroundCutout
        # Android's guaranteed adaptive-icon safe zone is approximately 66/108.
        # Keep the complete authored gate within 60% to tolerate OEM mask variance.
        $foreground = Place-In-Safe-Zone $foregroundCutout $alphaBounds 432 260
    }
    finally {
        $foregroundCutout.Dispose()
    }
    $monochrome = New-Monochrome $foreground

    try {
        Save-Png $launcher (Join-Path $outputDir 'launcher_main.png')
        Save-Png $foreground (Join-Path $outputDir 'adaptive_foreground.png')
        Save-Png $background (Join-Path $outputDir 'adaptive_background.png')
        Save-Png $monochrome (Join-Path $outputDir 'adaptive_monochrome.png')

        # Godot 4.3.stable predates its own monochrome export implementation.
        # Supply the same density ladder expected by the later 4.3 branch via
        # the Gradle project's resource overlay, while retaining the preset
        # reference for forward-compatible validation.
        $monochromeTargets = @(
            @{ Folder = 'mipmap'; Size = 432 },
            @{ Folder = 'mipmap-xxxhdpi-v4'; Size = 432 },
            @{ Folder = 'mipmap-xxhdpi-v4'; Size = 324 },
            @{ Folder = 'mipmap-xhdpi-v4'; Size = 216 },
            @{ Folder = 'mipmap-hdpi-v4'; Size = 162 },
            @{ Folder = 'mipmap-mdpi-v4'; Size = 108 }
        )
        foreach ($target in $monochromeTargets) {
            $targetDir = Join-Path $androidResDir $target.Folder
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            $densityIcon = Resize-Square $monochrome $target.Size
            try {
                Save-Png $densityIcon (Join-Path $targetDir 'icon_monochrome.png')
            }
            finally {
                $densityIcon.Dispose()
            }
        }

        $composite = New-Bitmap 432 432
        $graphics = [System.Drawing.Graphics]::FromImage($composite)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $graphics.DrawImageUnscaled($background, 0, 0)
            $graphics.DrawImageUnscaled($foreground, 0, 0)
        }
        finally {
            $graphics.Dispose()
        }
        try {
            Save-Png $composite (Join-Path $evidenceDir 'adaptive_composite_full_square.png')

            $themedLight = New-ThemedComposite $monochrome ([System.Drawing.Color]::FromArgb(255, 45, 55, 65)) ([System.Drawing.Color]::FromArgb(255, 224, 218, 202))
            $themedDark = New-ThemedComposite $monochrome ([System.Drawing.Color]::FromArgb(255, 231, 190, 111)) ([System.Drawing.Color]::FromArgb(255, 25, 31, 38))

            $smallPreviewSpecs = @(
                @{ Image = $composite; Mask = 'circle'; Name = 'launcher_48_circle.png' },
                @{ Image = $composite; Mask = 'squircle'; Name = 'launcher_48_squircle.png' },
                @{ Image = $composite; Mask = 'rounded'; Name = 'launcher_48_rounded_square.png' },
                @{ Image = $launcher; Mask = 'square'; Name = 'launcher_48_legacy_square.png' },
                @{ Image = $themedLight; Mask = 'circle'; Name = 'launcher_48_themed_light.png' },
                @{ Image = $themedDark; Mask = 'circle'; Name = 'launcher_48_themed_dark.png' }
            )
            foreach ($smallSpec in $smallPreviewSpecs) {
                $smallIcon = New-MaskedIcon $smallSpec.Image $smallSpec.Mask 48
                try {
                    Save-Png $smallIcon (Join-Path $evidenceDir $smallSpec.Name)
                }
                finally {
                    $smallIcon.Dispose()
                }
            }

            $contactSheet = New-Bitmap 1440 280
            $sheetGraphics = [System.Drawing.Graphics]::FromImage($contactSheet)
            try {
                $sheetGraphics.Clear([System.Drawing.Color]::FromArgb(255, 32, 37, 43))
                $previewSpecs = @(
                    @{ Image = $composite; Mask = 'circle'; Label = 'Adaptive - circle' },
                    @{ Image = $composite; Mask = 'squircle'; Label = 'Adaptive - squircle' },
                    @{ Image = $composite; Mask = 'rounded'; Label = 'Adaptive - rounded square' },
                    @{ Image = $launcher; Mask = 'square'; Label = 'Legacy - full square' },
                    @{ Image = $themedLight; Mask = 'circle'; Label = 'Themed - light' },
                    @{ Image = $themedDark; Mask = 'circle'; Label = 'Themed - dark' }
                )
                for ($index = 0; $index -lt $previewSpecs.Count; $index++) {
                    $spec = $previewSpecs[$index]
                    $tile = New-PreviewTile $spec.Image $spec.Mask $spec.Label ([System.Drawing.Color]::FromArgb(255, 32, 37, 43))
                    try {
                        $sheetGraphics.DrawImageUnscaled($tile, $index * 240, 0)
                    }
                    finally {
                        $tile.Dispose()
                    }
                }
                Save-Png $contactSheet (Join-Path $evidenceDir 'launcher_mask_contact_sheet.png')
            }
            finally {
                $sheetGraphics.Dispose()
                $contactSheet.Dispose()
                $themedLight.Dispose()
                $themedDark.Dispose()
            }
        }
        finally {
            $composite.Dispose()
        }
    }
    finally {
        $launcher.Dispose()
        $foreground.Dispose()
        $background.Dispose()
        $monochrome.Dispose()
    }
}
finally {
    $master.Dispose()
    $backgroundMaster.Dispose()
    $foregroundChroma.Dispose()
}

Write-Output 'Android launcher assets generated: main=512, adaptive layers=432, foreground safe diameter=260.'
