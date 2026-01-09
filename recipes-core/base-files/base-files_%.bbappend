# base-files_%.bbappend
# StarryOS 基础文件定制

# ==================== Hostname 配置 ====================
# 方法 1：固定 hostname（用于测试环境）
# hostname = "starryos-dev"

# 方法 2：根据 MACHINE 动态设置
# hostname = "starryos-${MACHINE}"

# 方法 3：禁用默认 hostname（用于虚拟机/容器环境）
# hostname = ""

# 注意：
# - local.conf 或 distro.conf 中的设置会覆盖这里的值
# - 当前 meta-starry/conf/distro/starryos.conf 已设置默认值为 "starryos"
