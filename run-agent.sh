#!/bin/sh

if [ ! -f "ldfu.sh" ] ; then
echo "please create ldfu.sh based on ldfu.sh.template"
exit 1
fi

if [ ! $# -eq "1" ] ; then
echo "please run with task id as parameter, eg. ts1"
exit 2
fi

curl -X PUT http://127.0.1.1:8080/sim --data-binary @../bbench-server/data/sim.ttl -Hcontent-type:text/turtle -v

./ldfu.sh -p brick-*.n3 -p $1*/*.n3

curl -X DELETE http://127.0.1.1:8080/sim

