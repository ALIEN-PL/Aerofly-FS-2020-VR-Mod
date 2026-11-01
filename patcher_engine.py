#!/usr/bin/env python3
"""
Autonomous Windows patcher engine for Aerofly FS 2020 VR Mod (Meta Quest 2 / 3 / 3S / Pro).
Merges the original base.apk with the OpenXR VR mod payload, aligns to 16 KiB page boundaries,
and signs the package using Android debug keys.
"""

import os
import sys
import time
import zipfile
import hashlib
import subprocess
import shutil

def check_file_sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest().upper()

def find_java():
    # 1. PATH lookup
    java_cmd = shutil.which("java")
    if java_cmd:
        return java_cmd

    # 2. JAVA_HOME lookup
    java_home = os.environ.get("JAVA_HOME")
    if java_home:
        cand = os.path.join(java_home, "bin", "java.exe")
        if os.path.isfile(cand):
            return cand

    # 3. Known common directories on Windows
    common_paths = [
        r"C:\Program Files\Eclipse Adoptium\jdk-17\bin\java.exe",
        r"C:\Program Files\Eclipse Adoptium\jdk-21\bin\java.exe",
        r"C:\Program Files\Java\jdk-17\bin\java.exe",
        r"C:\Program Files\Java\jdk-21\bin\java.exe",
        r"C:\Program Files\Android\Android Studio\jbr\bin\java.exe",
        r"C:\Program Files\Android\Android Studio\jre\bin\java.exe",
        r"C:\Program Files (x86)\Common Files\Oracle\Java\javapath\java.exe"
    ]
    for p in common_paths:
        if os.path.isfile(p):
            return p
    return None

