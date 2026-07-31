$repoRoot = Split-Path -Parent $PSScriptRoot
$sampleRate = 22050

function Write-Wav([string]$path, [double[]]$samples) {
    $stream = [System.IO.File]::Create($path)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $dataSize = $samples.Length * 2
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
        $writer.Write([int](36 + $dataSize))
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
        $writer.Write([int]16); $writer.Write([int16]1); $writer.Write([int16]1)
        $writer.Write([int]$sampleRate); $writer.Write([int]($sampleRate * 2))
        $writer.Write([int16]2); $writer.Write([int16]16)
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data')); $writer.Write([int]$dataSize)
        foreach ($sample in $samples) {
            $clamped = [Math]::Max(-1.0, [Math]::Min(1.0, $sample))
            $writer.Write([int16]($clamped * 32767.0))
        }
    } finally { $writer.Dispose(); $stream.Dispose() }
}

$duration = 12.0
$count = [int]($sampleRate * $duration)
$ambience = [double[]]::new($count)
$random = [System.Random]::new(1702)
$filtered = 0.0
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / [double]$sampleRate
    $noise = $random.NextDouble() * 2.0 - 1.0
    $filtered = $filtered * 0.986 + $noise * 0.014
    $wind = $filtered * (0.20 + 0.06 * [Math]::Sin(2.0 * [Math]::PI * $t / $duration * 3.0))
    $generator = 0.025 * [Math]::Sin(2.0 * [Math]::PI * 55.0 * $t) + 0.012 * [Math]::Sin(2.0 * [Math]::PI * 110.0 * $t)
    $wire = 0.007 * [Math]::Sin(2.0 * [Math]::PI * 183.0 * $t) * (0.5 + 0.5 * [Math]::Sin(2.0 * [Math]::PI * $t / $duration))
    $ambience[$i] = $wind + $generator + $wire
}
Write-Wav (Join-Path $repoRoot 'assets/audio/ambience/redwater_station_loop.wav') $ambience

$repairDuration = 1.35
$repairCount = [int]($sampleRate * $repairDuration)
$repair = [double[]]::new($repairCount)
$random = [System.Random]::new(808)
for ($i = 0; $i -lt $repairCount; $i++) {
    $t = $i / [double]$sampleRate
    $sample = 0.0
    foreach ($hit in @(0.06, 0.34, 0.66, 0.94)) {
        $local = $t - $hit
        if ($local -ge 0.0 -and $local -lt 0.18) {
            $env = [Math]::Exp(-$local * 24.0)
            $sample += $env * (0.22 * [Math]::Sin(2.0 * [Math]::PI * 410.0 * $local) + 0.10 * ($random.NextDouble() * 2.0 - 1.0))
        }
    }
    $repair[$i] = $sample
}
Write-Wav (Join-Path $repoRoot 'assets/audio/sfx/redwater_repair_metal.wav') $repair
Write-Output 'Built Redwater seamless forecourt ambience and repair-metal cue.'
