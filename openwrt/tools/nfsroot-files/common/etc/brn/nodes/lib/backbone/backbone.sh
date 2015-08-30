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

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

case "$1" in
    "save_backbone_info")
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-4`
	    if [ "x$DEV_PREFIX" = "xwlan" ]; then
	      exit 0
	    else
	      exit 1
	    fi
	    ;;
    "stop_backbone")
	    if [ -f /etc/rc.d/S42olsr_or_brn ]; then
              /etc/rc.d/S42olsr_or_brn stop 2>&1
              /sbin/ifconfig ath1 down 2>&1
            fi
            ;;
    "start_backbone")
            if [ -f /etc/rc.d/S42olsr_or_brn ]; then
              wlanconfig ath1 destroy
              /etc/rc.d/S42olsr_or_brn start 2>&1
              sleep 15;
            fi
            ;;
        *)
            ;;
esac

exit 0
