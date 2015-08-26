#!/bin/sh

OPENWRT_STAGING_DIR=$STAGING_DIR
OPENWRT_BUILD_DIR=OPENWRT_STAGING_DIR/../build_dir/

mips-openwrt-linux-uclibc-objcopy -O binary -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id -S vmlinux vmlinux-wndr3700v2

# $OPENWRT_STAGING_DIR/host/bin/patch-cmdline $OPENWRT_BUILD_DIR/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/tmp/vmlinux-wndr3700v2 "board=WNDR3700 console=ttyS0,115200 mtdparts=spi0.0:320k(u-boot)ro,128k(u-boot-env)ro,15872k(firmware),64k(art)ro"

$OPENWRT_STAGING_DIR/host/bin/lzma e ./vmlinux-wndr3700v2 -lc1 -lp2 -pb2 -d20 ./vmlinux-wndr3700v2.bin.lzma
mkimage -A mips -O linux -T kernel -a 0x80060000 -C lzma -M 0x33373031 -e 0x80060000 -n 'MIPS OpenWrt Linux-3.10.49' -d ./vmlinux-wndr3700v2.bin.lzma ./vmlinux-wndr3700v2.uImage
mkimage -A mips -O linux -T kernel -a 0x80060000 -C lzma -M 0x33373030 -e 0x80060000 -n 'MIPS OpenWrt Linux-3.10.49' -d ./vmlinux-wndr3700v2.bin.lzma ./vmlinux-wndr3700v1.uImage
