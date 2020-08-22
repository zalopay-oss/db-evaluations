-- Copyright (C) 2006-2018 Alexey Kopytov <akopytov@gmail.com>

-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

-- -----------------------------------------------------------------------------
-- Common code for OLTP benchmarks.
-- -----------------------------------------------------------------------------

function init()
   assert(event ~= nil,
            "this script is meant to be included by other OLTP scripts and " ..
               "should not be called directly.")
   end

   if sysbench.cmdline.command == nil then
   error("Command is required. Supported commands: prepare, prewarm, run, " ..
               "cleanup, help")
end

function thread_init()
   drv = sysbench.sql.driver()
   con = drv:connect()

   -- Create global nested tables for prepared statements and their
   -- parameters. We need a statement and a parameter set for each combination
   -- of connection/table/query
   stmt = {}
   param = {}

   for t = 1, sysbench.opt.tables do
      stmt[t] = {}
      param[t] = {}
   end

   print_lock = 0
   -- print('INIT THREAD')
   -- This function is a 'callback' defined by individual benchmark scripts
   prepare_statements()
end

function thread_done()
   close_statements()
   con:disconnect()
end

-- Re-prepare statements if we have reconnected, which is possible when some of
-- the listed error codes are in the --mysql-ignore-errors list
function sysbench.hooks.before_restart_event(errdesc)
   if errdesc.sql_errno == 2013 or -- CR_SERVER_LOST
      errdesc.sql_errno == 2055 or -- CR_SERVER_LOST_EXTENDED
      errdesc.sql_errno == 2006 or -- CR_SERVER_GONE_ERROR
      errdesc.sql_errno == 2011    -- CR_TCP_CONNECTION
   then
      close_statements()
      prepare_statements()
   end
end

-- Command line options
sysbench.cmdline.options = {
   table_size =
      {"Number of rows per table", 10000},
   range_size =
      {"Range size for range SELECT queries", 100},
   tables =
      {"Number of tables", 1},
   point_selects =
      {"Number of point SELECT queries per transaction", 10},
   simple_ranges =
      {"Number of simple range SELECT queries per transaction", 1},
   sum_ranges =
      {"Number of SELECT SUM() queries per transaction", 1},
   order_ranges =
      {"Number of SELECT ORDER BY queries per transaction", 1},
   distinct_ranges =
      {"Number of SELECT DISTINCT queries per transaction", 1},
   index_updates =
      {"Number of UPDATE index queries per transaction", 1},
   non_index_updates =
      {"Number of UPDATE non-index queries per transaction", 1},
   delete_inserts =
      {"Number of DELETE/INSERT combinations per transaction", 1},
   deletes =
      {"Number of DELETE queries per transaction", 1},
   inserts =
      {"Number of INSERT queries per transaction", 1},
   range_selects =
      {"Enable/disable all range SELECT queries", true},
   range_insert =
      {"Range for parallel insert of current server", "0,1000000"},
   auto_inc =
   {"Use AUTO_INCREMENT column as Primary Key (for MySQL), " ..
      "or its alternatives in other DBMS. When disabled, use " ..
      "client-generated IDs", true},
   skip_trx =
      {"Don't start explicit transactions and execute all queries " ..
         "in the AUTOCOMMIT mode", false},
   secondary =
      {"Use a secondary index in place of the PRIMARY KEY", false},
   create_secondary =
      {"Create a secondary index in addition to the PRIMARY KEY", true},
   mysql_storage_engine =
      {"Storage engine, if MySQL is used", "innodb"},
   pgsql_variant =
      {"Use this PostgreSQL variant when running with the " ..
         "PostgreSQL driver. The only currently supported " ..
         "variant is 'redshift'. When enabled, " ..
         "create_secondary is automatically disabled, and " ..
         "delete_inserts is set to 0"}
}

-- Implement parallel prepare and prewarm commands
sysbench.cmdline.commands = {
   prepare = {cmd_prepare, sysbench.cmdline.PARALLEL_COMMAND},
   prewarm = {cmd_prewarm, sysbench.cmdline.PARALLEL_COMMAND},
}

-- Template strings of random digits with 11-digit groups separated by dashes

-- 10 groups, 119 characters
local c_value_template = "###########-###########-###########-" ..
   "###########-###########-###########-" ..
   "###########-###########-###########-" ..
   "###########"

