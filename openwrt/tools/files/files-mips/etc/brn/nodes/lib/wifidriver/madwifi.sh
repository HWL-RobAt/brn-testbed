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
    "responsible")
		#check whether ath_pci.ko exists. if so, then his script is responsible 
		if [ "x$KERNELVERSION" = "x" ]; then
		  KERNELVERSION=`uname -r`
		fi
		if [ "x$NODEARCH" = "x" ]; then
		  NODEARCH=`$DIR/../../bin/system.sh get_arch`
		fi

                FINMODULSDIR=`echo $MODULSDIR | sed -e "s#KERNELVERSION#$KERNELVERSION#g" -e "s#NODEARCH#$NODEARCH#g"`
		if [ -f ${FINMODULSDIR}/ath_pci.ko ]; then
		    exit 0
		else
		    exit 1
		fi
		;;
    "device_name")
                IS_TMPL=`echo $DEVICE | grep "DEV" | wc -l` 
		                     
		if [ $IS_TMPL -ne 0 ]; then 
		  NUM=`echo $DEVICE | sed "s#DEV##g"` 
		  echo "ath$NUM" 
		else 
		  echo $DEVICE 
		fi 
		;; 
    "install")
                . $DIR/../../etc/wifi/default

		if [ "x$MODOPTIONS" = "x" ]; then
			MODOPTIONS=$DEFAULT_RECOMMENDMODOPTIONS
		fi
		if [ "x$MODOPTIONS" = "x" ]; then
			. $DIR/../../etc/madwifi/modoptions.default
		else
			if [ -e $MODOPTIONS ]; then
			. $MODOPTIONS
			else
			if [ -e ../etc/madwifi/$MODOPTIONS ]; then
			  . $DIR/../../etc/madwifi/$MODOPTIONS
			else
				echo "Modoptionsfile $MODOPTIONS doesn't exist ! Use default"
				. $DIR/../../etc/madwifi/modoptions.default
			fi
			fi
		fi
		
                KERNELVERSION=`uname -r`
                NODEARCH=`$DIR/../../bin/system.sh get_arch`
		
                FINMODULSDIR=`echo $MODULSDIR | sed -e "s#KERNELVERSION#$KERNELVERSION#g" -e "s#NODEARCH#$NODEARCH#g"`
                echo "Use $FINMODULSDIR"
			
		MODLIST="wlan.ko ath_hal.ko ath_rate_sample.ko wlan_acl.ko wlan_ccmp.ko wlan_scan_ap.ko wlan_scan_sta.ko wlan_tkip.ko wlan_wep.ko wlan_xauth.ko"
#		MODLIST="ath_hal.ko wlan.ko ath_rate_sample.ko"
		for mod in $MODLIST
		do
			if [ -f ${FINMODULSDIR}/$mod ]; then
			echo "insmod $mod"
			insmod ${FINMODULSDIR}/$mod
			fi
		done

		echo "insmod ath_pci $ATH_PCI"
		insmod ${FINMODULSDIR}/ath_pci.ko $ATH_PCI 
		;;
    "uninstall")
		MODLIST="ath9k ath5k wlan_xauth wlan_wep wlan_tkip wlan_scan_ap wlan_scan_sta wlan_ccmp wlan_acl ath_pci ath_rate_sample ath_rate_minstrel wlan ath_hal hostap_pci hostap ieee80211_crypt "
		
		for mod in $MODLIST
		do
			MOD_EX=`lsmod | grep $mod | wc -l`

			if [ ! $MOD_EX = 0 ]; then
			echo "rmmod $mod"
			rmmod $mod
			fi

		done
		;;
    "wifi_type")
                echo "805"
                ;;
    *)
		echo "unknown options"
		;;
esac

exit 0
