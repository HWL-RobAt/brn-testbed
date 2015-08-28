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
		if [ -f ${FINMODULSDIR}/cdc-acm.ko ]; then
		    exit 0
		else
		    exit 1
		fi
		;;
    "device_name")
                IS_TMPL=`echo $DEVICE | grep "DEV" | wc -l`
		    
	        if [ $IS_TMPL -ne 0 ]; then
	            NUM=`echo $DEVICE | sed "s#DEV##g"`
	            echo "obd$NUM"
	        else
	            echo "$DEVICE"
	        fi
                ;;
    "install")
                KERNELVERSION=`uname -r`
                NODEARCH=`$DIR/../../bin/system.sh get_arch`
		
                FINMODULSDIR=`echo $MODULSDIR | sed -e "s#KERNELVERSION#$KERNELVERSION#g" -e "s#NODEARCH#$NODEARCH#g"`

		export PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin
		rmmod usbserial
		rmmod cdc_acm
		(cd $FINMODULSDIR; insmod ./usbserial.ko vendor=0x03EB product=0x6124; insmod ./cdc-acm.ko)
		#(cd $FINMODULSDIR; insmod ./tun.ko)
		;;
    "uninstall")
		;;
    "wifi_type")
                echo "807"
		;;
    *)
		echo "unknown options"
		;;
esac

exit 0
