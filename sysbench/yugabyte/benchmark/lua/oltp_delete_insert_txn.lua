dofile("./lua/oltp_common.lua")

function prepare_statements()
   if not sysbench.opt.skip_trx then
      prepare_begin()
      prepare_commit()
   end
   
   prepare_delete_inserts()
end

function event()
   if not sysbench.opt.skip_trx then
      begin()
   end

   execute_delete_inserts()

   if not sysbench.opt.skip_trx then
      commit()
   end
end