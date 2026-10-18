#
# Copyright (C) 2026 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

-include device/lge/msm8226-common/BoardConfigCommon.mk
-include vendor/lge/vfp/BoardConfigVendor.mk

DEVICE_PATH := device/lge/vfp

TARGET_OTA_ASSERT_DEVICE := vfp,d486,D486,LG-D486,f480,F480

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := vfp

# Kernel
TARGET_KERNEL_SOURCE := kernel/lge/vfp
TARGET_KERNEL_CONFIG := vfp_lineage_defconfig
# The uncompressed kernel is ~20M: keep the ramdisk out of its way (stock: 0x02000000)
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x02000000 --tags_offset 0x00000100
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

# Partitions (boot holds lk2nd in its first 512K)
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE     := 22544384
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 23068672
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 1400897536
BOARD_USERDATAIMAGE_PARTITION_SIZE := 1803550720
BOARD_CACHEIMAGE_PARTITION_SIZE    := 318767104
BOARD_PERSISTIMAGE_PARTITION_SIZE  := 33554432

# Display
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"

# Only 1G RAM + small system partition
MALLOC_SVELTE := true
WITH_DEXPREOPT := true
DONT_DEXPREOPT_PREBUILTS := true

# Charger: let the CM charger turn on the LM3530 backlight
BACKLIGHT_PATH := /sys/class/leds/lcd-backlight/brightness
HEALTHD_BACKLIGHT_LEVEL := 100
