# meta-starry 接口说明

本文档详细说明 meta-starry 提供的 BitBake Classes、变量和配置文件接口。

---

## 核心 Classes（构建类）

### 1. `rust-kernel.bbclass`

**用途**：Rust 内核通用构建逻辑

**继承方式**：
```python
inherit rust-kernel
```

**提供的功能**：
- 配置 Rust 工具链路径
- 设置 `RUSTC_BOOTSTRAP=1`
- 生成 `.cargo/config.toml`
- 默认的 `do_configure`、`do_compile`、`do_install` 实现

**关键变量**：

| 变量 | 类型 | 说明 | 示例 |
|:-----|:-----|:-----|:-----|
| `RUST_TARGET` | 必需 | Rust 目标三元组 | `aarch64-unknown-none-softfloat` |
| `KERNEL_ARCH` | 必需 | 内核架构 | `aarch64` |
| `CARGO_FEATURES` | 可选 | Cargo features | `defplat dwarf smp` |

**使用示例**：
```python
inherit rust-kernel

RUST_TARGET = "aarch64-unknown-none-softfloat"
KERNEL_ARCH = "aarch64"
CARGO_FEATURES = "defplat dwarf smp qemu"
```

---

### 2. `arceos.bbclass`

**用途**：ArceOS 特定构建逻辑

**继承方式**：
```python
inherit arceos
```

**提供的功能**：
- 生成 `.axconfig.toml` 平台配置文件
- 导出 ArceOS 环境变量
- 配置 musl 工具链
- 设置 RUSTFLAGS

**关键变量**：

| 变量 | 类型 | 说明 | 默认值 |
|:-----|:-----|:-----|:-------|
| `ARCEOS_ARCH` | 必需 | 架构名称 | 由 MACHINE 推导 |
| `ARCEOS_PLATFORM` | 必需 | 平台名称 | 由 MACHINE 推导 |
| `ARCEOS_PLAT_PACKAGE` | 必需 | 平台包名 | 由 MACHINE 推导 |
| `ARCEOS_SMP` | 可选 | CPU 核心数 | `4` |
| `ARCEOS_LOG` | 可选 | 日志级别 | `warn` |
| `ARCEOS_DWARF` | 可选 | 调试符号 | `y` |
| `ARCEOS_MEM` | 可选 | 内存大小 | 由平台决定 |
| `ARCEOS_BUS` | 可选 | 总线类型 | `pci` |

**核心函数**：

#### `arceos_generate_config()`

生成 `.axconfig.toml` 平台配置文件。

**调用时机**：`do_configure`

**生成的配置示例**：
```toml
[kernel]
name = "starry"
arch = "aarch64"
platform = "aarch64-qemu-virt"
smp = 4
log_level = "warn"

[build]
profile = "release"
```

#### `arceos_setup_musl_wrapper()`

设置 musl 工具链 wrapper（用于 lwext4_rust 等依赖 C 编译器的 crate）。

**使用示例**：
```python
inherit arceos

ARCEOS_ARCH = "aarch64"
ARCEOS_PLATFORM = "aarch64-qemu-virt"
ARCEOS_SMP = "8"
ARCEOS_LOG = "debug"
```

---

### 3. `arceos-features.bbclass`

**用途**：自动生成 Cargo features（复刻 Makefile 的 `features.mk` 逻辑）

**继承方式**：
```python
inherit arceos-features
```

**提供的功能**：
- 自动推导 `CARGO_FEATURES` 变量
- 支持 `defplat`/`myplat`、`dwarf`、`smp` 等特性
- 复刻 Makefile 的特性解析逻辑

**输入变量**：

| 变量 | 说明 | 示例 |
|:-----|:-----|:-----|
| `ARCEOS_PLAT_PACKAGE` | 平台包名 | `axplat-aarch64-qemu-virt` |
| `ARCEOS_SMP` | CPU 核心数 | `4` |
| `ARCEOS_DWARF` | 是否启用 DWARF | `y` |
| `ARCEOS_FEATURES` | 额外的 features | `net fs` |
| `ARCEOS_APP_FEATURES` | 应用级 features | `qemu` |
| `ARCEOS_USE_MYPLAT` | 使用 myplat（默认 0） | `0` 或 `1` |

**输出变量**：
- `CARGO_FEATURES` - 完整的 Cargo features 字符串

**推导逻辑**：

```python
# 平台特性
if ARCEOS_USE_MYPLAT == "1":
    ax_feat = ["myplat"]
else:
    ax_feat = ["defplat"]

# 调试特性
if ARCEOS_DWARF == "y":
    ax_feat.append("dwarf")

# SMP 特性
if ARCEOS_SMP > 1:
    lib_feat.append("smp")

# 组合成最终的 CARGO_FEATURES
CARGO_FEATURES = "axfeat/" + " axfeat/".join(ax_feat) + " " + " ".join(lib_feat) + " " + ARCEOS_APP_FEATURES
```

