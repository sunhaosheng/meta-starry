SUMMARY = "ArceOS configuration generator"
DESCRIPTION = "Tool for generating ArceOS platform configurations from TOML files"
LICENSE = "MIT | Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
                    file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit cargo

# 对于 native 构建，不指定 --target，让 Rust 使用默认主机目标
CARGO_BUILD_FLAGS:class-native = "-v --release --manifest-path=${MANIFEST_PATH}"

# 从 GitHub 获取源码
SRC_URI = "git://github.com/arceos-org/axconfig_crates.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PV = "0.2.0+git${SRCPV}"

S = "${WORKDIR}/git/axconfig-gen"

# Need CA certificates for cargo to fetch from crates.io
DEPENDS += "ca-certificates-native"

# 配置 Cargo 使用 gcc 作为链接器
do_configure:append:class-native() {
    # 创建 cc 符号链接到 gcc
    if [ ! -e "${WORKDIR}/cc" ]; then
        ln -sf $(which gcc) ${WORKDIR}/cc
        export PATH="${WORKDIR}:$PATH"
    fi
    
    # 配置 cargo 使用 gcc 作为链接器
    mkdir -p ${CARGO_HOME}
    cat >> ${CARGO_HOME}/config.toml << 'EOF'
[target.x86_64-unknown-linux-gnu]
linker = "gcc"
EOF
}

# 确保 cc 在 PATH 中
do_compile:prepend:class-native() {
    ln -sf $(which gcc) ${WORKDIR}/cc || true
    export PATH="${WORKDIR}:$PATH"
}

# Disable bitbake's crates vendoring - allow cargo to fetch from crates.io
# This is needed because we don't provide pre-downloaded crates
CARGO_DISABLE_BITBAKE_VENDORING = "1"

# 允许 cargo 在编译时下载依赖（native 工具可以联网）
CARGO_BUILD_FLAGS += "--locked"
do_compile[network] = "1"

# 自定义安装（因为我们为 native 构建时没有指定 --target）
do_install:class-native() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/target/release/axconfig-gen ${D}${bindir}/
}

BBCLASSEXTEND = "native"
