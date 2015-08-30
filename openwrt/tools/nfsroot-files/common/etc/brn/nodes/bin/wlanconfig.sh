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
    ATH=`echo $1 | grep ath | wc -l`
    if [ $ATH -eq 0 ]; then
	echo "$1"
    else
      NUMBER=`echo $1 | cut -b 4`
      echo "wifi$NUMBER"
    fi
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
    "set_channel")
	${IWCONFIG} $DEVICE channel $2
	;;
    "set_txpower")
	${IWCONFIG} $DEVICE txpower $2
	;;
    "set_diversity")
	PHYDEV=`get_phy_dev $DEVICE`
        sysctl -w dev.$PHYDEV.diversity=$2
        sleep 1
        sysctl -w dev.$PHYDEV.txantenna=$3
        sleep 1
  	sysctl -w dev.$PHYDEV.rxantenna=$4					 
	;;
    "get_config")
        ;;
        *)
            ;;
esac

exit 0
