#!/bin/bash
FILE_RUN=""
TABLE=1
TABLE_SIZE=1000000
CREATE_SEC=false

case $1 in
    --prepare|-pp)
        echo "=========================================================="
        echo "||                     PREPARE DATA                     ||"
        echo "==========================================================\n"

        sysbench ./lua/oltp_clean.lua --config-file=config --tables=$TABLE --table-size=$TABLE_SIZE cleanup
        sysbench ./lua/oltp_prepare.lua --config-file=config  --tables=$TABLE --table-size=$TABLE_SIZE --create_secondary=$CREATE_SEC prepare
        sysbench ./lua/oltp_parallel_insert.lua --config-file=config --tables=$TABLE --table-size=$TABLE_SIZE --range_insert=$2 --events=64 --percentile=99 run

        echo "=========================================================="
        echo "||                PREPARE DATA DONE                     ||"
        echo "==========================================================\n"
        ;;

    --warmup|-wu)
        echo "=========================================================="
        echo "||                     WARM UP DATABASE                 ||"
        echo "==========================================================\n"
  
        sysbench --config-file=config --test=./lua/oltp_warmup.lua --tables=$TABLE --table-size=$TABLE_SIZE prewarm

        echo "=========================================================="
        echo "||                WARM UP DATABASE DONE                 ||"
        echo "==========================================================\n"
        ;;
    
    --run | -r)
        echo "=========================================================="
        echo "||                    RUN BENCHMARK                       ||"
        echo "==========================================================\n"

        case $2 in
            1)
                FILE_RUN="oltp_read_only"
                echo "Benchmark read only"
                ;;
            2)
                FILE_RUN="oltp_write_only"
                echo "Benchmark write only"
                ;;
            3)
                FILE_RUN="oltp_read_write"
                echo "Benchmark read write"
                ;;
            4)
                FILE_RUN="oltp_point_select"
                echo "Benchmark point select"
                ;;
            5)
                FILE_RUN="oltp_insert"
                echo "Benchmark insert"
                sysbench ./lua/oltp_clean.lua --config-file=config --tables=$TABLE --table-size=$TABLE_SIZE cleanup
                sysbench ./lua/oltp_prepare.lua --config-file=config  --tables=$TABLE --table-size=$TABLE_SIZE --create_secondary=$CREATE_SEC prepare
                ;;
            6)
                FILE_RUN="oltp_update_index"
                echo "Benchmark update index"
                ;;
            7)
                FILE_RUN="oltp_update_non_index"
                echo "Benchmark update non index"
                ;;
            8)
                FILE_RUN="oltp_delete"
                echo "Benchmark delete"
                ;;
            9)
                FILE_RUN="oltp_point_select_txn"
                echo "Benchmark point select transaction"
                ;;
            10)
                FILE_RUN="oltp_delete_insert_txn"
                echo "Benchmark delete insert transaction"
                ;;
            *)
                FILE_RUN="oltp_point_select"
                echo "Benchmark point select"
                ;;
        esac
        echo "START TIME $(date +'%d-%m-%Y %H:%M:%S')"
        sysbench ./lua/$FILE_RUN --range_insert=$3 --config-file=config --tables=$TABLE --table-size=$TABLE_SIZE --percentile=99 --threads=$4 run
        echo "END TIME $(date +'%d-%m-%Y %H:%M:%S')"
        echo "=========================================================="
        echo "||                     RUN BENCHMARK DONE               ||"
        echo "==========================================================\n"
        ;;
    --clear|-cl)
        echo "=========================================================="
        echo "||                      CLEAR DATA                      ||"
        echo "==========================================================\n"
  
        sysbench --config-file=config --test=./lua/oltp_clean.lua --tables=$TABLE --table-size=$TABLE_SIZE cleanup

        echo "=========================================================="
        echo "||                 CLEAR DATA DONE                      ||"
        echo "==========================================================\n"
        ;;

    --oltp-help|oh)
        sysbench ./oltp_common.lua help
        ;;

    --help|-h)
        echo "usage: ./run.sh [options]"
        echo "--prepare, -pp                    Prepare data"
        echo "--prewarm, -pw                    Warm up database"   
        echo "--run, -r                         Run benchmark"     
        echo "--clear, -cl                      Clear data"    
        echo "========================="
        echo "map file [number] - [file_name]"
        echo "1. oltp_read_only"
        echo "2. oltp_write_only"
        echo "3. oltp_read_write"
        echo "4. oltp_point_select"
        echo "5. oltp_insert"
        echo "6. oltp_update_index"
        echo "7. oltp_update_non_index"
        echo "8. oltp_delete"
        ;;       
    *)
		echo ">> Sorry, I don't support"
		;;
esac
