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

get_arch() {
    $DIR/../../bin/system.sh get_arch
}

case "$1" in
    "responsible")
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-3`
	    if [ "x$DEV_PREFIX" = "xobd" ]; then
	      exit 0
	    else
	      exit 1
	    fi
	    ;;
    "create")
	;;
    "delete" | "stop")
	NODEARCH=`$DIR/../../bin/system.sh get_arch`    
	killall obd-$NODEARCH
	ifconfig $DEVICE down
	tunctl -d $DEVICE
	;;
    "config_pre_start")
	;;
    "start")
	export PATH=$PATH:/bin/:/sbin/:/usr/bin/:/usr/sbin/
	ifconfig eth0 |	
	tunctl -d $DEVICE
	tunctl -t $DEVICE
	MADDR=`ifconfig eth0 | grep eth0 | awk '{print $5}' | sed -e "s#-# #g" -e "s#:# #g" | awk '{print"00:00:00:00:"$5":"$6}'`
	echo "$MADDR"
	ip link set $DEVICE address $MADDR
	ifconfig $DEVICE up
	
	NODEARCH=`$DIR/../../bin/system.sh get_arch`
	killall obd-$NODEARCH
	
	sleep 1

	NUM=`echo $DEVICE | sed "s#obd##g"`
	ARCH=$NODEARCH $DIR/../openbeacon/obd-$NODEARCH -O $NUM -path /testbedhome/testbed/tmp/openbeacon/$MADDR -d < /dev/null > /dev/null 2>&1 &

	;;
    "config_post_start")
	;;
    "getiwconfig")
	export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin
	ifconfig $DEVICE
	ps
	NODEARCH=`$DIR/../../bin/system.sh get_arch`
	echo "PID of obd"
	pidof obd-$NODEARCH
        ;;
        *)
        ;;
esac

exit 0
