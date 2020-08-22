export JAVA_HOME=/myserver/jdk1.8.0_181

case $1 in
    --load|-l)
        echo "=========================================================="
        echo "||                       LOAD DATA                      ||"
        echo "==========================================================\n"
        java -cp jdbc-binding/lib/jdbc-binding-0.18.0-SNAPSHOT.jar:mysql-connector-java-5.1.37-bin.jar site.ycsb.db.JdbcDBCreateTable -P db-yuga.properties -n sbtest
        echo "START TIME $(date +'%d-%m-%Y %H:%M:%S')"
        bin/ycsb load jdbc -P workloads/workload$2 -P db-tidb.properties -p threadcount=$3 -cp mysql-connector-java-5.1.37-bin.jar
        echo "END TIME $(date +'%d-%m-%Y %H:%M:%S')"

        echo "=========================================================="
        echo "||                   LOAD DATA DONE                     ||"
        echo "==========================================================\n"
        ;;
    --run|-r)
        echo "=========================================================="
        echo "||                       RUN DATA                       ||"
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
        echo "START TIME $(date +'%d-%m-%Y %H:%M:%S')"
        bin/ycsb run jdbc -P workloads/workload$2 -s -P db-tidb.properties -p threadcount=$3 -p operationcount=$4 -cp mysql-connector-java-5.1.37-bin.jar
        echo "END TIME $(date +'%d-%m-%Y %H:%M:%S')"

        echo "=========================================================="
        echo "||                    RUN DATA DONE                     ||"
        echo "==========================================================\n"
        ;;
esac
