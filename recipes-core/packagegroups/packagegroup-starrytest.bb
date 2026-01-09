# packagegroup-starrytest.bb
# StarryOS 测试组件包组

SUMMARY = "StarryOS Test Package Group"
DESCRIPTION = "Modular package group for StarryOS test distribution, providing \
shell environment, Python runtime, and test harness."
LICENSE = "Apache-2.0"

inherit packagegroup

# ==================== 包划分 ====================
PACKAGES = "\
    ${PN} \
    ${PN}-core \
    ${PN}-shell \
    ${PN}-python \
    ${PN}-harness \
"

# ==================== 运行时依赖 ====================
# 主包：安装所有子包
RDEPENDS:${PN} = "\
    ${PN}-shell \
    ${PN}-python \
"

# 核心组件（保留用于将来扩展）
RDEPENDS:${PN}-core = ""

# Shell 环境和基础工具
RDEPENDS:${PN}-shell = "\
    bash \
    coreutils \
    util-linux \
    procps \
    psmisc \
    findutils \
    grep \
    sed \
"

# Python 运行环境
RDEPENDS:${PN}-python = "\
    python3 \
    python3-core \
    python3-io \
    python3-json \
"

# StarryOS 测试套件（暂未实现）
# RDEPENDS:${PN}-harness = "starry-test-harness"
