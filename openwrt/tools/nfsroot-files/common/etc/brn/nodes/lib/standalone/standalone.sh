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


#MODULSDIR
#WIFICONFIG
# incl. MODOPTIONS
#CLICKFILE
#CLICKLOG

MODULSDIR=$DIR/../modules/i586/2.6.32.25
MODOPTIONS=$DIR/../../etc/madwifi/modoptions.japan

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

case "$1" in
    "driver")
      /etc/rc.d/S42olsr_or_brn stop >> /tmp/seismo_brn.log 2>&1
      /sbin/ifconfig ath1 down >> /tmp/seismo_brn.log 2>&1
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh delete >> /tmp/seismo_brn.log 2>&1
      sleep 1
      MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $DIR/../../bin/wlanmodules.sh uninstall >> /tmp/seismo_brn.log 2>&1
      sleep 1
      MODOPTIONS=$MODOPTIONS MODULSDIR=$MODULSDIR $DIR/../../bin/wlanmodules.sh install >> /tmp/seismo_brn.log 2>&1
      sleep 10
      CONFIG=$CONFIG DEVICE=wlan1 $DIR/../../bin/wlandevice.sh delete >> /tmp/seismo_brn.log 2>&1
      sleep 2
      /etc/rc.d/S42olsr_or_brn start >> /tmp/seismo_brn.log 2>&1
      ;;
    "brndev")
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh delete >> /tmp/seismo_brn.log 2>&1
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh create >> /tmp/seismo_brn.log 2>&1
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh config_pre_start >> /tmp/seismo_brn.log 2>&1
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh start  >> /tmp/seismo_brn.log 2>&1
      CONFIG=$CONFIG DEVICE=$DEVICE $DIR/../../bin/wlandevice.sh config_post_start >> /tmp/seismo_brn.log 2>&1
      ;;
    "click_start")
      ARCH=`$DIR/../../bin/system.sh get_arch`
      ($DIR/../../bin/click-align-$ARCH $CLICKFILE 2> /dev/null | $DIR/../../bin/click-$ARCH >> /tmp/seismo_brn.log 2>&1 ) &
      sleep 5
      ;;
    "click_stop")
      ARCH=`$DIR/../../bin/system.sh get_arch`
      killall click > /dev/null 2>&1
      killall click-$ARCH > /dev/null 2>&1
      ;;
    "setup")
      CLICKFILE=$CLICKFILE RUNMODE=$RUNMODE MODULSDIR=$MODULSDIR MODOPTIONS=$MODOPTIONS CONFIG=$CONFIG DEVICE=$DEVICE $0 delaysetup &
      ;;
    "delaysetup")
       sleep 40
       $0 checker &

       $0 click_stop &

       if [ "x$RUNMODE" = "xDRIVER"  ]; then
         if [ ! -f /tmp/brn_driver ]; then
            #TODO better check for existing driver (version,...)
            RUNMODE=$RUNMODE MODULSDIR=$MODULSDIR MODOPTIONS=$MODOPTIONS CONFIG=$CONFIG DEVICE=$DEVICE $0 driver
            touch /tmp/brn_driver
            sleep 1
         fi
       fi

       RUNMODE=$RUNMODE MODULSDIR=$MODULSDIR MODOPTIONS=$MODOPTIONS CONFIG=$CONFIG DEVICE=$DEVICE $0 brndev
       sleep 1

       if [ "x$CLICKFILE" != "x" ]; then
         CLICKFILE=$CLICKFILE $0 start_click
       fi
       ;;
    "checker")
       sleep 180
       DEVICE_EX=`/sbin/ifconfig ath1 2> /dev/null | grep ath1 | wc -l`

       if [ $DEVICE_EX -eq 0 ]; then
         reboot
       fi
       #else
    #     ROUTE_EX=`/sbin/route -n | grep "10." | wc -l`

     #    if [ $ROUTE_EX -eq 0 ]; then
      #     reboot
       #  fi
       #fi
       ;;
    "seismo")
       MODULSDIR=$DIR/../modules/i586/2.6.32.25
       MODOPTIONS=$DIR/../../etc/madwifi/modoptions.japan
       CLICKFILE=$DIR/../../etc/seismo/testbed_long_run.click.seismo
       CONFIG=$DIR/../../etc/seismo/monitor.b.channel

       if [ "x$DRIVERSETUP" = "xyes" ]; then
         rm -f /tmp/brn_driver
         RUNMODE=DRIVER
       fi

       CLICKFILE=$CLICKFILE CONFIG=$CONFIG DEVICE="ath0" RUNMODE=$RUNMODE MODULSDIR=$MODULSDIR MODOPTIONS=$MODOPTIONS $0 setup
       ;;
    *)
       echo "unknown options"
       ;;
esac

exit 0

