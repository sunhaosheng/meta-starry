# starry-targets.inc
# StarryOS 多目标构建配置
#
# 对应 StarryOS/Makefile 中的特殊目标:
#   - make rv      -> ARCH=riscv64
#   - make la      -> ARCH=loongarch64
#   - make vf2     -> ARCH=riscv64 APP_FEATURES=vf2 MYPLAT=axplat-riscv64-visionfive2 BUS=mmio
#   - make crosvm  -> ARCH=aarch64 APP_FEATURES=crosvm MYPLAT=axplat-aarch64-crosvm-virt BUS=pci
#   - make dice    -> ARCH=aarch64 APP_FEATURES=dice MYPLAT=axplat-aarch64-crosvm-virt BUS=pci
#
# 这些配置通过机器配置文件和此 include 文件的组合来实现

# ==================== 机器特定配置 ====================
# 使用匿名 Python 函数根据 MACHINE 设置特定参数

python () {
    machine = d.getVar('MACHINE')
    
    # ==================== VisionFive2 (make vf2) ====================
    if machine == 'riscv64-visionfive2':
        # 对应: make vf2
        # ARCH=riscv64 APP_FEATURES=vf2 MYPLAT=axplat-riscv64-visionfive2 BUS=mmio
        d.setVar('ARCEOS_APP_FEATURES', 'vf2')
        d.setVar('ARCEOS_PLAT_PACKAGE', 'axplat-riscv64-visionfive2')
        d.setVar('ARCEOS_BUS', 'mmio')
        bb.note("StarryOS target: VisionFive2 (vf2)")
        
    # ==================== Crosvm (make crosvm) ====================
    elif machine == 'aarch64-crosvm':
        # 对应: make crosvm
        # ARCH=aarch64 APP_FEATURES=crosvm MYPLAT=axplat-aarch64-crosvm-virt BUS=pci
        d.setVar('ARCEOS_APP_FEATURES', 'crosvm')
        d.setVar('ARCEOS_PLAT_PACKAGE', 'axplat-aarch64-crosvm-virt')
        d.setVar('ARCEOS_BUS', 'pci')
        bb.note("StarryOS target: Crosvm (crosvm)")
        
    # ==================== Dice (make dice) ====================
    elif machine == 'aarch64-dice':
        # 对应: make dice
        # ARCH=aarch64 APP_FEATURES=dice MYPLAT=axplat-aarch64-crosvm-virt BUS=pci
        d.setVar('ARCEOS_APP_FEATURES', 'dice')
        d.setVar('ARCEOS_PLAT_PACKAGE', 'axplat-aarch64-crosvm-virt')
        d.setVar('ARCEOS_BUS', 'pci')
        bb.note("StarryOS target: Dice (dice)")
        
    # ==================== 标准 QEMU 目标 ====================
    elif machine in ['aarch64-qemu-virt', 'riscv64-qemu-virt', 'loongarch64-qemu-virt', 'x86_64-qemu-q35']:
        # 对应: make (默认) 或 make rv / make la
        # 使用默认的 APP_FEATURES=qemu
        current_features = d.getVar('ARCEOS_APP_FEATURES') or ''
        if not current_features:
            d.setVar('ARCEOS_APP_FEATURES', 'qemu')
        bb.note(f"StarryOS target: QEMU ({machine})")
        
    else:
        bb.warn(f"Unknown machine for StarryOS: {machine}, using defaults")
}

# ==================== Makefile 目标对照表 ====================
#
# | Makefile 目标 | MACHINE 配置              | 关键变量差异                    |
# |--------------|---------------------------|--------------------------------|
# | make         | aarch64-qemu-virt         | APP_FEATURES=qemu              |
# | make rv      | riscv64-qemu-virt         | APP_FEATURES=qemu              |
# | make la      | loongarch64-qemu-virt     | APP_FEATURES=qemu              |
# | make vf2     | riscv64-visionfive2       | APP_FEATURES=vf2, BUS=mmio     |
# | make crosvm  | aarch64-crosvm            | APP_FEATURES=crosvm            |
# | make dice    | aarch64-dice              | APP_FEATURES=dice              |

