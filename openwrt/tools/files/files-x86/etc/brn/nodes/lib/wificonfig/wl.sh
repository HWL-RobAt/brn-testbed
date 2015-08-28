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

if [ -e /usr/sbin/wl ]; then
    WL=/usr/sbin/wl
else
    if [ -e /sbin/wl ]; then
	WL=/sbin/wl
    fi
fi

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
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-3`
	    if [ "x$DEV_PREFIX" = "xeth" ]; then
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
	    echo "Start device config"
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

	    if [ "x$MODE" = "x" ]; then
	    	MODE=$DEFAULT_MODE
	    fi

	    #${IFCONFIG} $DEVICE hw ether 00:0F:B5:3F:57:43
	    ${WL} country jp
	    ${WL} antdiv 3
	    ${WL} txant 0
	    ${WL} rts 2347
	    ${WL} monitor 1
	    ${WL} promisc 1
	    ${IFCONFIG} $DEVICE up
	    ${WL} srl 1
	    ${WL} lrl 1
            ${WL} rate ${RATE}
            #${IWCONFIG} $DEVICE mode ad-hoc essid "${SSID}" channel ${CHANNEL}
            ${IWCONFIG} $DEVICE channel $CHANNEL
            ${WL} monitor on
            ${WL} srl 1
            ${WL} lrl 1
            ${WL} rate ${RATE}
            #${WL} txpwr ${POWER}

	    if [ "x$MTU" = "x" ]; then
		#TODO: mtu depends on wifitype
		MTU=2290  #madwifi
		MTU=2272  #ath
	    fi

	    #TODO: set mtu depending on WIFITYPE
	    echo "$IFCONFIG $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN"
	    ${IFCONFIG} $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN

	    echo "Finished device config"
	    ;;
    "start")
	    ;;
    "config_post_start")
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
