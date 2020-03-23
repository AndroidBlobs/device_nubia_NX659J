#!/vendor/bin/sh

if [ -c /dev/sec-nfc ]; then
    setprop ro.boot.product.hardware.sku nfc
else
    setprop ro.boot.product.hardware.sku nfc_empty
fi

