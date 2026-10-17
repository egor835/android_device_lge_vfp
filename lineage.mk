$(call inherit-product, vendor/cm/config/common_full_phone.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, device/lge/vfp/device_vfp.mk)

# Boot animation
TARGET_SCREEN_WIDTH := 320
TARGET_SCREEN_HEIGHT := 480

PRODUCT_RELEASE_NAME := LG Wine Smart
PRODUCT_NAME := lineage_vfp
PRODUCT_DEVICE := vfp
PRODUCT_MODEL := LG-D486
PRODUCT_MANUFACTURER := LGE
PRODUCT_BRAND := lge

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=vfp_open_tw \
    BUILD_FINGERPRINT=lge/vfp_open_tw/vfp:4.4.2/KOT49I.D48610b/D48610b.1416275489:user/release-keys \
    PRIVATE_BUILD_DESC="vfp_open_tw-user 4.4.2 KOT49I.D48610b D48610b.1416275489 release-keys"
