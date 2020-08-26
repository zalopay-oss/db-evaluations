dofile("./lua/non-transaction/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
   sysbench.opt.point_selects=1
   print(sysbench.opt.point_selects)
   prepare_begin()
   prepare_commit()
   prepare_point_selects()
end

function event()
   begin()
   execute_point_selects()
   commit()
end