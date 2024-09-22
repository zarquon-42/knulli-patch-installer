#!/bin/bash

echo "========================" >>/tmp/test.log
echo "DEBUG: \$0 = $0" >>/tmp/test.log
echo "DEBUG: \$@ = $@" >>/tmp/test.log
echo "DEBUG: \$PWD = $PWD" >>/tmp/test.log

if [ ! -z "$0" ] && [[ "$0" != "bash" ]]; then
    echo "DEBUG: rm \"$0\"" >>/tmp/test.log
    rm "$0"
    echo "DEBUG: reload games list" >>/tmp/test.log
    batocera-es-swissknife --restart
fi

#echo "reboot" >>/tmp/test.log
