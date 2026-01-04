SUMMARY = "Cargo binutils - LLVM tools wrappers"
DESCRIPTION = "Provides rust-objcopy, rust-objdump, etc. via rustc's llvm-tools"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

S = "${WORKDIR}"

INHIBIT_DEFAULT_DEPS = "1"
DEPENDS:class-native = "rust-prebuilt-native"

do_install() {
    install -d ${D}${bindir}
    
    
    
    bbnote "cargo-binutils is no longer needed with rust-prebuilt-native"
    bbnote "rust-prebuilt-native provides all required tools"
    
    # rust-prebuilt-native 已在 ${RUST_TOOLCHAIN}/lib/rustlib/${HOST_TRIPLE}/bin/ 
    # 提供以下工具：
    # - rust-objcopy
    # - rust-objdump  
    # - rust-nm
    # - rust-strip
    # - rust-lld
    #
    # 这些工具已经在 sysroot 中，无需额外安装
}

BBCLASSEXTEND = "native nativesdk"
