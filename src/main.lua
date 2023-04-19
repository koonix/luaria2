-- penlight
local pl = require('pl.import_into')()
local unix = require('unix')
local aria2 = require('aria2')

local function main(...)
	local port = 65432
	local a2 = aria2:new(port, {...})
	a2 = a2:start()
	os.execute('sleep 1')
	pl.pretty.dump(a2:status())
	a2:stop()
	print(a2:output())
end

main(...)
