<#
.SYNOPSIS
  Installs aeroflyfs2020vrmod.apk, deploys OBB files, and configures VR runtime files on Meta Quest.
.DESCRIPTION
  This script performs a complete setup of the Aerofly FS 2020 VR mod on a Meta Quest device:
    1. Installs the patched APK (aeroflyfs2020vrmod.apk).
    2. Deploys OBB expansion files from the 'obb' directory to /sdcard/Android/obb/com.aerofly.aeroflyfs2020/.
    3. Deploys vr-controls.cfg (enables OpenXR native hooks, stereo 3D, 6DoF tracking, and mod menus).
    4. Deploys gc-map.mcf (flight controls mapping for Quest Touch thumbsticks/triggers).
    5. Deploys main.mcf (gamepad input and cockpit interaction configuration).
#>
[CmdletBinding()]
param(
    [string]$Serial,
    [switch]$SkipInstall,
    [switch]$SkipObb,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-Adb {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:ANDROID_HOME\platform-tools\adb.exe",
        "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
    )) {
        if (Test-Path $p) { return $p }
    }
    throw "adb.exe not found! Please ensure Android SDK platform-tools or Meta Quest Developer Hub is installed."
}

$Adb = Resolve-Adb
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "     Aerofly FS 2020 VR Mod - Meta Quest Setup & Deploy     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[1/6] Using ADB: $Adb" -ForegroundColor Cyan

# Enumerate devices
$devLines = @(& $Adb devices -l | Select-Object -Skip 1 | Where-Object { $_ -match 'device ' })
if ($devLines.Count -eq 0) {
    throw "No Quest / Android device detected via ADB! Connect your headset via USB or Wi-Fi and allow USB debugging."
}

if (-not $Serial) {
    $questLines = @($devLines | Where-Object { $_ -match 'model:Quest|model:Miramar|oculus|eureka|panther' })
    if ($questLines.Count -gt 0) {
        $firstMatch = [string]$questLines[0]
        $Serial = ($firstMatch.Trim() -split '\s+')[0]
        Write-Host "Auto-detected Quest target: $Serial" -ForegroundColor Green
    } elseif ($devLines.Count -eq 1) {
        $firstMatch = [string]$devLines[0]
        $Serial = ($firstMatch.Trim() -split '\s+')[0]
        Write-Host "Using single attached device: $Serial" -ForegroundColor Green
    } else {
        throw "Multiple devices connected. Please specify -Serial <device_id>."
    }
}

function Run-Adb {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    & $Adb -s $Serial @Args
}

$Package = "com.aerofly.aeroflyfs2020"
$ApkPath = Join-Path $ScriptDir "aeroflyfs2020vrmod.apk"
$ConfigsDir = Join-Path $ScriptDir "configs"
$ObbDir = Join-Path $ScriptDir "obb"

# 1. Install APK if requested
if (-not $SkipInstall) {
    if (-not (Test-Path $ApkPath)) {
        Write-Warning "aeroflyfs2020vrmod.apk not found in $ScriptDir. Skipping APK installation step."
    } else {
        Write-Host "`n[2/6] Installing $ApkPath to $Serial..." -ForegroundColor Cyan
        Run-Adb install -r -g $ApkPath
        if ($LASTEXITCODE -ne 0) {
            throw "APK installation failed! Check headset storage or package signature."
        }
        Write-Host "APK installed successfully." -ForegroundColor Green
    }
} else {
    Write-Host "`n[2/6] Skipping APK install as requested (-SkipInstall)." -ForegroundColor Yellow
}

