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

if [ "x$CPUS" = "x" ]; then
  if [ -f /proc/cpuinfo ]; then
    CPUS=`grep -e "^processor" /proc/cpuinfo | wc -l`
  else
    CPUS=1
  fi
fi

if [ "x$CLICKPATH" = "x" ]; then
  echo "Set CLICKPATH"
  exit 1
fi

if [ "x$BRN_TOOLS_PATH/helper" = "x" ]; then
  echo "Set BRN_TOOLS_PATH or helper is missing"
  exit 1
fi

ARCHS="mips mipsel i386"

for i in $ARCHS; do
  which $i-linux-uclibc-gcc > /dev/null
  ARCHALIAS=`cat $FULLNAME | grep -e "^#alias $i " | awk '{print $3}'`
  BUILDALIAS=`cat $FULLNAME | grep -e "^#build $i " | awk '{print $3}'`

  if [ $? -eq 0 ]; then
    echo "Found $i-linux-uclibc-gcc"
    if [ ! -e click-brn-$ARCHALIAS ]; then
      git clone $CLICKPATH/.git click-brn-$ARCHALIAS
    else
      ( cd click-brn-$ARCHALIAS; git pull )
    fi

    if [ ! -e click-brn-$ARCHALIAS/Makefile ]; then
      ( cd click-brn-$ARCHALIAS; TARGET=$BUILDALIAS sh ./brn-conf.sh userlevel )
    else
      if [ "x$RECONFIGURE" = "x1" ]; then
        ( cd click-brn-$ARCHALIAS; touch ./configure )
      fi
    fi

    if [ -e click-brn-$ARCHALIAS/Makefile ]; then
      if [ "x$ELEMLISTUPDATE" = "x1" ]; then
        ( cd click-brn-$ARCHALIAS; make elemlist )
      else
        if [ "x$CLEAN" = "x1" ]; then
          ( cd click-brn-$ARCHALIAS; make clean )
        fi
      fi
      ( cd click-brn-$ARCHALIAS; make -j $CPUS)
    fi

    if [ ! "x$DISABLE_STRIP" = "x1" ]; then
       $i-linux-uclibc-strip --strip-unneeded click-brn-$ARCHALIAS/userlevel/click
       $i-linux-uclibc-strip --strip-unneeded click-brn-$ARCHALIAS/tools/click-align/click-align
    fi

    LINKS=`cat $FULLNAME | grep -e "^#link $i " | awk '{print $3}'`

    for l in $LINKS; do
      if [ "x$CLEARLINKS" = "x1" ]; then
        rm -f $BRN_TOOLS_PATH/helper/nodes/bin/click-$l $BRN_TOOLS_PATH/helper/nodes/bin/click-align-$l
      fi
      if [ ! -f $BRN_TOOLS_PATH/helper/nodes/bin/click-$l ]; then
        ln -s $DIR/click-brn-$ARCHALIAS/userlevel/click $BRN_TOOLS_PATH/helper/nodes/bin/click-$l
      fi
      if [ ! -f $BRN_TOOLS_PATH/helper/nodes/bin/click-align-$l ]; then
        ln -s $DIR/click-brn-$ARCHALIAS/tools/click-align/click-align $BRN_TOOLS_PATH/helper/nodes/bin/click-align-$l
      fi
    done
  fi
done

#alias mips mips-wndr3700
#alias mipsel mips
#alias i386 x86

#build mips mips2
#build mipsel mips
#build i386 i386

#link mips mips-wndr3700
#link mipsel mips
#link i386 i386
#link i386 i486
#link i386 i586
#link i386 i686
