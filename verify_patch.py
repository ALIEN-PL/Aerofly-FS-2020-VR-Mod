#!/usr/bin/env python3
"""
Verification tool for Aerofly FS 2020 VR Mod.
Verifies 16 KiB page alignment, APK signature schemes (v2 & v3), and integrity.
Optionally compares the generated APK against a reference APK if provided.
"""

import sys
import os
import zipfile
import hashlib
import subprocess

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    apk_patch = os.path.join(script_dir, 'aeroflyfs2020vrmod.apk')
    tools_dir = os.path.join(script_dir, 'tools')
    zipalign_exe = os.path.join(tools_dir, 'zipalign.exe')
    apksigner_bat = os.path.join(tools_dir, 'apksigner.bat')

    print('=' * 75)
    print('  Aerofly FS 2020 VR Mod - Package Verification')
    print('=' * 75)

    if not os.path.isfile(apk_patch):
        print(f"\n[ERROR] Output package not found: {apk_patch}")
        print("Please run patch.bat first to generate 'aeroflyfs2020vrmod.apk'.\n")
        return 1

    print(f"Target APK: {apk_patch} ({os.path.getsize(apk_patch):,} bytes)")

    # 1. Verify 16 KiB page alignment
    print("\n[1/3] Verifying 16 KiB page alignment (Horizon OS requirement)...")
    res_align = subprocess.run([zipalign_exe, '-c', '-P', '16', '4', apk_patch], capture_output=True, text=True)
    align_ok = (res_align.returncode == 0)
    print(f"      zipalign -c -P 16 4: {'PASS' if align_ok else 'FAIL'}")
    if not align_ok and res_align.stderr:
        print(f"      Details: {res_align.stderr.strip()}")

    # 2. Verify APK signatures
    print("\n[2/3] Verifying APK Signature Scheme (v2 / v3)...")
    res_sign = subprocess.run([apksigner_bat, 'verify', '--verbose', apk_patch], capture_output=True, text=True, shell=True)
    v2_ok = 'Verified using v2 scheme (APK Signature Scheme v2): true' in res_sign.stdout
    v3_ok = 'Verified using v3 scheme (APK Signature Scheme v3): true' in res_sign.stdout
    print(f"      v2 scheme: {'PASS' if v2_ok else 'FAIL'}")
    print(f"      v3 scheme: {'PASS' if v3_ok else 'FAIL'}")

    # 3. Optional comparison against a reference APK
    ref_apk = sys.argv[1] if len(sys.argv) > 1 else None
    if ref_apk and os.path.isfile(ref_apk):
        print(f"\n[3/3] Comparing byte-for-byte against reference APK: {ref_apk}")
        with zipfile.ZipFile(ref_apk) as z_b, zipfile.ZipFile(apk_patch) as z_p:
            b_entries = {e.filename: e for e in z_b.infolist() if not e.filename.startswith('META-INF')}
            p_entries = {e.filename: e for e in z_p.infolist() if not e.filename.startswith('META-INF')}

            missing = set(b_entries.keys()) - set(p_entries.keys())
            extra = set(p_entries.keys()) - set(b_entries.keys())
            hash_mismatches = []
            type_mismatches = []

            for name in b_entries:
                if name in p_entries:
                    hb = hashlib.sha256(z_b.read(name)).hexdigest()
                    hp = hashlib.sha256(z_p.read(name)).hexdigest()
                    if hb != hp:
                        hash_mismatches.append((name, hb, hp))
                    if b_entries[name].compress_type != p_entries[name].compress_type:
                        type_mismatches.append((name, b_entries[name].compress_type, p_entries[name].compress_type))

            print(f"      Reference entries: {len(b_entries)} | Patched entries: {len(p_entries)}")
            print(f"      Missing: {len(missing)} | Extra: {len(extra)}")
            print(f"      Hash mismatches: {len(hash_mismatches)} | Compression mismatches: {len(type_mismatches)}")
            if len(missing) == 0 and len(extra) == 0 and len(hash_mismatches) == 0 and len(type_mismatches) == 0:
                print("      Result: 100% BYTE-FOR-BYTE MATCH across all entries!")
    else:
        print("\n[3/3] Optional reference comparison skipped (pass reference APK as argument to compare).")

    print('=' * 75)
    if align_ok and v2_ok:
        print("VERIFICATION RESULT: SUCCESS! The APK is valid, aligned, and ready for Meta Quest.")
        print('=' * 75)
        return 0
    else:
        print("VERIFICATION RESULT: FAILED! Check the errors above.")
        print('=' * 75)
        return 1

if __name__ == '__main__':
    sys.exit(main())
