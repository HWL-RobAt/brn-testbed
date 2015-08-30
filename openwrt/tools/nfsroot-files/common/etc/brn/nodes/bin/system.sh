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
	"get_arch")
		WNDR=`cat /proc/cpuinfo | grep "WNDR" | wc -l`
		if [ $WNDR -gt 0 ]; then
		  echo "mips-wndr3700"
		else
		  uname -m
		fi
		;;
	*)
		$0 help
		;;
esac

exit 0		
