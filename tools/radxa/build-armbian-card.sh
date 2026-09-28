#!/bin/bash
# 给 Radxa Zero 3W（V1.12，AIC8800 WiFi）做一张能直接开机、自动连 WiFi、ssh 能进的 Armbian 卡。
#   sudo bash build-armbian-card.sh <Armbian_26.2.1_Radxa-zero3_trixie_vendor_6.1.115_minimal.img.xz> [card.conf]
# 做的事（每一条都是踩过坑的）：
#   1. 换引导程序：Armbian 自带的主线 U-Boot 在 V1.12 板上内核起不来（灯双闪、永远进不了系统），
#      换成瑞莎 u-boot-rk2410 包里的 idbloader.img + u-boot.itb（扇区 64 / 16384）
#   2. 瑞莎 U-Boot 走 extlinux：写 /boot/extlinux/extlinux.conf，挂 uart2-m0（舵机串口 /dev/ttyS2）
#      和 dwc3-peripheral（OTG 口插电脑就是串口）两个 overlay，内核控制台放 tty1，不占舵机串口
#   3. 首次开机预设：用户名密码、locale、时区；WiFi 用 Armbian 标准 netplan 写法，
#      官方 migrate-network.sh 能接手
#   4. USB 串口控制台：g_serial + serial-getty@ttyGS0，板子插电脑多出一个 COM 口，救命用
#   5. 把登录控制台从舵机串口上拿掉：mask serial-getty@ttyS2 / ttyFIQ0
set -euo pipefail
export LC_ALL=C.UTF-8
XZ="${1:?用法: sudo bash $0 <Armbian_xxx.img.xz> [card.conf]}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="${2:-$HERE/card.conf}"
[ "$(id -u)" = 0 ] || { echo "要 root：sudo bash $0 ..."; exit 1; }
[ -f "$XZ" ] || { echo "找不到 $XZ"; exit 1; }
[ -f "$CONF" ] || { echo "找不到 $CONF"; exit 1; }
# shellcheck disable=SC1090
. <(tr -d '\r' < "$CONF")
# WIFI_SSID 留空 = 公开镜像模式：不写任何网络配置，开机后插 USB 当串口进去自己连
PUBLIC=0
if [ -z "${WIFI_SSID:-}" ]; then
  PUBLIC=1
  echo "公开镜像模式：不写 WiFi，开机后用 USB 串口（COM 口）进去连网"
elif [ "${WIFI_SSID}" = "改成你的WiFi名" ]; then
  echo "先把 card.conf 里的 WiFi 名和密码改掉，或者整行留空做公开镜像"; exit 1
fi

UBOOT_DEB_URL=https://radxa-repo.github.io/bookworm/pool/main/u/u-boot-rk2410/u-boot-rk2410_2017.09-64-39cd993_arm64.deb
UBOOT_DEB_SHA=fb319203ab7d568aac77505504c05698385aea8a0e8f895c226c6bc557a1bce7
OUT="${XZ%.img.xz}-鸭子卡.img"
WORK=$(mktemp -d /root/mkcard.XXXX); trap 'umount -q "$WORK/m" 2>/dev/null; rm -rf "$WORK"' EXIT

echo "[1/6] 瑞莎引导程序"
DEB="$HERE/$(basename "$UBOOT_DEB_URL")"
[ -f "$DEB" ] || curl -fL --retry 3 -o "$DEB" "$UBOOT_DEB_URL"
echo "$UBOOT_DEB_SHA  $DEB" | sha256sum -c - >/dev/null || { echo "u-boot 包校验失败"; exit 1; }
mkdir -p "$WORK/deb"; dpkg-deb -x "$DEB" "$WORK/deb"
UB="$WORK/deb/usr/lib/u-boot/radxa-zero3"; ls "$UB/idbloader.img" "$UB/u-boot.itb" >/dev/null

echo "[2/6] 解压 Armbian（放本地盘，/mnt 下 loop 挂不了）"
xz -dkc "$XZ" > "$WORK/card.img"

echo "[3/6] 写入引导程序（idbloader @64，u-boot.itb @16384）"
dd if="$UB/idbloader.img" of="$WORK/card.img" bs=512 seek=64 conv=notrunc status=none
dd if="$UB/u-boot.itb"   of="$WORK/card.img" bs=512 seek=16384 conv=notrunc status=none

START=$(python3 - "$WORK/card.img" <<'PY'
import struct,sys
f=open(sys.argv[1],'rb'); f.seek(512); h=f.read(512)
elba=struct.unpack('<Q',h[72:80])[0]; esz=struct.unpack('<I',h[84:88])[0]
f.seek(elba*512); e=f.read(esz); print(struct.unpack('<Q',e[32:40])[0])
PY
)
UUID=$(python3 - "$WORK/card.img" "$START" <<'PY'
import sys,uuid
f=open(sys.argv[1],'rb'); f.seek(int(sys.argv[2])*512+1024); sb=f.read(1024); print(uuid.UUID(bytes=sb[104:120]))
PY
)
echo "      根分区起始扇区 $START，UUID $UUID"
mkdir -p "$WORK/m"; mount -o loop,offset=$((START*512)) "$WORK/card.img" "$WORK/m"; R="$WORK/m"
KVER=$(ls "$R/lib/modules" | head -1)

echo "[4/6] extlinux（瑞莎 U-Boot 认这个，不认 boot.scr）"
mkdir -p "$R/boot/extlinux"
cat > "$R/boot/extlinux/extlinux.conf" <<CONF
default armbian
timeout 3
menu title Armbian (Radxa U-Boot)

