================================================================================
     Aerofly FS 2020 VR Mod Patcher (Meta Quest 2 / Quest 3 / Quest 3S / Quest Pro)
================================================================================

1. OVERVIEW
-----------
This patcher attaches the native OpenXR VR modification to the original Android
APK of Aerofly FS 2020 (com.aerofly.aeroflyfs2020).

After patching, the game runs as a native, fully immersive VR application on
Meta Quest headsets (Horizon OS / OpenXR runtime) with:
 - Full 6DoF head tracking (position + orientation provided by OpenXR)
 - Calibrated stereo projection for cockpit and environment (zero-divergence)
 - Meta Touch controller support (laser pointer, trigger/buttons, switch interactions)
 - Quest Graphics & Controls in-game mod overlays (FPS, scale, MSAA, FOV, 90Hz)
 - AppSW (Application SpaceWarp) pacing and robust EGL/OpenXR lifecycle recovery
 - Horizon OS compatibility guards (GameManager service crash prevention, focus awareness)

The patcher runs 100% locally and securely on Windows systems.


2. REQUIREMENTS
---------------
 1. Windows 10 or Windows 11 (64-bit).
 2. Java Runtime Environment (`java.exe`) - present on most Windows PCs
    (Oracle Java, OpenJDK, Eclipse Adoptium, or bundled inside Android Studio).
    Java is required by Google's official `apksigner` tool to sign the output APK.
 3. Original, unmodified Aerofly FS 2020 APK named:
    base.apk
    (from your legally owned copy, e.g., backed up from your Android phone or Google Play).
 4. (Optional but recommended) Original game expansion files (OBB) placed in the 'obb' folder:
    - obb\main.202043.com.aerofly.aeroflyfs2020.obb
    - obb\patch.202013.com.aerofly.aeroflyfs2020.obb


3. STEP-BY-STEP INSTRUCTIONS
----------------------------
 STEP 1:
   Copy your original 'base.apk' into this folder (the same directory where this
   readme.txt and 'patch.bat' are located).

 STEP 2 (Optional):
   Place your two OBB files into the 'obb' subfolder:
     - obb\main.202043.com.aerofly.aeroflyfs2020.obb
     - obb\patch.202013.com.aerofly.aeroflyfs2020.obb
   (If you already have them installed on your Quest headset, you can skip this).

 STEP 3:
   Double-click 'patch.bat' in Windows Explorer
   or run it from PowerShell:
       .\patch.ps1

 STEP 4:
   The patcher will automatically perform the following steps:
    - Verify that 'base.apk' is a valid ARM64 Aerofly FS 2020 package.
    - Merge untouched game engine and scenery assets with the VR mod payload
      (OpenXR Interposer, PLT/inline hook engines, VR manifest, patched classes.dex).
    - Align shared libraries and zip structures to 16 KiB page boundaries (`zipalign -P 16 4`),
      which is strictly required by Horizon OS (Android 14) on Snapdragon XR2 Gen 2.
    - Sign the resulting APK using Android debug keys (APK Signature Scheme v2 & v3).
    - Verify the archive integrity and signatures.

 STEP 5:
   Once finished, the ready-to-install VR package will be generated:
       aeroflyfs2020vrmod.apk


