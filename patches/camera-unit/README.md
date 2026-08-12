# CameraUnit SDK compatibility patches

This is the tracked, reverse-engineered patch series for
`system_ext/framework/com.oplus.camera.unit.sdk.jar`. `extract-files.py`
decodes the jar with apktool, applies every numbered patch here, rebuilds it,
and strips stale zip metadata during proprietary blob extraction.

| Patch | Purpose |
| --- | --- |
| `0001` | Overrides only microscope still capture to a single-frame ZSL request with MFNR/MFSR and custom noise reduction disabled. Ferrari's Waipio HAL rejects the newer app's ten-frame SWMF/MFSR request; this path returns a valid 1200x1200 JPEG from physical camera ID 3. |
| `0002` | Forces portrait still capture onto a single-frame non-bokeh path. The matched OPlusCamera APS `ALGO_BOKEH` stack fails to resolve `bokehInitializeEx`, so multi-frame portrait requests leave MediaStore pending JPEGs unfinalized. |

Keep this series synchronized with the app-side microscope changes in
`patches/opluscamera/0008`. Verify both 30x and 60x capture, persistent
MediaStore output, thumbnail handoff to Google Photos, and ordinary Photo and
Portrait captures (Portrait saves without APS bokeh) before committing rebuilt blobs.
