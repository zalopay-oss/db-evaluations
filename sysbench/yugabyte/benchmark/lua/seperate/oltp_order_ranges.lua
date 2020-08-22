dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.order_ranges=1
   prepare_begin()
   prepare_commit()
   prepare_order_ranges()
end

function event()
    begin()
    execute_order_ranges()
    commit()
end