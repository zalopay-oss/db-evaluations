#!/bin/bash
nohup ./run.sh -pp 2>&1 > sysbench.log &
echo $! > save_pid.txt