**使用示例**：
```python
inherit arceos-features

# 输入
ARCEOS_PLAT_PACKAGE = "axplat-aarch64-qemu-virt"
ARCEOS_SMP = "4"
ARCEOS_DWARF = "y"
ARCEOS_APP_FEATURES = "qemu"

# 自动生成
# CARGO_FEATURES = "axfeat/defplat axfeat/dwarf axfeat/smp qemu"
```

---

## 配置文件接口

### Machine 配置（`conf/machine/*.conf`）

定义目标硬件平台的配置。

#### 必需变量

```python
# 架构和平台
ARCEOS_ARCH = "aarch64"
ARCEOS_PLATFORM = "aarch64-qemu-virt"
ARCEOS_PLAT_PACKAGE = "axplat-aarch64-qemu-virt"
RUST_TARGET = "aarch64-unknown-none-softfloat"

# QEMU 配置（用于 runqemu）
QB_SYSTEM_NAME = "qemu-system-aarch64"
QB_MACHINE = "-machine virt"
QB_CPU = "-cpu cortex-a72"
QB_MEM = "-m 1G"
QB_SMP = "-smp 4"
QB_DEFAULT_KERNEL = "starry.bin"
QB_KERNEL_ROOT = " "
QB_SERIAL_OPT = "-nographic"
QB_OPT_APPEND = ""
```

#### 可选变量

```python
# 覆盖默认值
ARCEOS_SMP ?= "8"
ARCEOS_LOG ?= "debug"
ARCEOS_MEM ?= "2G"
ARCEOS_BUS ?= "mmio"
```

#### 示例配置

**aarch64-qemu-virt.conf**：
```python
require conf/machine/include/arceos-machine-common.inc
require conf/machine/include/arm/arch-armv8a.inc

ARCEOS_ARCH = "aarch64"
ARCEOS_PLATFORM = "aarch64-qemu-virt"
ARCEOS_PLAT_PACKAGE = "axplat-aarch64-qemu-virt"
RUST_TARGET = "aarch64-unknown-none-softfloat"

QB_SYSTEM_NAME = "qemu-system-aarch64"
QB_MACHINE = "-machine virt"
QB_CPU = "-cpu cortex-a72"
QB_MEM = "-m 1G"
QB_SMP = "-smp 4"
QB_DEFAULT_KERNEL = "starry.bin"
QB_KERNEL_ROOT = " "
QB_SERIAL_OPT = "-nographic"
```

---

### 发行版配置（`conf/distro/starryos.conf`）

定义发行版级别的全局配置。

#### 关键设置

```python
DISTRO_NAME = "starryos"
DISTRO_VERSION = "2.0"

# 工具链选择
PREFERRED_PROVIDER_rust-native = "rust-prebuilt-native"
PREFERRED_PROVIDER_cargo-native = "rust-prebuilt-native"

# 镜像主机名
hostname:pn-base-files ?= "starryos"

# Bare-metal 优化
ASSUME_PROVIDED += "libgcc-dev virtual/${TARGET_PREFIX}compilerlibs"
PACKAGE_CLASSES = "package_ipk"
```

#### 自定义发行版配置

在 `build/conf/local.conf` 中覆盖：

```python
# 修改发行版名称
DISTRO_NAME = "myos"
DISTRO_VERSION = "1.0"

# 修改主机名
hostname:pn-base-files = "myos-${MACHINE}"
```

---

## Image 配方接口

### `starry-minimal-image.bb`

**用途**：最小测试镜像

**继承**：`core-image`

**安装的包**：
```python
IMAGE_INSTALL = "\
    packagegroup-core-boot \
    bash \
"
```

**IMAGE_FEATURES**：
```python
IMAGE_FEATURES += "debug-tweaks"
```

**自定义方法**：

创建 `.bbappend` 文件：
```bash
# 创建 bbappend
cat > my-layer/recipes-core/images/starry-minimal-image.bbappend << 'EOF'
IMAGE_INSTALL:append = " \
    vim \
    htop \
"
EOF
```

---

### `starry-test-image.bb`

**用途**：完整测试发行版

**继承**：`core-image`

**安装的包**：
```python
IMAGE_INSTALL:append = " packagegroup-starrytest "
```

**IMAGE_FEATURES**：
```python
IMAGE_FEATURES += "\
    debug-tweaks \
    ssh-server-dropbear \
    tools-debug \
    tools-profile \
    tools-testapps \
    package-management \
    bash-completion-pkgs \
"
```

**自定义方法**：

在 `build/conf/local.conf` 中：
```python
# 添加额外的包
IMAGE_INSTALL:append:pn-starry-test-image = " \
    vim \
    git \
    python3-pip \
"

# 添加额外的特性
IMAGE_FEATURES:append:pn-starry-test-image = " \
    read-only-rootfs \
"
```

---

## PackageGroup 接口

### `packagegroup-starrytest`

**用途**：StarryOS 测试组件集合

**子包**：

