local M = {}
local http = require('socket.http')
local ltn12 = require('ltn12')
local json = require('dkjson')

-- make an HTTP POST request at the given URL with the given data
local function post(url, type, data)
	local sink, response = ltn12.sink.table()
	local source = ltn12.source.string(data)
	local err, code = http.request{
		method = 'POST',
		url = url,
		sink = sink,
		source = source,
		headers = {
			['Content-Type'] = type,
			['Content-Length'] = tostring(#data),
		},
	}
	local success = err ~= nil and code == 200
	return success, success and table.concat(response) or code
end

-- call a jsonrpc method at the given url return it's response
function M.call(url, id, method, params)
	local success, response = post(url, 'application/json', json.encode{
		jsonrpc = '2.0',
		id = id,
		method = method,
		params = params
	})
	return success, success and json.decode(response) or response
end

return M
