dofile("./lua/oltp_common.lua")

function prepare_statements()

    if not sysbench.opt.skip_trx then
       prepare_begin()
       prepare_commit()
    end
    prepare_point_selects()
end

function event()
    if not sysbench.opt.skip_trx then
        begin()
    end

    execute_point_selects()

    if not sysbench.opt.skip_trx then
        commit()
    end
end