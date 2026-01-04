# rust-kernel.bbclass
# Generic build class for bare-metal Rust kernels
#
# Design: High cohesion, low coupling
# - All Rust environment config at metadata level (not shell functions)
# - Shell functions only do verification and logging
# - No wrapper scripts - trust BitBake's environment export
#
# Provides:
#   - Rust toolchain setup (rust-native + rust-std-{arch}-none-native)
#   - Cargo environment configuration
#   - Common build/install tasks for bare-metal kernels
#
# Usage:
#   inherit rust-kernel
#
# Required variables:
#   RUST_TARGET - Target triple (e.g., aarch64-unknown-none-softfloat)
#   KERNEL_ARCH - Kernel architecture (e.g., aarch64, riscv64, loongarch64, x86_64)
#
# Optional variables:
#   CARGO_FEATURES - Cargo features to enable
#   EXTRA_CARGO_FLAGS - Additional cargo flags
# ==================== Dependencies ====================
DEPENDS:append = " rust-native"

CLEANBROKEN = "1"

# Dynamically add rust-std for target architecture
python __anonymous() {
    rust_provider = d.getVar('PREFERRED_PROVIDER_rust-native')
    
    if rust_provider == 'rust-prebuilt-native':
        bb.note("Using rust-prebuilt-native (includes all target std libs)")
        return
    
    arch = d.getVar('KERNEL_ARCH')
    if not arch:
        arch = d.getVar('TARGET_ARCH')
    
    if arch:
        arch_map = {
            'aarch64': 'rust-std-aarch64-none-native',
            'riscv64': 'rust-std-riscv64-none-native',
            'loongarch64': 'rust-std-loongarch64-none-native',
            'x86_64': 'rust-std-x86_64-none-native',
        }
        
        rust_std = arch_map.get(arch)
        if rust_std:
            d.appendVar('DEPENDS', f' {rust_std}')
        else:
            bb.warn(f"No rust-std package defined for architecture: {arch}")
}

# ==================== Packaging ====================
PACKAGES = ""
RDEPENDS:${PN} = ""
ALLOW_EMPTY:${PN} = "1"

deltask package
deltask package_write_rpm
deltask package_write_ipk
deltask package_write_deb
deltask packagedata
deltask package_qa

# ==================== Environment Configuration ====================
# All critical environment variables are set at METADATA level
# DO NOT override these in shell functions!

# Rust target for cargo
export CARGO_BUILD_TARGET = "${RUST_TARGET}"
export RUST_TARGET_TRIPLE = "${RUST_TARGET}"

# CRITICAL: Allow stable Rust to use unstable features
# This MUST be at metadata level for BitBake to properly export to child processes
export RUSTC_BOOTSTRAP = "1"

# Rust native toolchain paths
# 支持 rust-native (从源码构建) 和 rust-prebuilt-native (预编译)
# rust-prebuilt-native 优先
python () {
    components_dir = d.getVar('COMPONENTS_DIR')
    build_arch = d.getVar('BUILD_ARCH')
    
    # 优先使用 rust-prebuilt-native
    prebuilt_path = os.path.join(components_dir, build_arch, 'rust-prebuilt-native')
    source_path = os.path.join(components_dir, build_arch, 'rust-native')
    
    if os.path.exists(os.path.join(prebuilt_path, 'usr', 'bin', 'rustc')):
        d.setVar('RUST_NATIVE', prebuilt_path)
    else:
        d.setVar('RUST_NATIVE', source_path)
}
RUST_NATIVE ?= "${COMPONENTS_DIR}/${BUILD_ARCH}/rust-prebuilt-native"
export PATH:prepend = "${RUST_NATIVE}/usr/bin:"
export RUST_TARGET_PATH = "${RUST_NATIVE}/usr/lib/rustlib"

