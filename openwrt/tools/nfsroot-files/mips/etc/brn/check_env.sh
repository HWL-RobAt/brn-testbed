#!/bin/sh

HOSTNAME=`sysctl kernel.hostname | awk '{print $3}'`

MTD_DEV=`cat /proc/mtd | tail -n 1 | awk -F: '{print $1}'`

MTDBLOCK_DEV=`echo $MTD_DEV | sed 's#d#dblock#g'`

MTDSIZE=`cat /proc/partitions | grep $MTDBLOCK_DEV | awk '{print $3}'`

echo "$MTD_DEV $MTDBLOCK_DEV $MTDSIZE"

if [ $MTDSIZE -eq 256 ] || [ $MTDSIZE -eq 128 ]; then
  dd if=/dev/$MTD_DEV\ro of=/tmp/env_$HOSTNAME\_$MTD_DEV.img
else
  echo "ERROR: wrong mtd size!"
fi