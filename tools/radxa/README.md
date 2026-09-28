> **烧卡风险：** 本轮未执行脚本或验证板卡兼容性。写卡可能清空目标存储，请先核对设备；示例账户密码公开，首次使用必须更改。

> **上游技术参考，不是本项目实测结论。** 来源：[fanhao375/microduck-replica](https://github.com/fanhao375/microduck-replica/blob/a23f4c18a4741a3cde5257e639960ea37bbadd8d/tools/radxa/README.md)。保留原作者及贡献者署名；正文中的“本项目”、实物、照片和测试记录属于上游。与我们的硬件不一致时，以[本项目说明](../../docs/hardware.md)为准。

# Radxa Zero 3W · 做一张能直接开机的 Armbian 卡

配合 [不打 HAT · 第 1 步](../../docs/不打HAT.md#第-1-步--主控点亮什么都别接) 用。
**V1.12 板（2024-11 以后买的，WiFi 是 AIC8800）用 Armbian 官方镜像直接烧是起不来的**：灯双闪、永远进不了系统。
原因是 Armbian 给这块板配的主线 U-Boot（内存初始化固件 2024-01 的 v1.21）带不起新板，换成瑞莎自家的引导程序就好。
这个目录把换引导、写 WiFi、开串口、开 USB 控制台全打进镜像里，烧完插上就能 ssh。

**不想自己做卡？** [release 里有做好的镜像](https://github.com/fanhao375/microduck-replica/releases)（不带 WiFi，插 USB 当串口进去连），
烧完就能开机，用法见[镜像使用说明](镜像使用说明.md)。板子不是这一批（比如 V1.12J、WiFi 换成移远 FSK960K）也在那篇里说了怎么办。

| 文件 | 干什么 |
|---|---|
| `card.conf` | 改 WiFi 名 / 密码，用户名密码默认 `duck` / `duck1234`；国内要装官方软件时填一个 HTTP 代理。**WiFi 两行留空 = 公开镜像模式**，不写任何网络配置 |
| `镜像使用说明.md` | 给 release 里那张镜像用的：烧卡、USB 串口登录、连 WiFi、换引导救别的批次的板子 |
| `1-做卡.ps1` | Windows 右键「使用 PowerShell 运行」，选下载的 `.img.xz`，出一个 `xxx-鸭子卡.img`，Rufus 烧它 |
| `build-armbian-card.sh` | 实际干活的脚本，Linux / WSL 里 `sudo bash build-armbian-card.sh xxx.img.xz card.conf` |

镜像用 **Armbian 26.2.1 trixie vendor 6.1.115 minimal**（Pollen 官方指定；国内镜像站只剩 26.8.1，
26.2.1 在 `https://fi.mirror.armbian.de/archive/radxa-zero3/archive/`）。瑞莎引导程序从
`radxa-repo.github.io` 的 `u-boot-rk2410` 包自动下载，脚本里锁了版本和 sha256。

脚本做的五件事：

1. 扇区 64 写 `idbloader.img`，扇区 16384 写 `u-boot.itb`（瑞莎 u-boot-rk2410 2017.09-64，DDR v1.25，BL31 v1.46）
2. `/boot/extlinux/extlinux.conf`：瑞莎 U-Boot 认 extlinux 不认 Armbian 的 boot.scr；挂 `uart2-m0`（舵机串口 `/dev/ttyS2`）和 `dwc3-peripheral`（OTG 口当 USB 串口）两个 overlay，内核控制台放 tty1
3. 首次开机预设 `/root/.not_logged_in_yet`（用户、密码、时区、locale）+ Armbian 标准写法的 `/etc/netplan/30-wifis-dhcp.yaml`，官方 `migrate-network.sh` 能接手
4. `g_serial` + `serial-getty@ttyGS0`：板子插电脑多出一个 COM 口，115200，root 能登
5. mask 掉 `serial-getty@ttyS2` / `ttyFIQ0`，登录控制台不占舵机串口

烧完开机 2～3 分钟，路由器里找 `radxa-zero3`，`ssh duck@IP`。之后按 Pollen 官方
[install-dev.md](https://github.com/pollen-robotics/microduck/blob/main/docs/robot/install-dev.md)
跑 `setup-board.sh` → `migrate-network.sh` → 重启 → 再各跑一次 → `install.sh`。
它们会改 `armbianEnv.txt`，在这张卡上不生效（extlinux 说了算），但脚本自己检查的项都能过。
