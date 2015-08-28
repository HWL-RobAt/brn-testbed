#!/bin/sh

while [ true ]; do

  NEXT=`nc -l -w 1  -p 7777 2> /dev/null`

  if [ "x$NEXT" != "x" ]; then
    OP=`echo $NEXT | awk '{print $1}'`
    HANDLER=`echo $NEXT | awk '{print $2}' | sed "s#\.#/#g"`

    STUFF=`echo $NEXT | awk '{print $3}'`

    echo "$OP $HANDLER $STUFF" >> /tmp/kctrl.log

    if [ "x$OP" = "xwrite" ]; then
      echo "$STUFF" >> /tmp/click/$HANDLER
    fi
    if [ "x$OP" = "xread" ]; then
      cat /tmp/click/$HANDLER >> /tmp/kctrl.log
    fi
  fi

done

exit 0
