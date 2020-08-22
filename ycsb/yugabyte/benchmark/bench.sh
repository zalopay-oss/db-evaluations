#!/bin/bash

input=./config-run.txt
if [[ $2 == '-f' ]] || [[ $2 == '--file' ]]; then
    if [[ ! -n "$3" ]]; then
        echo ">> Invalid path file !!!"
        exit 0
    fi
    input=$3
fi

case $1 in
    --run|-r)
        echo "=========================================================="
        echo "||                   START BENCHMARK YCSB               ||"
        echo "==========================================================\n"
        case $2 in
            a)
                echo "Benchmark workload A: Heavy workload for update"
                echo "\n==========================================================\n"
                ;;
            b)
                echo "Benchmark workload B: Read mostly"
                echo "\n==========================================================\n"
                ;;
            c)
                echo "Benchmark workload C: Read-only"
                echo "\n==========================================================\n"
                ;;
            d)
                echo "Benchmark workload D: Read the latest"
                echo "\n==========================================================\n"
                ;;
            e)
                echo "Benchmark workload E: Short ranges"
                echo "\n==========================================================\n"
                ;;
            f)
                echo "Benchmark workload F: Read-modify-write"
                echo "\n==========================================================\n"
                ;;
            q)
                echo "Benchmark workload Q: Custom"
                echo "\n==========================================================\n"
                ;;
        esac
        while read  line || [[ -n "$line" ]]; do
            items=(${line//:/ })
            host=${items[0]}
            path=${items[1]}
            range=${items[2]}
            echo ">> Run benchmark on $host ...."
            echo ">> Script location in $path"
            ssh -nt serverdeploy@$host "cd $path; nohup ./run.sh $1 $2 $3 $4 >>ycsblog.log 2>>ycsblog.log" &
            # sleep 5
            echo ">> Run benchmark workload$1 on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||               START BENCHMARK SCRIPT DONE            ||"
        echo "==========================================================\n"
        ;;
    
    --load|-l)
        echo "=========================================================="
        echo "||                     START LOAD DATA                   ||"
        echo "==========================================================\n"
        case $2 in
            a)
                echo "Load workload A: Heavy workload for update"
                echo "\n==========================================================\n"
                ;;
            b)
                echo "Load workload B: Read mostly"
                echo "\n==========================================================\n"
                ;;
            c)
                echo "Load workload C: Read-only"
                echo "\n==========================================================\n"
                ;;
            d)
                echo "Load workload D: Read the latest"
                echo "\n==========================================================\n"
                ;;
            e)
                echo "Load workload E: Short ranges"
                echo "\n==========================================================\n"
                ;;
            f)
                echo "Load workload F: Read-modify-write"
                echo "\n==========================================================\n"
                ;;
            q)
                echo "Load workload Q: Custom"
                echo "\n==========================================================\n"
                ;;
        esac
        while read  line || [[ -n "$line" ]]; do
            items=(${line//:/ })
            host=${items[0]}
            path=${items[1]}
            range=${items[2]}
            echo ">> Load data on $host ...."
            echo ">> Script location in $path"
            ssh -nt serverdeploy@$host "cd $path; ./run.sh $1 $2 $3 >>ycsblog.log 2>>ycsblog.log" &
            echo ">> Load data for workload$1 on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||                   LOAD DATA DONE                     ||"
        echo "==========================================================\n"
        ;;

    --help|-h)
        echo "usage: ./benchmark.sh [options]"
        echo "--run,-r --file,-f <path file>                     Run on service in file -f.  Default pathFile=./config.txt"
        echo "--stop,-s --file,-f <path file>                    Stop on service in file -f. Defaul pathFile=./config.txt"
        echo "--pull,-p <src> <dest>                             Pull source code from dest to src. 
                                                   Default src=10.20.11.56:/myserver/benchmark/benchmark-api, 
                                                   dest=./source"
        echo "--deploy,-d <src> <dest>                           Deploy source code from src to dest.
                                                   Default src=./source,
                                                   dest=10.20.11.56:/myserver/benchmark-1"
        echo "-pd <src> <dest>                                   Pull from src then deploy to dest.
                                                   Default src=10.20.11.56:/myserver/benchmark/benchmark-api,
                                                   dest=10.20.11.56:/myserver/benchmark-1"
        echo "--tail,-t <src> <number line>                      Tail log in src/log/benchmark-api.log. 
                                                   Default src=10.20.11.56:/myserver/benchmark/benchmark-api, line=100"
        ;;
    *)
		echo ">> Sorry, I don't support"
		;;
esac