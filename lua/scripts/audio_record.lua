session:answer()
session:consoleLog("err", '--------answer------------' .. "\n")

-- warning tone 
-- session:speak('Please say, what you say will be recorded')

session:streamFile("silence_stream://1000")
session:streamFile("tone_stream://%(250,0,1000)")

-- record
local recording_dir = '/usr/local/freeswitch/storage/upload'
local uuid = session:get_uuid()
local date=os.date('%Y%m%d%H%M%S')
local recording_filename = string.format('%s/record-%s-%s.wav', recording_dir, date, uuid)
session:recordFile(recording_filename, 6000, 50, 5)

session:consoleLog("err", '--------record over--------------' .. "\n")

-- get file len
local f = assert(io.open(recording_filename, "rb"))
local len = assert(f:seek("end"))
f:close()
session:consoleLog("err", '--------file len=--------------' .. len .. "\n")

-- generate sql command
local data = {}
data.type = "audio"
data.name = "Record-" .. session:getVariable("caller_id_number")
data.description = "audio record"
data.file_name = recording_filename
data.file_size = len
data.mime = "audio/wave"
data.ext = "wav"
data.abs_path = recording_filename
data.dir_path = recording_dir
data.rel_path = string.sub(data.abs_path, string.len(data.dir_path) + 2)
data.created_epoch = os.time()
data.updated_epoch = data.created_epoch

local comma = ""
local keys = ""
local values = ""
for k, v in pairs(data) do
	keys =  keys .. comma .. k
	if type(v) == "string" then
		values = values .. comma .. '"' .. v .. '"'
	else 
		values = values .. comma .. v
	end
	comma = ","
end

local sql = 'insert into media_files(' .. keys .. ') values(' .. values .. ')'

session:consoleLog("err", '--------sql command--------------' .. sql .. "\n")

-- operate sqlite
local dbh = freeswitch.Dbh("sqlite://xui")
dbh:query(sql)
dbh:release()


local event = freeswitch.Event("custom", "xui::record_complete");
for k, v in pairs(data) do
	event:addHeader(k, v)
end
event:fire();
