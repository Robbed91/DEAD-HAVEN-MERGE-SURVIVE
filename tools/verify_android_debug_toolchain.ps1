param(
    [Parameter(Mandatory = $true)][string]$GodotConsole,
    [Parameter(Mandatory = $true)][string]$ExportTemplatesDirectory,
    [Parameter(Mandatory = $true)][string]$Jdk17Home,
    [Parameter(Mandatory = $true)][string]$AndroidSdk,
    [Parameter(Mandatory = $true)][string]$DebugKeystore,
    [Parameter(Mandatory = $true)][string]$BaselineApk,
    [string]$ExpectedCertificateSha256 = ''
)

$ErrorActionPreference = 'Stop'

function Require-Path([string]$path, [string]$label) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "$label is missing: $path"
    }
}

Require-Path $GodotConsole 'Godot console executable'
Require-Path $ExportTemplatesDirectory 'Godot export-template directory'
Require-Path (Join-Path $ExportTemplatesDirectory 'android_debug.apk') 'Godot Android debug template'
Require-Path (Join-Path $ExportTemplatesDirectory 'android_release.apk') 'Godot Android release template'
Require-Path (Join-Path $Jdk17Home 'bin\java.exe') 'OpenJDK 17 java executable'
Require-Path (Join-Path $AndroidSdk 'platform-tools\adb.exe') 'Android adb executable'
Require-Path $DebugKeystore 'Godot debug keystore'
Require-Path $BaselineApk 'Version-code-1 baseline APK'

$buildTools = Get-ChildItem -LiteralPath (Join-Path $AndroidSdk 'build-tools') -Directory |
    Sort-Object { [version]$_.Name } -Descending
if ($buildTools.Count -eq 0) {
    throw "No Android build-tools installation found below $AndroidSdk"
}
$apksigner = Join-Path $buildTools[0].FullName 'apksigner.bat'
$aapt = Join-Path $buildTools[0].FullName 'aapt.exe'
Require-Path $apksigner 'apksigner'
Require-Path $aapt 'aapt'

$godotVersion = (& $GodotConsole --version | Select-Object -First 1).Trim()
if ($godotVersion -notmatch '^4\.3\.stable') {
    throw "Expected matching Godot 4.3.stable, found: $godotVersion"
}

$priorErrorPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$javaVersionLines = @(& (Join-Path $Jdk17Home 'bin\java.exe') -version 2>&1)
$ErrorActionPreference = $priorErrorPreference
$javaVersion = $javaVersionLines | Select-Object -First 1
if ($javaVersion -notmatch '"17\.') {
    throw "Expected OpenJDK 17, found: $javaVersion"
}

$badging = (& $aapt dump badging $BaselineApk) -join "`n"
if ($badging -notmatch "package: name='com\.deadhaven\.mergeandsurvive' versionCode='1'") {
    throw 'Baseline APK package name or version code is not the required v1 identity.'
}
if ($badging -notmatch "native-code:.*'arm64-v8a'.*'x86_64'") {
    throw 'Baseline APK does not include both arm64-v8a and x86_64 verification ABIs.'
}

$ErrorActionPreference = 'Continue'
$certificateLines = @(& $apksigner verify --verbose --print-certs $BaselineApk 2>&1)
$certificateExit = $LASTEXITCODE
$ErrorActionPreference = $priorErrorPreference
$certificateReport = $certificateLines -join "`n"
if ($certificateExit -ne 0 -or $certificateReport -notmatch '(?m)^Verifies$') {
    throw 'Baseline APK signature verification failed.'
}
$certificateMatch = [regex]::Match(
    $certificateReport,
    '(?im)^.*certificate SHA-256 digest:\s*([0-9a-fA-F]{64})\s*$'
)
if (-not $certificateMatch.Success) {
    throw 'Could not read the baseline signing-certificate SHA-256 digest.'
}
$certificateSha256 = $certificateMatch.Groups[1].Value.ToLowerInvariant()
if ($ExpectedCertificateSha256 -and
    $certificateSha256 -ne $ExpectedCertificateSha256.ToLowerInvariant()) {
    throw "Signing certificate mismatch: $certificateSha256"
}

$apkSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $BaselineApk).Hash.ToLowerInvariant()
Write-Output "ANDROID_DEBUG_TOOLCHAIN_OK godot=$godotVersion java=17 package=com.deadhaven.mergeandsurvive version_code=1 abis=arm64-v8a,x86_64"
Write-Output "BASELINE_APK_SHA256=$apkSha256"
Write-Output "DEBUG_CERTIFICATE_SHA256=$certificateSha256"
