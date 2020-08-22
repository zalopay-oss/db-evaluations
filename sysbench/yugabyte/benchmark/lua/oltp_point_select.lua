dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.point_selects=1
   -- print('QUYEN')
   prepare_point_selects()
end

function event()
   -- print("EVENT")
   execute_point_selects()
end