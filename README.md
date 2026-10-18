# LineageOS 14.1 for the LG Wine Smart (vfp)

Device tree for the LG Wine Smart family, codename **vfp**: an MSM8926 (Snapdragon 400)
flip phone with a 320x480 screen, a hardware keypad and 1 GB of RAM.

| Model | Notes |
|---|---|
| LG-D486 | retail (TW / open), KitKat 4.4.2 stock |
| LG-F480S/K/L | Korean variants |
| LG F480L / FB480T prototype | shipped with Firefox OS 2.2 |

## Status

| Working | |
|---|---|
| Display, touch, keypad, keypad backlight | |
| Flip (hall sensor): screen off when closed | |
| Wi-Fi, Bluetooth | |
| Calls, SMS, mobile data (LTE) | |
| Audio: speaker, earpiece, headset, in-call | |
| Rear camera (Sony IMX219 **or** Hynix HI544, see below), front camera (HI707), video | |
| Sensors: accelerometer, proximity, step counter | |
| FM radio | |
| RGB notification / battery LED (LP5521) | |
| Off-mode charging | |
| Hardware keystore (QSEECOM keymaster) | |
| GPS | not tested |

SELinux is **permissive**.

### Hardware variants

The kernel probes both and registers whichever answers; the userspace libraries for
all of them are shipped:

| | rear camera | keypad IRQ |
|---|---|---|
| D486 (newer boards) | Sony IMX219 | GPIO 52 |
| F480 / prototype boards | Hynix HI544 | GPIO 115 |

## Installing

The stock bootloader is locked, so this ROM boots through
[lk2nd](https://github.com/msm8916-mainline/lk2nd) (msm8226 build, 23.1 or newer):
lk2nd lives in the first 512 KiB of the `boot` partition and boots the Android image
stored right after it. lk2nd's fastboot takes care of that offset for `boot`.

1. Install lk2nd into `boot` (e.g. from TWRP or a rooted shell):
   ```
   dd if=/dev/zero of=/dev/block/platform/msm_sdcc.1/by-name/boot bs=1M
   dd if=lk2nd-msm8226.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
   ```
2. Reboot. With no Android image in `boot` you land in lk2nd fastboot
   (`fastboot getvar product` → `lk2nd-msm8226`). Once a ROM is installed, enter lk2nd by
   holding Volume Down while powering on.
   Note: `adb reboot bootloader` goes to the stock aboot fastboot, not lk2nd.
3. Flash the images from `out/target/product/vfp`:
   ```
   fastboot flash system system.img
   fastboot flash boot boot.img
   fastboot flash cache cache.img
   fastboot flash userdata userdata.img   # wipes data
   fastboot reboot
   ```

Do **not** flash the OTA zip from TWRP as is: its updater script writes `boot.img` over the
whole `boot` partition and removes lk2nd.

## Building

```
repo init -u https://github.com/LineageOS/android.git -b cm-14.1
cp local_manifests/vfp.xml .repo/local_manifests/      # from this repository
repo sync
device/lge/vfp/patches/apply.sh
source build/envsetup.sh
lunch lineage_vfp-userdebug
make bacon
```

LineageOS 14.1 wants an old host: build in an Ubuntu 16.04 container with OpenJDK 8.
Newer OpenJDK 8 updates disable TLSv1/1.1, which Jack needs: remove them from
`jdk.tls.disabledAlgorithms` in `java.security`, and make sure `USER` is set.

### Patches to other projects

`patches/apply.sh` applies these on top of the synced tree:

- **art** — `ImageWriter` relocated the `ArtMethod` of `Method`/`Constructor` objects in a
  multi-image boot image against the first image instead of their own. A cached
  `X500Principal` constructor ended up pointing 0x14000 bytes off, and every TLS handshake
  crashed in `art::InvokeMethod`; `system_server` crashed as soon as Wi-Fi connected.
- **device/lge/msm8226-common** — build the common HALs for vfp (it ships its own lights
  HAL); mount the modem firmware in charger mode, otherwise the modem firmware request
  blocked for 60 s and so did leaving off-mode charging.
- **vendor/lge** — build the msm8226-common blobs for vfp.

## Repositories

- Device: [egor835/android_device_lge_vfp](https://github.com/egor835/android_device_lge_vfp)
- Kernel: [egor835/android_kernel_lge_vfp](https://github.com/egor835/android_kernel_lge_vfp)
  (LineageOS `android_kernel_lge_msm8226` plus vfp support taken from the LG D486 KK v10a
  source release, including the KK camera driver the stock camera blobs need)
- Vendor: [egor835/proprietary_vendor_lge_vfp](https://github.com/egor835/proprietary_vendor_lge_vfp)
  (from stock D48610b; regenerate with `extract-files.sh <stock /system dump>`)

## Debugging notes

- The persistent RAM console sits at lk2nd's ramoops console (0x2ffc0000), but the
  bootloader clears it on reboot, so `/proc/last_kmsg` is usually empty.
- On a kernel panic the phone drops into Qualcomm crash mode (USB `1004:61a1`/`05c6:9006`).
  RAM can then be read over Sahara; the kernel log is at `__log_buf` (physical address =
  virtual - 0xc0000000).
