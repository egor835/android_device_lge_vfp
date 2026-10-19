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

$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

LOCAL_PATH := device/lge/vfp

# Camera: autofocus, but no flash. msm8226-common installs the flash-autofocus
# feature file; PRODUCT_COPY_FILES keeps the first entry for a destination, so
# put the plain autofocus feature at that path first.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml

# PrintSpooler is not built: drop android.software.print. Comes before
# msm8226-common's copy of the stock file, so this one wins.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/etc/permissions/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml

# Overlay
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Screen: 320x480 HVGA
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := mdpi

# Ramdisk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.vfp.rc:system/etc/init/init.vfp.rc

# Audio / media
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/etc/mixer_paths.xml:system/etc/mixer_paths.xml \
    $(LOCAL_PATH)/prebuilt/etc/media_profiles.xml:system/etc/media_profiles.xml

# Input: PP2106 keypad, touch, keys
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/usr/keylayout/pp2106-keypad.kl:system/usr/keylayout/pp2106-keypad.kl \
    $(LOCAL_PATH)/prebuilt/usr/keylayout/gpio-keys.kl:system/usr/keylayout/gpio-keys.kl \
    $(LOCAL_PATH)/prebuilt/usr/keylayout/qpnp_pon.kl:system/usr/keylayout/qpnp_pon.kl \
    $(LOCAL_PATH)/prebuilt/usr/keychars/pp2106-keypad.kcm:system/usr/keychars/pp2106-keypad.kcm \
    $(LOCAL_PATH)/prebuilt/usr/idc/pp2106-keypad.idc:system/usr/idc/pp2106-keypad.idc \
    $(LOCAL_PATH)/prebuilt/usr/idc/touch_dev.idc:system/usr/idc/touch_dev.idc

# Bluetooth NV library (not shipped on D486 stock)
PRODUCT_COPY_FILES += \
    vendor/lge/g2m/proprietary/lib/libbtnv.so:system/lib/libbtnv.so

# Shims
PRODUCT_PACKAGES += \
    libshim_camera

# Features
BOARD_HAS_QCOM_WCNSS := true
BOARD_HAS_NFC := false
BOARD_HAS_LG_IRRC := false

# Low-RAM friendly defaults
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.low_ram=false \
    dalvik.vm.jit.codecachesize=0 \
    ro.sf.lcd_density=160

# Dalvik heap: ~880 MB usable RAM. The phone-hdpi-512 profile (48m growth
# limit) makes modern apps (media3/Compose) throw OutOfMemoryError.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=96m \
    dalvik.vm.heapsize=192m \
    dalvik.vm.heaptargetutilization=0.75 \
    dalvik.vm.heapminfree=2m \
    dalvik.vm.heapmaxfree=8m

$(call inherit-product, device/lge/msm8226-common/msm8226.mk)
$(call inherit-product, vendor/lge/vfp/vfp-vendor.mk)