# ==================== Toolchain Setup ====================
# Minimal setup: only verify and link std library
# NO wrapper scripts, NO environment overrides
rust_kernel_setup_toolchain() {
    # 查找可用的 rust 工具链 (优先 rust-prebuilt-native)
    local rust_prebuilt="${COMPONENTS_DIR}/${BUILD_ARCH}/rust-prebuilt-native"
    local rust_source="${COMPONENTS_DIR}/${BUILD_ARCH}/rust-native"
    local rust_native=""
    
    if [ -x "${rust_prebuilt}/usr/bin/rustc" ]; then
        rust_native="${rust_prebuilt}"
        bbnote "Using rust-prebuilt-native"
    elif [ -x "${rust_source}/usr/bin/rustc" ]; then
        rust_native="${rust_source}"
        bbnote "Using rust-native (built from source)"
    else
        bbfatal "No Rust toolchain found. Checked:\n  ${rust_prebuilt}\n  ${rust_source}"
    fi
    
    # 导出工具链路径
    export PATH="${rust_native}/usr/bin:${PATH}"
    export RUST_TARGET_PATH="${rust_native}/usr/lib/rustlib"
    
    # Verify toolchain
    if [ ! -x "${rust_native}/usr/bin/cargo" ]; then
        bbfatal "cargo not found in rust-native at ${rust_native}/usr/bin/"
    fi
    if [ ! -x "${rust_native}/usr/bin/rustc" ]; then
        bbfatal "rustc not found in rust-native at ${rust_native}/usr/bin/"
    fi
    
    # 检查是否是 rust-prebuilt-native (所有目标库已包含)
    if [ "${rust_native}" = "${rust_prebuilt}" ]; then
        # rust-prebuilt-native: 所有 target 库已在正确位置
        bbnote "All target libraries included in prebuilt toolchain"
    else
        # 从源码编译的 rust-native: 需要链接 rust-std
        local target_rustlib="${rust_native}/usr/lib/rustlib/${RUST_TARGET}"
        local kernel_arch="${KERNEL_ARCH:-${TARGET_ARCH}}"
        local std_src="${COMPONENTS_DIR}/${BUILD_ARCH}/rust-std-${kernel_arch}-none-native/usr/lib/rustlib/${RUST_TARGET}"
        
        if [ ! -d "${target_rustlib}" ]; then
            if [ ! -d "${std_src}" ]; then
                bbfatal "Target ${RUST_TARGET} std library not found at ${std_src}"
            fi
            bbnote "Linking ${RUST_TARGET} std library into rust-native sysroot"
            ln -sf "${std_src}" "${target_rustlib}"
        fi
        
        bbnote "Using rust-native (built from source)"
    fi
    
    # Verify target std library
    local target_rustlib="${rust_native}/usr/lib/rustlib/${RUST_TARGET}"
    if [ ! -d "${target_rustlib}/lib" ]; then
        bbfatal "Target ${RUST_TARGET} library directory not found: ${target_rustlib}/lib"
    fi
    
    if [ ! -f "${target_rustlib}/lib/libcore.rlib" ] && ! ls "${target_rustlib}/lib/libcore-"*.rlib >/dev/null 2>&1; then
        bbfatal "libcore not found for target ${RUST_TARGET} in ${target_rustlib}/lib/"
    fi
    
    # Log configuration
    bbnote "Rust toolchain configured:"
    bbnote "  RUSTC_BOOTSTRAP=${RUSTC_BOOTSTRAP}"
    bbnote "  RUST_TARGET_PATH=${RUST_TARGET_PATH}"
    bbnote "  rustc: $(${rust_native}/usr/bin/rustc --version)"
    bbnote "  cargo: $(${rust_native}/usr/bin/cargo --version)"
    bbnote "  target: ${RUST_TARGET}"
    bbnote "  target libs: ${target_rustlib}/lib/"
}

# ==================== Cargo Configuration ====================
rust_kernel_setup_cargo() {
    mkdir -p "${S}/.cargo"
    
    # Minimal cargo config - no wrapper, no env overrides
    cat > "${S}/.cargo/config.toml" <<EOF
# Auto-generated by rust-kernel.bbclass

[target.x86_64-unknown-linux-gnu]
linker = "gcc"

[target.x86_64-linux]
linker = "gcc"

[target.${RUST_TARGET}]
rustflags = [
    "-C", "link-arg=-nostartfiles",
    "-C", "link-arg=-no-pie",
]

[build]
# Target is specified on command line, not here

[env]
# Enable unstable features on stable Rust (required for bare-metal kernels)
RUSTC_BOOTSTRAP = "1"

# Recipes can append additional config
EOF

    bbnote "Created .cargo/config.toml for ${RUST_TARGET}"
}

# ==================== Build Tasks ====================
do_configure:prepend() {
    rust_kernel_setup_toolchain
    rust_kernel_setup_cargo
}

do_compile() {
    rust_kernel_setup_toolchain
    
    export CARGO_BUILD_TARGET="${RUST_TARGET}"
    export RUST_BACKTRACE=1
    
    # Host tools for build scripts
    if [ -z "${BUILD_CC}" ]; then
        export CC="gcc"
        export CXX="g++"
        export AR="ar"
    else
        export CC="${BUILD_CC}"
        export CXX="${BUILD_CXX}"
        export AR="${BUILD_AR}"
    fi
    
    bbnote "Building Rust kernel for ${RUST_TARGET}"
    bbnote "Cargo manifest: ${S}/Cargo.toml"
    
    cargo build \
        --manifest-path "${S}/Cargo.toml" \
        --target "${RUST_TARGET}" \
        --release \
        ${CARGO_FEATURES:+--features "${CARGO_FEATURES}"} \
        ${EXTRA_CARGO_FLAGS}
    
    bbnote "Build completed successfully"
}

do_install() {
    bbwarn "rust-kernel.bbclass: No do_install defined, recipes should override this"
    
    install -d ${D}/boot
    
    local kernel_bin=""
    for name in ${PN} kernel main; do
        if [ -f "${B}/target/${RUST_TARGET}/release/${name}" ]; then
            kernel_bin="${B}/target/${RUST_TARGET}/release/${name}"
            break
        fi
    done
    
    if [ -n "${kernel_bin}" ]; then
        install -m 0755 "${kernel_bin}" "${D}/boot/${PN}.elf"
        bbnote "Installed kernel binary: ${D}/boot/${PN}.elf"
    else
        bbwarn "Kernel binary not found in ${B}/target/${RUST_TARGET}/release/"
    fi
}

# ==================== Network Access ====================
do_compile[network] = "1"
do_configure[network] = "1"