4. INSTALLATION & ONE-CLICK QUEST SETUP (RECOMMENDED)
-----------------------------------------------------
 To ensure full VR functionality (6DoF tracking, stereo 3D, and the custom Quest
 Controls / Graphics menus), configuration files must be present on the headset.

 EASIEST METHOD (Automated via install_on_quest.bat):
   1. Connect your Meta Quest to your PC via USB cable (or wireless ADB).
   2. Ensure Developer Mode is enabled and authorize USB debugging inside the headset.
   3. Run:
          install_on_quest.bat
      This script automatically:
       - Installs `aeroflyfs2020vrmod.apk` onto the Quest.
       - Checks the 'obb' directory and uploads expansion files to the Quest if needed
         (skips upload if matching files already exist on the headset).
       - Deploys `vr-controls.cfg` (enables VR mode, 6DoF camera, and settings menus).
       - Deploys `gc-map.mcf` (maps Touch thumbsticks to aileron, elevator, rudder, throttle).
       - Configures `main.mcf` for gamepad/VR input.

 MANUAL METHOD (Using ADB):
   If you install the APK manually via SideQuest or standard `adb install -r`:
   
   1. Install APK:
        adb install -r aeroflyfs2020vrmod.apk

   2. Push OBB files (if not already on device):
        adb shell "mkdir -p /sdcard/Android/obb/com.aerofly.aeroflyfs2020"
        adb push obb/main.202043.com.aerofly.aeroflyfs2020.obb /sdcard/Android/obb/com.aerofly.aeroflyfs2020/
        adb push obb/patch.202013.com.aerofly.aeroflyfs2020.obb /sdcard/Android/obb/com.aerofly.aeroflyfs2020/

   3. Push VR runtime configs (from configs\ directory):
        adb shell "am force-stop com.aerofly.aeroflyfs2020"
        adb push configs/vr-controls.cfg /sdcard/Android/data/com.aerofly.aeroflyfs2020/files/vr-controls.cfg
        adb push configs/vr-controls.cfg /data/local/tmp/vr-controls.cfg
        adb shell "run-as com.aerofly.aeroflyfs2020 mkdir -p /data/data/com.aerofly.aeroflyfs2020/files/aerofly_fs_2020_android_v2020xx"
        adb shell "run-as com.aerofly.aeroflyfs2020 cp /data/local/tmp/vr-controls.cfg /data/data/com.aerofly.aeroflyfs2020/files/aerofly_fs_2020_android_v2020xx/vr-controls.cfg"
        adb push configs/gc-map.mcf /data/local/tmp/gc-map.mcf
        adb shell "run-as com.aerofly.aeroflyfs2020 cp /data/local/tmp/gc-map.mcf /data/data/com.aerofly.aeroflyfs2020/files/gc-map.mcf"
        adb shell "rm -f /data/local/tmp/vr-controls.cfg /data/local/tmp/gc-map.mcf"


5. TECHNICAL MOD SPECIFICATIONS
-------------------------------
The patcher injects the following components into the APK:
 - lib/arm64-v8a/libvrinterposer.so: Core native OpenXR interposer that hooks
   graphics calls, manages the XrSession, and renders stereo eyes with 6DoF tracking.
 - lib/arm64-v8a/libopenxr_loader.so: Khronos OpenXR loader for ARM64.
 - lib/arm64-v8a/libbytehook.so & libshadowhook.so: Dynamic hooking engines.
 - lib/arm64-v8a/libvricockpittrace.so: Cockpit telemetry and interaction observer.
 - AndroidManifest.xml: VR declarations (`vr_only`, `android.hardware.vr.headtracking`,
   `org.khronos.openxr.intent.category.IMMERSIVE_HMD`, OpenXR and Hand Tracking permissions).
 - classes.dex: TMNativeActivity bytecode hooks that initialize the interposer,
   pass the foreground Activity handle to OpenXR, manage window focus, and guard
   against the missing GameManager service on Horizon OS.
 - assets/third_party/sgsr1-LICENSE.txt: Qualcomm Snapdragon Super Resolution license.


6. TROUBLESHOOTING
------------------
 - Problem: VR mode does not start or settings menus in Controls/Graphics are missing.
   Reason: `vr-controls.cfg` is missing from the app's data folder on the Quest.
   Fix: Run `install_on_quest.bat` or follow the manual ADB push instructions in Section 4.

 - Problem: Error: "Could not find 'base.apk'"
   Fix: Ensure the file is named exactly 'base.apk' (lowercase) and placed in the
   same folder as 'patch.bat'.

 - Problem: Error: "Java (java.exe) was not found on your system"
   Fix: Install a standard Java JRE/JDK (e.g. Eclipse Adoptium Temurin or Oracle Java),
   or ensure that your Java installation's 'bin' directory is added to your PATH.

 - Problem: Black screen on headset startup
   Fix: Make sure both OBB files are placed in `/sdcard/Android/obb/com.aerofly.aeroflyfs2020/`
   and storage permissions are granted to the app on your Quest.
