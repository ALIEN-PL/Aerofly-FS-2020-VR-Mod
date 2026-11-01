<#
.SYNOPSIS
  Autonomous Windows patcher for Aerofly FS 2020 VR Mod (Meta Quest 2 / 3 / 3S / Pro).
.DESCRIPTION
  Patches the original base.apk by injecting the OpenXR VR interposer, hook engines,
  VR manifest, and required patched bytecode. Produces a 16 KiB page-aligned and signed
  aeroflyfs2020vrmod.apk ready for Meta Quest (Horizon OS).
#>
[CmdletBinding()]
param(
    [string]$BaseApkPath,
    [string]$OutApkName = 'aeroflyfs2020vrmod.apk'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$rootDir = $scriptDir

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "      Aerofly FS 2020 VR Mod Patcher (Meta Quest 2 / 3 / 3S / Pro)    " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. If Python is available, prefer the high-performance Python engine
$python = Get-Command python -ErrorAction SilentlyContinue
$enginePy = Join-Path $rootDir 'patcher_engine.py'
if ($python -and (Test-Path -LiteralPath $enginePy)) {
    Write-Host "Launching patcher engine via Python ($($python.Source))..." -ForegroundColor DarkGray
    & $python.Source $enginePy
    exit $LASTEXITCODE
}

# 2. Fall back to PowerShell / .NET
Write-Host "Running patcher in PowerShell / .NET environment..." -ForegroundColor DarkGray

if (-not $BaseApkPath) {
    $BaseApkPath = Join-Path $rootDir 'base.apk'
}

if (-not (Test-Path -LiteralPath $BaseApkPath)) {
    Write-Host ""
    Write-Host "[ERROR] 'base.apk' not found!" -ForegroundColor Red
    Write-Host "-> Place your original Aerofly FS 2020 base.apk in the same folder as this patcher:" -ForegroundColor Yellow
    Write-Host "   $rootDir\base.apk" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$payloadZip = Join-Path $rootDir 'payload.zip'
if (-not (Test-Path -LiteralPath $payloadZip)) {
    Write-Host "[ERROR] Missing payload.zip in patcher directory!" -ForegroundColor Red
    exit 1
}

$toolsDir = Join-Path $rootDir 'tools'
$zipalign = Join-Path $toolsDir 'zipalign.exe'
$apksignerJar = Join-Path $toolsDir 'apksigner.jar'
$keystore = Join-Path $toolsDir 'debug.keystore'
$baseFilesTxt = Join-Path $toolsDir 'base_files.txt'
$outApk = Join-Path $rootDir $OutApkName
$unsignedApk = Join-Path $rootDir '_unsigned.apk'
$alignedApk = Join-Path $rootDir '_aligned.apk'

foreach ($tmp in @($unsignedApk, $alignedApk)) {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -Force $tmp }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "[1/4] Reading base.apk and mod payload..." -ForegroundColor Cyan
$zBase = [System.IO.Compression.ZipFile]::OpenRead($BaseApkPath)
$zPayload = [System.IO.Compression.ZipFile]::OpenRead($payloadZip)

# Verify libaeroflyfs2020.so
$engineFound = $false
foreach ($e in $zBase.Entries) {
    if ($e.FullName -eq 'lib/arm64-v8a/libaeroflyfs2020.so') {
        $engineFound = $true
        break
    }
}
if (-not $engineFound) {
    $zBase.Dispose()
    $zPayload.Dispose()
    Write-Host "[ERROR] base.apk does not contain libaeroflyfs2020.so (ARM64 engine library)!" -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] Merging original game assets and VR mod components..." -ForegroundColor Cyan
$zOut = [System.IO.Compression.ZipFile]::Open($unsignedApk, [System.IO.Compression.ZipArchiveMode]::Create)

# 1. Write payload entries
foreach ($ep in $zPayload.Entries) {
    $level = [System.IO.Compression.CompressionLevel]::Optimal
    if ($ep.FullName -eq 'resources.arsc' -or $ep.FullName.EndsWith('vricockpittrace.so')) {
        $level = [System.IO.Compression.CompressionLevel]::NoCompression
    }
    $newEntry = $zOut.CreateEntry($ep.FullName, $level)
    $src = $ep.Open()
    $dst = $newEntry.Open()
    $src.CopyTo($dst)
    $dst.Dispose()
    $src.Dispose()
}

# 2. Write entries from base.apk using base_files.txt
$baseMap = @{}
foreach ($eb in $zBase.Entries) {
    $baseMap[$eb.FullName] = $eb
}

if (Test-Path -LiteralPath $baseFilesTxt) {
    $needed = Get-Content -LiteralPath $baseFilesTxt | Where-Object { $_.Trim() }
    foreach ($name in $needed) {
        if ($baseMap.ContainsKey($name)) {
            $eb = $baseMap[$name]
            $level = [System.IO.Compression.CompressionLevel]::Optimal
            if ($eb.FullName -eq 'lib/arm64-v8a/libaeroflyfs2020.so') {
                $level = [System.IO.Compression.CompressionLevel]::NoCompression
            }
            $newEntry = $zOut.CreateEntry($eb.FullName, $level)
            $src = $eb.Open()
            $dst = $newEntry.Open()
            $src.CopyTo($dst)
            $dst.Dispose()
            $src.Dispose()
        }
    }
} else {
    foreach ($eb in $zBase.Entries) {
        if ($eb.FullName -like 'META-INF/*') { continue }
        if ($eb.FullName -in @('classes.dex', 'AndroidManifest.xml', 'resources.arsc')) { continue }
        if ($eb.FullName -like 'res/*') { continue }

        $level = [System.IO.Compression.CompressionLevel]::Optimal
        if ($eb.FullName -eq 'lib/arm64-v8a/libaeroflyfs2020.so') {
            $level = [System.IO.Compression.CompressionLevel]::NoCompression
        }
        $newEntry = $zOut.CreateEntry($eb.FullName, $level)
        $src = $eb.Open()
        $dst = $newEntry.Open()
        $src.CopyTo($dst)
        $dst.Dispose()
        $src.Dispose()
    }
}

$zOut.Dispose()
$zBase.Dispose()
$zPayload.Dispose()
Write-Host "      Intermediate _unsigned.apk generated successfully." -ForegroundColor Green

Write-Host "[3/4] Aligning APK structures (zipalign -P 16 4)..." -ForegroundColor Cyan
& $zipalign '-P' '16' '-f' '4' $unsignedApk $alignedApk
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] zipalign failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[4/4] Signing APK..." -ForegroundColor Cyan
function Resolve-JavaPath {
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) { return "$env:JAVA_HOME\bin\java.exe" }
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($cand in @(
        "C:\Program Files (x86)\Common Files\Oracle\Java\javapath\java.exe",
        "C:\Program Files\Android\Android Studio\jbr\bin\java.exe",
        "C:\Program Files\Android\Android Studio\jre\bin\java.exe"
    )) {
        if (Test-Path $cand) { return $cand }
    }
    return $null
}

