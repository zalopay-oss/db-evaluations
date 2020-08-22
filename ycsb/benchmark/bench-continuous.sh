#!/bin/bash
for test in a; do
    t=64
    op=30000000
    while [ $t -le 64 ]
    do  
        # java -cp jdbc-binding/lib/jdbc-binding-0.18.0-SNAPSHOT.jar:postgresql-42.2.14.jar site.ycsb.db.JdbcDBCreateTable -P db-yuga.properties -n sbtest
        # ./run.sh -l $test $t 2>&1 >>ycsb.log
        nohup ./run.sh -r $test $t $op 2>&1 >>ycsb.log
        sleep 15
        t=$(( $t * 2 ))
    done
done