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

export PATH=$PATH:/sbin:/usr/sbin/

#echo "Check responsible for $1"

RESPONSIBLE=""

for s in `ls $DIR/../lib/wifidriver/`; do
  #echo "Check $DIR/../lib/wifidriver/$s"
  export MODOPTIONS=$MODOPTIONS
  export MODULSDIR=$MODULSDIR
  KERNELVERSION=$KERNELVERSION NODEARCH=$NODEARCH $DIR/../lib/wifidriver/$s responsible
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    RESPONSIBLE=$DIR/../lib/wifidriver/$s
    break
  fi
done

case "$1" in
    "install")
		if [ "x$RESPONSIBLE" != "x" ]; then
		    echo "$RESPONSIBLE is responsible"
		    MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $RESPONSIBLE install
		    exit 0
		fi
		;;
    "uninstall")
		if [ "x$RESPONSIBLE" != "x" ]; then
		    echo "$RESPONSIBLE is responsible"
		    MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $RESPONSIBLE uninstall
		    exit 0
		fi
		;;
    "device_name")
		if [ "x$RESPONSIBLE" != "x" ]; then
		    #echo "$RESPONSIBLE is responsible"
		    DEVICE=$DEVICE MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $RESPONSIBLE device_name
		    exit 0
		fi
		;;
    "wifi_type")
		if [ "x$RESPONSIBLE" != "x" ]; then
		    #echo "$RESPONSIBLE is responsible"
		    DEVICE=$DEVICE MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $RESPONSIBLE wifi_type
		    exit 0
		fi
		;;
              *)
		echo "unknown options"
		;;
esac

exit 0
