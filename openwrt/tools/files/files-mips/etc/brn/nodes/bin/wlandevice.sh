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

if [ -e /usr/sbin/ifconfig ]; then
    IFCONFIG=/usr/sbin/ifconfig
else
    if [ -e /sbin/ifconfig ]; then
        IFCONFIG=/sbin/ifconfig
    fi
fi

echo "Check responsible for $1"

RESPONSIBLE=""

for s in `ls $DIR/../lib/wificonfig/`; do
  echo "Check $DIR/../lib/wificonfig/$s"
  export CONFIG=$CONFIG
  $DIR/../lib/wificonfig/$s responsible
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    RESPONSIBLE=$DIR/../lib/wificonfig/$s
    break
  fi
done

case "$1" in
    "help")
		echo "Use $0 create | delete | config"
		exit 0;
	;;
    "create")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE create
	  exit 0
	fi
	;;
    "config_pre_start")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE config_pre_start
	  exit 0
	fi
	;;
    "start")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE start
	  exit 0
	fi
	;;
    "config_post_start")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE config_post_start
	  exit 0
	fi
	;;
    "getmac")
            MADDR=`$IFCONFIG $DEVICE | grep HWaddr | awk '{print $5}' | sed -e "s#-# #g" -e "s#:# #g" | awk '{print $1":"$2":"$3":"$4":"$5":"$6}'`
            echo $MADDR
        ;;
    "getiwconfig")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE getiwconfig
	  exit 0
	fi
        ;;
    "delete")
	if [ "x$RESPONSIBLE" != "x" ]; then
	  echo "$RESPONSIBLE is responsible"
	  CONFIG="$CONFIG" DEVICE="$DEVICE" $RESPONSIBLE delete
	  exit 0
	fi
	;;
    *)
        ;;
esac

exit 0
