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
    #TODO: use sysctl (net.ath0.%parent = wifi0)
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


POST_START_SLEEP=1
START_SLEEP=1
PRE_START_SLEEP=1

case "$1" in
    "responsible")
#	    ARCH=`get_arch`
#	    if [ "$ARCH" = "mips" ]; then
#	      exit 1
#	    fi
	    DEV_PREFIX=`echo $DEVICE | cut -b 1-3`
	    if [ "x$DEV_PREFIX" = "xath" ]; then
#	      exit 1
	      exit 0
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

	;;
    "delete")
	    echo "$IFCONFIG $DEVICE down"
	    ${IFCONFIG} $DEVICE down
	    echo "$WLANCONFIG $DEVICE destroy"
	    ${WLANCONFIG} $DEVICE destroy
	;;
    "config_pre_start")
	    echo "Config device (pre_start)"
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


            if [ "x$MODE" = "x" ]; then	MODE=$DEFAULT_MODE; fi
            if [ "x$MODE" = "x" ]; then echo "No mode. Can not create dev."; exit 0; fi

	    if [ "$MODE" = "sta" ] || [ "$MODE" = "ap" ] || [ "$MODE" = "adhoc" ] || [ "$MODE" = "ahdemo" ]; then
		if [ ! "x$SSID" = "x" ]; then
			echo "$IWCONFIG $DEVICE essid $SSID" 
			${IWCONFIG} $DEVICE essid $SSID 
			sleep 1
		fi
	    fi

	    if [ "$MODE" = "ahdemo" ]; then
		if [ "x$BSSID" = "x" ]; then
			BSSID=$DEFAULT_BSSID
		fi
		echo "$IWCONFIG $DEVICE ap $BSSID"
		${IWCONFIG} $DEVICE ap $BSSID

		sleep $PRE_START_SLEEP
	    fi

	    if [ "x$WIFITYPE" = "x" ]; then
		WIFITYPE=$DEFAULT_WIFITYPE
	    fi
	    if [ "x$WIFITYPE" = "x0" ]; then
		WIFITYPE=805
	    fi

	    echo "echo $WIFITYPE > /proc/sys/net/$DEVICE/dev_type"
	    echo $WIFITYPE > /proc/sys/net/$DEVICE/dev_type

	    sleep $PRE_START_SLEEP

	    if [ ! "x$RATE" = "x" ]; then
		if [ $RATE -gt 0 ]; then
			echo "$IWCONFIG $DEVICE rate $RATE"
			${IWCONFIG} $DEVICE rate $RATE
			
			sleep $PRE_START_SLEEP
		fi
	    fi

	    if [ "x$MODE" = "x" ]; then
		MODE=$DEFAULT_MODE
	    fi
