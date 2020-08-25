# Database re-evaluation

<div align="center">
    <img src="./images/benchmark.jpg">
</div>

- [Database re-evaluation](#database-re-evaluation)
  - [1. Overview](#1-overview)
  - [2. Why](#2-why)
  - [3. Documents](#3-documents)
  - [4. Contributors](#4-contributors)

## 1. Overview
A place to store documents introducing tools: Sysbench, YCSB, TPC-C and script to run benchmark. Moreover, we write model deployment of databases: TiDB, YugabyteDB, CockroachDB.

## 2. Why
*Why are we doing this ?*
- We have researched and interested in two distributed databases: [TiDB](https://github.com/pingcap/tidb) and [YugabyteDB](https://www.yugabyte.com/). Each database has its strengths in specific use cases so we need to clearly define  **pros and cons** in order to apply in the organization's uses. 
- We also went through the benchmarks of [GO-JEK’s](https://blog.yugabyte.com/go-jeks-performance-benchmarking-of-cockroachdb-tidb-yugabyte-db-on-kubernetes/), [Jepsen](https://blog.yugabyte.com/announcing-yugabyte-db-2-0-ga-jepsen-tested-high-performance-distributed-sql/), [TiDB benchmark](https://pingcap.com/blog/building-running-and-benchmarking-tikv-and-tidb#benchmarking), [YugabyteDB benchmark](https://blog.yugabyte.com/category/performance-benchmarks/). However, they do not provide a clear model setup, execution plan,... which may lead to unfair evaluation. In addition, the benchmark environment in their reports is not adaptable to our infrastructure. Therefore, we need a detailed test plan and perform benchmark databases with suitable hardware configuration to match our reality.

## 3. Documents

Can see detail:
- [Sysbench](./sysbench/README.md)
- [YCSB](./ycsb/README.md)
- [TPC-C](./tpc-c/README.md)
- [Deployment TiDB](./deployment/TiDB.md)
- [Deployment YugabyteDB](./deployment/YugabyteDB.md)
- [Deployment CockroachDB](./deployment/CockroachDB.md)

Result benchmark:
  - [Plan benchmark](./docs/plan-test.md)
  - [Detail result benchmark Tidb with Sysbench](./docs/result-benchmark/sysbench-tidb.md)
  - [Detail result benchmark Tidb with YCSB](./docs/result-benchmark/ycsb-tidb.md)
  - [Detail result benchmark YugabyteDB with Sysbench](./docs/result-benchmark/sysbench-yuga.md)
  - [Detail result benchmark YugabyteDB with YCSB](./docs/result-benchmark/ycsb-yuga.md)

## 4. Contributors

| [<img src="https://avatars1.githubusercontent.com/u/38773351?s=460&v=4" width="100px;"/><br /><sub><b>phamtai97</b></sub>](https://github.com/phamtai97) | [<img src="https://avatars0.githubusercontent.com/u/27961917?s=400&u=976e473f167949563cdf10b1706e08ca259cc552&v=4" width="100px;"/><br /><sub><b>Quyen Pham</b></sub>](https://github.com/ptq204) | [<img src="https://avatars3.githubusercontent.com/u/13825568?s=400&u=5e922e1f04d9d3d5674943014c3fe3ec95c330f7&v=4" width="100px;"/><br /><sub><b>Võ Tiến Thiều</b></sub>](https://github.com/VoxT) | [<img src="https://avatars1.githubusercontent.com/u/3270746?s=460&v=4" width="100px;"/><br /><sub><b>anhldbk</b></sub>](https://github.com/anhldbk) |
| :---------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------------------------------------------: |