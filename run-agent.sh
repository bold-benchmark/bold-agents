#!/bin/sh

# Checking for BOLD server
curl http://127.0.1.1:8080/ || { echo "No BOLD server running on localhost on port 8080" ; exit 3 ; }

# Checking for agent runtime
if [ ! -f "ldfu.sh" ] ; then
echo "please create ldfu.sh based on ldfu.sh.template"
exit 1
fi

# Checking for task specification
if [ ! $# -ge "1" ] ; then
echo "please run with task id as parameter, eg. 'ts1', with optional parameter 'serial'"
exit 2
fi

# Some useful code
beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

serial() { [ $1 = "serial" ]; }

# Setting parameters
if beginswith tc $1 ; then
LDFU_PARAM="--interval 500"
else
LDFU_PARAM=""
fi

if serial $2 ; then
LDFU_PARAM=$LDFU_PARAM" -s"
echo "option set: serial"
fi


# Cleaning up the BOLD server
curl -X DELETE http://127.0.1.1:8080/sim

# Starting a simulation
curl -X PUT http://127.0.1.1:8080/sim --data-binary @sim.ttl -Hcontent-type:text/turtle -v

# Running the specified task on ldfu with a duration of a single run ~ 150s
timeout 150s ./ldfu.sh -p brick-*.n3 -p $1*/*.n3 $LDFU_PARAM

# Cleaning up the BOLD server
curl -X DELETE http://127.0.1.1:8080/sim

