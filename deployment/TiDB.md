# TiDB

## 1. Deployment
Mô hình deploy benchmark:  
<div align="center">
    <img src="../images/model-deploy-tidb.png">
</div>

**Lưu ý:**
- Topology lý tưởng là **3 cụm**, mỗi cụm có **1 TiDB** server, **1 PD** server và **1 TiKV** server.  
- Số lượng connection chạy đồng thời tới cụm TiDB không nên quá **500**.

## 2. Test environment

### 2.1 Cấu hình hệ điều hành
|Linux OS platform|Version|
|--|--|
|CentOS Linux|  7.7.1908

### 2.2 Cấu hình server
Component| CPU| Memory| Disk type| Instance Number
|--|--|--|--|--|
TiDB|   32 core|    64 GB|  HDD|    3 (10.20.11.56-57-58)
PD| 32 core|    64 GB|  SSD|    3 (10.20.11.56-54-55)
TiKV|  32 core|  64 GB|   SSD|   4 (10.20.11.56-54-55-56)

**Lưu ý:**
- Instance của TiDB và PD có thể được deploy chung trên 1 server.  
- Đối với TiKV server, nên sử dụng NVWe SSDs để đảm bảo tốc độ đọc/ghi nhanh.
- Không có yêu cầu đặc biệt với loại đĩa, dung lượng cho storage của TiDB server vì nó chỉ dùng để lưu server logs.
- Giả sử server test có 32 bảng, mỗi bảng có hơn 10 triệu dòng thì kích thước đĩa cho TiKV server nên lớn hơn 512 GB.
- Nên giữ kích thước đĩa của TiKV trong khoảng 2TB nếu dùng PCIe SSDs hay 1.5TB nếu dùng SSDs thông thường.

## 3. Test configuration

