#!/bin/sh

echo "nameserver 192.168.3.2" > /etc/resolv.conf
IP=`ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
NAME=`nslookup $IP | grep "$IP" | grep Addr | sed "s#\.# #g" | awk '{print $7}'`
sysctl -w kernel.hostname=$NAME

#if [ "x$NAME" = "xwgt20" ]; then
#  exit
#fi

MODULSDIR=/lib/modules/KERNELVERSION/madwifi ./nodes/lib/wifidriver/madwifi.sh uninstall
MODULSDIR=/lib/modules/KERNELVERSION/madwifi ./nodes/lib/wifidriver/madwifi.sh install

DEVICE=ath0 ./nodes/lib/wificonfig/madwifi.sh delete
CONFIG=monitor DEVICE=ath0 ./nodes/lib/wificonfig/madwifi.sh create
CONFIG=monitor DEVICE=ath0 ./nodes/lib/wificonfig/madwifi.sh config_pre_start
CONFIG=monitor DEVICE=ath0 ./nodes/lib/wificonfig/madwifi.sh start
CONFIG=monitor DEVICE=ath0 ./nodes/lib/wificonfig/madwifi.sh config_post_start

(click-align receiver.click | sed "s#NODENAME#$NAME#g" | click) &
