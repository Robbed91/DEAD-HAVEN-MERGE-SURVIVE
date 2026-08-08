param(
    [ValidateSet('redwater', 'greybridge', 'saint_mercy', 'northgate')]
    [string]$Residence = 'redwater'
)

Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $repoRoot "assets/art/$Residence"
$sourceRoot = Join-Path $assetRoot 'source'
$runtimeRoot = Join-Path $assetRoot 'runtime'
$layerRoot = Join-Path $assetRoot 'layers'
$overlayRoot = Join-Path $assetRoot 'repair_overlays'
$width = 720
$height = 1080

function Resize-Bitmap([string]$path) {
    $source = [System.Drawing.Bitmap]::FromFile($path)
    try {
        $output = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($output)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($source, 0, 0, $width, $height)
        } finally { $graphics.Dispose() }
        return $output
    } finally { $source.Dispose() }
}

function Save-Jpeg([System.Drawing.Bitmap]$image, [string]$path, [long]$quality = 91) {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
    $parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, $quality)
    $image.Save($path, $codec, $parameters)
    $parameters.Dispose()
}

function Feather-Alpha([int]$x, [int]$y, [int[]]$rect, [int]$feather) {
    if ($x -lt $rect[0] -or $x -ge $rect[2] -or $y -lt $rect[1] -or $y -ge $rect[3]) { return 0 }
    $distance = [Math]::Min([Math]::Min($x - $rect[0], $rect[2] - 1 - $x), [Math]::Min($y - $rect[1], $rect[3] - 1 - $y))
    return [Math]::Min(255, [int](255.0 * $distance / [Math]::Max(1, $feather)))
}

