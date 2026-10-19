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

The retail D486 aboot only boots LG-signed images and has no fastboot. Both ways below
need the **unlocked prototype aboot** (`FX_VZW_US`, from the Firefox OS prototype) in the
`aboot` partition: it boots unsigned images and provides fastboot. It is attached to the
releases (`aboot.img`, `abootb.img`).

> Flashing a bootloader can hard-brick the phone. Make a full eMMC backup first and make
> sure you can reach Qualcomm EDL mode (9008) to restore it.

```
# from TWRP or a root shell
dd if=aboot.img  of=/dev/block/platform/msm_sdcc.1/by-name/aboot
dd if=abootb.img of=/dev/block/platform/msm_sdcc.1/by-name/abootb
```

Prototype aboot fastboot: hold **Volume Down** while powering on until the first
vibration, or `adb reboot bootloader` (`fastboot getvar product` → `FX_VZW_US`).

### A. TWRP + zip (recommended)

1. Boot TWRP from the release: `fastboot boot twrp-vfp.img` (or `fastboot flash recovery`).
2. Wipe data/cache if coming from stock, then install the LineageOS zip.
   The zip does not check `aboot`: make sure yours boots unsigned images (the prototype
   one, or a stock aboot with the signature check patched out).
3. Reboot: the prototype aboot boots LineageOS straight from `boot`.

### B. Through lk2nd

[lk2nd](https://github.com/msm8916-mainline/lk2nd) (msm8226, 23.1+) lives in the first
512 KiB of `boot` and boots the Android image stored right after it; its fastboot takes
care of that offset.

1. Write lk2nd to `boot` (zero the partition first):
   ```
   dd if=/dev/zero of=/dev/block/platform/msm_sdcc.1/by-name/boot bs=1M
   dd if=lk2nd-msm8226.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
   ```
2. With no Android image after it you land in lk2nd fastboot
   (`fastboot getvar product` → `lk2nd-msm8226`). With a ROM installed, press Volume Down
   *after* the first vibration (pressing it before the vibration enters the aboot
   fastboot instead).
3. `fastboot flash system system.img`, `boot`, `cache`, `userdata`, then `fastboot reboot`.

Installing the zip from TWRP replaces lk2nd (it writes the whole `boot` partition).

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
