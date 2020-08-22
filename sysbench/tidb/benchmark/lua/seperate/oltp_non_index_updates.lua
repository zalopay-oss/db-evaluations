dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts

   prepare_begin()
   prepare_commit()

   sysbench.opt.non_index_updates=1

   prepare_non_index_updates()
end

function event()
    begin()
    execute_non_index_updates()
    commit()
end