#
	    if [ "$MODE" = "sta" ] || [ "$MODE" = "ap" ] || [ "$MODE" = "adhoc" ] || [ "$MODE" = "ahdemo" ]; then
		if [ ! "x$WEPKEY" = "x" ]; then
		    echo "$IWCONFIG $DEVICE key $WEPKEY"
		    ${IWCONFIG} $DEVICE key $WEPKEY
		    sleep 1
		    sleep $PRE_START_SLEEP
		fi
		if [ ! "x$WEPMODE" = "x" ]; then
		    echo "$IWCONFIG $DEVICE key $WEPMODE"
		    ${IWCONFIG} $DEVICE key $WEPMODE
		    sleep 1
		    sleep $PRE_START_SLEEP
		fi
		if [ ! "x$SSID" = "x" ]; then
			    sleep 1
			    echo "$IWCONFIG $DEVICE essid $SSID" 
			    ${IWCONFIG} $DEVICE essid $SSID 
			    sleep 1
			    sleep $PRE_START_SLEEP
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
		MTU=2290
	    fi

	    #TODO: set mtu depending on WIFITYPE
	    #txqueuelen: queuelen of ath is not relevant ( queuelen(ath0)==0 is no problem)
	    #            queuelen of wifi is relevant ( queuelen(wifi0)==0 results in disabling transmission)	    

	    echo "$IFCONFIG $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN"
            ${IFCONFIG} $PHYDEV mtu $MTU txqueuelen $TXQUEUE_LEN
            ${IFCONFIG} $DEVICE mtu $MTU txqueuelen $TXQUEUE_LEN

	    sleep $PRE_START_SLEEP

	    if [ "x$INTMIT" = "x" ]; then
		INTMIT=$DEFAULT_INTMIT
	    fi

	    echo "sysctl -w dev.$PHYDEV.intmit = $INTMIT"
	    sysctl -w dev.$PHYDEV.intmit=$INTMIT

	    sleep $PRE_START_SLEEP

	    if [ "x$CHANNEL" = "x" ]; then
		CHANNEL=$DEFAULT_CHANNEL
	    fi

	    echo "$IWCONFIG $DEVICE channel $CHANNEL"
	    ${IWCONFIG} $DEVICE channel $CHANNEL

	    sleep $PRE_START_SLEEP

	;;
    "start")
	    sleep $START_SLEEP

	    echo "Start dev $DEVICE"
	    echo "$IFCONFIG $DEVICE up"
	    ${IFCONFIG} $DEVICE up

	    sleep $START_SLEEP
	;;
    "config_post_start")

	    echo "Device config (post_start)"

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

	    if [ "x$POWER" = "x" ]; then
		POWER=$DEFAULT_POWER
	    fi
	    echo "$IWCONFIG $DEVICE txpower $POWER"
	    if [ "x$POWER" != "xMAX" ]; then
                ${IWCONFIG} $DEVICE txpower $POWER
            fi

	    sleep $POST_START_SLEEP

	    if [ "x$MODE" = "x" ]; then
		MODE=$DEFAULT_MODE
	    fi

	    if [ "x$MODE_ABG" != "x" ]; then
	      # 802.11b/802.11g/802.11a
	      echo "iwpriv $DEVICE mode $MODE_ABG"
	      ${IWPRIV} $DEVICE mode $MODE_ABG
	    fi

	    if [ "x$PUREG" != "x" ]; then
	      # disable/enable b
	      echo "iwpriv $DEVICE pureg $PUREG"
	      ${IWPRIV} $DEVICE pureg $PUREG

	      sleep $POST_START_SLEEP
	    fi

	    if [ "x$PROTMODE" != "x" ]; then
	      # no ofdm protection
	      echo "iwpriv $DEVICE protmode $PROTMODE"
	      ${IWPRIV} $DEVICE protmode $PROTMODE

	      sleep $POST_START_SLEEP
	    fi

	    if [ "x$BURST" != "x" ]; then
	      # no burst
	      echo "iwpriv $DEVICE burst $BURST"
	      ${IWPRIV} $DEVICE burst $BURST
	    else
	      echo "iwpriv $DEVICE burst 0"
	      ${IWPRIV} $DEVICE burst 0
	    fi

	    sleep $POST_START_SLEEP

	    if [ "x$ABOLT" != "x" ]; then
	      # no atheros proprietary in general
	      echo "iwpriv $DEVICE abolt $ABOLT"
	      ${IWPRIV} $DEVICE abolt $ABOLT
	    else
	      echo "iwpriv $DEVICE abolt 0"
	      ${IWPRIV} $DEVICE abolt 0
	    fi

	    sleep $POST_START_SLEEP

	    if [ "x$WMM" != "x" ]; then
	      # no multimedia
	      echo "iwpriv $DEVICE wmm $WMM"
	      ${IWPRIV} $DEVICE wmm $WMM
	    else
	      echo "iwpriv $DEVICE wmm $DEFAULT_WMM"
	      ${IWPRIV} $DEVICE wmm $DEFAULT_WMM
	    fi

	    sleep $POST_START_SLEEP

	    if [ "x$AR" != "x" ]; then
	      # no adaptive radio
	      echo "iwpriv $DEVICE ar $AR"
	      ${IWPRIV} $DEVICE ar $AR
	    else
	      echo "iwpriv $DEVICE ar 0"
	      ${IWPRIV} $DEVICE ar 0
	    fi

	    sleep $POST_START_SLEEP

	    if [ "x$INTMIT" = "x" ]; then
		INTMIT=$DEFAULT_INTMIT
	    fi

	    echo "sysctl -w dev.$PHYDEV.intmit = $INTMIT"
	    sysctl -w dev.$PHYDEV.intmit=$INTMIT

	    sleep $POST_START_SLEEP

