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

mkdir -p brn-testbed-wndr3700-0.0.1/srv/boot

#(cd ../../../testbed-server; tar -czf $DIR/brn-testbed-wndr3700-0.0.1.tar.gz srv/)
(cd ../../../testbed-server/srv/; cp -r *wndr3700 $DIR/brn-testbed-wndr3700-0.0.1/srv/ )
(cd ../../../testbed-server/srv/boot; cp *wndr3700 $DIR/brn-testbed-wndr3700-0.0.1/srv/boot )
(cd brn-testbed-wndr3700-0.0.1; debuild -uc -us)
