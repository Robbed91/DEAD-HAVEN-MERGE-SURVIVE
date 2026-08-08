Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$expressions = @('neutral', 'concerned', 'angry', 'afraid', 'relieved', 'injured', 'exhausted', 'determined')

function Export-Portraits([string]$characterId, [array]$boxes) {
    $sourcePath = Join-Path $repoRoot "assets/art/characters/source/${characterId}_sheet.png"
    $outputDir = Join-Path $repoRoot "assets/art/characters/${characterId}/portraits"
    $source = [System.Drawing.Bitmap]::FromFile($sourcePath)
    try {
        for ($index = 0; $index -lt $expressions.Count; $index++) {
            $box = $boxes[$index]
            $sourceRect = [System.Drawing.Rectangle]::new($box[0], $box[1], $box[2], $box[3])
            $output = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($output)
            try {
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 512, 512), $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            } finally {
                $graphics.Dispose()
            }
            $output.Save((Join-Path $outputDir "$($expressions[$index]).png"), [System.Drawing.Imaging.ImageFormat]::Png)
            $output.Dispose()
        }
    } finally {
        $source.Dispose()
    }
}

$riley = @(
    @(893, 621, 144, 177), @(1055, 621, 144, 177), @(1217, 621, 144, 177), @(1379, 621, 144, 177),
    @(893, 826, 144, 177), @(1217, 826, 144, 177), @(1055, 826, 144, 177), @(1379, 826, 144, 177)
)
$caleb = @(
    @(668, 592, 177, 180), @(867, 592, 177, 180), @(1068, 592, 195, 180), @(1287, 592, 235, 180),
    @(668, 795, 177, 215), @(1068, 795, 195, 215), @(867, 795, 177, 215), @(1287, 795, 235, 215)
)

Export-Portraits 'riley_chen' $riley
Export-Portraits 'caleb_rusk' $caleb
Write-Output 'Corrected Riley Chen and Caleb Rusk portrait crops.'
