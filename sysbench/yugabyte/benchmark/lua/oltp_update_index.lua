dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.index_updates=1

   prepare_index_updates()
end

function event()
    execute_index_updates()
end