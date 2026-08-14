#!/bin/bash
#
# Applies the ferrari device patch set onto the ROM sources.
#
# Usage:
#   After `repo sync` (or any upstream update), run from the ROM root:
#       bash device/realme/ferrari/patches/apply-patches.sh
#
# Behavior:
#   - Repo dirs are matched to the patch dir names (frameworks/base,
#     kernel/oneplus/sm8450, vendor/lineage).
#   - A local branch "ferrari-patches" is (re)created at the current HEAD
#     if not already checked out, so git am has a branch to commit onto.
#   - Patches already applied (same commit subject in history) are skipped.
#   - If the newest patch in a directory is already in history (typical
#     for bubundas17 ferrari-fixes forks, or a depth=1 clone of them),
#     the whole directory is skipped. Re-applying LFS pointer diffs onto
#     smudged binaries would conflict.
#   - Remaining patches are applied with `git am --3way` so upstream
#     context changes can be merged automatically when possible.
#
# Regenerate the patch files after any source change with
# device/realme/ferrari/patches/make-patches.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
BRANCH="ferrari-patches"

declare -A REPO_PATHS=(
    [frameworks-base]="frameworks/base"
    [frameworks-libs-systemui]="frameworks/libs/systemui"
    [frameworks-native]="frameworks/native"
    [bionic]="bionic"
    [kernel-oneplus-sm8450]="kernel/oneplus/sm8450"
    [vendor-lineage]="vendor/lineage"
    [build-soong]="build/soong"
    [frameworks-av]="frameworks/av"
    [hardware-interfaces]="hardware/interfaces"
    [hardware-lineage-compat]="hardware/lineage/compat"
    [hardware-oplus]="hardware/oplus"
    [hardware-qcom-caf-sm8450-audio-primary-hal]="hardware/qcom-caf/sm8450/audio/primary-hal"
    [hardware-qcom-caf-sm8450-display]="hardware/qcom-caf/sm8450/display"
    [packages-apps-evolver]="packages/apps/Evolver"
    [packages-apps-settings]="packages/apps/Settings"
    [vendor-oneplus-sm8450-common]="vendor/oneplus/sm8450-common"
    [vendor-realme-ferrari]="vendor/realme/ferrari"
)

applied=0
skipped=0
failed=0

# First line of Subject: plus RFC 2822 wrapped continuations.
patch_subject() {
    awk '
        BEGIN { s = "" }
        /^Subject: / {
            sub(/^Subject: \[PATCH[^]]*\] /, "")
            s = $0
            next
        }
        s != "" && /^[ \t]/ {
            sub(/^[ \t]+/, " ")
            s = s $0
            next
        }
        s != "" { exit }
        END { print s }
    ' "$1"
}

subject_in_history() {
    local target="$1" subject="$2"
    [ -n "$subject" ] || return 1
    git -C "$target" log --format=%s HEAD | grep -qF "$subject"
}

for repo_dir in "$SCRIPT_DIR"/*/; do
    repo_name="$(basename "$repo_dir")"
    target="$ROOT/${REPO_PATHS[$repo_name]:-$repo_name}"

    if [ ! -e "$target/.git" ]; then
        echo "skip: $repo_name (no git repo at $target)"
        continue
    fi

    git -C "$target" am --abort >/dev/null 2>&1 || true

    cur="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ "$cur" != "$BRANCH" ]; then
        if ! git -C "$target" checkout -q -B "$BRANCH"; then
            echo "FAIL: $repo_name: cannot create branch $BRANCH (uncommitted changes?)"
            failed=$((failed + 1))
            continue
        fi
    fi

    shopt -s nullglob
    patches=("$repo_dir"*.patch)
    shopt -u nullglob
    if [ ${#patches[@]} -eq 0 ]; then
        continue
    fi

    # Forks already on ferrari-fixes (or a depth=1 clone of it) already
    # contain every patch in the tree. Re-applying LFS pointer diffs onto
    # smudged binaries conflicts. If the newest patch is in history, skip
    # the whole directory.
    last_subject="$(patch_subject "${patches[-1]}")"
    if subject_in_history "$target" "$last_subject"; then
        echo "already applied: $repo_name (tree includes: $last_subject)"
        skipped=$((skipped + ${#patches[@]}))
        continue
    fi

    for patch in "${patches[@]}"; do
        name="$(basename "$patch")"
        subject="$(patch_subject "$patch")"
        if subject_in_history "$target" "$subject"; then
            echo "already applied: $repo_name/$name"
            skipped=$((skipped + 1))
            continue
        fi
        # Several upstream OPLUS framework stubs use CRLF. Preserve carriage
        # returns while parsing mail patches so their context stays exact.
        if git -C "$target" am --3way --keep-cr "$patch"; then
            echo "applied: $repo_name/$name"
            applied=$((applied + 1))
        else
            echo "FAILED: $repo_name/$name"
            git -C "$target" am --abort 2>/dev/null
            failed=$((failed + 1))
        fi
    done
done

echo
echo "Summary: $applied applied, $skipped skipped, $failed failed"
[ "$failed" -eq 0 ]
