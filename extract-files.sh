#!/bin/bash
# Extract proprietary blobs for vfp from a stock /system dump (dir) and
# regenerate vendor/lge/vfp. usage: ./extract-files.sh <stock-system-dir>
set -e
SRC=${1:?usage: $0 <stock-system-dir>}
cd "$(dirname "$0")"
VENDOR=lge; DEVICE=vfp
OUT=../../../vendor/$VENDOR/$DEVICE
rm -rf $OUT/proprietary; mkdir -p $OUT/proprietary
for line in $(grep -vE '^#|^$' proprietary-blobs.txt); do
    src=${line%%:*}; dst=${line#*:}
    mkdir -p $OUT/proprietary/$(dirname $dst)
    cp -L "$SRC/$src" $OUT/proprietary/$dst
done
./setup-makefiles.sh
