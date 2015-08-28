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
    "help")
	echo "Use $0"
	exit 0;
	;;
    "arch")
	WNDR=`cat /proc/cpuinfo | grep "WNDR3700" | wc -l`
	if [ $WNDR -gt 0 ]; then
	  echo "mips-wndr3700"
	else
	  uname -m
	fi
	;;
    *)
	;;
esac

exit 0
