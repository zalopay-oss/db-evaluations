# New SQL Plan Test

- [New SQL Plan Test](#new-sql-plan-test)
  - [1. Objective](#1objective)
  - [2. Tools](#2-tools)
  - [3. Classification test](#3classification-test)
    - [3.1 DMLs](#31-dmls)
    - [3.2 OLTP](#32-oltp)
      - [3.2.1 OLTP_READ_ONLY](#321-oltp_read_only)
      - [3.2.2 OLTP_Write_Only](#322-oltp_write_only)
      - [3.2.3 OLTP_READ_WRITE](#323-oltp_read_write)
      - [3.2.4 OLTP_POINT_SELECT](#324-oltp_point_select)
      - [3.2.5 OLTP_INSERT](#325-oltp_insert)
      - [3.2.6 OLTP_UPDATE_INDEX](#326-oltp_update_index)
      - [3.2.7 OLTP_UPDATE_NON_INDEX](#327-oltp_update_non_index)
      - [3.2.8 OLTP_DELETE](#328-oltp_delete)
    - [3.3 OLAP](#33-olap)
  - [4. Benchmark](#4-benchmark)
  - [Test env](#test-env)

## 1. Objective

- Provide general test plan for 3 databases: TiDB, YugabyteDB and CockroachDB. The aim of this test plan is to ensure correctness and equality while comparing different databases.

- Tests are designed on the general template but different input data. Data can be tuned to optimize each kind of database.

## 2. Tools

Using available tools such as YCSB, sysbench to run benchmarks with pre-defined tests and workloads.

## 3. Classification test

Tests are categorized into DML, OLTP, OLAP,...

-   DMLs includes Read, Insert, Update, Read/Update, Read/Insert/Update operations

-   OLTP

-   OLAP includes Join, Count, Sum, GroupBy, OrderBy operations

-   Consistency: run tests on cases when network partition, node crash,...

### 3.1 DMLs

Using YCSB and YCSB's available pre-defined workloads to benchmark. The aim is to evaluate serving capability of database through:

-   Throughput: operation per second

-   Latency: P99, P95

Table structure:

```sql
CREATE TABLE sbtest(

YCSB_KEY VARCHAR(255) PRIMARY KEY,

FIELD0 CHAR(120) NOT NULL, FIELD1 CHAR(120) NOT NULL,

FIELD2 CHAR(120) NOT NULL, FIELD3 CHAR(120) NOT NULL,

FIELD4 CHAR(120) NOT NULL, FIELD5 CHAR(120) NOT NULL,

FIELD6 CHAR(120) NOT NULL, FIELD7 CHAR(120) NOT NULL,

FIELD8 CHAR(120) NOT NULL);
```

Workload data:

-   Init data (**recordcount**): 30,000,000 records

-   Data generation:

    -   Data of each field is generated randomly under 120 bytes length ASCII string format.

    -   Primary field is generated consecutively with format "user123", "user124" when initializing data in order to choose data in select and update workloads. When running insert workload, primary ket is generated randomly which is not duplicate with old keys.

-   Data selecting (**requestdistribution**): Uniform ( all records have the same selecting ratio).

**Workloads:**

**Workload A: Heavy workload for update operation**

- Description: Combine 50% read and 50% write.
  
**Workload B: Read mostly workload**

- Description: Combine 95% read và 5% write. We need to custom read operation (select range or select point).


**Workload C: Read-only**

- Description: Contain only read operations. Need to custom select point or select range like workload B.

Proceed:

1.  Get randomly an id

2.  Read record corresponding to that id in the database.


**Workload D: Read the latest workload**

- Description: Read records recently inserted in database.

Proceed:

1.  Insert one record to database

2.  Read record recently inserted

3.  Repeat two above steps until reaching 1000000 records.

**Workload E: Short ranges**

- Description: Read range instead of reading one record point.

Proceed:

1.  Random range amount (min value, max value)

2.  Select records in that range amount

Usecase: Read account log in time range, or select account in.

**Workload F: Read-modify-write**

- Description: Read one record then modify it, finally update that change.

Proceed:

1.  Selecting randomly 1 record within 1000000 records

2.  Change 1 filed of that record, update that record in database

**Custom workload:**

- Custom workload to fit with specific problems. YCSB allows creating new
workload.

Read more: <https://github.com/brianfrankcooper/YCSB/wiki/Implementing-New-Workloads>

### 3.2 OLTP

Evaluate:

-   Throughput: Transaction per second

-   Latency: P99, P95

Define additional bank test to test consistency of each kind of database.

Table structure:

```sql
CREATE TABLE sbtest(

id VARCHAR(255) PRIMARY KEY,

amount BIGINT(20) NOT NULL,

FIELD0 INTEGER DEFAULT '0' NOT NULL, FIELD1 CHAR(120) NOT NULL,

FIELD2 CHAR(120) NOT NULL, FIELD3 CHAR(120) NOT NULL,

FIELD4 CHAR(120) NOT NULL, FIELD5 CHAR(120) NOT NULL,

FIELD6 CHAR(120) NOT NULL, FIELD7 CHAR(120) NOT NULL,

FIELD8 CHAR(120) NOT NULL),

KEY (FIELD0));
```

Workload data:

-   Init data: 30,000,000 records

-   Data generation:

    -   Primary field, FIELD0 are generated consecutively with format **"abc123"** while initializing data in order to choose data for select and update workloads. When running insert workload, primary key is generated randomly that is not duplicate with old keys.

    -   FILED0 is the secondary key that increases consecutively.

    -   Data of each field is generated randomly under **120 bytes length ASCII string format.**

-   Data selecting: Uniform (All records have the same selecting ratio).

General transaction: 

```sql
begin();

...

execute_statments()

...

commit();

```

Contains the following tests:

#### 3.2.1 OLTP_READ_ONLY

Contain statements:

-   Point selects

-   Simple ranges (optional)

-   Sum ranges  (optional)

-   Order ranges  (optional)

-   Distinct range  (optional)

**a. Point selects**

-   Define number of Point SELECT queries in each transaction by modifying config **point_selects** (default value = 10)**.**

-   Statement  definition:

```sql
SELECT * FROM sbtest WHERE id = A;
```

A is a random value in initialized data.

**b. Simple ranges**

-   Define number of simple ranges SELECT queries in each mỗi transaction by modifying config **simple_ranges **(default value = 1)**.**

-   Statement definition:

```sql
SELECT * FROM sbtest WHERE id BETWEEN A AND B
```

A, B  are random values in initialized data.

**c. Sum ranges**

-   Define number of SELECT SUM() queries in each transaction by modifying config **sum_ranges** (default value = 1).

-   Statement definition:

```sql
SELECT SUM(amount) FROM sbtest WHERE id BETWEEN A AND B
```

A, B  are random values in initialized data.

**d. Order ranges**

-   Define number of SELECT ORDER BY queries in each transaction by modifying config **order_ranges** (default value = 1).

-   Statement definition:

```sql
SELECT * FROM sbtest WHERE id BETWEEN A AND B ORDER BY FIELD1
```

A, B  are random values in initialized data.

**e. Distinct range**

-   Define number of ELECT DISTINCT queries in each transaction by modifying config **distinct_ranges** (default value = 1).

-   Statement definition:

```sql
SELECT DISTINCT FIELD1 FROM sbtest WHERE id BETWEEN A AND B ORDER BY FIELD2
```

A, B  are random values in initialized data.

#### 3.2.2 OLTP_Write_Only

Contain statements:

-   Index updates

-   Non-index updates

-   Delete inserts

**a. Index updates**

-   Define number of UPDATE index queries in each transaction by modifying config **index_updates **(default value = 1).

-   Statement definition:

```sql
UPDATE sbtest SET FIELD0 = FIELD0 + 1 WHERE id = A
```

A is a random value in initialized data.

**b. Non-index updates**

-   Define number of UPDATE non-index queries in each transaction by modifying config **non_index_updates** (default value = 1).

-   Statement define:

```sql
UPDATE sbtest SET FIELD1 = B WHERE id = A
```

A is a random value in initialized data. B is a random value.

**c. Delete, inserts**

-   Define number of DELETE/INSERT queries mixed in each transaction by modifying config **delete_inserts** (default value = 1).

-   Statement definition:

```sql
DELETE FROM sbtest WHERE id = A

INSERT INTO sbtest (id, amount, FIELD0, FIELD1, ..., FIELD8) VALUES (A, B, C, D,
..., E)

```

A, B, C, D, E are random values

#### 3.2.3 OLTP_READ_WRITE

Contain statements:

-   Point selects

-   Simple ranges (optional)

-   Sum ranges (optional)

-   Order ranges (optional)

-   Distinct range (optional)

-   Index updates

-   Non-index updates

-   Delete, inserts

Statements:

-   Point selects, Simple ranges, Sum ranges, Order ranges, Distinct range like **OLTP_READ_ONLY.**

-   Index updates, Non-index updates, Delete, inserts like **OLTP_WRITE_ONLY.**

#### 3.2.4 OLTP_POINT_SELECT

Not use transaction, contain statement:

-   Point selects

**Point selects**

-   Define number of point SELECT queries in each transaction by modifying config **point_selects** (default value = 10)**.**

-   Statement  definition:

```sql
SELECT * FROM sbtest WHERE id = A;
```

A is a random value in initialized data.

#### 3.2.5 OLTP_INSERT

Not use transaction, contain statement:

-   Insert

**Insert**

```sql
INSERT INTO sbtest (id, amount, FIELD0, FIELD1, ..., FIELD8) VALUES (A, B, C, D, ..., E)
```

#### 3.2.6 OLTP_UPDATE_INDEX

Not use transaction, contain statement:

-   Index updates

**Index updates**

-   Define number of UPDATE index queries in each transaction by modifying config **index_updates **(default value = 1).

-   Statement definition:

```sql
UPDATE sbtest SET FIELD0 = FIELD0 + 1 WHERE id = A
```

A is a random value in initialized data.

#### 3.2.7 OLTP_UPDATE_NON_INDEX

Not use transaction, contain statement:

-   Non-index updates

**Non-index updates**

-   Define number of UPDATE non-index queries in each transaction by modifying config **non_index_updates** (default value = 1).

-   Statement definition:

```sql
UPDATE sbtest SET FIELD1 = B WHERE id = A
```

A is a random value in initialized data. B is a random value.

#### 3.2.8 OLTP_DELETE

Not use transaction, contain statement:

-   deletes

**Deletes**

-   Statement definition:

```sql
DELETE FROM sbtest WHERE id = A
```

A is a random value in initialized data.

### 3.3 OLAP

Define new custom workload in YCSB to run benchmarks.

## 4. Benchmark

In order to ensure fairly benchmark, we need to apply tests with the same hardware configurations  for each kind of database:

## Test env

Database Machine info (3 nodes):

| **Type** | **Name** |
|----------|----------|
| OS       | Centos 7 |
| RAM      | 64GB     |
| CPU      | 32 Core  |
| Disk     | SSD      |
| NIC      |          |

Workload machine info (3 nodes):

| **Type** | **Name** |
|----------|----------|
| OS       | Centos 7 |
| RAM      | 64GB     |
| CPU      | 16 Core  |
| Disk     | SSD      |
| NIC      |          |
