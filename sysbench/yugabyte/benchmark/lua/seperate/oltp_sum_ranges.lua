dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.sum_ranges=1
   prepare_begin()
   prepare_commit()
   prepare_sum_ranges()
end

function event()
    begin()
    execute_sum_ranges()
    commit()
end