def main():
    t0 = time.time()
    root_dir = os.path.dirname(os.path.abspath(__file__))
    base_apk = os.path.join(root_dir, "base.apk")
    payload_zip = os.path.join(root_dir, "payload.zip")
    tools_dir = os.path.join(root_dir, "tools")
    base_files_txt = os.path.join(tools_dir, "base_files.txt")
    zipalign_exe = os.path.join(tools_dir, "zipalign.exe")
    apksigner_jar = os.path.join(tools_dir, "apksigner.jar")
    debug_keystore = os.path.join(tools_dir, "debug.keystore")
    
    unsigned_apk = os.path.join(root_dir, "_unsigned.apk")
    aligned_apk = os.path.join(root_dir, "_aligned.apk")
    out_apk = os.path.join(root_dir, "aeroflyfs2020vrmod.apk")

    print("=" * 70)
    print("      Aerofly FS 2020 VR Mod Patcher (Meta Quest 2 / 3 / 3S / Pro)    ")
    print("=" * 70)

    # Step 1: Verify presence and validity of base.apk
    print("[1/5] Verifying input package base.apk...")
    if not os.path.isfile(base_apk):
        print("\n[ERROR] 'base.apk' not found!")
        print("-> Place your original Aerofly FS 2020 base.apk in the same folder as this patcher:")
        print(f"   {root_dir}\\base.apk\n")
        return 1

    try:
        with zipfile.ZipFile(base_apk, 'r') as z_test:
            names = set(z_test.namelist())
            if 'lib/arm64-v8a/libaeroflyfs2020.so' not in names:
                print("\n[ERROR] base.apk does not contain libaeroflyfs2020.so (ARM64 engine library)!")
                print("Make sure this is the original ARM64 version of Aerofly FS 2020 (com.aerofly.aeroflyfs2020).\n")
                return 1
            print("      Valid base.apk recognized (engine library libaeroflyfs2020.so present).")
    except Exception as e:
        print(f"\n[ERROR] Failed to open base.apk as a ZIP archive: {e}\n")
        return 1

    # Step 2: Verify mod payload.zip
    print("\n[2/5] Verifying VR mod components (payload.zip)...")
    if not os.path.isfile(payload_zip):
        print(f"\n[ERROR] Missing {payload_zip} containing VR mod components!\n")
        return 1

    with zipfile.ZipFile(payload_zip, 'r') as z_pay:
        pay_count = len(z_pay.namelist())
        print(f"      Loaded mod payload ({pay_count} files: OpenXR interposer, hooks, manifest, dex, assets).")

    # Load list of files required from base.apk
    base_needed = []
    if os.path.isfile(base_files_txt):
        with open(base_files_txt, 'r', encoding='utf-8') as f:
            base_needed = [line.strip() for line in f if line.strip()]

    # Step 3: Merge files into unsigned APK
    print("\n[3/5] Merging original game assets and VR mod components...")
    for tmp in [unsigned_apk, aligned_apk]:
        if os.path.isfile(tmp):
            try: os.remove(tmp)
            except: pass

    count_payload = 0
    count_base = 0

    with zipfile.ZipFile(unsigned_apk, 'w') as z_out:
        # Write payload entries first
        with zipfile.ZipFile(payload_zip, 'r') as z_pay:
            for item in z_pay.infolist():
                data = z_pay.read(item.filename)
                compress_type = zipfile.ZIP_DEFLATED
                # Uncompressed files for instant mmap
                if item.filename == "resources.arsc" or item.filename.endswith("vricockpittrace.so"):
                    compress_type = zipfile.ZIP_STORED
                
                zi = zipfile.ZipInfo(item.filename)
                zi.compress_type = compress_type
                zi.date_time = (2026, 1, 1, 0, 0, 0)
                zi.external_attr = 0o644 << 16
                z_out.writestr(zi, data)
                count_payload += 1

        # Write base.apk entries
        with zipfile.ZipFile(base_apk, 'r') as z_base:
            if base_needed:
                for filename in base_needed:
                    try:
                        data = z_base.read(filename)
                        compress_type = zipfile.ZIP_DEFLATED
                        if filename == "lib/arm64-v8a/libaeroflyfs2020.so":
                            compress_type = zipfile.ZIP_STORED
                        zi = zipfile.ZipInfo(filename)
                        zi.compress_type = compress_type
                        zi.date_time = (2026, 1, 1, 0, 0, 0)
                        zi.external_attr = 0o644 << 16
                        z_out.writestr(zi, data)
                        count_base += 1
                    except KeyError:
                        pass
            else:
                for item in z_base.infolist():
                    if item.filename.startswith("META-INF/"):
                        continue
                    if item.filename in ("classes.dex", "AndroidManifest.xml", "resources.arsc"):
                        continue
                    if item.filename.startswith("res/"):
                        continue
                    data = z_base.read(item.filename)
                    compress_type = zipfile.ZIP_DEFLATED
                    if item.filename == "lib/arm64-v8a/libaeroflyfs2020.so":
                        compress_type = zipfile.ZIP_STORED
                    zi = zipfile.ZipInfo(item.filename)
                    zi.compress_type = compress_type
                    zi.date_time = (2026, 1, 1, 0, 0, 0)
                    zi.external_attr = 0o644 << 16
                    z_out.writestr(zi, data)
                    count_base += 1

    print(f"      Merged {count_payload} mod entries and {count_base} original game entries (total: {count_payload + count_base}).")

    # Step 4: 16 KiB alignment (zipalign -P 16 4)
    print("\n[4/5] Aligning shared libraries to 16 KiB boundaries (zipalign -P 16 4)...")
    if not os.path.isfile(zipalign_exe):
        print(f"\n[ERROR] Missing {zipalign_exe} in tools directory!\n")
        return 1

    align_cmd = [zipalign_exe, "-P", "16", "-f", "4", unsigned_apk, aligned_apk]
    res_align = subprocess.run(align_cmd, capture_output=True, text=True)
    if res_align.returncode != 0:
        print(f"\n[ERROR] zipalign failed:\n{res_align.stderr}\n")
        return 1
    print("      16 KiB alignment completed successfully.")

    # Step 5: Android Signature Scheme v2 & v3 signing
    print("\n[5/5] Signing APK with Android debug keys (apksigner v2/v3)...")
    java_exe = find_java()
    if not java_exe:
        print("\n[ERROR] Java Runtime Environment (java.exe) was not found!")
        print("Please install Java (JRE/JDK) or Android Studio to enable APK signing.")
        return 1

    if not os.path.isfile(apksigner_jar) or not os.path.isfile(debug_keystore):
        print("\n[ERROR] Missing apksigner.jar or debug.keystore in tools directory!\n")
        return 1

    if os.path.isfile(out_apk):
        try: os.remove(out_apk)
        except: pass

    sign_cmd = [
        java_exe, '-jar', apksigner_jar, 'sign',
        '--ks', debug_keystore,
        '--ks-key-alias', 'androiddebugkey',
        '--ks-pass', 'pass:android',
        '--key-pass', 'pass:android',
        '--v4-signing-enabled', 'false',
        '--out', out_apk,
        aligned_apk
    ]
    res_sign = subprocess.run(sign_cmd, capture_output=True, text=True)
    if res_sign.returncode != 0:
        print(f"\n[ERROR] apksigner failed:\n{res_sign.stderr}\n")
        return 1

    # Verify signature
    verify_cmd = [java_exe, '-jar', apksigner_jar, 'verify', out_apk]
    res_ver = subprocess.run(verify_cmd, capture_output=True, text=True)
    if res_ver.returncode != 0:
        print(f"\n[WARNING] Signature verification warning: {res_ver.stderr}")
    else:
        print("      APK Signature (v2/v3 scheme) verified successfully.")

    # Cleanup temporary files
    for tmp in [unsigned_apk, aligned_apk]:
        if os.path.isfile(tmp):
            try: os.remove(tmp)
            except: pass

    elapsed = time.time() - t0
    apk_size = os.path.getsize(out_apk)
    apk_hash = check_file_sha256(out_apk)

    print("\n" + "=" * 70)
    print(" SUCCESS! Patched VR APK was generated successfully!")
    print("=" * 70)
    print(f" Output file: {out_apk}")
    print(f" File size:   {apk_size:,} bytes ({apk_size / 1024 / 1024:.2f} MB)")
    print(f" SHA-256:     {apk_hash}")
    print(f" Time elapsed: {elapsed:.2f} s")
    print("=" * 70)
    print("\nNext steps:")
    print(" Run the automated Quest installer:")
    print("   .\\install_on_quest.bat")
    print()
    return 0

if __name__ == '__main__':
    sys.exit(main())
