#!/bin/bash
# Wait for lk2nd fastboot, `fastboot boot` the given image, report ADB_UP / CRASH(9006) / TIMEOUT
IMG=$1; WAIT=${2:-400}
for i in $(seq 1 $WAIT); do timeout 2 fastboot getvar product 2>&1 | grep -q lk2nd && break; sleep 1; done
timeout 2 fastboot getvar product 2>&1 | grep -q lk2nd || { echo NO_LK2ND; exit 1; }
timeout 60 fastboot boot "$IMG" 2>&1 | tail -1
for i in $(seq 1 120); do
  adb devices | grep -qE 'recovery$|device$' && { echo ADB_UP; exit 0; }
  /usr/bin/lsusb | grep -qiE '1004:61a1|05c6:900' && { echo CRASH; exit 2; }
  sleep 1
done
echo TIMEOUT; exit 3