$java = Resolve-JavaPath
if (-not $java) {
    Write-Host "[ERROR] java.exe was not found. Java Runtime Environment is required by apksigner!" -ForegroundColor Red
    exit 1
}

if (Test-Path -LiteralPath $outApk) { Remove-Item -Force $outApk }

& $java '-jar' $apksignerJar 'sign' `
    '--ks' $keystore '--ks-key-alias' 'androiddebugkey' `
    '--ks-pass' 'pass:android' '--key-pass' 'pass:android' `
    '--v4-signing-enabled' 'false' '--out' $outApk $alignedApk

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] apksigner signing failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Cleanup temporary files
Remove-Item -Force -ErrorAction SilentlyContinue $unsignedApk, $alignedApk

$hash = (Get-FileHash -LiteralPath $outApk -Algorithm SHA256).Hash
$size = (Get-Item -LiteralPath $outApk).Length

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " SUCCESS! Patched VR APK was generated successfully!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " Output file: $outApk" -ForegroundColor White
Write-Host " File size:   $size bytes ($([math]::Round($size/1MB, 2)) MB)" -ForegroundColor White
Write-Host " SHA-256:     $hash" -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To install and configure on Meta Quest, run:" -ForegroundColor Yellow
Write-Host " .\install_on_quest.bat" -ForegroundColor Yellow
Write-Host ""
