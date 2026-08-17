# vendor/oneplus/aconfig overlay

`vendor/oneplus/aconfig/` is not a git repo, so these files cannot be
`git am`'d. `apply-patches.sh` copies this tree onto
`vendor/oneplus/aconfig/` after every `repo sync`.

Release-config value sets are looked up by name from every
`aconfig_declarations` module, so they must live in the root Soong
namespace (`vendor/oneplus/aconfig`), not under `device/realme/ferrari`.
`device/realme/ferrari/release/release_configs/cp2a.textproto` references
`aconfig_value_set-ferrari`.

- LHDC disabled: QTI A2DP offload has no LHDC parser; earbuds fall back to AAC/SBC.
- Flashlight strength enabled: QS torch long-press level slider.