label armbian
  linux /boot/vmlinuz-$KVER
  initrd /boot/initrd.img-$KVER
  fdt /boot/dtb/rockchip/rk3566-radxa-zero3.dtb
  fdtoverlays /boot/dtb/rockchip/overlay/rk3568-uart2-m0.dtbo /boot/dtb/rockchip/overlay/rk3568-dwc3-peripheral.dtbo
  append root=UUID=$UUID rootwait rw console=tty1 consoleblank=0 cma=256M
CONF
# armbianEnv 也同步改一下，官方 setup-board.sh 看它；实际生效的是上面 extlinux
sed -i 's/^overlay_prefix=.*/overlay_prefix=rk3568/; s/^console=.*/console=display/' "$R/boot/armbianEnv.txt"
grep -q '^overlays=' "$R/boot/armbianEnv.txt" && sed -i 's/^overlays=.*/overlays=uart2-m0 dwc3-peripheral/' "$R/boot/armbianEnv.txt" || echo 'overlays=uart2-m0 dwc3-peripheral' >> "$R/boot/armbianEnv.txt"

echo "[5/6] 首次开机预设 + WiFi"
cat > "$R/root/.not_logged_in_yet" <<PRESET
PRESET_NET_CHANGE_DEFAULTS=0
PRESET_CONNECT_WIRELESS=n
PRESET_ROOT_PASSWORD='${ROOT_PASSWORD:-duck1234}'
PRESET_USER_NAME='${USER_NAME:-duck}'
PRESET_USER_PASSWORD='${USER_PASSWORD:-duck1234}'
PRESET_DEFAULT_REALNAME='Duck'
PRESET_LOCALE='en_US.UTF-8'
PRESET_TIMEZONE='Asia/Shanghai'
PRESET
chmod 600 "$R/root/.not_logged_in_yet"
if [ "$PUBLIC" = 1 ]; then
cat > "$R/root/先连WiFi.txt" <<'NOTE'
这张卡没写 WiFi（公开镜像）。板子没有网口，登录后自己配，两种办法：

A) 命令行配（下面这套是在 V1.12 + AIC8800 上实测能连的写法）：

   sudo tee /etc/wpa_supplicant/wpa_supplicant-wlan0.conf >/dev/null <<'CONF'
   ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
   update_config=1
   country=CN

   network={
       ssid="你的WiFi名"
       psk="你的WiFi密码"
       key_mgmt=WPA-PSK
       pairwise=CCMP
       ieee80211w=0
       scan_ssid=1
       priority=10
   }
   CONF
   sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
   sudo systemctl enable --now wpa_supplicant@wlan0
   ip a show wlan0          # 看有没有拿到 IP（DHCP 由系统自带的 netplan 做）

   pairwise=CCMP 和 ieee80211w=0 这两行别删：AIC8800 不支持 GCMP-256，
   路由器开 WPA2/WPA3 混合模式时，不写这两行握手会失败。

B) 图形界面：sudo nmtui，选 Activate a connection 挑 WiFi。
   （连不上就用 A，多半还是上面那个 WPA3 的问题）

烧卡前就想把 WiFi 写进去：用仓库里的 tools/radxa/build-armbian-card.sh，
card.conf 填上 WiFi 名和密码，自己生成一张带网的卡。
NOTE
chmod 644 "$R/root/先连WiFi.txt"
else
# WiFi 用 wpa_supplicant（V1.12 + AIC8800 实测能连的那套；netplan 的写法没在这块板上验证过）。
# pairwise=CCMP + ieee80211w=0 是绕开 AIC8800 不支持 GCMP-256 的关键，路由器开 WPA2/WPA3 混合时缺了就握不上手。
# DHCP 交给 Armbian 自带的 /etc/netplan/10-dhcp-all-interfaces.yaml。
mkdir -p "$R/etc/wpa_supplicant"
cat > "$R/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" <<CONF
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
update_config=1
country=CN

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    key_mgmt=WPA-PSK
    pairwise=CCMP
    ieee80211w=0
    scan_ssid=1
    priority=10
}
CONF
chmod 600 "$R/etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
ln -sf /lib/systemd/system/wpa_supplicant@.service "$R/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service"
fi
if [ -n "${HTTP_PROXY:-}" ]; then
  printf 'http_proxy=%s\nhttps_proxy=%s\nHTTP_PROXY=%s\nHTTPS_PROXY=%s\nno_proxy=localhost,127.0.0.1,192.168.0.0/16\nNO_PROXY=localhost,127.0.0.1,192.168.0.0/16\n' "$HTTP_PROXY" "$HTTP_PROXY" "$HTTP_PROXY" "$HTTP_PROXY" >> "$R/etc/environment"
fi

echo "[6/6] USB 串口控制台开、舵机串口上的登录控制台关"
echo g_serial > "$R/etc/modules-load.d/duck-usb-serial.conf"
ln -sf /lib/systemd/system/serial-getty@.service "$R/etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service"
ln -sf /dev/null "$R/etc/systemd/system/serial-getty@ttyS2.service"
ln -sf /dev/null "$R/etc/systemd/system/serial-getty@ttyFIQ0.service"
rm -f "$R/etc/systemd/system/getty.target.wants/serial-getty@ttyFIQ0.service"
sync; umount "$R"
cp "$WORK/card.img" "$OUT"
echo; echo "好了，用 Rufus / Armbian Imager 烧这个： $OUT"
if [ "$PUBLIC" = 1 ]; then
  echo "公开镜像：没写 WiFi。插电脑的 USB 线就是串口（COM 口，115200），登录 ${USER_NAME:-duck}/${USER_PASSWORD:-duck1234} 后按 /root/先连WiFi.txt 连网，第一件事改密码。"
else
  echo "开机 2~3 分钟后路由器里找 radxa-zero3，ssh ${USER_NAME:-duck}@IP，密码 ${USER_PASSWORD:-duck1234}；插电脑的那根 USB 线同时是串口（COM 口）。"
fi
