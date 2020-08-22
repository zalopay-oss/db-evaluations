require("oltp_common")

 -- Preload the dataset into the server cache. This command supports parallel
 -- execution, i.e. will benefit from executing with --threads > 1 as long as
 -- --tables > 1
 --
 -- PS. Currently, this command is only meaningful for MySQL/InnoDB benchmarks
function cmd_prewarm()
   local drv = sysbench.sql.driver()
   local con = drv:connect()

   assert(drv:name() == "mysql", "prewarm is currently MySQL only")

   -- Do not create on disk tables for subsequent queries
   con:query("SET tmp_table_size=2*1024*1024*1024")
   con:query("SET max_heap_table_size=2*1024*1024*1024")

   for i = sysbench.tid % sysbench.opt.threads + 1, sysbench.opt.tables,
   sysbench.opt.threads do
      local t = "sbtest" .. i
      print("Prewarming table " .. t)
      con:query("ANALYZE TABLE sbtest" .. i)
      con:query(string.format(
                  "SELECT AVG(id) FROM " ..
                     "(SELECT * FROM %s FORCE KEY (PRIMARY) " ..
                     "LIMIT %u) t",
                  t, sysbench.opt.table_size))
      con:query(string.format(
                  "SELECT COUNT(*) FROM " ..
                     "(SELECT * FROM %s WHERE k LIKE '%%0%%' LIMIT %u) t",
                  t, sysbench.opt.table_size))
   end
 end