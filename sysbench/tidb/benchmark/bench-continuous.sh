#!/bin/bash
for test in 1 2; do
    t=8
    while [ $t -le 64 ]
    do
        nohup ./run.sh -r $test $1 $t 2>&1 >>sysbench.log
        sleep 15
        t=$(( $t * 2 ))
    done
done