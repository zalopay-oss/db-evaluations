require("oltp_common")

print_lock = 0

function cleanup()
    local drv = sysbench.sql.driver()
    local con = drv:connect()

    for i = 1, sysbench.opt.tables do
      print(string.format("Dropping table 'sbtest%d'...", i))
      con:query("DROP TABLE IF EXISTS sbtest" .. i)
      -- if i == 1 then 
      --    print(string.format("Dropping table 'sbtest'"))
      --    con:query("DROP TABLE IF EXISTS sbtest")
      -- else
        
      -- end
    end
 end

 function log_info(msg)
   prefix = os.date("%Y/%m/%d %H:%M:%S [info] ")
   while print_lock > 0 do
   end
   print_lock = 1
   print(prefix .. msg)
   print_lock = 0
end