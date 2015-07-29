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
  mkdir $DIR/dl
fi

DL_PATH=$DIR/dl

if [ ! -e build ]; then
  mkdir build;
fi

if [ ! -e feeds ]; then
  mkdir feeds;
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

  OPENWRT_PATH=$OPENWRT_VERSION\-$i
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

  cp config/$OPENWRT_CONFIG $OPENWRT_PATH/
  cp config/$OPENWRT_CONFIG $OPENWRT_PATH/.config

  (cd $OPENWRT_PATH; yes "" | make oldconfig; make V=99 -j10)

done


