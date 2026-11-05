#!/bin/bash
#
# Applies (or tests) the ferrari device patch set onto the ROM sources.
#
# Usage:
#   Test all patches without modifying source trees (dry run):
#       bash device/realme/ferrari/patches/apply-patches.sh --check
#
#   Apply patches onto the ROM trees:
#       bash device/realme/ferrari/patches/apply-patches.sh
#
# Behavior:
#   - Repo dirs are matched to the patch dir names (frameworks/base,
#     kernel/oneplus/sm8450, vendor/lineage, etc.).
#   - OPlus Camera patches and manifest overrides have been completely removed.
#   - Upstream already-merged patches (bionic hide, SAF removal, etc.) have been omitted.
#   - If --check or --dry-run is passed, tests sequential application in an isolated
#     temporary git index without touching any working trees or git branches.
#   - In normal mode, resets local branch "ferrari-patches" to synced manifest revision
#     and applies with `git am --keep-cr`, falling back to `--3way`.
#   - vendor/oneplus/aconfig is a Soong root-namespace overlay and is copied into place.
#

set -u

DRY_RUN=0
if [ "${1:-}" = "--check" ] || [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    echo "=== Running in DRY-RUN mode (isolated sequential index check) ==="
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
BRANCH="ferrari-patches"

declare -A REPO_PATHS=(
    [frameworks-av]="frameworks/av"
    [frameworks-base]="frameworks/base"
    [frameworks-libs-systemui]="frameworks/libs/systemui"
    [frameworks-native]="frameworks/native"
    [hardware-interfaces]="hardware/interfaces"
    [hardware-lineage-compat]="hardware/lineage/compat"
    [hardware-oplus]="hardware/oplus"
    [hardware-qcom-caf-sm8450-audio-primary-hal]="hardware/qcom-caf/sm8450/audio/primary-hal"
    [hardware-qcom-caf-sm8450-display]="hardware/qcom-caf/sm8450/display"
    [hardware-qcom-caf-sm8450-6.6-display-hal]="hardware/qcom-caf/sm8450-6.6/display/hal"
    [kernel-oneplus-sm8450]="kernel/oneplus/sm8450"
    [packages-apps-evolver]="packages/apps/Evolver"
    [packages-apps-settings]="packages/apps/Settings"
    [vendor-lineage]="vendor/lineage"
    [vendor-oneplus-sm8450-common]="vendor/oneplus/sm8450-common"
)

applied=0
skipped=0
failed=0

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
    case "$repo_name" in
        vendor-oneplus-aconfig) continue ;;
    esac
    target="$ROOT/${REPO_PATHS[$repo_name]:-$repo_name}"

    if [ ! -e "$target/.git" ]; then
        echo "skip: $repo_name (no git repo at $target)"
        continue
    fi

    shopt -s nullglob
    patches=("$repo_dir"*.patch)
    shopt -u nullglob
    if [ ${#patches[@]} -eq 0 ]; then
        continue
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Checking $repo_name (${#patches[@]} patches)..."
        TMP_INDEX="$(mktemp)"
        cp "$target/.git/index" "$TMP_INDEX" 2>/dev/null || true
        export GIT_INDEX_FILE="$TMP_INDEX"
        for patch in "${patches[@]}"; do
            name="$(basename "$patch")"
            subject="$(patch_subject "$patch")"
            if subject_in_history "$target" "$subject"; then
                echo "  ALREADY APPLIED: $name"
                applied=$((applied + 1))
            elif git -C "$target" apply --check --cached "$patch" >/dev/null 2>&1; then
                git -C "$target" apply --cached "$patch" >/dev/null 2>&1
                echo "  OK: $name"
                applied=$((applied + 1))
            else
                echo "  FAILED: $name"
                git -C "$target" apply --check --cached "$patch"
                failed=$((failed + 1))
            fi
        done
        rm -f "$TMP_INDEX"
        unset GIT_INDEX_FILE
        continue
    fi

    git -C "$target" am --abort >/dev/null 2>&1 || true

    start_ref=""
    case "$repo_name" in
        hardware-qcom-caf-sm8450-display|hardware-qcom-caf-sm8450-audio-primary-hal|hardware-qcom-caf-sm8450-audio-pal|hardware-qcom-caf-sm8450-audio-agm)
            if git -C "$target" rev-parse -q --verify "lineage-24.0-caf-sm8450" >/dev/null; then
                start_ref="lineage-24.0-caf-sm8450"
            elif git -C "$target" rev-parse -q --verify "pjgowtham/lineage-24.0-caf-sm8450" >/dev/null; then
                start_ref="pjgowtham/lineage-24.0-caf-sm8450"
            fi
            ;;
        hardware-qcom-caf-sm8450-6.6-display-hal|hardware-qcom-caf-sm8450-6.6-audio-primary-hal|hardware-qcom-caf-sm8450-6.6-audio-pal|hardware-qcom-caf-sm8450-6.6-audio-agm)
            if git -C "$target" rev-parse -q --verify "lineage-24.0-caf-sm8450-6.6" >/dev/null; then
                start_ref="lineage-24.0-caf-sm8450-6.6"
            elif git -C "$target" rev-parse -q --verify "pjgowtham/lineage-24.0-caf-sm8450-6.6" >/dev/null; then
                start_ref="pjgowtham/lineage-24.0-caf-sm8450-6.6"
            fi
            ;;
        hardware-qcom-caf-thermal)
            if git -C "$target" rev-parse -q --verify "lineage-24.0" >/dev/null; then
                start_ref="lineage-24.0"
            fi
            ;;
    esac

    if [ -z "$start_ref" ]; then
        current_branch="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
        if [ "$current_branch" != "HEAD" ] && [ "$current_branch" != "$BRANCH" ] && [ -n "$current_branch" ]; then
            start_ref="$current_branch"
        elif git -C "$target" rev-parse -q --verify m/cnb >/dev/null; then
            start_ref="m/cnb"
        elif git -C "$target" rev-parse -q --verify evo/cnb >/dev/null; then
            start_ref="evo/cnb"
        elif git -C "$target" rev-parse -q --verify lineage-24.0 >/dev/null; then
            start_ref="lineage-24.0"
        elif git -C "$target" rev-parse -q --verify lineage-22.0 >/dev/null; then
            start_ref="lineage-22.0"
        fi
    fi
    if [ -n "$start_ref" ]; then
        if ! git -C "$target" checkout -q -B "$BRANCH" "$start_ref"; then
            echo "FAIL: $repo_name: cannot reset $BRANCH to $start_ref (uncommitted changes?)"
            failed=$((failed + 1))
            continue
        fi
    else
        cur="$(git -C "$target" rev-parse --abbrev-ref HEAD 2>/dev/null)"
        if [ "$cur" != "$BRANCH" ]; then
            if ! git -C "$target" checkout -q -B "$BRANCH"; then
                echo "FAIL: $repo_name: cannot create branch $BRANCH (uncommitted changes?)"
                failed=$((failed + 1))
                continue
            fi
        fi
    fi

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
        if git -C "$target" am --keep-cr "$patch" \
                || { git -C "$target" am --abort >/dev/null 2>&1; git -C "$target" am --3way --keep-cr "$patch"; }; then
            echo "applied: $repo_name/$name"
            applied=$((applied + 1))
        elif git -C "$target" apply --index "$patch" >/dev/null 2>&1; then
            git -C "$target" am --abort >/dev/null 2>&1 || true
            git -C "$target" commit -q -m "$subject" --author="Bubun Das <bubundas17@gmail.com>"
            echo "applied (apply+commit): $repo_name/$name"
            applied=$((applied + 1))
        else
            echo "FAILED: $repo_name/$name"
            git -C "$target" am --abort 2>/dev/null
            failed=$((failed + 1))
        fi
    done
done

# vendor/oneplus/aconfig is a Soong root-namespace overlay, not a git repo.
aconfig_src="$SCRIPT_DIR/vendor-oneplus-aconfig"
aconfig_dst="$ROOT/vendor/oneplus/aconfig"
if [ -d "$aconfig_src" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Checking vendor-oneplus-aconfig overlay: OK (present at $aconfig_src)"
        applied=$((applied + 1))
    else
        mkdir -p "$aconfig_dst/com.android.bluetooth.flags" \
                 "$aconfig_dst/com.android.systemui.flags"
        cp -a "$aconfig_src/Android.bp" "$aconfig_dst/Android.bp"
        cp -a "$aconfig_src/com.android.bluetooth.flags/." \
            "$aconfig_dst/com.android.bluetooth.flags/"
        cp -a "$aconfig_src/com.android.systemui.flags/." \
            "$aconfig_dst/com.android.systemui.flags/"
        echo "applied: vendor-oneplus-aconfig -> vendor/oneplus/aconfig"
        applied=$((applied + 1))
    fi
else
    echo "FAILED: vendor-oneplus-aconfig overlay missing at $aconfig_src"
    failed=$((failed + 1))
fi

echo
echo "Summary: $applied checked/applied, $skipped skipped, $failed failed"
[ "$failed" -eq 0 ]
