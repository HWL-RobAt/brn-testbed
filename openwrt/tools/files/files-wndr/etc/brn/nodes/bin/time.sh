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

get_in_seconds() {
    H=`echo $1 | cut -b 1,2`
    M=`echo $1 | cut -b 3,4`
    S=`echo $1 | cut -b 5,6`

    SEC=`expr \( \( \( $H * 60 \) + $M \) * 60 \) + $S`
    echo $SEC
}

case "$1" in
    "help")
	echo "Use $0 settime"
	exit 0;
	;;
    "settime")
	export PATH=/bin:/sbin:/usr/bin:/usr/sbin

        NOW=`date`
        echo "Date: $NOW"
        #echo "Settime"
	. $DIR/../etc/environment/ntpserver

	HWCLOCK=`which hwclock | wc -l | awk '{print $1}'`
	
	NTPCLIENT=`which ntpclient | wc -l | awk '{print $1}'`
	if [ $NTPCLIENT -gt 0 ]; then
	    NTPCLIENT=`which ntpclient`
	    #echo "found ntpclient $NTPSERVER"
	    #date
	    ${NTPCLIENT} -h $NTPSERVER -s > /dev/null 2>&1
	    #date
	    NOW=`date`
            echo "(Pre)Date: $NOW"
	    if [ $HWCLOCK -gt 0 ]; then
                echo "Set hwclock"
                hwclock --systohc
                hwclock -w
                hwclock
	    fi
	    exit 0
	fi

	NTPDATE=`which ntpdate | wc -l | awk '{print $1}'`
	if [ $NTPDATE -gt 0 ]; then
	    ntpdate $NTPSERVER > /dev/null 2>&1
	    if [ $HWCLOCK -gt 0 ]; then
              echo "Set hwclock"
	      hwclock --systohc
	      hwclock -w
	      hwclock
	    fi
	    NOW=`date`
            echo "(Pre)Date: $NOW"
	    exit 0
	fi

	RDATE=`which rdate | wc -l | awk '{print $1}'`
	if [ $RDATE -gt 0 ]; then
	    rdate $NTPSERVER > /dev/null 2>&1
	    if [ $HWCLOCK -gt 0 ]; then
              echo "Set hwclock"
	      hwclock --systohc
	      hwclock -w
	      hwclock
	    fi
	    NOW=`date`
            echo "(Pre)Date: $NOW"
	    exit 0
	fi
	
	echo "Unable to set time"
	;;
    "waitfor")
	export PATH=/bin:/sbin:/usr/bin:/usr/sbin

	if [ $1 -gt 235959 ]; then
	    TIMENOW=`date +%s`
	    TIMEDIFF=`$1 - $TIMENOW`
	else
	    TIMENOW=`date +%H%M%S`
	    TIMENOW=`get_in_seconds $TIMENOW`
	    TIMEWAIT=`get_in_seconds $1`
	    TIMEDIFF=`expr $TIMEWAIT - $TIMENOW`
	fi
	
	if [ $TIMEDIFF -gt 0 ]; then
	    sleep $TIMEDIFF
	fi
	;;
    *)
	;;
esac

exit 0