#	    ${IWPRIV} $DEVICE bgscan        0
#	    ${IWPRIV} $DEVICE protmode      0
#	    ${IWPRIV} $DEVICE rssi11a       11
#	    ${IWPRIV} $DEVICE rssi11b       11
#	    ${IWPRIV} $DEVICE rssi11g       11
#	    ${IWPRIV} $DEVICE bintval       500
#	    ${IWPRIV} $DEVICE ff            0
#	    ${IWPRIV} $DEVICE burst         0
#	    ${IWPRIV} $DEVICE abolt         0

#Step3
	    if [ "x$FAST_FRAME" != "x" ]; then
	      # no fast frame
	      echo "iwpriv $DEVICE ff $FAST_FRAME"
	      ${IWPRIV} $DEVICE ff $FAST_FRAME
	    else
	      echo "iwpriv $DEVICE ff 0"
	      ${IWPRIV} $DEVICE ff 0
	    fi

	    sleep $POST_START_SLEEP
#end Step3

	    if [ "x$DIVERSITY" = "x" ]; then
		DIVERSITY=$DEFAULT_DIVERSITY
	    fi
	    echo "sysctl -w dev.$PHYDEV.diversity=$DIVERSITY"
	    sysctl -w dev.$PHYDEV.diversity=$DIVERSITY

	    if [ "x$TXANTENNA" = "x" ]; then
		TXANTENNA=$DEFAULT_TXANTENNA
	    fi
	    echo "sysctl -w dev.$PHYDEV.txantenna=$TXANTENNA"
	    sysctl -w dev.$PHYDEV.txantenna=$TXANTENNA

	    sleep $POST_START_SLEEP

	    if [ "x$RXANTENNA" = "x" ]; then
		RXANTENNA=$DEFAULT_RXANTENNA
	    fi
	    echo "sysctl -w dev.$PHYDEV.rxantenna=$RXANTENNA"
	    sysctl -w dev.$PHYDEV.rxantenna=$RXANTENNA

	    sleep $POST_START_SLEEP

#Step4            if [ "x" = "Y" ]; then
	    if [ "$MODE" = "monitor" ]; then

			if [ "x$CRCERROR" = "x" ]; then
				CRCERROR=$DEFAULT_CRCERROR
			fi
			echo "echo \"$CRCERROR\" > /proc/sys/net/$DEVICE/monitor_crc_errors"
			echo "$CRCERROR" > /proc/sys/net/$DEVICE/monitor_crc_errors

			sleep $POST_START_SLEEP

			if [ "x$PHYERROR" = "x" ]; then
				PHYERROR=$DEFAULT_PHYERROR
			fi
			echo "echo \"$PHYERROR\" > /proc/sys/net/$DEVICE/monitor_phy_errors"
			echo "$PHYERROR" > /proc/sys/net/$DEVICE/monitor_phy_errors

			if [ "x$TXFEEDBACK_LEN" = "x" ]; then
				TXFEEDBACK_LEN=$DEFAULT_TXFEEDBACK_LEN
			fi
			echo "echo \"$TXFEEDBACK_LEN\" > /proc/sys/net/$DEVICE/monitor_txf_len"
			echo "$TXFEEDBACK_LEN" > /proc/sys/net/$DEVICE/monitor_txf_len
			
			sleep $POST_START_SLEEP
			
			if [ "x$MACCLONE" = "x" ]; then
				MACCLONE=$DEFAULT_MACCLONE
			fi
			echo "$IWPRIV $DEVICE macclone $MACCLONE"
			${IWPRIV} $DEVICE macclone $MACCLONE

			sleep $POST_START_SLEEP

			if [ "x$CHANNELSWITCH" = "x" ]; then
				CHANNELSWITCH=$DEFAULT_CHANNELSWITCH
			fi
			echo "$IWPRIV $DEVICE channelswitch $CHANNELSWITCH"
			${IWPRIV} $DEVICE channelswitch $CHANNELSWITCH
			
			sleep $POST_START_SLEEP
			
			if [ "x$CUTIL_PACKET_THRESHOLD" != "x" ]; then
			    echo "sysctl -w dev.$PHYDEV.cutil_pkt_threshold=$CUTIL_PACKET_THRESHOLD"
			    sysctl -w dev.$PHYDEV.cutil_pkt_threshold=$CUTIL_PACKET_THRESHOLD
			    sleep $POST_START_SLEEP
			fi

			if [ "x$CUTIL_UPDATE_MODE" != "x" ]; then
			    echo "sysctl -w dev.$PHYDEV.cu_update_mode=$CUTIL_UPDATE_MODE"
			    sysctl -w dev.$PHYDEV.cu_update_mode=$CUTIL_UPDATE_MODE
			    sleep $POST_START_SLEEP
			fi
			
			if [ "x$CUTIL_ANNO_MODE" != "x" ]; then
			    echo "sysctl -w dev.$PHYDEV.cu_anno_mode=$CUTIL_ANNO_MODE"
			    sysctl -w dev.$PHYDEV.cu_anno_mode=$CUTIL_ANNO_MODE
			    sleep $POST_START_SLEEP
			fi
	    fi
