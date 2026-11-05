# Realme GT2 Pro (ferrari) Adapted Patch Set for Evolution X (cnb)

This directory contains the adapted, conflict-free device patch set for Realme GT2 Pro (`ferrari`) on **Evolution X** (`cnb` / Android 16).

---

## 1. Quick Usage

### Dry-Run Test (Verification without modifying code)
To check that all patches apply cleanly against the current source tree without touching any git branches:
```bash
bash device/realme/ferrari/patches/apply-patches.sh --check
```

### Apply All Patches
To apply all patches onto local `ferrari-patches` branches:
```bash
bash device/realme/ferrari/patches/apply-patches.sh
```

---

## 2. Changes from Legacy Patch Set

### Completely Removed Patches (Per User Instruction)
1. **Manifest Override Patch**:
   - `vendor-lineage/0001-evolution-ferrari-specific-vendor-config-tweaks.patch` (repo allowlist & fingerprint override hacks).
   - `local_manifests/ferrari.xml`.
2. **All OPlus Camera Patches & Proprietary Blobs**:
   - `patches/opluscamera/` (all 8 smali bytecode patches + docs).
   - `patches/camera-unit/` (all 2 smali bytecode patches + docs).
   - `patches/build-soong/0001-check_boot_jars-allow-OCS-camera-unit-SDK-bundled-pa.patch` (OCS Camera Unit SDK bootclasspath allowlist).
   - `patches/hardware-oplus/0001-oplus-fwk-expose-framework-APIs-required-by-OPlusCam.patch` (framework API shims).
   - `patches/vendor-realme-ferrari/` (all 13 patches modifying proprietary camera blobs).
   - `scripts/push-camera-unit-jar.sh`.

### Omitted as Already Merged Upstream in `evo` / Replaced Repositories
1. `bionic/0001`: Property spoofing, partition DM map, and process gating are already present in `bionic/libc/bionic/custom_rom_hide.cpp`.
2. `packages-apps-settings/0001`: `BasePreferenceFragment.kt` and `SearchIndexProviderHolder.java` are already merged in `packages/apps/Settings`.
3. `packages-apps-settings/0002`: `doze_on_charge` is already integrated upstream in `evolution_strings.xml` and `security_lockscreen_settings.xml`.
4. `packages-apps-settings/0003`: `no_storage_restrict` is already integrated upstream in `more_security_privacy_settings.xml` and `security_advanced_settings.xml`.
5. `packages-apps-evolver/0003`: `forceStopPackage` is already invoked directly in Kotlin `SpoofingSharedUi.kt`.
6. `kernel-oneplus-sm8450/0001`: C null-pointer initializations in `qcom-hv-haptics.c` and `cpu_voltage_cooling.c` are already present upstream.
7. `kernel-oneplus-sm8450/0002` & `0005`: Out-of-tree module fixes (`KEY_WAKEUP` on double tap and commented `ABS_TOUCH_COST_TIME_KERNEL`) are already implemented in `kernel/oneplus/sm8450-modules`.
8. `frameworks-base/0004`: LMOFreeform removal was dropped because Evolution-X actively uses LMOFreeform.
9. `hardware-qcom-caf-sm8450-display` (former 0001, 0002, 0003):
   - `sdm: Support Samsung FINGERPRINT_MASK DRM property` (Gerrit 432430)
   - `sdm: Operate FINGERPRINT_MASK for oplus optical UDFPS` (Gerrit 432431)
   - `sdm: Support pixelworks soft iris color calibration` (Gerrit 432432)
   Already integrated into `pjgowtham/android_hardware_qcom_display` (`lineage-24.0-caf-sm8450` and `lineage-24.0-caf-sm8450-6.6`).
10. `hardware-qcom-caf-sm8450/audio/pal` & `sm8450-6.6/audio/pal`:
   - `pal: Parse LVACFS microphone feature parameter` is already present upstream in ROM source.
11. `hardware-qcom-caf-sm8450/audio/agm` & `sm8450-6.6/audio/agm`:
   - `agm: Support sku agnostic acdb odm path` (Gerrit 507722/1) is cherry-picked directly in ROM source.

---

## 3. Directory Breakdown & Adapted Patches

| Subsystem | Target Repository in `evo` | Patches | Description |
| :--- | :--- | :---: | :--- |
| **`frameworks-av`** | `frameworks/av` | 2 | Device extension static lib hooks and legacy audio base connection export. |
| **`frameworks-base`** | `frameworks/base` | 9 | Multisensory LRA slider tuning, discrete haptics, binary torch fallback, night light wake flash fix, unified optical UDFPS dim layer with AOD near-black dimming, and banking compatibility USB sanitization / Build field spoofing / TrickyStore AUTO target. |
| **`frameworks-libs-systemui`** | `frameworks/libs/systemui` | 1 | Lumina / MSDL calibrated prebaked haptics fallback for X-axis LRA. |
| **`frameworks-native`** | `frameworks/native` | 1 | SurfaceFlinger dirty HWC color matrix for display transforms. |
| **`hardware-interfaces`** | `hardware/interfaces` | 1 | Audio HAL Bluetooth bridge prioritization. |
| **`hardware-lineage-compat`** | `hardware/lineage/compat` | 1 | Export legacy audio symbols and compatibility shims. |
| **`hardware-oplus`** | `hardware/oplus` | 4 | Fingerprint full-screen HBM flash avoidance, pickup wake-to-keyguard, power HAL checkService fallback (avoids deadlock watchdog), and SLA0815 X-axis LRA effect calibration. |
| **`hardware-qcom-caf-sm8450-audio-primary-hal`** | `hardware/qcom-caf/sm8450/audio/primary-hal` | 1 | Always initialize A2DP source offload. |
| **`hardware-qcom-caf-sm8450-display`** | `hardware/qcom-caf/sm8450/display` | 2 | Primary display mode power-on color transform restore (avoids cold Night Light wake flash) and zero-alpha UDFPS dim ignore. |
| **`hardware-qcom-caf-sm8450-6.6-display-hal`** | `hardware/qcom-caf/sm8450-6.6/display/hal` | 2 | AIDL HWC3 power mode color transform restore and 6.6 BuildLayerStack zero-alpha UDFPS dim ignore. |
| **`kernel-oneplus-sm8450`** | `kernel/oneplus/sm8450` | 1 | World-writable `0666` torch brightness sysfs nodes for user-space control. |
| **`packages-apps-evolver`** | `packages/apps/Evolver` | 1 | Compose-based banking compatibility picker integrated with `AxSandboxManager` and TrickyStore synchronization. |
| **`packages-apps-settings`** | `packages/apps/Settings` | 1 | Reverts leftover Settings per-app volume panel for HAL stability. |
| **`vendor-lineage`** | `vendor/lineage` | 1 | `libcamera_torch_ext` sysfs torch strength extension library. |
| **`vendor-oneplus-sm8450-common`** | `vendor/oneplus/sm8450-common` | 1 | Disable broken `tcmd` autostart daemon. |
| **`vendor-oneplus-aconfig`** | `vendor/oneplus/aconfig` | Overlay | Soong root-namespace overlay (LHDC disabled, torch strength enabled). |

**Total**: 29 git patches (sm8450 display + sm8450-6.6 display dual support) + 1 Soong aconfig overlay directory. All verified 100% clean with 0 conflicts.

