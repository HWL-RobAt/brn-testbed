#!/bin/sh


PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-x86/staging_dir/toolchain-i386_gcc-4.1.2_uClibc-0.9.30.1/usr/bin
PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-mips/staging_dir/toolchain-mipsel_gcc-4.1.2_uClibc-0.9.30.1/usr/bin
PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-wndr3700/staging_dir/toolchain-mips_r2_gcc-4.1.2_uClibc-0.9.30.1/usr/bin/

dir=$(dirname "$0")
pwd=$(pwd)

SIGN=`echo $dir | cut -b 1`

case "$SIGN" in
 "/")
   DIR=$dir
   ABS=`echo $0 | cut -b 1`
   if [ "$ABS" = "/" ]; then
     FULLNAME=$0
   else
     FULLNAME=$DIR/$0
   fi
   ;;
 ".")
   DIR=$pwd/$dir
   FULLNAME=$pwd/$0
   ;;
   *)
   echo "Error while getting directory"
   exit -1
   ;;
esac

if [ "x$CLICKPATH" = "x" ]; then
  echo "Set CLICKPATH"
  exit 1
fi

if [ "x$BRN_TOOLS_PATH/helper" = "x" ]; then
  echo "Set BRN_TOOLS_PATH or helper is missing"
  exit 1
fi

if [ "x$1" = "xstatus" ]; then
  echo "brn-testbed"
  git status
  exit 0
fi

(cd $DIR; sh ./brn-testbed-click.sh)
(cd $DIR; sh ./brn-testbed-driver.sh)
