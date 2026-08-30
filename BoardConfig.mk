#
# Copyright (C) 2021-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Include the common OEM chipset BoardConfig.
include device/oneplus/sm8450-common/BoardConfigCommon.mk

DEVICE_PATH := device/realme/ferrari

# Optional KSU-Next + SuSFS boot pipeline (./build_ksu_boot.sh).
# Command-line TARGET_KERNEL_SOURCE overrides are ignored by kati once
# BoardConfig has assigned the path, so this flag must be set at parse time.
ifeq ($(BUILD_KSU_BOOT),true)
TARGET_KERNEL_SOURCE := out/ksu-ferrari/kernel
TARGET_KERNEL_CONFIG_EXT += $(DEVICE_PATH)/ksu/ksu.config
endif

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery
TARGET_RECOVERY_DENSITY := xxhdpi
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 126

# Include the proprietary files BoardConfig.
include vendor/realme/ferrari/BoardConfigVendor.mk

# SEPolicy
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/vendor

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/private

SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy/public

# VoltageOS Flags
TARGET_BOOT_ANIMATION_RES := 1440
TARGET_USES_OPLUS_TOUCH := true
TARGET_CAMERA_NEEDS_CLIENT_INFO_LIB_OPLUS := true

BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE := true
BUILD_BROKEN_TREBLE_SYSPROP_NEVERALLOW := true
