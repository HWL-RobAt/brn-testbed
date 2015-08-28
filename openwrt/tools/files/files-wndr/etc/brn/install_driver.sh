#!/bin/sh

echo "nameserver 192.168.3.2" > /etc/resolv.conf
IP=`ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
NAME=`nslookup $IP | grep "$IP" | grep Addr | sed "s#\.# #g" | awk '{print $7}'`
sysctl -w kernel.hostname=$NAME

#if [ "x$NAME" = "xwndr243" ]; then
#  exit
#fi

MODULSDIR=/lib/modules/KERNELVERSION ./nodes/lib/wifidriver/athXk.sh uninstall
MODULSDIR=/lib/modules/KERNELVERSION ./nodes/lib/wifidriver/athXk.sh install

#backports

DEVICE=wlan0 ./nodes/lib/wificonfig/athXk.sh delete
CONFIG=monitor DEVICE=wlan0 ./nodes/lib/wificonfig/athXk.sh create
CONFIG=monitor DEVICE=wlan0 ./nodes/lib/wificonfig/athXk.sh config_pre_start
CONFIG=monitor DEVICE=wlan0 ./nodes/lib/wificonfig/athXk.sh start
CONFIG=monitor DEVICE=wlan0 ./nodes/lib/wificonfig/athXk.sh config_post_start

(click-align receiver.click | sed "s#NODENAME#$NAME#g" | click) &
