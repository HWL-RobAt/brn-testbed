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


if [ ! -e $DIR/dl ]; then
  mkdir --mode=755 $DIR/dl
fi

DL_PATH=$DIR/dl

if [ ! -e feeds ]; then
  mkdir --mode=755 feeds;
fi

if [ ! -e kernel ]; then
  mkdir --mode=755 kernel;
fi

if [ ! -e testbed-server ]; then
  mkdir --mode=755 testbed-server;
fi

if [ ! -e testbed-server/srv/boot ]; then
  mkdir -p --mode=755 testbed-server/srv/boot;
fi

. ./config/config.common

if [ "x$CONFIG" != "x" ]; then
  if [ -f $CONFIG ]; then
    . $CONFIG
  fi
fi

for i in $EXTRA_FEEDS; do
  (cd feeds; git clone $i)
done

FEED_PATHS=`(cd feeds; ls)`

for i in $BUILD_ARCH; do
  . config/config.$i

  export OPENWRT_PATH=$DIR/$OPENWRT_VERSION\-$i

  if [ ! -e $OPENWRT_PATH/openwrt_build.log ]; then

    (git clone $OPENWRT_GITURL $OPENWRT_PATH)
    (cd $OPENWRT_PATH; git reset --hard $OPENWRT_REVISION)

    (cd $OPENWRT_PATH; ln -s $DL_PATH dl)
    (cd $OPENWRT_PATH; cp feeds.conf.default feeds.conf)

    for f in $FEED_PATHS; do
      FEEDPATH=`echo $f | sed "s#-feeds##g" | sed "s#-##g"`
      echo "src-link $FEEDPATH $DIR/feeds/$f" >> $OPENWRT_PATH/feeds.conf
    done

    (cd $OPENWRT_PATH; ./scripts/feeds update; ./scripts/feeds install -a)
     #-d n

    cp -a config/$OPENWRT_CONFIG $OPENWRT_PATH/
    cp -a config/$OPENWRT_CONFIG $OPENWRT_PATH/.config

    (cd $OPENWRT_PATH; yes "" | make oldconfig; make V=99 -j10) | tee $OPENWRT_PATH/openwrt_build.log

  fi

  #
  # TOOLCHAIN BASHRC
  #

  echo "export OPENWRT_PATH=$OPENWRT_PATH" > $OPENWRT_PATH/toolchain.bashrc

  TOOLCHAIN_DIR=`(cd $OPENWRT_PATH; for i in staging_dir/tool*; do if [ -e $i/bin/ ]; then echo $i; break; fi; done)`

  echo "export TOOLCHAIN_DIR=\$OPENWRT_PATH/$TOOLCHAIN_DIR" >> $OPENWRT_PATH/toolchain.bashrc
  echo "export STAGING_DIR=\$OPENWRT_PATH/staging_dir/" >> $OPENWRT_PATH/toolchain.bashrc

  echo "export PATH=\$TOOLCHAIN_DIR/bin/:\$PATH" >> $OPENWRT_PATH/toolchain.bashrc
  echo "export PATH=\$STAGING_DIR/host/bin:\$PATH" >> $OPENWRT_PATH/toolchain.bashrc

  #OPENWRT_ROOTFS_DIR=`(cd $OPENWRT_PATH; for i in staging_dir/target-*; do if [ -e $i/bin/ ]; then echo $i; break; fi; done)`
  OPENWRT_ROOTFS_DIR=`(cd $OPENWRT_PATH; for i in build_dir/target-*; do echo $i; break; done)`

  echo "export OPENWRT_ROOTFS_DIR=\$OPENWRT_PATH/$OPENWRT_ROOTFS_DIR" >> $OPENWRT_PATH/toolchain.bashrc

  OPENWRT_ARCH=`(cd $OPENWRT_PATH/bin; ls)`
  echo "export OPENWRT_ARCH=$OPENWRT_ARCH" >> $OPENWRT_PATH/toolchain.bashrc

  #
  # KERNEL (NFSROOT)
  #

  if [ "x$KERNEL_CONFIG" != "x" ]; then
    if [ ! -e $DIR/testbed-server/srv/nfsroot-$i ]; then
      #copy openwrt files (rootfs)
      (cd $OPENWRT_PATH/$OPENWRT_ROOTFS_DIR; cp -ar root-* $DIR/testbed-server/srv/nfsroot-$i)


      if [ -e $DIR/tools/nfsroot-files/$i/ ]; then
          #copy common files
          (cd $DIR/tools/nfsroot-files/common/; cp -ar * $DIR/testbed-server/srv/nfsroot-$i)

          #copy arch files
          (cd $DIR/tools/nfsroot-files/$i/; cp -ar * $DIR/testbed-server/srv/nfsroot-$i)
      fi

    fi


    BUILD_DIR=`cd $OPENWRT_PATH; ls -d build_dir/target-*`
    LINUXTOOL_DIR=`cd $OPENWRT_PATH/$BUILD_DIR; ls -d linux-*`
    LINUX_DIR=`cd $OPENWRT_PATH/$BUILD_DIR/$LINUXTOOL_DIR; ls -d linux-3*`

    if [ ! -e kernel/$LINUX_DIR\-$i ]; then
        cp -ar $OPENWRT_PATH/$BUILD_DIR/$LINUXTOOL_DIR/$LINUX_DIR kernel/$LINUX_DIR\-$i
    fi

    cp -a tools/*.sh kernel/$LINUX_DIR\-$i/

    if [ "x$i" = "xx86" ]; then
        if [ ! -e kernel/$LINUX_DIR\-$i/.brn-kernel_build ]; then
          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=1 sh ./kernelbuild.sh distclean clean )
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/.config

          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=30 sh ./kernelbuild.sh bzImage modules)
          touch kernel/$LINUX_DIR\-$i/.brn-kernel_build
        fi

        rm -rf $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        mkdir --mode=755 $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i INSTALL_MOD_PATH=$DIR/testbed-server/srv/nfsroot-$i/ sh ./kernelbuild.sh modules_install)

        cp -a kernel/$LINUX_DIR\-$i/arch/x86/boot/bzImage $DIR/testbed-server/srv/boot/vmlinuz-$i
    fi
    if [ "x$i" = "xmips" ]; then
        if [ ! -e kernel/$LINUX_DIR\-$i/.brn-kernel_build ]; then
          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=1 sh ./kernelbuild.sh distclean clean )
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/.config

          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=30 sh ./kernelbuild.sh vmlinux modules)
          touch kernel/$LINUX_DIR\-$i/.brn-kernel_build
        fi

        rm -rf $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        mkdir --mode=755 $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i INSTALL_MOD_PATH=$DIR/testbed-server/srv/nfsroot-$i/ sh ./kernelbuild.sh modules_install)

        cp -a kernel/$LINUX_DIR\-$i/vmlinux $DIR/testbed-server/srv/boot/vmlinux-$i
    fi
    if [ "x$i" = "xwndr3700" ]; then
        if [ ! -e kernel/$LINUX_DIR\-$i/.brn-kernel_build ]; then
          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=1 sh ./kernelbuild.sh distclean clean )
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/
          cp -a config/$KERNEL_CONFIG kernel/$LINUX_DIR\-$i/.config

          ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i CPUS=30 sh ./kernelbuild.sh vmlinux modules; sh build-tftp.sh)
          touch kernel/$LINUX_DIR\-$i/.brn-kernel_build
        fi

        rm -rf $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        mkdir --mode=755 $DIR/testbed-server/srv/nfsroot-$i/lib/modules
        ( cd kernel/$LINUX_DIR\-$i/; . $OPENWRT_PATH/toolchain.bashrc; BUILD_ARCH=$i INSTALL_MOD_PATH=$DIR/testbed-server/srv/nfsroot-$i/ sh ./kernelbuild.sh modules_install)

        cp -a kernel/$LINUX_DIR\-$i/vmlinux-wndr3700v1.uImage  $DIR/testbed-server/srv/boot/vmlinuz-$i-v210
        cp -a kernel/$LINUX_DIR\-$i/vmlinux-wndr3700v2.uImage  $DIR/testbed-server/srv/boot/vmlinuz-$i
    fi

    KERNELVERSION=`(cd $DIR/testbed-server/srv/nfsroot-$i/lib/modules/; ls)`
    (cd $DIR/testbed-server/srv/nfsroot-$i/lib/modules/$KERNELVERSION; ls -1 | grep -v kernel | xargs rm -rf; find . -name "*.ko" -print0 | xargs -0 cp -a --target=$DIR/testbed-server/srv/nfsroot-$i/lib/modules/$KERNELVERSION; rm -rf kernel)


    if [ -e $OPENWRT_PATH/bin/$OPENWRT_ARCH/packages/hwlpackages ]; then
      (cd $DIR/testbed-server/srv/nfsroot-$i/etc; cp opkg.conf opkg.conf.bak; echo "arch all 100" >> opkg.conf; echo "arch $OPENWRT_ARCH 300 " >> opkg.conf)

      for p in `(cd $OPENWRT_PATH/bin/$OPENWRT_ARCH/packages/hwlpackages; ls -1 | grep "ipk")`; do
        (cd $OPENWRT_PATH/bin/$OPENWRT_ARCH/packages/hwlpackages; . $OPENWRT_PATH/toolchain.bashrc; opkg --nodeps -o $DIR/testbed-server/srv/nfsroot-$i/ -f $DIR/testbed-server/srv/nfsroot-$i/etc/opkg.conf install $p)
      done

      (cd $DIR/testbed-server/srv/nfsroot-$i/etc; rm opkg.conf; mv opkg.conf.bak opkg.conf)
    fi
  fi

done

#copy and setup server files
( cd $DIR/testbed-server/srv/boot/; chmod 644 * )
( cd tools/server-files/; cp -r * $DIR/testbed-server/)

unset OPENWRT_PATH