-- 5 groups, 59 characters
local pad_value_template = "###########-###########-###########-" ..
   "###########-###########"

function get_c_value()
   return sysbench.rand.string(c_value_template)
end

function get_pad_value()
   return sysbench.rand.string(pad_value_template)
end

function get_int_value()
   local val = sysbench.rand.uniform(0, 2000000000)
   return val
end

local t = sysbench.sql.type
local stmt_defs = {
   point_selects = {
      "SELECT * FROM sbtest%u WHERE id=?",
      {t.VARCHAR,255}},
   simple_ranges = {
      "SELECT * FROM sbtest%u WHERE id BETWEEN ? AND ?",
      {t.VARCHAR,255}, {t.VARCHAR,255}},
   sum_ranges = {
      "SELECT SUM(amount) FROM sbtest%u WHERE id BETWEEN ? AND ?",
      {t.VARCHAR,255}, {t.VARCHAR,255}},
   order_ranges = {
      "SELECT * FROM sbtest%u WHERE id BETWEEN ? AND ? ORDER BY FIELD1",
      {t.VARCHAR,255}, {t.VARCHAR,255}},
   distinct_ranges = {
      "SELECT DISTINCT FIELD1 FROM sbtest%u WHERE id BETWEEN ? AND ? ORDER BY FIELD1",
      {t.VARCHAR,255}, {t.VARCHAR,255}},
   index_updates = {
      "UPDATE sbtest%u SET FIELD0=FIELD0+1 WHERE id=?",
      {t.VARCHAR,255}},
   non_index_updates = {
      "UPDATE sbtest%u SET FIELD1=? WHERE id=?",
      {t.VARCHAR,255}, {t.VARCHAR,255}},
   deletes = {
      "DELETE FROM sbtest%u WHERE id=?",
      {t.VARCHAR,255}},
   inserts = {
      "INSERT INTO sbtest%u (id, amount, FIELD0, FIELD1, FIELD2, FIELD3, FIELD4, FIELD5, FIELD6, FIELD7, FIELD8) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      {t.VARCHAR,255}, t.INT, t.INT, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}, {t.CHAR,120}},
}

function prepare_begin()
   stmt.begin = con:prepare("BEGIN")
end

function prepare_commit()
   stmt.commit = con:prepare("COMMIT")
end

function prepare_for_each_table(key)   
   for t = 1, sysbench.opt.tables do
      -- print(string.format(stmt_defs[key][1], t))
      stmt[t][key] = con:prepare(string.format(stmt_defs[key][1], t))
   
      local nparam = #stmt_defs[key] - 1

      if nparam > 0 then
         param[t][key] = {}
      end

      for p = 1, nparam do
         local btype = stmt_defs[key][p+1]
         local len

         if type(btype) == "table" then
            len = btype[2]
            btype = btype[1]
         end
         if btype == sysbench.sql.type.VARCHAR or
            btype == sysbench.sql.type.CHAR then
               param[t][key][p] = stmt[t][key]:bind_create(btype, len)
         else
            param[t][key][p] = stmt[t][key]:bind_create(btype)
         end
      end

      if nparam > 0 then
         stmt[t][key]:bind_param(unpack(param[t][key]))
      end
   end
end

function prepare_point_selects()
   prepare_for_each_table("point_selects")
end

function prepare_simple_ranges()
   prepare_for_each_table("simple_ranges")
end

function prepare_sum_ranges()
   prepare_for_each_table("sum_ranges")
end

function prepare_order_ranges()
   prepare_for_each_table("order_ranges")
end

function prepare_distinct_ranges()
   prepare_for_each_table("distinct_ranges")
end

function prepare_index_updates()
   prepare_for_each_table("index_updates")
end

function prepare_non_index_updates()
   prepare_for_each_table("non_index_updates")
end

function prepare_deletes()
   prepare_for_each_table("deletes")
end

function prepare_inserts()
   prepare_for_each_table("inserts")
end

function prepare_delete_inserts()
   prepare_for_each_table("deletes")
   prepare_for_each_table("inserts")
end



-- Close prepared statements
function close_statements()
   for t = 1, sysbench.opt.tables do
      for k, s in pairs(stmt[t]) do
         stmt[t][k]:close()
      end
   end
   if (stmt.begin ~= nil) then
      stmt.begin:close()
   end
   if (stmt.commit ~= nil) then
      stmt.commit:close()
   end
end


local function get_table_num()
   return sysbench.rand.uniform(1, sysbench.opt.tables)
end

local function get_id()
   local id = "abc" .. sysbench.rand.default(1, sysbench.opt.table_size)
   -- print(id)
   return id
end

local function get_id_for_thread()
   local idx = 0
	local tmp = {}
	for val in string.gmatch(sysbench.opt.range_insert, "%d+") do
		tmp[idx] = val
		idx = idx + 1
	end
	local size = (tonumber(tmp[1]) - tonumber(tmp[0]))
   local range = math.floor(size / sysbench.opt.threads)
   local start = sysbench.tid
   local id = sysbench.rand.default(start*range+tmp[0], (start+1)*range+tmp[0])
   --- return "abc" .. (start * range + tmp[0])
   return "abc" .. id
end

function begin()
   stmt.begin:execute()
end

function commit()
   stmt.commit:execute()
end

function execute_point_selects()
   -- print(sysbench.opt.point_selects)
   local tnum = get_table_num()
   local i

   for i = 1, sysbench.opt.point_selects do
      param[tnum].point_selects[1]:set(get_id())

      stmt[tnum].point_selects:execute()
   end
end

local function execute_range(key)
   local tnum = get_table_num()

   for i = 1, sysbench.opt[key] do
      local id = get_id()
      local id_num = tonumber(string.sub(id, 4))
      param[tnum][key][1]:set(id)
      -- param[tnum][key][2]:set(id + sysbench.opt.range_size - 1)
      param[tnum][key][2]:set("abc" .. (id_num + sysbench.opt.range_size - 1))

      stmt[tnum][key]:execute()
   end
end

function execute_simple_ranges()
   execute_range("simple_ranges")
end

function execute_sum_ranges()
   execute_range("sum_ranges")
end

function execute_order_ranges()
   execute_range("order_ranges")
end

function execute_distinct_ranges()
   execute_range("distinct_ranges")
end

function execute_index_updates()
   local tnum = get_table_num()

   for i = 1, sysbench.opt.index_updates do
      param[tnum].index_updates[1]:set(get_id_for_thread())

      stmt[tnum].index_updates:execute()
   end
end

function execute_non_index_updates()
   local tnum = get_table_num()

   for i = 1, sysbench.opt.non_index_updates do
      param[tnum].non_index_updates[1]:set_rand_str(c_value_template)
      param[tnum].non_index_updates[2]:set(get_id_for_thread())

      stmt[tnum].non_index_updates:execute()
   end
end

function execute_delete_inserts()
   local tnum = get_table_num()
   local id = get_id_for_thread()

   for i = 1, sysbench.opt.delete_inserts do
      param[tnum].deletes[1]:set(id)

      local amount = get_int_value()
      local field0 = get_int_value()
      
      param[tnum].inserts[1]:set(id)
      param[tnum].inserts[2]:set(amount)
      param[tnum].inserts[3]:set(field0)

      for j = 4, 11 do
         param[tnum].inserts[j]:set(get_c_value())
      end

      stmt[tnum].deletes:execute()
      stmt[tnum].inserts:execute()
   end
end

function execute_deletes()
   local tnum = get_table_num()

   for i = 1, sysbench.opt.deletes do
      local id = get_id_for_thread()
      param[tnum].deletes[1]:set(id)
      stmt[tnum].deletes:execute()
   end
end

function execute_inserts()
   local tnum = get_table_num()

   for i = 1, sysbench.opt.inserts do
      local id = get_id_for_thread() .. (sysbench.rand.unique() - 2147483648)
      local amount = get_int_value()
      local field0 = get_int_value()
      
      param[tnum].inserts[1]:set(id)
      param[tnum].inserts[2]:set(amount)
      param[tnum].inserts[3]:set(field0)

      for j = 4, 11 do
         param[tnum].inserts[j]:set(get_c_value())
      end
      stmt[tnum].inserts:execute()
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

function log_error(msg)
   prefix = os.date("%Y/%m/%d %H:%M:%S [error] ")
   while print_lock > 0 do
   end
   print_lock = 1
   print(prefix .. msg)
   print_lock = 0
end