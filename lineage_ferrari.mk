#
# Copyright (C) 2021-2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from ferrari device
$(call inherit-product, device/realme/ferrari/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_ferrari
PRODUCT_DEVICE := ferrari
PRODUCT_MANUFACTURER := realme
PRODUCT_BRAND := realme
PRODUCT_MODEL := RMX3301
WITH_GMS := true
WITH_GMS_COMMS_SUITE := true
WITH_SUPERSU := true
WITH_ADB_INSECURE := true
TARGET_ENABLE_BLUR := true
TARGET_SUPPORTS_QUICK_TAP := true
TARGET_INCLUDE_LIVE_WALLPAPERS := true
TARGET_INCLUDE_STOCK_ARCORE := true
TARGET_HAS_UDFPS := true
TARGET_FACE_UNLOCK_SUPPORTED := true
TARGET_INCLUDE_BCR := true
TARGET_EXCLUDES_AUDIOFX := true
TARGET_INCLUDE_BOOT_ANIMATIONS := true
TARGET_BOOT_ANIMATION_RES := 1080

PRODUCT_GMS_CLIENTID_BASE := android-oppo

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi-user 15 AP3A.240617.008 1772180233946 release-keys" \
    BuildFingerprint=realme/RMX3301/RED8ACL1:15/AP3A.240617.008/S.22c0248-3e8d8-3e8da:user/release-keys \
    DeviceName=RED8ACL1 \
    DeviceProduct=RMX3301 \
    SystemDevice=RED8ACL1 \
    SystemName=RMX3301
