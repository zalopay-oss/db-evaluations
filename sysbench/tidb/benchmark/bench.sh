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
        echo "||                   RUN BENCHMARK SYSBENCH             ||"
        echo "==========================================================\n"
        case $2 in
            1)
                echo "Benchmark read_only"
                echo "\n==========================================================\n"
                ;;
            2)
                echo "Benchmark write only"
                echo "\n==========================================================\n"
                ;;
            3)
                echo "Benchmark read-write"
                echo "\n==========================================================\n"
                ;;
            4)
                echo "Benchmark point select"
                echo "\n==========================================================\n"
                ;;
            5)
                echo "Benchmark insert"
                echo "\n==========================================================\n"
                ;;
            6)
                echo "Benchmark update index"
                echo "\n==========================================================\n"
                ;;
            7)
                echo "Benchmark update non-index"
                echo "\n==========================================================\n"
                ;;
            8)
                echo "Benchmark delete"
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
            ssh -nt serverdeploy@$host "cd $path; ./run.sh -r $2 $range 2>&1 >>sysbench.log" &
            # sleep 5
            echo ">> Run benchmark script on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||               START BENCHMARK SCRIPT DONE            ||"
        echo "==========================================================\n"
        ;;
    
    --clean|-cl)
        echo "=========================================================="
        echo "||                     CLEAN DATA                       ||"
        echo "==========================================================\n"
        while read  line || [[ -n "$line" ]]; do
            items=(${line//:/ })
            host=${items[0]}
            path=${items[1]}
            range=${items[2]}
            echo ">> Clean data on $host ...."
            echo ">> Script location in $path"
            ssh -nt serverdeploy@$host "cd $path; ./run.sh -cl >>sysbench.log" &
            echo ">> clean data on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||                     CLEAN DATA DONE                  ||"
        echo "==========================================================\n"
        ;;
    
    --prepare|-pp)
        echo "=========================================================="
        echo "||                     PREPARE DATA                     ||"
        echo "==========================================================\n"
        while read  line || [[ -n "$line" ]]; do
            items=(${line//:/ })
            host=${items[0]}
            path=${items[1]}
            range=${items[2]}
            echo ">> Prepare data on $host ...."
            echo ">> Script location in $path"
            ssh -nt serverdeploy@$host "cd $path; ./run.sh -pp $range >>sysbench.log" &
            echo ">> Prepare data on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||                   PREPARE DATA DONE                  ||"
        echo "==========================================================\n"
        ;;

    --stop|-s)
        input=./config-api.txt
        if [[ $2 == '-f' ]] || [[ $2 == '--file' ]]; then
            if [[ ! -n "$3" ]]; then
                echo ">> Invalid path file !!!"
                exit 0
            fi
            input=$3
        fi

        echo "=========================================================="
        echo "||                  STOP ALL SERVICES BENCHMARK               ||"
        echo "==========================================================\n"

        while read line || [[ -n "$line" ]]; do
            items=$(echo $line | tr ":" " ")
            host=${items[0]}
            path=${items[1]}

            echo ">> Stop benchmark on $host ...."
            echo ">> Deploy location in $path"
            ssh -nt serverdeploy@$host "cd $path; ./runserver.sh stop" 
            sleep 5
            echo ">> Stop BENCHMARK on $host DONE"
            echo "\n==========================================================\n"
        done < $input

        echo "=========================================================="
        echo "||              STOP ALL SERVICES BENCHMARK DONE              ||"
        echo "==========================================================\n"
        ;;

    --pull|-p)
        src=10.20.11.6:/myserver/dev/benchmark-api
        dest=./source

        if [[ -n "$2" ]]; then
            src=$2
        fi

        if [[ -n "$3" ]]; then
            dest=$3
        fi

        echo "=========================================================="
        echo "||                PULL SOURCE SERVICE BENCHMARK               ||"
        echo "==========================================================\n"

        rm -rf dest
        echo ">> Pull source benchmark from $src to $dest ...."

        rsync -avzP serverdeploy@$src $dest

        echo "=========================================================="
        echo "||               PULL SOURCE SERVICE BENCHMARK DONE           ||"
        echo "==========================================================\n"
        ;;

    --deploy|-d)
        input=./config-api.txt
        src=./source/benchmark-api
        if [[ -n "$2" ]]; then
            src=$2
        fi
        if [[ $3 == '-f' ]] || [[ $3 == '--file' ]]; then
            if [[ ! -n "$4" ]]; then
                echo ">> Invalid path file !!!"
                exit 0
            fi
            input=$4
        fi
        
        echo "=========================================================="
        echo "||                DEPLOY SOURCE SERVICE BENCHMARK             ||"
        echo "==========================================================\n"

        while read  dest || [[ -n "$dest" ]]; do
            echo ">> Deploy benchmark from $src to $dest ...."

            items=$(echo $dest | tr ":" " ")
            host=${items[0]}
            path=${items[1]}

            ssh -nt serverdeploy@$host  "cd "$path/benchmark-api"; rm bin/*; ./runserver_bk.sh stop"
            sleep 10
            rsync -avzP $src serverdeploy@$dest

            echo ">> Run benchmark on $dest ...."
            echo ">> Deploy location in "$dest" "
            ssh -nt serverdeploy@$host "cd "$path/benchmark-api"; ./runserver_bk.sh start"
            sleep 10
            echo ">> Run BENCHMARK on $dest DONE"
        done < $input

        echo "=========================================================="
        echo "||                DEPLOY SOURCE SERVICE BENCHMARK  DONE        ||"
        echo "==========================================================\n"
        ;;

    -pd)
        src=10.20.11.56:/myserver/benchmark/benchmark-api
        dest=10.20.11.56:/myserver/benchmark-1/benchmark-api

        if [[ -n "$2" ]] && [[ ! $# -eq 3 ]]; then
            echo ">> Not enought arguments"
            exit 0
        fi

        if [[ -n "$2" ]]; then
            src=$2
        fi

        if [[ -n "$3" ]]; then
            dest=$3
        fi

        $0 -p $src
        $0 -d ./source/benchmark-api/* $dest
        ;;

    --tail|-t)
        src=10.20.11.56:/myserver/benchmark/benchmark-api
        line=100
        
        if [[ -n "$2" ]] && [[ ! $# -eq 3 ]]; then
            echo ">> Not enought arguments"
            exit 0
        fi

        if [[ -n "$2" ]]; then
            src=$2
        fi

        if [[ -n "$3" ]]; then
            line=$3
        fi

        items=$(echo $src | tr ":" " ")
        server=${items[0]}
        path=${items[1]}

        echo "server"
        ssh -nt serverdeploy@$server "tail -"$line"f $path/log/benchmark-api.log"
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