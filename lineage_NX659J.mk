# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from NX659J device
$(call inherit-product, $(LOCAL_PATH)/device.mk)

PRODUCT_BRAND := nubia
PRODUCT_DEVICE := NX659J
PRODUCT_MANUFACTURER := nubia
PRODUCT_NAME := lineage_NX659J
PRODUCT_MODEL := NX659J

PRODUCT_GMS_CLIENTID_BASE := android-nubia
TARGET_VENDOR := nubia
TARGET_VENDOR_PRODUCT_NAME := NX659J
PRODUCT_BUILD_PROP_OVERRIDES += PRIVATE_BUILD_DESC="qssi_NX659J-user 10 QKQ1.200127.002 eng.nubia.20200221.061255 release-keys"

# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop
BUILD_FINGERPRINT := nubia/NX659J/NX659J:10/QKQ1.200127.002/eng.nubia.20200221.061255:user/release-keys
