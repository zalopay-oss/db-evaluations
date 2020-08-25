# Benchmark Database Tool Sysbench
- [Benchmark Database Tool Sysbench](#benchmark-database-tool-sysbench)
  - [Sysbench](#sysbench)
    - [1. Overview](#1-overview)
    - [2. Install](#2-install)
    - [3. Using](#3-using)
      - [3.1 Step prepare Config file](#31-step-prepare-config-file)
      - [3.2 Overview sysbench with lua](#32-overview-sysbench-with-lua)
      - [3.3 Phase prepare](#33-phase-prepare)
      - [3.4 Phase warmup](#34-phase-warmup)
      - [3.5 Phase run](#35-phase-run)
      - [3.6 Phase clean](#36-phase-clean)
    - [4. Run script on client](#4-run-script-on-client)
      - [4.1 Phase clean](#41-phase-clean)
      - [4.2 Phase run](#42-phase-run)
      - [4.3 Phase clean](#43-phase-clean)
      - [4.4 Benchmark continuously](#44-benchmark-continuously)
  - [5. References](#5-references)


## Sysbench
### 1. Overview
[sysbench](https://github.com/akopytov/sysbench) is a scriptable multi-threaded benchmark tool based on LuaJIT.

### 2. Install
On macOS, using Homebrew:
```sh
# Add --with-postgresql if you need PostgreSQL support
$ brew install sysbench
```

Debian/Ubuntu
```sh
$ curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
sudo apt -y install sysbench
```

Note: If Using sysbench benchmark for TiDB, you must install **mysql-client v5.7**.

```sh
$ brew install mysql-client@5.7
```

### 3. Using
#### 3.1 Step prepare Config file
This is an example of the Sysbench configuration file:
```
mysql-host={DB_HOST}
mysql-port=n
mysql-user=user
mysql-password=password
mysql-db=sbtest
time=600
threads={8, 16, 32, 64, 128, 256}
report-interval=10
db-driver=mysql
```

Example:

```sh
mysql-host=localhost
mysql-port=4000
mysql-user=root
mysql-password=password
mysql-db=sbtest
time=600
threads=16
report-interval=10
db-driver=mysql
```

- If using PostgreSQL, replacing mysql to pgsql.
- See full config: https://github.com/akopytov/sysbench#general-command-line-options or run **cmd sysbench --help**.

#### 3.2 Overview sysbench with lua
- Define [oltp_common.lua](./tidb/benchmark/lua/oltp_common.lua) to contains shared scripts for other script. For each test we will define a script .lua.
- Lifecycle run benchmark:
  
<img src="./images/lifecycle.png">

- Phases:
  - **Prepare**: init database, table, rows...
  - **Warnup**: run statment such as **ANALYZE TABLE**, **SUMM**, **AVG**, ... to warmup.
  - **Run**: run benchmark.
  - **Clean**: clean data.

- Each phase, we define script .lua to run.

#### 3.3 Phase prepare
- Create database:
  - Restart MySQL client and execute the following SQL statement to create a database sbtest:
```sql
$ mysql> create database sbtest;
```
- Writing script [oltp_prepare.lua](./tidb/benchmark/lua/oltp_prepare.lua) to prepare data.
- Then, using cmd (stay on server) with `range` follows a format (start_id, end_id). Suppose we want to prepare data on range (0,10000). That means it creates a table with size 10000:  
```sh
#sysbench --config-file=config --test=./lua/oltp_prepare.lua --tables=$TABLE --table-size=$TABLE_SIZE prepare
$ cd ./tidb//benchmark
$ /run.sh -pp 0,10000
```  

**Note:** 
- tables: number of tables will be created in database. It is the same with `TABLE` flag in `run.sh` script.   
- table-size: number of rows will be inserted in each table.
- `range` param will override the `table-size` or `TABLE_SIZE` defined in `run.sh`.  

#### 3.4 Phase warmup
- Writing script [oltp_warmup.lua](./tidb/benchmark/lua/oltp_warmup.lua) to warmup DB.
- Then, using cmd:
```sh
#sysbench --config-file=config --test=./lua/oltp_warmup.lua --tables=$TABLE --table-size=$TABLE_SIZE prewarm
$ cd ./tidb//benchmark
$ ./run.sh -wu
```

#### 3.5 Phase run
- In Each test case, we need to write script .lua to benchmark. Example [oltp_test.lua](benchmark/lua/oltp_test.lua):

```lua
--oltp_test.lua
require("oltp_common")

function prepare_statements()
    print("Call prepare_statements")
end

function event()
    print("Call event")
end
```  
- Lifecyle call func when runing:
  - [function thread_init()](./tidb/benchmark/lua/oltp_common.lua): called by sysbench one time to initialize this script. 
    - Init global variable, thread, connection db, prepare statement,.... 
    - Number of thread defined in file `config`. 
    - In function thread_init(), each thread call function [prepare_statements()](./tidb/benchmark/lua/oltp_test.lua).
  - [function event()](./tidb/benchmark/lua/oltp_test.lua): called by sysbench for each execution.
  - [function thread_done()](./tidb/benchmark/lua/oltp_common.lua): called by sysbench when script is done executing.
    - Close connection DB,...
- Time to run benchmark defined in file `config`.  

Example of one `config` file for `TiDB`:  

```yaml
db-driver=mysql
mysql-host=localhost
mysql-port=4001
mysql-user=mybenchmark
mysql-password=abczyz
mysql-db=sbtest
time=10
threads=64
report-interval=10
```  

For `Yugabyte`, use `pg` drive instead:  

```yaml
db-driver=pgsql
pgsql-host=localhost
pgsql-port=5433
pgsql-user=mybenchmark
pgsql-password=abczyz
pgsql-db=sbtest
time=10
threads=64
report-interval=10
```  

- Then, using cmd:
```sh
#sysbench --config-file=config --test=./lua/$2 --tables=$TABLE --table-size=$TABLE_SIZE run
$ cd ./tidb//benchmark
$ ./run.sh -r $num $range
```  

With `num` is the number_id of the oltp test script. Using `-h` option to check:  

```sh
./run.sh -h

--prepare, -pp                    Prepare data
--prewarm, -pw                    Warm up database
--run, -r                         Run benchmark
--clear, -cl                      Clear data
=========================
map file [number] - [file_name]
1. oltp_read_only
2. oltp_write_only
3. oltp_read_write
4. oltp_point_select
5. oltp_insert
6. oltp_update_index
7. oltp_update_non_index
8. oltp_delete
```  

For example, run `oltp_point_select`:  

```sh
./run.sh -r 4
```  

`range` is provided when we want to run **write** test script on multiple nodes to avoid write conflict. For example, run `oltp_write_only` with id range from 0 to 100000:  

```sh
./run.sh -r 2 0,100000
```  

- See more .lua test scripts: [sysbench lua](https://github.com/pingcap/tidb-bench/tree/cwen/prepared_statement/sysbench/lua)

#### 3.6 Phase clean
- After benchmark, we can clean data.
- Writing script [oltp_clean.lua](./tidb/benchmark/lua/oltp_clean.lua) to clean data.
- Then, using cmd (stay on server):
```sh
#sysbench --config-file=config --test=./lua/oltp_clean.lua --tables=$TABLE --table-size=$TABLE_SIZE cleanup
$ cd ./tidb//benchmark
$ ./run.sh -cl
```  

### 4. Run script on client  

We define config in file `config-run.txt` with a format:  

```
$HOST:$RUN_DIRECTORY_ON_SERVER:$RANGE
```  

For example, we want to run benchmark on two servers parallelly within specific range:  

```txt
10.20.11.57:/myserver/benchmark/sysbench:0,100000
10.20.11.58:/myserver/benchmark/sysbench:100000,200000
```  

#### 4.1 Phase clean  

Run this cmd:  

```sh
./tidb//bench.sh -pp
```  

#### 4.2 Phase run  

Run this cmd:  

```sh
./tidb//bench.sh -r $num
```  

With `num` is the number_id of the oltp test script.  

#### 4.3 Phase clean  

Run this cmd:  

```sh
./tidb//bench.sh -cl
```  

#### 4.4 Benchmark continuously  

Sometimes, we want to automatically run next oltp when current oltp finished.  

To do that, we first locate `bench-continuous.sh` on the directory of benchmark script in the loadtest server. Here is the content of the `bench-continuous.sh` script:  

```sh
#!/bin/bash
for test in 1 2 3 4; do
    t=8
    while [ $t -le 64 ]
    do
        nohup ./run.sh -r $test $1 $t 2>&1 >>sysbench.log
        sleep 15
        t=$(( $t * 2 ))
    done
done
```  

In the above script, the oltp script with id `1, 2, 3, 4` will run respectively.  

The parameter which represents id of oltp script is `test` (ex: 1, 2, 3, 4, ...), and `t` is the number of threads. We can see in the script, `t` doubles for every benchmark and when one test done, it sleeps for 15s.  

`$1` is the range mentioned earlier which is passed by another script.  

Then, on the client, run `bench-continuous-client.sh` script.  

Note that, when running oltp script continuously, we have to remove `threads` flag in the `config` file.  

## 5. References  

- https://github.com/pingcap/docs/blob/master/benchmark/benchmark-tidb-using-sysbench.md

- https://github.com/akopytov/sysbench

- https://mariadb.org/lua-sysbench-crash-course/