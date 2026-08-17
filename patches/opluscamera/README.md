# OPlusCamera compatibility patches

This directory is the tracked, reverse-engineered compatibility layer for the
stock Ferrari OPlusCamera APK. `extract-files.py` applies every numbered patch
to `system_ext/priv-app/OplusCamera/OplusCamera.apk` through
`apktool_patch('patches/opluscamera')` when proprietary blobs are extracted.
The companion `patches/camera-unit` series tracks fixes to the proprietary
CameraUnit SDK jar used by the app.

Keep patches numbered and narrowly scoped.  Do not replace the patched APK by
hand: update this series, re-extract the blob, and commit the resulting vendor
change through `patches/make-patches.sh`.

The companion `vendor-realme-ferrari/0006` patch removes the unavailable SAT
entry, while `0008` restores Ferrari's distinct rear-portrait logical camera.
Camera Unit ID 4 must remain present: it is the main + ultrawide portrait
composite, not the absent SAT/tele slot.

| Patch | Purpose |
| --- | --- |
| `0001` | Removes OOS-only manifest assumptions that prevent use from the AOSP system-ext linker namespace. |
| `0002` | Falls back to the platform typeface when the OOS typeface is unavailable. |
| `0003` | Maps logical camera IDs before looking up camcorder profiles. |
| `0004` | Uses a safe default camcorder profile when the requested profile is absent. |
| `0005` | Avoids recorder setup when no profile can be resolved. |
| `0006` | Launches the captured image or video in Google Photos and bypasses the obsolete OPlus Gallery presence check. |
| `0007` | Restores Ferrari's supported 60-fps video, 120/240/480-fps slow video, and microscope entries when the OOS feature aliases are absent. |
| `0008` | Uses the microscope sensor's supported 1080x1080 preview and keeps the app-side capture request at one frame. |

After changing this series, verify all of the following on a booted device with
SELinux enforcing:

1. The camera opens without a crash.
2. A photo finalizes in MediaStore.
3. A video finalizes in MediaStore.
4. Tapping the latest photo and latest video thumbnails opens Google Photos.
5. The video selector offers 60 fps at 720p, 1080p, and 4K.
6. More modes includes Slow motion and Microscope; verify 1080p120, 720p240/480, and both 30x and 60x microscope captures produce persistent 1200x1200 JPEGs.
7. Portrait opens the stock rear-portrait logical camera (main + ultrawide) and retains a responsive preview after using Microscope.
