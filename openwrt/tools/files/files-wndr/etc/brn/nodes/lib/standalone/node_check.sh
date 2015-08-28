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
    "start")
      if [ ! -e /tmp/run ]; then
        mkdir -p /tmp/run
      else
        if [ -f /tmp/run/node_check.pid ]; then
          NC_PID=`cat /tmp/run/node_check.pid`
          kill $NC_PID
        fi
      fi

      echo $$ > /tmp/run/node_check.pid

      WIFI_ERROR_COUNT=0
      SSH_ERROR_COUNT=0

      WIFI_ERROR_COUNT_LIMIT=5
      SSH_ERROR_COUNT_LIMIT=30

      while true; do
        #CHECK ath1
        ATH1_EX=`iwconfig ath1 | grep ath1 | wc -l`
        if [ $ATH1_EX -eq 0 ]; then
          WIFI_ERROR_COUNT=`expr $WIFI_ERROR_COUNT + 1`
        else
          SSID=`iwconfig ath1 | grep ESSID | sed "s#:# #g" | sed 's#"# #g' | awk '{print $5}'`

          if [ "x$SSID" != "xSeismoOLSR" ]; then
            WIFI_ERROR_COUNT=`expr $WIFI_ERROR_COUNT + 1`
          else

            CHANNEL=`iwconfig ath1 | grep Frequency | sed "s#:# #g" | awk '{print $4}'`

            if [ "x$CHANNEL" != "x5.17" ]; then
              WIFI_ERROR_COUNT=`expr $WIFI_ERROR_COUNT + 1`
            else

              OLSR_RUNNING=`ps | grep olsrd | grep -v grep | wc -l`

              if [ $OLSR_RUNNING -eq 0 ]; then
                 WIFI_ERROR_COUNT=`expr $WIFI_ERROR_COUNT + 1`
              else
                WIFI_ERROR_COUNT=0
              fi
            fi
          fi
        fi

        if [ -f /tmp/ssh_test ]; then
          SSH_ERROR_COUNT=0
          rm -f /tmp/ssh_test
        else
          SSH_ERROR_COUNT=`expr $SSH_ERROR_COUNT + 1`
        fi

        echo "Error count: SSH: $SSH_ERROR_COUNT/$SSH_ERROR_COUNT_LIMIT WIFI: $WIFI_ERROR_COUNT/$WIFI_ERROR_COUNT_LIMIT" > /tmp/node_status.log

        if [ $SSH_ERROR_COUNT -gt $SSH_ERROR_COUNT_LIMIT ] || [ $WIFI_ERROR_COUNT -gt $WIFI_ERROR_COUNT_LIMIT ]; then
          mkdir -p /data/node_check_log
          CDIR=`date +%Y-%m-%d-%H:%M:%S`
          mkdir -p /data/node_check_log/$CDIR

          LOG=/data/node_check_log/$CDIR/error.log

          echo "Error count: SSH: $SSH_ERROR_COUNT/$SSH_ERROR_COUNT_LIMIT WIFI: $WIFI_ERROR_COUNT/$WIFI_ERROR_COUNT_LIMIT" > $LOG
          iwconfig >> $LOG 2>&1
          ifconfig >> $LOG 2>&1
          route -n >> $LOG 2>&1
          iptables -L -n -v >> $LOG 2>&1
          ps >> $LOG 2>&1
          dmesg >> $LOG 2>&1

          sync
          reboot
          sleep 120
          reboot
          exit 0
        else
          sleep 60
        fi

      done
      ;;
    "stop")
      if [ -f /tmp/run/node_check.pid ]; then
        NC_PID=`cat /tmp/run/node_check.pid`
        kill $NC_PID
      fi
      ;;
    *)
        echo "unknown options"
        ;;
esac

exit 0

