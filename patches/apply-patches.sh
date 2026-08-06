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
    [kernel-oneplus-sm8450]="kernel/oneplus/sm8450"
    [vendor-lineage]="vendor/lineage"
)

applied=0
skipped=0
failed=0

for repo_dir in "$SCRIPT_DIR"/*/; do
    repo_name="$(basename "$repo_dir")"
    target="$ROOT/${REPO_PATHS[$repo_name]:-$repo_name}"

    if [ ! -e "$target/.git" ]; then
        echo "skip: $repo_name (no git repo at $target)"
        continue
    fi

    cur="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [ "$cur" != "$BRANCH" ]; then
        if ! git -C "$target" checkout -q -B "$BRANCH"; then
            echo "FAIL: $repo_name: cannot create branch $BRANCH (uncommitted changes?)"
            failed=$((failed + 1))
            continue
        fi
    fi

    for patch in "$repo_dir"*.patch; do
        name="$(basename "$patch")"
        subject="$(sed -n 's/^Subject: \[PATCH[^]]*\] //p' "$patch" | head -n1)"
        if [ -n "$subject" ] && git -C "$target" log --format=%s HEAD | grep -qF "$subject"; then
            echo "already applied: $repo_name/$name"
            skipped=$((skipped + 1))
            continue
        fi
        if git -C "$target" am --3way "$patch"; then
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
