dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.simple_ranges=1
   prepare_begin()
   prepare_commit()
   prepare_simple_ranges()
end

function event()
    begin()
    execute_simple_ranges()
    commit()
end