# 2. Deploy OBB expansion files
if (-not $SkipObb) {
    Write-Host "`n[3/6] Checking OBB expansion files..." -ForegroundColor Cyan
    $obbFiles = @(Get-ChildItem -Path $ObbDir -Filter *.obb -File -ErrorAction SilentlyContinue)
    if ($obbFiles.Count -eq 0) {
        Write-Warning "No .obb files found in $ObbDir. Skipping OBB deployment."
    } else {
        $remoteObbDir = "/sdcard/Android/obb/$Package"
        Run-Adb shell "mkdir -p $remoteObbDir" | Out-Null

        foreach ($f in $obbFiles) {
            $remoteFile = "$remoteObbDir/$($f.Name)"
            $localSize = $f.Length
            
            # Check existing remote size
            $remoteStat = Run-Adb shell "stat -c %s '$remoteFile' 2>/dev/null"
            $remoteSize = [string]::Join('', $remoteStat).Trim()

            if ($remoteSize -eq [string]$localSize) {
                Write-Host "  -> $($f.Name): Already present with matching size ($([math]::Round($localSize/1MB)) MB). Skipping." -ForegroundColor Green
            } else {
                Write-Host "  -> Uploading $($f.Name) ($([math]::Round($localSize/1MB)) MB)..." -ForegroundColor Yellow
                Run-Adb push $f.FullName $remoteFile
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to push $($f.Name) to headset!"
                }
                Write-Host "     Uploaded $($f.Name) successfully." -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "`n[3/6] Skipping OBB deployment as requested (-SkipObb)." -ForegroundColor Yellow
}

# 3. Stop app before writing configs
Write-Host "`n[4/6] Stopping $Package before updating configs..." -ForegroundColor Cyan
Run-Adb shell "am force-stop $Package"
Start-Sleep -Milliseconds 500

# 4. Deploy VR configuration files
Write-Host "`n[5/6] Deploying VR configuration files..." -ForegroundColor Cyan

# Create internal directory via run-as
Run-Adb shell "run-as $Package mkdir -p /data/data/$Package/files/aerofly_fs_2020_android_v2020xx"
Run-Adb shell "mkdir -p /sdcard/Android/data/$Package/files"

# Push vr-controls.cfg
$vrCfg = Join-Path $ConfigsDir "vr-controls.cfg"
if (Test-Path $vrCfg) {
    Run-Adb push $vrCfg /data/local/tmp/vr-controls.cfg | Out-Null
    Run-Adb shell "run-as $Package cp /data/local/tmp/vr-controls.cfg /data/data/$Package/files/aerofly_fs_2020_android_v2020xx/vr-controls.cfg"
    Run-Adb shell "run-as $Package cp /data/local/tmp/vr-controls.cfg /data/data/$Package/files/vr-controls.cfg"
    Run-Adb push $vrCfg "/sdcard/Android/data/$Package/files/vr-controls.cfg" | Out-Null
    Run-Adb shell "rm -f /data/local/tmp/vr-controls.cfg"
    Write-Host "  -> vr-controls.cfg deployed (native hooks, stereo 3D, and menus enabled)" -ForegroundColor Green
} else {
    Write-Warning "vr-controls.cfg not found in $ConfigsDir!"
}

# Push gc-map.mcf (Flight controls channel map)
$gcMap = Join-Path $ConfigsDir "gc-map.mcf"
if (Test-Path $gcMap) {
    Run-Adb push $gcMap /data/local/tmp/gc-map.mcf | Out-Null
    Run-Adb shell "run-as $Package cp /data/local/tmp/gc-map.mcf /data/data/$Package/files/gc-map.mcf"
    Run-Adb shell "run-as $Package cp /data/local/tmp/gc-map.mcf /data/data/$Package/files/aerofly_fs_2020_android_v2020xx/gc-map.mcf"
    Run-Adb shell "rm -f /data/local/tmp/gc-map.mcf"
    Write-Host "  -> gc-map.mcf deployed (gamepad/touch controller axes mapped)" -ForegroundColor Green
}

# Push main.mcf (Initial settings with gamepad controls enabled)
$mainMcf = Join-Path $ConfigsDir "main.mcf"
if (Test-Path $mainMcf) {
    Run-Adb push $mainMcf /data/local/tmp/main.mcf | Out-Null
    Run-Adb shell "run-as $Package cp /data/local/tmp/main.mcf /data/data/$Package/files/main.mcf"
    Run-Adb shell "run-as $Package cp /data/local/tmp/main.mcf /data/data/$Package/files/aerofly_fs_2020_android_v2020xx/main.mcf"
    Run-Adb shell "rm -f /data/local/tmp/main.mcf"
    Write-Host "  -> main.mcf deployed (gamepad input & VR settings configured)" -ForegroundColor Green
}

# Verify files on device
Write-Host "`n[6/6] Verifying on-device files:" -ForegroundColor Cyan
Write-Host "--- Internal VR config directory ---" -ForegroundColor DarkGray
Run-Adb shell "run-as $Package ls -la /data/data/$Package/files/aerofly_fs_2020_android_v2020xx/"
Write-Host "--- Main runtime settings ---" -ForegroundColor DarkGray
Run-Adb shell "run-as $Package sh -c 'ls -la /data/data/$Package/files/*.mcf /data/data/$Package/files/*.cfg 2>/dev/null'"
Write-Host "--- OBB expansion directory ---" -ForegroundColor DarkGray
Run-Adb shell "ls -la /sdcard/Android/obb/$Package/"

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "     Meta Quest VR Mod Setup Completed Successfully!     " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

if ($Launch) {
    Write-Host "Launching $Package on headset..." -ForegroundColor Cyan
    Run-Adb shell "am start -n $Package/.TMNativeActivity"
} else {
    Write-Host "Put on your Meta Quest headset and start 'Aerofly FS 2020' from your app library!" -ForegroundColor Yellow
}