#end step 4	   fi

#step 5
	    if [ "x$DISABLECCA" = "x" ]; then
		DISABLECCA=$DEFAULT_DISABLECCA
	    fi
	    echo "sysctl -w dev.$PHYDEV.disable_cca=$DISABLECCA"
	    sysctl -w dev.$PHYDEV.disable_cca=$DISABLECCA

           sleep $POST_START_SLEEP

	    if [ "x$CCA_THRESHOLD" != "x" ]; then
		echo "sysctl -w dev.$PHYDEV.cca_thresh=$CCA_THRESHOLD"
		sysctl -w dev.$PHYDEV.cca_thresh=$CCA_THRESHOLD
		sleep $POST_START_SLEEP
	    fi
#end step 5
	
	    if [ "x$CWMIN" != "x" ]; then
		QUEUE=0
		for c in $CWMIN; do
		    ${IWPRIV} $DEVICE cwmin $QUEUE 0 $c
		    ${IWPRIV} $DEVICE cwmin $QUEUE 1 $c
		    QUEUE=`expr $QUEUE + 1`
		    sleep $POST_START_SLEEP
		done
	    fi

	    if [ "x$CWMAX" != "x" ]; then
		QUEUE=0
		for c in $CWMAX; do
		    ${IWPRIV} $DEVICE cwmax $QUEUE 0 $c
		    ${IWPRIV} $DEVICE cwmax $QUEUE 1 $c
		    QUEUE=`expr $QUEUE + 1`
		    sleep $POST_START_SLEEP
		done
	    fi

	    if [ "x$AIFS" != "x" ]; then
		QUEUE=0
		for c in $AIFS; do
		    ${IWPRIV} $DEVICE aifs $QUEUE 0 $c
		    ${IWPRIV} $DEVICE aifs $QUEUE 1 $c
		    QUEUE=`expr $QUEUE + 1`
		    sleep $POST_START_SLEEP
		done
	    fi

	    echo "Finished device config"
	    ;;
    "getiwconfig")
	    PHYDEV=`get_phy_dev $DEVICE`
	    echo "iwconfig"
	    ${IWCONFIG} $DEVICE
	    echo "ifconfig"
	    ${IFCONFIG} $DEVICE
	    ${IWPRIV} $DEVICE get_mode
	    ${IWPRIV} $DEVICE get_inact_init
	    ${IWPRIV} $DEVICE get_dtim_period
	    ${IWPRIV} $DEVICE get_doth
	    ${IWPRIV} $DEVICE get_driver_caps
	    ${IWPRIV} $DEVICE get_txoplimit
	    ${IWPRIV} $DEVICE get_xr
	    ${IWPRIV} $DEVICE get_pureg
	    ${IWPRIV} $DEVICE get_coveragecls
	    ${IWPRIV} $DEVICE get_regclass
	    ${IWPRIV} $DEVICE get_turbo
	    ${IWPRIV} $DEVICE get_rssi11a
	    ${IWPRIV} $DEVICE get_rssi11b
	    ${IWPRIV} $DEVICE get_rssi11g
	    ${IWPRIV} $DEVICE get_uapsd
	    ${IWPRIV} $DEVICE get_markdfs
	    ${IWPRIV} $DEVICE get_wmm
	    ${IWPRIV} $DEVICE get_ar
	    ${IWPRIV} $DEVICE get_burst
	    ${IWPRIV} $DEVICE get_ff
	    ${IWPRIV} $DEVICE get_abolt
	    sysctl dev.$PHYDEV.disable_cca
	    sysctl dev.$PHYDEV.cca_thresh
	    ${IWPRIV} $DEVICE get_macclone
	    sysctl dev.$PHYDEV.cutil_pkt_threshold
	    sysctl dev.$PHYDEV.cu_update_mode
	    sysctl dev.$PHYDEV.cu_anno_mode
            ;;
        *)
            ;;
esac

exit 0
