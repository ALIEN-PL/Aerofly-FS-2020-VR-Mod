# Aerofly FS 2020 VR Mod (Meta Quest 2 / 3 / 3S / Pro)

[![Platform](https://img.shields.io/badge/Platform-Meta%20Quest%20(Horizon%20OS)-blue.svg)](https://www.meta.com/quest/)
[![OpenXR](https://img.shields.io/badge/Runtime-OpenXR%20Native-brightgreen.svg)](https://www.khronos.org/openxr/)
[![Tested On](https://img.shields.io/badge/Tested%20On-Meta%20Quest%203-blueviolet.svg)](https://www.meta.com/quest/quest-3/)
[![Target App](https://img.shields.io/badge/Target-Aerofly%20FS%202020%20(com.aerofly.aeroflyfs2020)-orange.svg)](https://www.aerofly.com/)

A standalone, native **OpenXR Virtual Reality modification** and patcher for the Android release of **Aerofly FS 2020** (`com.aerofly.aeroflyfs2020`).

This mod transforms the flat-screen mobile flight simulator into a fully immersive 6DoF VR standalone experience on Meta Quest 3 headset

---

## Table of Contents

- [What is this Mod?](#what-is-this-mod)
- [Requirements & Legal Notice](#requirements--legal-notice)
- [Patcher Package Contents](#patcher-package-contents)
- [Installation Guide](#installation-guide)
  - [Step 1: Prepare Your Original Files](#step-1-prepare-your-original-files)
  - [Step 2: Run the Patcher](#step-2-run-the-patcher)
  - [Step 3: Deploy to Meta Quest](#step-3-deploy-to-meta-quest)
- [Controls & Flight Mapping (`QUEST MAPPING`)](#controls--flight-mapping-quest-mapping)
  - [Default Touch Controller Layout](#default-touch-controller-layout)
  - [In-Game Controls Menu](#in-game-controls-menu)
  - [Subtab 1: Aircraft Flight Surfaces](#subtab-1-aircraft-flight-surfaces)
  - [Subtab 2: VR Shortcuts](#subtab-2-vr-shortcuts)
  - [Subtab 3: Virtual Joystick / Yoke](#subtab-3-virtual-joystick--yoke)
  - [Subtab 4: USB HOTAS Hardware](#subtab-4-usb-hotas-hardware)
  - [Subtab 5: Optical Hand Tracking & Cockpit Poking](#subtab-5-optical-hand-tracking--cockpit-poking)
- [Graphics & VR Performance Settings (`QUEST GRAPHICS`)](#graphics--vr-performance-settings-quest-graphics)
  - [Detailed Graphics Options Breakdown](#detailed-graphics-options-breakdown)
  - [Recommended Quest 3 Presets](#recommended-quest-3-presets)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [License & Disclaimer](#license--disclaimer)

---

## What is this Mod?

The **Aerofly FS 2020 VR Mod** uses **OpenXR Interposer** (`libvrinterposer.so`) that dynamically hooks into the core simulation engine

### Key Features

* **Full 6DoF Head Tracking**
* **Mono or Stereo VR modes**
* **Touch Controller Interaction**:
  * Precision laser pointers for cockpit interactions.
  * Hand tracking in Stereo VR mode (poke, pinch up or down pull or push, pinch+rotate)
  * Plug-and-play USB HOTAS support via Quest USB-C port (tested T16000M FCS HOTAS + TWCS with usb-c hub)
  * Virtual joystick. Use right meta quest touch controller as yoke
* **Integrated In-Game Mod Menus**: Fully rendered within the simulator's UI under `SETTINGS -> CONTROLS -> QUEST MAPPING` and `SETTINGS -> GRAPHICS -> QUEST GRAPHICS`.
* **State-of-the-Art VR Rendering Pipeline**:
  * **Normal or MQSR sharpening**: Hardware contrast-adaptive layer sharpening for ultra-crisp cockpit avionics.
  * **[EXPERIMENTAL] Fixed Foveated Rendering (FFR)**: Concentrates shading power where your eyes look while lightening peripheral load.
  * **[EXPERIMENTAL] Application SpaceWarp (AppSW)**: Motion-vector reprojection 
  * **[EXPERIMENTAL] Snapdragon Game Super Resolution (SGSR1)**: High-fidelity spatial edge-preserving upscaling.
  * **MSAA Hardware Anti-Aliasing (2x / 4x)**: Eliminates shimmer on runway markings and instrument needles.
  * **High Refresh Rates**: Native support for **72 Hz**, **90 Hz**, and **120 Hz** panel modes.

---

## Requirements & Legal Notice

> [!IMPORTANT]
> **NO COPYRIGHTED GAME ASSETS ARE DISTRIBUTED IN THIS REPOSITORY.**
> You **MUST** legally own a purchased copy of **Aerofly FS 2020** (`com.aerofly.aeroflyfs2020`) for Android. This repository contains only open-source hooking tools, the OpenXR interposer payload, and an automated patcher script to add VR mode to your own legally obtained copy.

### 1. Game Files Required
* **`base.apk`**: Original 64-bit APK (`com.aerofly.aeroflyfs2020`, ARM64-v8a, v20.20.54 - tested), extracted from your Android device or Google Play backup.
* **Expansion Files (OBB)**:
  * `main.202043.com.aerofly.aeroflyfs2020.obb`
  * `patch.202013.com.aerofly.aeroflyfs2020.obb`

### 2. PC Hardware & Software
* **Operating System**: Windows 10 or Windows 11 (64-bit).
* **Java Runtime**: JRE or JDK 11+ (`java.exe` in system PATH or Android Studio / Eclipse Adoptium). Required by Google's official `apksigner`.
* **Python**: Python 3.8+ (recommended for high-speed patching; a pure PowerShell fallback is also included).

### 3. Headset Compatibility
* **Verified & Tested**: **Meta Quest 3** (Horizon OS / Android 14 / Snapdragon XR2 Gen 2).
* **Compatible**: Meta Quest 3S, Meta Quest Pro, Meta Quest 2.
* **Prerequisites**: Headset must have **Developer Mode** enabled with USB debugging authorized.

---

## Patcher Package Contents

```text
Aerofly-FS-2020-VR-Mod/
├── configs/                     # Runtime VR configurations pushed to headset
│   ├── vr-controls.cfg          # Master VR interposer & graphics configuration
│   ├── gc-map.mcf               # Touch controller flight axis mapping
│   └── main.mcf                 # Simulation input & camera initial state
├── obb/                         # Drop your original .obb expansion files here
│   └── README.md
├── tools/                       # Build & signing utilities
│   ├── apksigner.bat / .jar     # Official Android APK signer
│   ├── base_files.txt           # File verification manifest
│   ├── debug.keystore           # Development Android signing key
│   └── zipalign.exe             # 16 KiB page-alignment tool
├── install_on_quest.bat / .ps1  # Automated one-click headset installer & config deployer
├── patch.bat / .ps1             # Local APK patcher script
├── patcher_engine.py            # High-performance Python patcher engine
├── payload.zip                  # OpenXR VR interposer binaries, hooks, and manifest
└── verify_patch.py              # Verification tool for APK integrity & alignment
```

---

## Installation Guide

### Step 1: Prepare Your Original Files

1. Back up your legally purchased **Aerofly FS 2020** from your phone or tablet:
   ```powershell
   adb shell pm path com.aerofly.aeroflyfs2020
   adb pull /data/app/com.aerofly.aeroflyfs2020-.../base.apk .
   ```
2. Rename the APK file to exactly:
   ```text
   base.apk
   ```
   and place it in the root folder of this patcher (next to `patch.bat`).
3. Copy both of your original `.obb` files into the `obb/` folder:
   * `obb/main.202043.com.aerofly.aeroflyfs2020.obb`
   * `obb/patch.202013.com.aerofly.aeroflyfs2020.obb`

---

### Step 2: Run the Patcher

1. Double-click **`patch.bat`** (or execute `.\patch.ps1` from PowerShell).
2. The patcher will automatically:
   - Validate that `base.apk` contains the ARM64 flight simulation engine.
   - Inject the VR mod payload: `libvrinterposer.so`, `libopenxr_loader.so`, bytehook engines, VR manifest permissions, and classes.dex lifecycle hooks.
   - Align all uncompressed shared libraries to **16 KiB page boundaries** (`zipalign -P 16 4`).
   - Sign the package with Android APK Signature Schemes v2 and v3.
3. Upon completion, the installation file will be created:
   ```text
   aeroflyfs2020vrmod.apk
   ```

---

### Step 3: Deploy to Meta Quest

#### Method A: Automated Setup (Recommended)
1. Connect your Meta Quest to your PC using a USB-C link cable.
2. Put on the headset and click **Allow USB Debugging**.
3. Double-click **`install_on_quest.bat`** (or run `.\install_on_quest.ps1`).
4. The script will automatically:
   - Detect your connected Quest headset.
   - Install `aeroflyfs2020vrmod.apk`.
   - Push the `.obb` expansion files to `/sdcard/Android/obb/com.aerofly.aeroflyfs2020/`.
   - Deploy `vr-controls.cfg`, `gc-map.mcf`, and `main.mcf` directly into the game's internal data storage.

#### Method B: Manual ADB Setup
If you use SideQuest or standard `adb`:
```bash
# 1. Install APK
adb install -r -g aeroflyfs2020vrmod.apk

# 2. Push OBB expansion files
adb shell "mkdir -p /sdcard/Android/obb/com.aerofly.aeroflyfs2020"
adb push obb/main.202043.com.aerofly.aeroflyfs2020.obb /sdcard/Android/obb/com.aerofly.aeroflyfs2020/
adb push obb/patch.202013.com.aerofly.aeroflyfs2020.obb /sdcard/Android/obb/com.aerofly.aeroflyfs2020/

# 3. Deploy VR runtime configs (MANDATORY for VR mode & custom controls)
adb shell "am force-stop com.aerofly.aeroflyfs2020"
adb push configs/vr-controls.cfg /sdcard/Android/data/com.aerofly.aeroflyfs2020/files/vr-controls.cfg
adb push configs/vr-controls.cfg /data/local/tmp/vr-controls.cfg
adb shell "run-as com.aerofly.aeroflyfs2020 cp /data/local/tmp/vr-controls.cfg /data/data/com.aerofly.aeroflyfs2020/files/vr-controls.cfg"
adb push configs/gc-map.mcf /data/local/tmp/gc-map.mcf
adb shell "run-as com.aerofly.aeroflyfs2020 cp /data/local/tmp/gc-map.mcf /data/data/com.aerofly.aeroflyfs2020/files/gc-map.mcf"
adb shell "rm -f /data/local/tmp/vr-controls.cfg /data/local/tmp/gc-map.mcf"
```

> [!NOTE]
> `vr-controls.cfg` is essential. It enables the native OpenXR interposer, establishes 6DoF tracking calibration, and displays the in-game Quest VR settings menus.

---

## Controls & Flight Mapping (`QUEST MAPPING`)

**To enter VR mode use left grip + B**
**STEREO VR or MONO VR change by right grip + X**

The VR mod introduces an expanded controls menu accessible directly in the cockpit or main menu under:
**`SETTINGS` -> `CONTROLS` -> `QUEST MAPPING`**.

### Default Touch Controller Layout
setting can be changed in settings->controls->quest mapping

| Input | Primary Function | With `Left Grip` Held | With `Right Grip` Held |
| :--- | :--- | :--- | :--- |
| **Left Stick Y** | Throttle (Rate mode: Push = Up, Pull = Down) | Cockpit Zoom | — |
| **Left Stick X** | Rudder (Yaw) |  |  |
| **Right Stick Y**| Elevator (Pitch) |  | Horizontal FOV Adjust |
| **Right Stick X**| Ailerons (Roll) | | |
| **Left Trigger** | Left Wheel Brake / Laser Click | — | — |
| **Right Trigger**| Right Wheel Brake / Laser Click | — | — |
| **Left Grip**    | VR Shortcut Modifier Button | — | — |
| **Right Grip**   | Rudder Trim / Secondary Modifier | — | — |
| **X Button**     | Cockpit Button Interact | **Recenter VR View** | **Stereo / Mono Toggle** |
| **Y Button**     | Flaps (Cycle detents) | **Toggle HUD Horizon Mode** | — |
| **A Button**     | Switch Camera View | **Reset View to Pilot Eyepoint** | — |
| **B Button**     | Landing Gear (Toggle Up/Down) | **Toggle Flight Info Display** | — |
| **Left thumbstick**   | Toggle Left Controller Laser | Look X/Y Pan | — |
| **Right thumbstick**  | Toggle Right Controller Laser | | — |

---

### In-Game Controls Menu

The `QUEST MAPPING` tab contains five specialized subpages:

#### Subtab 1: Aircraft Flight Surfaces
Configure primary flight controls with full customization:
* **`FUNCTION`**: Ailerons, Elevator, Rudder, Throttle, Flaps, Gear, Airbrake, Wheelbrake.
* **`INPUT`**: Select any Quest controller button or axis:
  * Sticks: `left.x`, `left.y`, `right.x`, `right.y`
  * Triggers: `left.trigger`, `right.trigger`
  * Grips: `left.grip`, `right.grip`
  * Face Buttons: `a`, `b`, `x`, `y`, `left.click`, `right.click`
* **`HOLD`**: Modifier button required to activate the control (allows dual-purpose button mapping).
* **`DECREASE`**: Counter-input button (e.g. throttle down or flap retraction).
* **`MODE`**:
  * `direct`: Output immediately tracks the absolute stick position. Best for elevator and ailerons.
  * `rate`: Holding the stick continuously alters the target setting. Releasing retains the current level. Best for throttle and trim.
  * `toggle`: Flips between binary states (e.g., Landing Gear down ↔ up).
  * `cycle`: Steps sequentially through fixed detents (e.g., Flaps 0° → 10° → 20° → Full).
* **`INV`**: Inverts the deflection axis.

#### Subtab 2: VR Shortcuts (some of them took part for testing and debugging ie. laser gain or look gain and will be removed in future updates)
Dedicated hotkeys for headset operations:
* **`RECENTER`**: Re-aligns head tracking origin and forward direction to your current seated position.
* **`RESET VIEW`**: Restores the default eye viewpoint for the active aircraft.
* **`CAMERA`**: Cycles through Cockpit, External Chase, Tower, Wing, and Fly-by cameras.
* **`LOOK X / LOOK Y`**: Pans the camera with thumbsticks when using external or chase cameras.
* **`LOOK GAIN`**: Adjusts thumbstick camera rotation sensitivity.
* **`FOV`**: Live adjustment of horizontal field of view.
* **`ZOOM`**: Instant cockpit instrument zoom for reading small gauges and avionics.
* **`RENDER SCALE`**: Real-time adjustment of eye buffer resolution.
* **`STEREO / MONO`**: Instantly switch between stereoscopic 3D and high-performance mono rendering.
* **`STEREO DEPTH`**: Live tuning of 3D depth separation / IPD.
* **`DISPLAY` & `HUD`**: Toggle on-screen flight data and head-up display horizon bars.
* **`CALIBRATE`**: Recalibrates controller neutral center.
* **`LEFT / RIGHT LASER`**: Toggles visibility of the interactive pointer ray.
* **`LASER DEPTH & GAIN`**: Adjusts pointer range and instrument surface tracking.

#### Subtab 3: Virtual Joystick / Yoke
Enables 3D spatial flight control without physical hardware:
* Reach out to the cockpit yoke or flight stick with your Touch controller.
* Hold the **Grip** button to grab the control in 3D space.
* Realistic pitch and roll response based on physical hand tilt and displacement.
* Adjustable grab sensitivity, deadzones, and dual-hand yoke synchronization.

#### Subtab 4: USB HOTAS Hardware
Connect real flight simulation peripherals directly to your Meta Quest:
* Plug your USB joystick, throttle quadrant, or rudder pedals into the Quest USB-C port via an OTG adapter or USB-C hub.
* Built-in **Auto-Learning Wizard**: Click any flight function on screen, move the desired physical axis or press a button on your HOTAS, and it binds immediately.
* You can map brakes to button or use throttle 20% as a range for brakes

#### Subtab 5: Optical Hand Tracking & Cockpit Poking
Fly controller-free using Meta Quest optical hand tracking:
* **`HAND TOUCH`**: Poking switches, dials, and circuit breakers with your index finger.
* **`POKE RELEASE DISTANCE`**: Configurable release threshold (in millimeters) to eliminate accidental double-triggering of avionics switches.
* **`HAND MESH TOGGLE`**: Choose between displaying virtual hands or keeping an unobstructed cockpit view.

---

## Graphics & VR Performance Settings (`QUEST GRAPHICS`)

Accessible directly in-game under:
**`SETTINGS` -> `GRAPHICS` -> `QUEST GRAPHICS`**.

```text
+-----------------------------------------------------------------------------------+
|  [GRAPHICS]  |  [QUEST GRAPHICS]                                                  |
+-----------------------------------------------------------------------------------+
|  [< PREV]                                                        [PAGE 1/5] [NEXT >] |
|                                                                                   |
|  SETTING NAME                  STATUS     VALUE      MIN      MAX      STEP       |
|  -------------------------------------------------------------------------------  |
|  SHOW FPS AND HZ               [ON ]      --         --       --       --         |
|  RENDER SCALE                  [ON ]      1.000      0.500    1.500    0.050      |
|  FOV                           [ON ]      98.127     70.000   139.000  1.000      |
|  STEREO DEPTH                  [ON ]      1.000      0.250    2.000    0.050      |
|  LASER DEPTH                   [ON ]      1.500      0.500    10.000   0.250      |
|  LASER GAIN                    [ON ]      1.050      0.500    1.500    0.050      |
+-----------------------------------------------------------------------------------+
```

### Detailed Graphics Options Breakdown

#### Page 1: Display & Optical Calibration
* **`SHOW FPS AND HZ`**
  - Displays a real-time heads-up diagnostic overlay with current rendering FPS, frame delivery latency (in milliseconds), and the active display refresh rate.
* **`RENDER SCALE`** (Default: `1.000`, Range: `0.500` to `1.500`)
  - Eye buffer resolution multiplier. `1.0x` renders at native Quest 3 resolution (approx. 2064×2208 per eye). Lowering this boosts performance; raising it delivers ultra-sharp cockpit textures but performance in stereo VR may be worse.
* **`FOV` (Horizontal Field of View)** (Default: `98.127°`, Range: `70°` to `139°`)
  - Configures the horizontal camera projection angle. Defaults to matching the physical Quest 3 pancake optical geometry for zero geometric distortion.
* **`STEREO DEPTH`** (Default: `1.000`, Range: `0.250` to `2.000`)
  - Fine-tunes cockpit scale.
* **`LASER DEPTH`** (Default: `1.500m`, Range: `0.5m` to `10.0m`)
  - Maximum projection reach of the controller laser pointer.
* **`LASER GAIN`** (Default: `1.050`, Range: `0.5` to `1.5`)
  - Pointer sensitivity and smoothing on cockpit instrument panels.

#### Page 2: Image Quality & Power Clocks
* **`LAYER SHARPENING`** (Default: `Quality`)
  - Meta Quest Super Resolution / Contrast Adaptive Sharpening (CAS) applied directly during OpenXR composition. Dramatically enhances readability of avionics dials, digital HUDs, and terrain textures.
* **`AUTO LAYER FILTER`**
  - Enables hardware trilinear and anisotropic filtering on projection eye textures to prevent texture aliasing at oblique viewing angles.
* **`LAYER SUPERSAMPLING`**
  - Engages a multi-tap bicubic texture sampler in the compositor during time-warp reprojection.
* **`[NOT WORKING. Use QGO] CPU PERFORMANCE`** (Default: `Level 2`, Range: `1` to `2`)
  - Locks CPU clock tiers on the Snapdragon XR2 processor to prevent dynamic throttling stutters during dense scenery streaming.
* **`[NOT WORKING. Use QGO] GPU PERFORMANCE`** (Default: `Level 2`, Range: `1` to `2`)
  - Locks GPU clock frequencies to ensure sustained frame delivery.
* **`DISPLAY HZ`** (Default: `72 Hz`, Options: `72 Hz`, `90 Hz`, `120 Hz`)
  - Headset display refresh rate.

#### Page 3: Foveated Rendering & SpaceWarp
* **`FOVEATED RENDERING (FFR)`** (Default: `Off` / Level `1` to `4`)
  - Adreno Fixed Foveated Rendering. Concentrates full GPU shading resolution in your central line of sight while rendering peripheral vision at reduced density. Yields up to 25% GPU performance savings.
* **`APPLICATION SPACEWARP (AppSW)`**
  - Not recommended for MonoVR mode. Still experimental and may cause artifacting. 
* **`SCENE MSAA`** (Default: `Off`, Options: `2x`, `4x`)
  - Recommended off. Hardware Multisample Anti-Aliasing. Eliminates shimmering on runway lines, power lines, and aircraft cockpit struts.
* **`SWAPPY BYPASS`** (Default: `Enabled`)
  - Bypasses Android's default Choreographer frame pacer, synchronizing frame submission directly with OpenXR hardware vsync to eliminate stutter and reduce latency.
* **`ENGINE FPS UNLOCK`**
  - Decouples the simulation loop from Android's default 60 Hz mobile limit, allowing full 90 Hz or 120 Hz physics and frame rendering.
* **`DISCARD MONO SOURCE`** (Default: `Enabled`)
  - Automatically discards the unused 2D mobile framebuffer from memory during stereoscopic rendering, saving memory bandwidth.

#### Page 4 & 5: Advanced Optimization & Lens Tuning
* **`EYE OUTPUT SCALE`**: Independent secondary scaling for OpenXR swapchain eye textures. Use with SGSR1.
* **`SGSR1 UPSCALER`**: Not recommended. No significant changes at the moment. Qualcomm Snapdragon Game Super Resolution 1.0 single-pass spatial upscaling.
* **`MONO HUD DRAW SKIP`**: Prevents redundant HUD draw passes during stereo rendering to reduce draw-call overhead.
* **`ENGINE WORKER IDLE`**: Regulates background worker threads so the main simulation and rendering loops maintain high priority on performance CPU cores.
* **`DIRECT XR TARGET`**: Renders directly into OpenXR swapchains, eliminating intermediate blits. Use with FFR.
* **`FFR LENS CENTER` & `DOMINANT EYE`**: Calibrates the foveation sweet spot to align with Quest 3 pancake lens optical centers and asymmetrical eye dominance.

---

### Recommended Quest 3 Presets

| Setting | Balanced (Recommended) | Ultra Fidelity | Max Smoothness (120Hz) | My settings |
| :--- | :--- | :--- | :--- | :--- |
| **Display Refresh** | **90 Hz** | 72 Hz | 120 Hz | 90hz |
| **Render Scale** | **1.00x** (Native) | 1.25x | 0.85x | 1.00x |
| **MSAA** | **2x MSAA** | 4x MSAA | Off | Off |
| **Layer Sharpening**| **Quality (MQSR)** | Quality (MQSR) | Normal | Normal |
| **Foveation (FFR)** | **Level 2** | Level 1 | Level 3 | Off |
| **AppSW** | Off | Off | On (60 → 120 FPS) | off in mono vr, on in stereo vr |

---

## Troubleshooting & FAQ

#### Q: The game opens on the headset, but it displays in a flat 2D window rather than VR.
* **Cause**: `vr-controls.cfg` is missing from the app's internal storage directory on the Quest.
* **Solution**: Run `install_on_quest.bat` or manually execute Step 3 (Method B) in the [Installation Guide](#step-3-deploy-to-meta-quest) to push `vr-controls.cfg` to `/data/data/com.aerofly.aeroflyfs2020/files/`.

#### Q: The game crashes immediately upon launch with a black screen.
* **Cause**: Missing or misnamed OBB expansion files.
* **Solution**: Ensure both `main.202043.com.aerofly.aeroflyfs2020.obb` and `patch.202013.com.aerofly.aeroflyfs2020.obb` are located in `/sdcard/Android/obb/com.aerofly.aeroflyfs2020/`.

#### Q: `patch.bat` reports "Java (java.exe) was not found on your system".
* **Solution**: Install a 64-bit Java Runtime Environment (such as [Eclipse Adoptium Temurin](https://adoptium.net/) or Oracle JRE/JDK), and ensure that `java.exe` is added to your Windows system `PATH`.

#### Q: How do I recenter my cockpit seat in VR?
* **Solution**: Hold the **Left Grip** button and press the **X Button** on your left controller.

---

## License & Disclaimer
* **Aerofly FS 2020** is a registered trademark of **IPACS**. This project is not affiliated with, endorsed by, or sponsored by IPACS or Meta Platforms, Inc.
* This repository distributes **NO proprietary binaries, textures, models, sound files, or scenery data** from the original game. All original assets must be supplied by the user from their legally purchased copy.
* Qualcomm Snapdragon Game Super Resolution (SGSR1) is subject to its respective license in `assets/third_party/sgsr1-LICENSE.txt`.

