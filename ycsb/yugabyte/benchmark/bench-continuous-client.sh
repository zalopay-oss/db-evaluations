#!/bin/bash
input=./config-run.txt
while read line || [[ -n "$line" ]]; do
    items=(${line//:/ })
    host=${items[0]}
    path=${items[1]}
    range=${items[2]}
    echo ">> Run benchmark on $host ...."
    echo ">> Script location in $path"
    ssh -nt serverdeploy@$host "cd $path; ./bench-continuous.sh" &
    # sleep 5
    echo ">> Run benchmark script on $host DONE"
    echo "\n==========================================================\n"
done < $input