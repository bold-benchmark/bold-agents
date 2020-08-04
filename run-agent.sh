#!/bin/sh

if [ ! -f "ldfu.sh" ] ; then
echo "please create ldfu.sh based on ldfu.sh.template"
exit 1
fi

if [ ! $# -ge "1" ] ; then
echo "please run with task id as parameter, eg. 'ts1', with optional parameter 'serial'"
exit 2
fi

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

serial() { [ $1 = "serial" ]; }

if beginswith tc $1 ; then
LDFU_PARAM="--interval 500"
else
LDFU_PARAM=""
fi

if serial $2 ; then
LDFU_PARAM=$LDFU_PARAM" -s"
echo "option set: serial"
fi


curl -X DELETE http://127.0.1.1:8080/sim

curl -X PUT http://127.0.1.1:8080/sim --data-binary @sim.ttl -Hcontent-type:text/turtle -v

# duration of a single run ~ 150s
timeout 150s ./ldfu.sh -p brick-*.n3 -p $1*/*.n3 $LDFU_PARAM

curl -X DELETE http://127.0.1.1:8080/sim

