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

get_phy_dev() {
    NUMBER=`echo $1 | cut -b 4`
    echo "wifi$NUMBER"
}

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

if [ -e /usr/sbin/wlanconfig ]; then
    WLANCONFIG=/usr/sbin/wlanconfig
else
    if [ -e /sbin/wlanconfig ]; then
	WLANCONFIG=/sbin/wlanconfig
    else
      if [ -e /usr/bin/wlanconfig ]; then
	WLANCONFIG=/usr/bin/wlanconfig
      fi
    fi
fi

case "$1" in
    "responsible")
#	     ARCH=`get_arch`
#	     if [ "$ARCH" != "mips" ]; then
#	       exit 1
#	     fi
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-3`
	    #bth instead of ath to avoid that madwifi_test
	    if [ "x$DEV_PREFIX" = "xbth" ]; then
	      exit 1
#	      exit 0
	    else
	      exit 1
	    fi
	    ;;
    "create")
    	    if [ "x$CONFIG" = "x" ]; then
                echo "Use CONFIG to set the config"
                exit 0
        fi
    
                PHYDEV=`get_phy_dev $DEVICE`
        
        if [ -f  $DIR/../../etc/wifi/$CONFIG ]; then
            . $DIR/../../etc/wifi/$CONFIG
    else
        . $CONFIG
   fi
                . $DIR/../../etc/wifi/default

                            if [ "x$MODE" = "x" ]; then
                                    MODE=$DEFAULT_MODE
                        fi

	    ${WLANCONFIG} $DEVICE destroy
	    echo "$WLANCONFIG $DEVICE create wlandev $PHYDEV wlanmode $MODE"
	    ${WLANCONFIG} $DEVICE create wlandev $PHYDEV wlanmode $MODE

	    sleep 2
	;;
    "delete")
	    echo "$IFCONFIG $DEVICE down"
	    ${IFCONFIG} $DEVICE down
	    echo "$WLANCONFIG $DEVICE destroy"
	    ${WLANCONFIG} $DEVICE destroy
	;;
    "config_pre_start")
	;;
    "start")

	    echo "Start device config"
	    if [ "x$CONFIG" = "x" ]; then
		echo "Use CONFIG to set the config"
		exit 0
	    fi

	    PHYDEV=`get_phy_dev $DEVICE`
	    ARCH=`get_arch`

	    if [ -f  $DIR/../../etc/wifi/$CONFIG ]; then
			. $DIR/../../etc/wifi/$CONFIG
	    else
			. $CONFIG
	    fi

	    . $DIR/../../etc/wifi/default

	    if [ "x$WIFITYPE" = "x" ]; then
		WIFITYPE=$DEFAULT_WIFITYPE
	    fi
	    if [ "x$WIFITYPE" = "x0" ]; then
	      WIFITYPE=805
	    fi

	    echo "echo $WIFITYPE > /proc/sys/net/$DEVICE/dev_type"
	    echo $WIFITYPE > /proc/sys/net/$DEVICE/dev_type

	    sleep 1

	    if [ "x$MTU" = "x" ]; then
		MTU=2290
	    fi
            TXQUEUE_LEN=1
	    #TODO: set mtu depending on WIFITYPE
	    echo "$IFCONFIG $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN"
	    #txqueuelen: queuelen of ath is not relevant ( queuelen(ath0)==0 is no problem)
            #            queuelen of wifi is relevant ( queuelen(wifi0)==0 results in disabling transmission)
	    ${IFCONFIG} $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN
	    sleep 1

	    sysctl -w dev.$PHYDEV.intmit=0
	    sleep 1

	    echo "$IWCONFIG $DEVICE channel $CHANNEL"
	    ${IWCONFIG} $DEVICE channel $CHANNEL
	    sleep 1

	    echo "$IFCONFIG $DEVICE up"
	    ${IFCONFIG} $DEVICE up
	    sleep 1

	    echo "iwpriv $DEVICE burst 0"
            ${IWPRIV} $DEVICE burst 0
            sleep 1

            echo "iwpriv $DEVICE abolt 0"
            ${IWPRIV} $DEVICE abolt 0
            sleep 1

            echo "iwpriv $DEVICE wmm 0"
            ${IWPRIV} $DEVICE wmm 0
            sleep 1

            echo "iwpriv $DEVICE ar 0"
            ${IWPRIV} $DEVICE ar 0
            sleep 1


	    sysctl -w dev.$PHYDEV.intmit=0
	    sleep 1

	        if [ "x$DIVERSITY" = "x" ]; then
	    DIVERSITY=$DEFAULT_DIVERSITY
	    fi
	    echo "sysctl -w dev.$PHYDEV.diversity=$DIVERSITY"
	    sysctl -w dev.$PHYDEV.diversity=$DIVERSITY
	    sleep 1
 #
	        if [ "x$TXANTENNA" = "x" ]; then
	    TXANTENNA=$DEFAULT_TXANTENNA
	    fi
	    echo "sysctl -w dev.$PHYDEV.txantenna=$TXANTENNA"
	    sysctl -w dev.$PHYDEV.txantenna=$TXANTENNA
	    sleep 1
 #
	    if [ "x$RXANTENNA" = "x" ]; then
	     RXANTENNA=$DEFAULT_RXANTENNA
	    fi
	    echo "sysctl -w dev.$PHYDEV.rxantenna=$RXANTENNA"
	    sysctl -w dev.$PHYDEV.rxantenna=$RXANTENNA
	    sleep 1
	    ;;
    "config_post_start")
	;;
    "getiwconfig")
            PHYDEV=`get_phy_dev $DEVICE`
            echo "iwconfig"
            ${IWCONFIG} $DEVICE
            echo "ifconfig"
            ${IFCONFIG} $DEVICE
            ;;
        *)
            ;;
esac

exit 0