function Export-Band-Layer([System.Drawing.Bitmap]$source, [string]$name, [int]$top, [int]$bottom, [int]$fade) {
    $output = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = [Math]::Max(0, $top); $y -lt [Math]::Min($height, $bottom); $y++) {
        $edge = [Math]::Min($y - $top, $bottom - 1 - $y)
        $alpha = [Math]::Min(255, [int](255.0 * $edge / [Math]::Max(1, $fade)))
        for ($x = 0; $x -lt $width; $x++) {
            $c = $source.GetPixel($x, $y)
            $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B))
        }
    }
    $output.Save((Join-Path $layerRoot "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$destroyed = Resize-Bitmap (Join-Path $sourceRoot "${Residence}_master_destroyed.png")
$upgraded = Resize-Bitmap (Join-Path $sourceRoot "${Residence}_master_upgraded.png")

try {
    foreach ($directory in @($runtimeRoot, $layerRoot, $overlayRoot)) {
        if (-not (Test-Path $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    }
    Save-Jpeg $destroyed (Join-Path $runtimeRoot "${Residence}_state_01_destroyed.jpg")

    if ($Residence -eq 'northgate') {
        $hotspots = [ordered]@{
            sally_port = @(245, 700, 525, 1080)
            guard_tower = @(545, 0, 720, 420)
            armory = @(430, 290, 720, 690)
            mess_hall = @(0, 240, 385, 680)
            cell_block_a = @(135, 220, 510, 710)
            control_room = @(275, 70, 530, 455)
            transport_bay = @(0, 545, 405, 1000)
            warden_office = @(410, 90, 720, 520)
        }
        $stateGroups = @(
            @('sally_port'),
            @('sally_port', 'transport_bay', 'guard_tower'),
            @('sally_port', 'transport_bay', 'guard_tower', 'mess_hall', 'cell_block_a'),
            @('sally_port', 'transport_bay', 'guard_tower', 'mess_hall', 'cell_block_a', 'armory', 'control_room', 'warden_office')
        )
    } elseif ($Residence -eq 'saint_mercy') {
        $hotspots = [ordered]@{
            reception_er = @(245, 300, 510, 690)
            pharmacy = @(0, 285, 345, 730)
            patient_ward = @(430, 250, 720, 670)
            surgical_suite = @(390, 150, 720, 510)
            power_room = @(430, 625, 720, 1080)
            ambulance_bay = @(0, 620, 390, 1080)
            records_office = @(80, 165, 430, 535)
            isolation_ward = @(275, 0, 525, 340)
        }
        $stateGroups = @(
            @('reception_er'),
            @('reception_er', 'ambulance_bay', 'power_room'),
            @('reception_er', 'ambulance_bay', 'power_room', 'pharmacy', 'patient_ward'),
            @('reception_er', 'ambulance_bay', 'power_room', 'pharmacy', 'patient_ward', 'surgical_suite', 'records_office', 'isolation_ward')
        )
    } elseif ($Residence -eq 'greybridge') {
        $hotspots = [ordered]@{
            main_hall = @(250, 310, 505, 690)
            gymnasium = @(0, 285, 330, 700)
            library = @(450, 250, 720, 620)
            cafeteria = @(80, 300, 390, 700)
            boiler_room = @(480, 610, 720, 1080)
            admin_office = @(380, 210, 680, 500)
            playground_fence = @(0, 650, 720, 1080)
            radio_tower = @(300, 0, 470, 370)
        }
        $stateGroups = @(
            @('main_hall'),
            @('main_hall', 'playground_fence', 'gymnasium'),
            @('main_hall', 'playground_fence', 'gymnasium', 'cafeteria', 'library'),
            @('main_hall', 'playground_fence', 'gymnasium', 'cafeteria', 'library', 'boiler_room', 'admin_office', 'radio_tower')
        )
    } else {
        $hotspots = [ordered]@{
            fuel_pumps = @(45, 420, 420, 780)
            service_bay = @(430, 250, 720, 555)
            convenience_store = @(155, 260, 430, 520)
            cashier_office = @(205, 245, 475, 430)
            generator_room = @(475, 465, 720, 735)
            perimeter_fence = @(0, 245, 330, 1080)
            drainage_tunnel = @(420, 715, 720, 1080)
            garage_workshop = @(430, 280, 720, 665)
        }
        $stateGroups = @(
            @('fuel_pumps', 'drainage_tunnel'),
            @('fuel_pumps', 'drainage_tunnel', 'cashier_office', 'perimeter_fence'),
            @('fuel_pumps', 'drainage_tunnel', 'cashier_office', 'perimeter_fence', 'convenience_store', 'service_bay'),
            @('fuel_pumps', 'drainage_tunnel', 'cashier_office', 'perimeter_fence', 'convenience_store', 'service_bay', 'generator_room', 'garage_workshop')
        )
    }

    $overlays = @{}
    foreach ($entry in $hotspots.GetEnumerator()) {
        $overlay = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $rect = [int[]]$entry.Value
        for ($y = $rect[1]; $y -lt $rect[3]; $y++) {
            for ($x = $rect[0]; $x -lt $rect[2]; $x++) {
                $baseColor = $destroyed.GetPixel($x, $y)
                $finalColor = $upgraded.GetPixel($x, $y)
                $difference = [Math]::Abs($baseColor.R - $finalColor.R) + [Math]::Abs($baseColor.G - $finalColor.G) + [Math]::Abs($baseColor.B - $finalColor.B)
                if ($difference -lt 18) { continue }
                $edgeAlpha = Feather-Alpha $x $y $rect 28
                $differenceAlpha = [Math]::Min(255, $difference * 2)
                $alpha = [Math]::Min($edgeAlpha, $differenceAlpha)
                $overlay.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $finalColor.R, $finalColor.G, $finalColor.B))
            }
        }
        $overlay.Save((Join-Path $overlayRoot "$($entry.Key).png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $overlays[$entry.Key] = $overlay
    }

    $stateNames = @('02_cleared', '03_temporary', '04_habitable', '05_defended')
    for ($index = 0; $index -lt $stateGroups.Count; $index++) {
        $state = $destroyed.Clone()
        $graphics = [System.Drawing.Graphics]::FromImage($state)
        try {
            foreach ($id in $stateGroups[$index]) { $graphics.DrawImageUnscaled($overlays[$id], 0, 0) }
        } finally { $graphics.Dispose() }
        Save-Jpeg $state (Join-Path $runtimeRoot "${Residence}_state_$($stateNames[$index]).jpg")
        $state.Dispose()
    }
    Save-Jpeg $upgraded (Join-Path $runtimeRoot "${Residence}_state_06_upgraded.jpg")

    Export-Band-Layer $destroyed 'sky' 0 255 24
    Export-Band-Layer $destroyed 'distant_landscape' 135 360 28
    Export-Band-Layer $destroyed 'background_structures' 225 525 30
    Export-Band-Layer $destroyed 'main_building' 235 615 30
    Export-Band-Layer $destroyed 'damage' 300 820 26
    Export-Band-Layer $destroyed 'debris' 475 900 28
    Export-Band-Layer $destroyed 'furniture' 300 650 24
    Export-Band-Layer $destroyed 'vegetation' 320 1045 36
    Export-Band-Layer $destroyed 'foreground' 760 1080 30
    Export-Band-Layer $upgraded 'lighting' 210 900 34
    Export-Band-Layer $destroyed 'weather' 0 1080 38
    Export-Band-Layer $destroyed 'particles' 250 980 42

    foreach ($overlay in $overlays.Values) { $overlay.Dispose() }
} finally {
    $destroyed.Dispose()
    $upgraded.Dispose()
}

Write-Output "Built $Residence locked states, aligned hotspot overlays, and production layers."
