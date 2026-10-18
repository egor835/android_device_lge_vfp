#!/bin/bash
# Apply the vfp patches to the other projects of a LineageOS 14.1 tree.
# Run from anywhere; the tree root is found relative to this script.
set -e
TOP=$(cd "$(dirname "$0")/../../../.." && pwd)
PATCHES=$(cd "$(dirname "$0")" && pwd)

apply() {
    local project=$1 dir=$2
    echo "==> $project"
    for p in "$PATCHES/$dir"/*.patch; do
        if git -C "$TOP/$project" apply --check -R "$p" >/dev/null 2>&1; then
            echo "    already applied $(basename "$p")"
        elif git -C "$TOP/$project" am -3 --keep-cr "$p" >/dev/null 2>&1; then
            echo "    applied $(basename "$p")"
        else
            git -C "$TOP/$project" am --abort >/dev/null 2>&1 || true
            echo "    FAILED $(basename "$p")"; exit 1
        fi
    done
}

apply art art
apply device/lge/msm8226-common device_lge_msm8226-common
apply vendor/lge vendor_lge