### 3.1 TiDB configuration  
- Xem file config mặc định của TiBD [ở đây](https://github.com/pingcap/tidb/blob/master/config/config.toml.example). 
- Đặt **log level cao nhất** để tăng performance cho TiDB. Giá trị default là **info**.  
- Một số flag có thể tunning:

##### [prepared-plan-cache]:  

Type|Default|Description|
--|--|--| 
enabled|false|Bật prepared plan cache để giảm chi phí khi thực hiện tối ưu execution plan.
capacity|100|Số lượng cached statements
memory-guard-ratio|0.1|Ngăn chặn `performance.max-memory` vượt ngưỡng<br>Giá trị min là 0, max là 1
oom-action|log| Khi thực hiện SQL query vượt ngưỡng memory cho phép:<br> - oom-action="log": sẽ chỉ in ra log. <br> - oom-action="cancel: in ra log và huỷ thực hiện SQL query.
max-server-connections| 0| maximum số lượng client connection đồng thời tới TiDB. Mặc định là không giới hạn.



##### [performance]:

Type|Default|Description|
--|--|--|
max-procs|0|Số lượng CPUs. Nếu dùng giá trị `0`, mặc định sử dụng tất cả CPUs trên machine.  
max-memory|0|maximum memory cho Prepared Least Recently Used (LRU) cache <br> Phải bật `prepared-plan-cached` mới dùng config này
run-auto-analyze|true|Config cho TiDB thực hiện phân tích tự động
tcp-keep-alive|false| enable keepalive connection với TiDB
stats-lease| 3s| Định kì reloading statistics, update số lượng row của table, kiểm tra có cần chạy automatic analysis.
run-auto-analyze| true| enable thực thi automatic analysis.

##### [tikv-client]:

Type|Default|Description|
--|--|--|
grpc-connection-count| 16| maximum số lượng connection established với TiKV.
grpc-keepalive-time| 10 (second)| Thời gian giữ kết nối RPC giữa TiDB và TiKV. Nếu không có request từ TiDB tới TikV, TiDB sẽ gửi ping xuống TiKV.
grpc-keepalive-timeout| 3 (second)| Timeout RPC keepalive giữa TiDB và TiKV


Chi tiết thêm xem tại [đây](https://pingcap.com/docs/stable/tidb-configuration-file/)  

### 3.2 TiKV configuration  
- File config mặc định nằm ở `etc/config-template.toml`. Muốn kích hoạt, ta cần đổi tên thành `config.toml`  

- Đối với Sysbench test, tỉ lệ Default Column Families so với Write Column Families là hằng số: **4 : 1**
Ví dụ deploy TiKV trên máy 40GB:

```yml
log-level = "error"
[raftstore]
sync-log = false
[rocksdb.defaultcf]
block-cache-size = "24GB"
[rocksdb.writecf]
block-cache-size = "6GB"
```  


### 3.3 Configuration parameters  

#### 3.3.1 TiDB

##### [prepared-plan-cache]:  

Type|Default|Description|
--|--|--|
capacity|100|Số lượng cached statements
memory-guard-ratio|0.1|Ngăn chặn `performance.max-memory` vượt ngưỡng<br>Giá trị min là 0, max là 1   

##### [performance]:  

Type|Default|Description|
--|--|--|
max-procs|0|Số lượng CPUs. Nếu dùng giá trị `0`, mặc định sử dụng tất cả CPUs trên machine.  
max-memory|0|maximum memory cho Prepared Least Recently Used (LRU) cache <br> Phải bật `prepared-plan-cached` mới dùng config này
stat-lease|3s|Time interval để reload các thống kê.  
run-auto-analyze|true|Config cho TiDB thực hiện phân tích tự động

##### [txn-local-latches]  
Type|Default|Description|
--|--|--|
enanled|false|Phát hiện transaction conflict để giảm số lần retry của transaction commits gây ra bởi write conflicts.  


Chi tiết thêm xem tại [đây](https://pingcap.com/docs/stable/tidb-configuration-file/)  

#### 3.3.2 TiKV
- Một số flags có thể tunning:

##### [storage.block-cache]
Parameter|Default|Description|
--|--|--|
|shared|true|Kích hoạt sharing block cache|  
|capacity|45% tổng memory|Kích thước cho shared block cache|  

##### [rocksdb.defaultcf]
Parameter|Default|Description|
--|--|--|
block-cache-size|Total memory machine / 4|Cache size cho RocksDB block  
disable-block-cache| fasle| enable or disable block cache.

##### [rocksdb.writecf]  
Parameter|Default|Description|
--|--|--|
block-cache-size|Total machine memory * 15%|Kích thước size của CF write 

Chi tiết xem thêm tại [đây](https://pingcap.com/docs/stable/tikv-configuration-file/)  

### 3.3 PD Configuration
##### [schedule]  

Parameter|Default|Description|
--|--|--|
max-merge-region-size|20|Megre regions với region bên cạnh khi region size nhỏ hơn giá trị được set|  
max-merge-region-keys|200000|Megre Regions với Region bên cạnh khi Region key nhỏ hơn giá trị được set
merge-schedule-limit|8|Số lượng scheduling tasks cho Region Merge thực hiện đồng thời
max-replicas| 3| Số lượng replicas.

## 4. Best practices  

### 4.1 Tuning TiKV  

Số lượng lớn Region trên một TiKV instance ảnh hưởng lớn đến performance. Do đó, ta có giải quyết điều đó bằng một trong hai hướng:  
- Giảm số lượng Regions trên một TiKV instance.  
- Giảm số lượng messsage đến cho một Region.  

#### 4.1.1 Tăng conccurency cho Raftstore  

Mặc định, `raftstore.store-pool-size` đặt là `2`. Ta có thể tăng giá trị này để tránh bottleneck cho Raftstore nhưng không tăng quá cao để tránh thread switching.  

#### 4.1.2 Bật `Region Merge`  

Sau khi drop data hay thực hiện `Drop Table` hay `Truncate Table`, ta có thể merge các Region nhỏ hay thậm chí Region trống để giảm chi phí tiêu thụ.  
Tuy nhiên, chức năng này được bật tự động kể từ phiên bản 3.0   
Các parameters liên quan đến config cho region merge xem ở mục [3.3](#33-pd-configuration)  

#### 4.1.3 Tăng TiKV instance  

Ta có thể tăng số lượng TiKV instance trên 1 machine hay tăng số lượng machine trong một cụm.  

#### 4.1.4 Chỉnh `raft-base-tick-interval`  
Đây là hướng giảm message đến tới một Region. Tham số này là sau mỗi khoảng thời gian nhất định, Raftstore gửi messsage tới Raft state machine của mỗi Region. Tăng giá trị này sẽ làm giảm số lượng message đến Region nhưng tốn nhiều thời gian hơn để detect leader failure.  

```
[raftstore]
raft-base-tick-interval = "2s"
```

#### 4.1.5 Avoid hotspot - highly concurrent write  
TiDB hỗ trợ tính năng Split Region:  

```sql
SPLIT TABLE table_name [INDEX index_name] BETWEEN (lower_value) AND (upper_value) REGIONS region_num
```  

Có thể check lại Region distribution sử dụng script `table-regions.py`:  

```sh
python table-regions.py --host DB_HOST --port DB_PORT DB_NAME TABLE_NAME
```  
 
## 5. References  

[Software and Hardware Recommendations](https://pingcap.com/docs/dev/hardware-and-software-requirements/)  

[How to Test TiDB Using Sysbench](https://pingcap.com/docs/v2.1/benchmark/benchmark-tidb-using-sysbench/)  

[How to Run TPC-C Test on TiDB](https://pingcap.com/docs/v3.0/benchmark/benchmark-tidb-using-tpcc/)  

[Building, Running, and Benchmarking TiKV and TiDB](https://pingcap.com/blog/building-running-and-benchmarking-tikv-and-tidb/)  

[Tune TiKV Performance](https://pingcap.com/docs/v2.1/tune-tikv-performance/)  

[TiKV configuration file](https://pingcap.com/docs/stable/tikv-configuration-file/)  

[TiDB configuration file](https://pingcap.com/docs/stable/tidb-configuration-file/)  

[Higly concurrent write best practices](https://pingcap.com/docs/stable/best-practices/high-concurrency-best-practices/)

[TiKV performance tuning with massive regions](https://pingcap.com/docs/stable/best-practices/massive-regions-best-practices/)