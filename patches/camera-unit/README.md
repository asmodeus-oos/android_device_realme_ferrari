# CameraUnit SDK compatibility patches

This is the tracked, reverse-engineered patch series for
`system_ext/framework/com.oplus.camera.unit.sdk.jar`. `extract-files.py`
decodes the jar with apktool, applies every numbered patch here, rebuilds it,
and strips stale zip metadata during proprietary blob extraction.

| Patch | Purpose |
| --- | --- |
| `0001` | Overrides only microscope still capture to a single-frame ZSL request with MFNR/MFSR and custom noise reduction disabled. Ferrari's Waipio HAL rejects the newer app's ten-frame SWMF/MFSR request; this path returns a valid 1200x1200 JPEG from physical camera ID 3. |

Keep this series synchronized with the app-side microscope changes in
`patches/opluscamera/0008`. Verify both 30x and 60x capture, persistent
MediaStore output, thumbnail handoff to Google Photos, and ordinary Photo and
Portrait previews before committing rebuilt blobs.
