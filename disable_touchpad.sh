#!/bin/bash

PATTERN="TouchPad"

echo "`xinput`" | \
while read line
do
    if [ -n "`echo "$line" | sed -n "/${PATTERN}/p" `" ]; then # found line
	 NUM=$(echo "$line" | grep -o "id=[0-9]\+" | grep -o "[0-9]\+")       # found number
	 echo "Disabling $PATTERN ..."
	 exec xinput --disable $NUM
	 exit $?
    fi
done
