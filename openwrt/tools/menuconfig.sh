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

case "$BUILD_ARCH" in
    "mips")
#mips
make ARCH=mips BOARD=brcm47xx menuconfig#mips
    ;;
    "wndr3700"|"wndr4300")
#wndr
make ARCH=mips BOARD=ath79 menuconfig
    ;;
        "x86")
#x86
make ARCH=i386 menuconfig
    ;;

esac
