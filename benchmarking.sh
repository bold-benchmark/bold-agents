#!/bin/bash

set -e

DATE=`date --rfc-3339=seconds | sed 's/ /T/g'`

rm -f ../bbench-server/query/t*.tsv

ITERATIONS=1

echo "=================================BOLD========================================="
echo "======= Benchmarking Read-write user Agents and Clients for Lined Data  ======"
echo "=================================BOLD========================================="

echo "Benchmarking with $ITERATIONS iterations..."

rm -f ldf.out

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

list_descendants ()
{
	local children=$(ps -o pid= --ppid "$1")

	for pid in $children
	do
		list_descendants "$pid"
	done

	echo "$children"
}

function tlo {

	TASK_SHORTHAND=${2:0:3};

	for file in $(find $2 -name "*.ld.n3"); do
		NEWNAME="$file.x.n3"
		cp $file $NEWNAME
		sed -i "s/Building_B3/$1/g" $NEWNAME
	done

	for ((i=1;i<=$ITERATIONS;i++)) ; do

		echo "Iteration $i"

		#if beginswith tc $2 ; then
		LDFU_PARAM="-n"
		#else
		#LDFU_PARAM=""

		cd ../bbench-server/
		./build/install/bold-benchmark/bin/bold-benchmark $TASK_SHORTHAND &
		SERVER_PID=$!
		cd -

		sleep 5

		if [ $3 = "serial" ] ; then
			LDFU_PARAM="$LDFU_PARAM -s"
		fi

		echo "Starting simulation"
		curl -X PUT "http://127.0.1.1:8080/sim" --data-binary @../bbench-server/data/sim.ttl -Hcontent-type:text/turtle

		echo "Warming up LDFU"
		./ldfu.sh -p brick*.n3 -p $2/*.x.n3 $LDFU_PARAM 2> ldfu.out > ldfu.out & 

		LDFU_PID=$!

		sleep 20

		echo "Pausing LDFU"
		kill -s SIGSTOP $LDFU_PID $(list_descendants $LDFU_PID)

		echo "Stopping simulation"
		curl -X DELETE "http://127.0.1.1:8080/sim" & 

		while read outputtsv ; do if [ "$outputtsv" = $TASK_SHORTHAND.tsv ]; then break; fi; done < <( timeout 600 inotifywait -e close --format "%f" --quiet "../bbench-server/query/" --monitor)

		rm -f ../bbench-server/query/$TASK_SHORTHAND.tsv

		echo "Starting simulation"
		curl -X PUT "http://127.0.1.1:8080/sim" --data-binary @../bbench-server/data/sim.ttl -Hcontent-type:text/turtle

		echo "Resuming LDFU"
		kill -s SIGCONT $LDFU_PID $(list_descendants $LDFU_PID)

		while read outputtsv ; do if [ "$outputtsv" = $TASK_SHORTHAND.tsv ]; then break; fi; done < <( timeout 180 inotifywait -e create --format "%f" --quiet "../bbench-server/query/" --monitor)

		echo "Killing LDFU"
		kill $LDFU_PID $(list_descendants $LDFU_PID)

		while read outputtsv ; do if [ "$outputtsv" = $TASK_SHORTHAND.tsv ]; then break; fi; done < <( timeout 600 inotifywait -e close --format "%f" --quiet "../bbench-server/query/" --monitor)


		if [ -f "../bbench-server/query/$TASK_SHORTHAND.tsv" ] ; then
			echo "Found output. Moving..."
			mv "../bbench-server/query/$TASK_SHORTHAND.tsv" "../bbench-server/query/$DATE-$TASK_SHORTHAND-$3-$1-$i.tsv"
		else
			echo "Found no output."
		fi

		kill $SERVER_PID
	done
}

for behaviour in "tc5_occupancy-based-control" "tc1_sun-hour-based-control" "tc2_work-hour-based-control" "tc3_1-lightsensor-threshold" "tc4_lightsensor-per-room" "tc6_occupancy-and-lightsensor" "tc7_occupany-and-custom-lightsensor" "ts2_toggle" # "ts1_all-off" 
do
	echo
	echo "============== behaviour: $behaviour =============="
	for place in "Building_B3" "Room_SOR42_G_19" "Wing_SOR46" "tenrooms" "twentyrooms" # "Floor_FirstFloor" "fiverooms"
	do
		for mode in "serial" "multi" ; do
			echo
			echo "== $behaviour in $place with mode $mode..."
			tlo $place $behaviour $mode
		done
	done
	find . -name "$behaviour.x.n3" -delete
done
