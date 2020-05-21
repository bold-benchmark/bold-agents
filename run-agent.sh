#!/bin/sh

if [ ! -f "ldfu.sh" ] ; then
echo "please create ldfu.sh based on ldfu.sh.template"
exit 1
fi

if [ ! $# -eq "1" ] ; then
echo "please run with task id as parameter, eg. ts1"
exit 2
fi

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

if beginswith tc $1 ; then
LDFU_PARAM="-n"
else
LDFU_PARAM=""
fi

curl -X DELETE http://127.0.1.1:8080/sim

curl -X PUT http://127.0.1.1:8080/sim --data-binary @../bbench-server/data/sim.ttl -Hcontent-type:text/turtle -v

timeout 60s ./ldfu.sh -p brick-*.n3 -p $1*/*.n3 $LDFU_PARAM

curl -X DELETE http://127.0.1.1:8080/sim

