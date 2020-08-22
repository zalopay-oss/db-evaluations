require("oltp_common")
-- Prepare the dataset. This command supports parallel execution, i.e. will
-- benefit from executing with --threads > 1 as long as --tables > 1
print_lock = 0

function cmd_prepare()
   local drv = sysbench.sql.driver()
   local con = drv:connect()

   for i = sysbench.tid % sysbench.opt.threads + 1, sysbench.opt.tables, sysbench.opt.threads do
      create_table(drv, con, i)
   end
end


function create_table(drv, con, table_num)   
   local id_index_def, id_def
   local engine_def = ""
   local extra_table_options = ""
   local query

   if sysbench.opt.secondary then
      id_index_def = "KEY xid"
   else
      id_index_def = "PRIMARY KEY"
   end

   if drv:name() == "mysql" or drv:name() == "attachsql" or
      drv:name() == "drizzle"
   then
      if sysbench.opt.auto_inc then
         id_def = "INTEGER NOT NULL AUTO_INCREMENT"
      else
         id_def = "INTEGER NOT NULL"
      end
      engine_def = "/*! ENGINE = " .. sysbench.opt.mysql_storage_engine .. " */"
      extra_table_options = mysql_table_options or ""
   elseif drv:name() == "pgsql"
   then
      if not sysbench.opt.auto_inc then
         id_def = "INTEGER NOT NULL"
      elseif pgsql_variant == 'redshift' then
         id_def = "INTEGER IDENTITY(1,1)"
      else
         id_def = "SERIAL"
      end
   else
      error("Unsupported database driver:" .. drv:name())
   end

   local table_num_str = ""
   table_num_str = tostring(table_num)
   -- if table_num > 1 then
   --    table_num_str = tostring(table_num)
   -- end
   -- log_info("Creating database sbtest")
   -- con:query("CREATE DATABASE IF NOT EXISTS sbtest")
   -- con:query("USE sbtest")

  -- prefix = os.date("%Y/%m/%d %H:%M:%S [info] ")
   log_info(string.format("Creating table 'sbtest%s'...", table_num_str))
   
   query = string.format([[
      CREATE TABLE sbtest%s (
         id VARCHAR(255),
         amount BIGINT(20) NOT NULL,
         FIELD0 INTEGER DEFAULT '0' NOT NULL, FIELD1 CHAR(120) NOT NULL,
         FIELD2 CHAR(120) NOT NULL, FIELD3 CHAR(120) NOT NULL,
         FIELD4 CHAR(120) NOT NULL, FIELD5 CHAR(120) NOT NULL,
         FIELD6 CHAR(120) NOT NULL, FIELD7 CHAR(120) NOT NULL,
         FIELD8 CHAR(120) NOT NULL, %s (id)
      ) %s %s]],
            table_num_str, id_index_def, engine_def, extra_table_options)

   con:query(query)

   if sysbench.opt.create_secondary then
      prefix = os.date("%Y/%m/%d %H:%M:%S [info] ")
      log_info(string.format(prefix .. "Creating a secondary index on 'sbtest%s'...",
                        table_num_str))
      con:query(string.format("CREATE INDEX FIELD0_%d ON sbtest%s(FIELD0)",
                              table_num, table_num_str))
   end
end

function log_info(msg)
   prefix = os.date("%Y/%m/%d %H:%M:%S [info] ")
   while print_lock > 0 do
   end
   print_lock = 1
   print(prefix .. msg)
   print_lock = 0
end