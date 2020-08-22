dofile("./lua/oltp_common.lua")


function prepare_statements()
   -- use 1 query per event, rather than sysbench.opt.point_selects which
   -- defaults to 10 in other OLTP scripts
    prepare_begin()
    prepare_commit()
    prepare_delete_inserts()
end

function event()
    begin()
    execute_delete_inserts()
    commit()
end