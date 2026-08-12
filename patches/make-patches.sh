#!/bin/bash
#
# Regenerates the ferrari device patch set from the local ROM source repos.
#
# Usage (from the ROM root, after committing new local source changes):
#     bash device/realme/ferrari/patches/make-patches.sh
#
# Each repo is diffed against its fork point (the last upstream commit the
# local branch was created from). Update the base SHAs below if the local
# branches are ever rebased onto a newer upstream.
#
# The generated patches are applied with
# device/realme/ferrari/patches/apply-patches.sh

set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
OUT="$ROOT/device/realme/ferrari/patches"

regenerate() {
    local repo="$1"
    local base="$2"
    local outdir="$3"
    rm -rf "$outdir"
    mkdir -p "$outdir"
    git -C "$ROOT/$repo" format-patch "$base"..HEAD -o "$outdir"
}

regenerate frameworks/base 9b016cee78fd "$OUT/frameworks-base"
regenerate frameworks/libs/systemui a7a3391 "$OUT/frameworks-libs-systemui"
regenerate frameworks/native 81c26abb45 "$OUT/frameworks-native"
regenerate bionic 9d89221a0 "$OUT/bionic"
regenerate kernel/oneplus/sm8450 2863ca29^ "$OUT/kernel-oneplus-sm8450"
regenerate vendor/lineage 381d6e41^ "$OUT/vendor-lineage"
regenerate build/soong 7be596ebc "$OUT/build-soong"
regenerate frameworks/av d6ae0c5d6c "$OUT/frameworks-av"
regenerate hardware/interfaces 99af2c382e "$OUT/hardware-interfaces"
regenerate hardware/lineage/compat 655b314 "$OUT/hardware-lineage-compat"
regenerate hardware/oplus 1a0f97a "$OUT/hardware-oplus"
regenerate hardware/qcom-caf/sm8450/audio/primary-hal ec8354bb1 "$OUT/hardware-qcom-caf-sm8450-audio-primary-hal"
regenerate hardware/qcom-caf/sm8450/display 9dfe54165606 "$OUT/hardware-qcom-caf-sm8450-display"
regenerate packages/apps/Evolver 4754f536c "$OUT/packages-apps-evolver"
regenerate packages/apps/Settings f80d3f65fe6 "$OUT/packages-apps-settings"
regenerate vendor/oneplus/sm8450-common c860054 "$OUT/vendor-oneplus-sm8450-common"
regenerate vendor/realme/ferrari 259ef42 "$OUT/vendor-realme-ferrari"

echo "Patches regenerated under $OUT"
