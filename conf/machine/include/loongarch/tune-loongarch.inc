# LoongArch tuning (minimal)

DEFAULTTUNE ?= "loongarch64"

TUNEVALID[loongarch64] = "Enable 64-bit LoongArch optimizations"

AVAILTUNES += "loongarch64"

TUNE_FEATURES:tune-loongarch64 = "loongarch64"
BASE_LIB:tune-loongarch64 = "lib64"
TUNE_ARCH:tune-loongarch64 = "loongarch64"
TUNE_PKGARCH:tune-loongarch64 = "loongarch64"
PACKAGE_EXTRA_ARCHS:tune-loongarch64 = "loongarch64"

TUNE_ARCH = "${TUNE_ARCH:tune-${DEFAULTTUNE}}"
TUNE_PKGARCH = "${TUNE_PKGARCH:tune-${DEFAULTTUNE}}"
BASE_LIB = "${BASE_LIB:tune-${DEFAULTTUNE}}"

# Match StarryOS build flags for LoongArch soft-float.
TUNE_CCARGS .= " -msoft-float"
