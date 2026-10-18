#!/sbin/sh
#
# vfp boots this ROM straight from the boot partition, which only works with the
# unlocked prototype aboot (the "FX_VZW_US" one that also provides fastboot).
# The retail D486 aboot only boots LG-signed images, so refuse to install there.
#

ABOOT=/dev/block/platform/msm_sdcc.1/by-name/aboot

# sha1 of the whole 2 MiB aboot partition with the prototype aboot flashed
KNOWN="868e49d3524be1290ceb09e25e5dd8e9553f224e"

sum=$(sha1sum "$ABOOT" 2>/dev/null | cut -d' ' -f1)
for k in $KNOWN; do
    [ "$sum" = "$k" ] && exit 0
done
exit 1
