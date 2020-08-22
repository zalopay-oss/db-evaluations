dofile("./lua/oltp_common.lua")

function prepare_statements()
end

function insert_data_prepare(start, end_bound, table_num)
	local table_num_str = ""
	table_num_str = tostring(table_num)
	-- if table_num > 1 then
	-- 	table_num_str = tostring(table_num)
	-- end
	insert_data(start, end_bound, table_num_str)
end


function insert_data(start, end_bound, table_num)
	start_time = os.time()

	query = "INSERT INTO sbtest" .. table_num .. "(id, amount, FIELD0, FIELD1, FIELD2, FIELD3, FIELD4, FIELD5, FIELD6, FIELD7, FIELD8) VALUES"
	con:bulk_insert_init(query)

	local c_val
	local pad_val
    local amount
    
    for i = start, end_bound-1, 1 do
		c_val = get_c_value()
		amount = get_int_value()
		query = string.format("('%s', '%d', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')",
												"abc" .. i, amount, i, c_val,
												c_val, c_val, c_val,
												c_val, c_val, c_val, c_val)
		con:bulk_insert_next(query)
	end

	con:bulk_insert_done()
	end_time = os.time()
	log_info("ThreadId: " .. sysbench.tid .. " inserting " .. "' done, within " .. os.difftime(end_time, start_time) .. " seconds")
end


function event()
	local idx = 0
	tmp = {}
	for val in string.gmatch(sysbench.opt.range_insert, "%d+") do
		tmp[idx] = val
		idx = idx + 1
	end
	local size = (tonumber(tmp[1]) - tonumber(tmp[0])) -- s[1] is range_end, s[0] is range_start
    local range = math.floor(size / sysbench.opt.threads)
	local remain = size % sysbench.opt.threads
	local start = sysbench.tid
    if start == sysbench.opt.threads-1 then
		log_info("ThreadId: " .. start .. " insert data from " .. start*range + tmp[0] .." to " .. (start+1)*range + remain + tmp[0])
		insert_data_prepare(start*range + tmp[0], (start+1)*range + remain + tmp[0], 1)
	else
		log_info("ThreadId: " .. start .. " insert data from " .. start*range + tmp[0] .." to " .. (start+1)*range + tmp[0])
		insert_data_prepare(start*range + tmp[0], (start+1)*range + tmp[0], 1)
	end
end