| 子包 | 内容 | 用途 |
|:-----|:-----|:-----|
| `packagegroup-starrytest` | 所有子包 | 完整测试环境 |
| `packagegroup-starrytest-core` | 保留（将来扩展） | 核心组件 |
| `packagegroup-starrytest-shell` | bash, coreutils, util-linux 等 | Shell 环境 |
| `packagegroup-starrytest-python` | python3 及模块 | 测试脚本运行环境 |
| `packagegroup-starrytest-harness` | starry-test-harness | StarryOS 测试套件 |

**使用方式**：

```python
# 在自定义镜像中安装所有组件
IMAGE_INSTALL:append = " packagegroup-starrytest "

# 或只安装 Shell 环境
IMAGE_INSTALL:append = " packagegroup-starrytest-shell "

# 或只安装 Python 环境
IMAGE_INSTALL:append = " packagegroup-starrytest-python "

# 或组合使用
IMAGE_INSTALL:append = " \
    packagegroup-starrytest-shell \
    packagegroup-starrytest-python \
"
```

**自定义 PackageGroup**：

创建新的 packagegroup：
```python
# my-layer/recipes-core/packagegroups/packagegroup-mytools.bb
SUMMARY = "My custom tools"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = "\
    vim \
    git \
    htop \
"
```

在镜像中使用：
```python
IMAGE_INSTALL:append = " packagegroup-mytools "
```

---

## 变量索引

### ArceOS 变量

| 变量 | 类型 | 默认值 | 说明 |
|:-----|:-----|:-------|:-----|
| `ARCEOS_ARCH` | string | 由 MACHINE 推导 | 架构名称（aarch64/riscv64/loongarch64/x86_64） |
| `ARCEOS_PLATFORM` | string | 由 MACHINE 推导 | 平台名称 |
| `ARCEOS_PLAT_PACKAGE` | string | 由 MACHINE 推导 | 平台包名 |
| `ARCEOS_SMP` | int | 4 | CPU 核心数 |
| `ARCEOS_LOG` | string | warn | 日志级别 |
| `ARCEOS_DWARF` | y/n | y | 是否启用 DWARF 调试符号 |
| `ARCEOS_MEM` | string | 由平台决定 | 内存大小（如 "1G"） |
| `ARCEOS_BUS` | string | pci | 总线类型 |
| `ARCEOS_FEATURES` | string | "" | 额外的 Cargo features |
| `ARCEOS_APP_FEATURES` | string | qemu | 应用级 Cargo features |
| `ARCEOS_NO_AXSTD` | y/n | y | 是否禁用 axstd |
| `ARCEOS_AX_LIB` | string | axfeat | 使用的 ArceOS 库 |

### Rust 变量

| 变量 | 类型 | 说明 |
|:-----|:-----|:-----|
| `RUST_TARGET` | string | Rust 目标三元组 |
| `CARGO_FEATURES` | string | Cargo features（自动生成） |
| `RUSTFLAGS` | string | Rust 编译器标志（自动生成） |

### 镜像变量

| 变量 | 类型 | 默认值 | 说明 |
|:-----|:-----|:-------|:-----|
| `IMAGE_FSTYPES` | string | ext4 | 镜像格式 |
| `IMAGE_ROOTFS_SIZE` | int | 8192000 | Rootfs 大小（KB） |
| `IMAGE_FEATURES` | string | - | 镜像特性列表 |
| `IMAGE_INSTALL` | string | - | 安装的包列表 |

---

## 扩展开发

### 添加新平台

1. 创建 machine 配置文件：

```bash
cat > meta-starry/conf/machine/my-platform.conf << 'EOF'
require conf/machine/include/arceos-machine-common.inc

ARCEOS_ARCH = "aarch64"
ARCEOS_PLATFORM = "my-platform"
ARCEOS_PLAT_PACKAGE = "axplat-my-platform"
RUST_TARGET = "aarch64-unknown-none-softfloat"

QB_SYSTEM_NAME = "qemu-system-aarch64"
QB_MACHINE = "-machine my-board"
QB_CPU = "-cpu cortex-a72"
EOF
```

2. 构建：

```bash
MACHINE=my-platform bitbake starry
```

### 添加新的 Cargo Feature

在 `build/conf/local.conf` 中：

```python
ARCEOS_FEATURES:pn-starry = "myfeature"
```

或在配方中：

```python
ARCEOS_FEATURES:append = " myfeature"
```

### 创建自定义镜像

```bash
cat > my-layer/recipes-core/images/my-image.bb << 'EOF'
require recipes-core/images/starry-test-image.bb

SUMMARY = "My custom image"

IMAGE_INSTALL:append = " \
    vim \
    git \
    packagegroup-mytools \
"

IMAGE_FEATURES:append = " \
    read-only-rootfs \
"
EOF
```

---

## 参考资料

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [BitBake User Manual](https://docs.yoctoproject.org/bitbake/)
- [OpenEmbedded Layer Index](https://layers.openembedded.org/)
- [Rust Embedded Book](https://docs.rust-embedded.org/)

---

**最后更新**：2026-01-09

