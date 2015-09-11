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

if [ "x$CPUS" = "x" ]; then
    CPUS=30
fi

case "$BUILD_ARCH" in
    "mips")
#mips
export ICP_ENV_DIR=$PWD/crypto/ocf/ep80579
make -j $CPUS \
CC=mipsel-openwrt-linux-gcc \
LD=mipsel-openwrt-linux-ld \
AR=mipsel-openwrt-linux-ar \
NM=mipsel-openwrt-linux-nm \
STRIP=mipsel-openwrt-linux-strip \
ARCH=mips BOARD=brcm47xx $*
    ;;
    "wndr3700"|"wndr4300")
#wndr
make -j $CPUS \
CC=mips-openwrt-linux-gcc \
LD=mips-openwrt-linux-ld \
AR=mips-openwrt-linux-ar \
NM=mips-openwrt-linux-nm \
STRIP=mips-openwrt-linux-strip \
ARCH=mips BOARD=ath79 $*
    ;;
    "x86")
#x86
export ICP_ENV_DIR=$PWD/crypto/ocf/ep80579
make -j $CPUS \
CC=i486-openwrt-linux-gcc \
LD=i486-openwrt-linux-ld \
AR=i486-openwrt-linux-ar \
NM=i486-openwrt-linux-nm \
STRIP=i486-openwrt-linux-strip \
ARCH=i386 $*
    ;;

esac

