# arceos-machine-common.inc
# ArceOS/StarryOS 机器通用配置
#
# 所有 ArceOS 目标机器应该 require 此文件
# 提供裸机内核构建所需的通用配置

# ==================== 内核配置 ====================
# StarryOS 是裸机内核，不使用标准 Linux 内核
PREFERRED_PROVIDER_virtual/kernel = ""

# 内核镜像类型为二进制
KERNEL_IMAGETYPE = "bin"

# ==================== QEMU 通用配置 ====================
# 无图形界面
QB_OPT_APPEND = "-nographic"

# ==================== 必须由具体机器设置的变量 ====================
# 以下变量必须在具体的 machine.conf 中设置:
#
# ARCEOS_ARCH         - 架构 (aarch64/riscv64/loongarch64/x86_64)
# ARCEOS_PLATFORM     - 平台名称 (如 aarch64-qemu-virt)
# ARCEOS_PLAT_PACKAGE - 平台包名 (如 axplat-aarch64-qemu-virt)
# RUST_TARGET         - Rust 目标三元组

# ==================== Rust 目标映射参考 ====================
# ARCEOS_ARCH=aarch64     -> RUST_TARGET=aarch64-unknown-none-softfloat
# ARCEOS_ARCH=riscv64     -> RUST_TARGET=riscv64gc-unknown-none-elf
# ARCEOS_ARCH=loongarch64 -> RUST_TARGET=loongarch64-unknown-none-softfloat
# ARCEOS_ARCH=x86_64      -> RUST_TARGET=x86_64-unknown-none

