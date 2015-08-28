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

case "$1" in
    "setup")
	CONFIGFILE=/tmp/wificonf
	echo "" > $CONFIGFILE
	case "$MODE" in
	    "adhoc")
		echo "MODE=adhoc" >> $CONFIGFILE
		;;
	    "monitor")
		echo "MODE=monitor" >> $CONFIGFILE
		;;
	esac
	
	if [ "x$CHANNEL" != "x" ]; then
	    echo "CHANNEL=$CHANNEL" >> $CONFIGFILE
	fi
	
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh delete
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh create
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh config_pre_start
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh start
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh config_post_start
	CONFIG=$CONFIGFILE DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh getiwconfig
	
	rm -f $CONFIGFILE
	;;
    "set_channel")
	DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh set_channel $2
	;;
    "set_txpower")
	DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh set_txpower $2
	;;
    "set_diversity")
	DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh set_diversity $2 $3 $4
	;;
    "get_config")
	DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh get_config
	;;
    *)
	echo "unknown options"
	;;
esac

exit 0
