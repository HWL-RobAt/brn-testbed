#!/bin/sh

PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-x86/staging_dir/toolchain-i386_gcc-4.1.2_uClibc-0.9.30.1/usr/bin
PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-mips/staging_dir/toolchain-mipsel_gcc-4.1.2_uClibc-0.9.30.1/usr/bin
PATH=$PATH:/testbedhome/testbed/software/openwrt/backfire-wndr3700/staging_dir/toolchain-mips_r2_gcc-4.1.2_uClibc-0.9.30.1/usr/bin/

if [ "x$CPUS" = "x" ]; then
  if [ -f /proc/cpuinfo ]; then
    CPUS=`grep -e "^processor" /proc/cpuinfo | wc -l`
  else
    CPUS=1
  fi
fi

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

KERNELBASE="/testbedhome/testbed/software/kernel-"

if [ "x$BRN_TOOLS_PATH/helper" = "x" ]; then
  echo "Set BRN_TOOLS_PATH or helper is missing"
  exit 1
fi

if [ "x$ARCHS" = "x" ]; then
  ARCHS="mips mipsel i386"
fi

if [ "x$KERNELDIRS" != "x" ]; then
  SETKERNELDIRS=1
else
  SETKERNELDIRS=0
fi

for i in $ARCHS; do
  which $i-linux-uclibc-gcc > /dev/null

  if [ $? -eq 0 ]; then
    echo "Found $i-linux-uclibc-gcc"
  fi
  ARCHALIAS=`cat $FULLNAME | grep -e "^#alias $i " | awk '{print $3}'`
  BUILDALIAS=`cat $FULLNAME | grep -e "^#build $i " | awk '{print $3}'`
  DRIVER=`cat $FULLNAME | grep -e "^#driver $ARCHALIAS " | awk '{print $3}'`

  LINK=`cat $FULLNAME | grep -e "^#link $ARCHALIAS " | awk '{print $3}'`

  if [ $SETKERNELDIRS -eq 0 ]; then
    KERNELDIRS=`(cd $KERNELBASE$ARCHALIAS; ls -d linux*)`
  fi
  for k in $KERNELDIRS; do
    pure_k_version=`echo $k | sed "s#linux-headers-##g" | sed "s#linux-##g"`
    if [ -f $KERNELBASE$ARCHALIAS/$k/.config ]; then
      for d in $DRIVER; do
        echo "Build $d for $ARCHALIAS $KERNELBASE$ARCHALIAS/$k -> $BRN_TOOLS_PATH/helper/nodes/lib/modules/$ARCHALIAS/$pure_k_version"
        (cd $DIR/../brn-driver; KERNELPATH=$KERNELBASE$ARCHALIAS/$k/ ARCH=$BUILDALIAS COMPILER_PREFIX=$i-linux-uclibc- TARGETDIR=$BRN_TOOLS_PATH/helper/nodes/lib/modules/$ARCHALIAS/$pure_k_version sh ./brn-driver.sh build-modules $d)
      done
    fi
  done

  if [ -e $BRN_TOOLS_PATH/helper/nodes/lib/modules/$ARCHALIAS/ ]; then
    for l in $LINK; do
      if [ ! -e $BRN_TOOLS_PATH/helper/nodes/lib/modules/$l ]; then
        (cd $BRN_TOOLS_PATH/helper/nodes/lib/modules/; ln -s $ARCHALIAS $l)
      fi
    done
  fi

done

#
#   C O N F I G   P A R T
#

#alias mips mips-wndr3700
#alias mipsel mips
#alias i386 x86

#build mips mips
#build mipsel mips
#build i386 i386

#link x86 i386
#link x86 i386
#link x86 i486
#link x86 i586
#link x86 i686

#driver x86 madwifi
#driver mips madwifi
#driver mips-wndr3700 ath
