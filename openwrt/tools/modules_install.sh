#!/bin/sh

dir=$(dirname "$0")
pwd=$(pwd)

SIGN=`echo $dir | cut -b 1`

case "$SIGN" in
  "/")
        DIR=$dir
        ;;
  ".")
        DIR=$pwd/$dir
        ;;
   *)
        echo "Error while getting directory"
        exit -1
        ;;
esac

CPUS=60

export ICP_ENV_DIR=$PWD/crypto/ocf/ep80579

case "$BUILD_ARCH" in
    "mips")
#mips
make -j $CPUS \
CC=mipsel-openwrt-linux-gcc \
LD=mipsel-openwrt-linux-ld \
AR=mipsel-openwrt-linux-ar \
NM=mipsel-openwrt-linux-nm \
STRIP=mipsel-openwrt-linux-strip \
INSTALL_MOD_PATH=$INSTALL_MOD_PATH \
ARCH=mips BOARD=brcm47xx $*
    ;;
    "wndr3700")
#wndr
make -j $CPUS \
CC=mips-openwrt-linux-gcc \
LD=mips-openwrt-linux-ld \
AR=mips-openwrt-linux-ar \
NM=mips-openwrt-linux-nm \
STRIP=mips-openwrt-linux-strip \
INSTALL_MOD_PATH=$INSTALL_MOD_PATH \
ARCH=mips BOARD=ath79 $*
    ;;
    "x86")
#x86
make -j $CPUS \
CC=i486-openwrt-linux-gcc \
LD=i486-openwrt-linux-ld \
AR=i486-openwrt-linux-ar \
NM=i486-openwrt-linux-nm \
STRIP=i486-openwrt-linux-strip \
INSTALL_MOD_PATH=$INSTALL_MOD_PATH \
ARCH=i386 $*
    ;;

esac

