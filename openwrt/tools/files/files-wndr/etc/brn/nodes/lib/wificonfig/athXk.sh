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

if [ -e /usr/sbin/iwconfig ]; then
    IWCONFIG=/usr/sbin/iwconfig
else
    if [ -e /sbin/iwconfig ]; then
	IWCONFIG=/sbin/iwconfig
    fi
fi

IW=none

if [ -e /usr/sbin/iw ]; then
    IW=/usr/sbin/iw
else
    if [ -e /sbin/iw ]; then
	IW=/sbin/iw
    fi
fi

if [ -e /usr/sbin/iwpriv ]; then
    IWPRIV=/usr/sbin/iwpriv
else
    if [ -e /sbin/iwpriv ]; then
	IWPRIV=/sbin/iwpriv
    fi
fi

if [ -e /usr/sbin/ifconfig ]; then
    IFCONFIG=/usr/sbin/ifconfig
else
    if [ -e /sbin/ifconfig ]; then
	IFCONFIG=/sbin/ifconfig
    fi
fi

case "$1" in
    "responsible")
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-4`
	    if [ "x$DEV_PREFIX" = "xwlan" ]; then
	      exit 0
	    else
	      exit 1
	    fi
	    ;;
    "create")
	;;
    "delete")
	    echo "$IFCONFIG $DEVICE down"
	    ${IFCONFIG} $DEVICE down
	;;
    "config_pre_start")
	    echo "Device config pre start"
	    if [ "x$CONFIG" = "x" ]; then
		echo "Use CONFIG to set the config"
		exit 0
	    fi

	    ARCH=`get_arch`

	    if [ -f  $DIR/../../etc/wifi/$CONFIG ]; then
			. $DIR/../../etc/wifi/$CONFIG
	    else
			. $CONFIG
	    fi

	    . $DIR/../../etc/wifi/default

	    ${IFCONFIG} $DEVICE down

	    if [ "x$MODE" = "x" ]; then
	    	MODE=$DEFAULT_MODE
	    fi


	    if [ "x$MODE" = "xadhoc" ]; then
	    	MODE="ad-hoc"
	    fi

	    echo "$IWCONFIG $DEVICE mode $MODE"
	    ${IWCONFIG} $DEVICE mode $MODE

	    ;;
    "start")
	    ${IFCONFIG} $DEVICE up
	    ;;
    "config_post_start")

	    echo "Device config post start"
	    if [ "x$CONFIG" = "x" ]; then
		echo "Use CONFIG to set the config"
		exit 0
	    fi

	    ARCH=`get_arch`

	    if [ -f  $DIR/../../etc/wifi/$CONFIG ]; then
			. $DIR/../../etc/wifi/$CONFIG
	    else
			. $CONFIG
	    fi

	    . $DIR/../../etc/wifi/default

	    if [ "$MODE" = "sta" ] || [ "$MODE" = "ap" ] || [ "$MODE" = "adhoc" ] || [ "$MODE" = "ahdemo" ]; then
			if [ ! "x$SSID" = "x" ]; then
		    	    sleep 1
		    	    echo "$IWCONFIG $DEVICE essid $SSID" 
		    	    ${IWCONFIG} $DEVICE essid $SSID 
			    sleep 1
			fi
	    fi

	    if [ "x$CHANNEL" = "x" ]; then
		CHANNEL=$DEFAULT_CHANNEL
	    fi
	    echo "$IWCONFIG $DEVICE channel $CHANNEL"
	    ${IWCONFIG} $DEVICE channel $CHANNEL
	    if [ "x$IW" != "xnone" ]; then
		if [ "x$HTMODE" = "x" ]; then
		    echo "${IW} $DEVICE set channel $CHANNEL"
		    ${IW} $DEVICE set channel $CHANNEL
		else
		    echo "${IW} $DEVICE set channel $CHANNEL $HTMODE"
		    ${IW} $DEVICE set channel $CHANNEL $HTMODE
		fi
	    fi

	    if [ "x$POWER" = "x" ]; then
		POWER=$DEFAULT_POWER
	    fi
	    echo "$IWCONFIG $DEVICE txpower $POWER"
	    if [ "x$POWER" != "xMAX" ]; then
		${IWCONFIG} $DEVICE txpower $POWER
	    fi

	    if [ ! "x$RATE" = "x" ]; then
			if [ $RATE -gt 0 ]; then
		    	echo "$IWCONFIG $DEVICE rate $RATE"
		    	${IWCONFIG} $DEVICE rate $RATE
			fi
	    fi

	    if [ "$MODE" = "sta" ] || [ "$MODE" = "ap" ] || [ "$MODE" = "adhoc" ] || [ "$MODE" = "ahdemo" ]; then
		if [ ! "x$WEPKEY" = "x" ] && [ ! "x$WEPMODE" = "x" ]; then
		    echo "$IWCONFIG $DEVICE key $WEPKEY key $WEPMODE" 
		    ${IWCONFIG} $DEVICE key $WEPKEY key $WEPMODE
		    sleep 1
		fi
	    fi

	    if [ "$MODE" = "monitor" ]; then
			if [ "x$TXQUEUE_LEN" = "x" ]; then
			    TXQUEUE_LEN=$DEFAULT_MONITOR_TXQUEUE_LEN
			fi
	    else
			if [ "x$TXQUEUE_LEN" = "x" ]; then
			    TXQUEUE_LEN=$DEFAULT_TXQUEUE_LEN
			fi
	    fi

	    if [ "x$MTU" = "x" ]; then
		MTU=2272
	    fi

	    echo "$IFCONFIG $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN"
	    ${IFCONFIG} $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN

	    echo "Finished device config"
	    ;;
    "getiwconfig")
            echo "iwconfig"
            ${IWCONFIG} $DEVICE
            echo "ifconfig"
            ${IFCONFIG} $DEVICE
            ;;
        *)
            ;;
esac

exit 0
