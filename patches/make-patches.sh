#!/bin/bash
#
# Regenerates the adapted ferrari device patch set from the local ROM source repos.
#
# Usage (from the ROM root, after committing new local source changes):
#     bash device/realme/ferrari/patches/make-patches.sh
#

set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
OUT="$ROOT/device/realme/ferrari/patches"

regenerate() {
    local repo="$1"
    local base="$2"
    local outdir="$3"
    if ! git -C "$ROOT/$repo" merge-base --is-ancestor "$base" HEAD 2>/dev/null; then
        echo "keep: $repo ($base is not an ancestor of HEAD; leaving $outdir)"
        return
    fi
    local count
    count="$(git -C "$ROOT/$repo" rev-list --count "$base"..HEAD)"
    if [ "$count" -eq 0 ]; then
        echo "keep: $repo (HEAD is $base, leaving existing patches)"
        return
    fi
    rm -rf "$outdir"
    mkdir -p "$outdir"
    git -C "$ROOT/$repo" format-patch "$base"..HEAD -o "$outdir"
}

# Active adapted repositories
regenerate frameworks/av HEAD~2 "$OUT/frameworks-av"
regenerate frameworks/base HEAD~9 "$OUT/frameworks-base"
regenerate frameworks/libs/systemui HEAD~1 "$OUT/frameworks-libs-systemui"
regenerate frameworks/native HEAD~1 "$OUT/frameworks-native"
regenerate hardware/interfaces HEAD~1 "$OUT/hardware-interfaces"
regenerate hardware/lineage/compat HEAD~1 "$OUT/hardware-lineage-compat"
regenerate hardware/oplus HEAD~4 "$OUT/hardware-oplus"
regenerate hardware/qcom-caf/sm8450/audio/primary-hal HEAD~1 "$OUT/hardware-qcom-caf-sm8450-audio-primary-hal"
regenerate hardware/qcom-caf/sm8450/display HEAD~2 "$OUT/hardware-qcom-caf-sm8450-display"
regenerate hardware/qcom-caf/sm8450-6.6/display/hal HEAD~2 "$OUT/hardware-qcom-caf-sm8450-6.6-display-hal"
regenerate kernel/oneplus/sm8450 HEAD~1 "$OUT/kernel-oneplus-sm8450"
regenerate packages/apps/Evolver HEAD~2 "$OUT/packages-apps-evolver"
regenerate packages/apps/Settings HEAD~2 "$OUT/packages-apps-settings"
regenerate vendor/lineage HEAD~1 "$OUT/vendor-lineage"
regenerate vendor/oneplus/sm8450-common HEAD~1 "$OUT/vendor-oneplus-sm8450-common"

echo "Patches check/regeneration finished under $OUT"

