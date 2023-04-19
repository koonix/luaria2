local M = {}
local pl = require('pl.import_into')()
local unix = require('unix')
local jrpc = require('jsonrpc')
local utils = require('utils')

function M:new(port, args)
	return utils.morph(self, {
		secret = utils.rndstr(50),
		port = port,
		args = args,
	})
end

function M:start()
	local conf = M.mkconfig(self.port, self.secret)
	if not conf then
		return nil
	end
	local args = pl.tablex.deepcopy(self.args)
	table.insert(args, 1, '--conf-path=' .. conf)
	local pid, outfd = unix.subprocess('aria2c', args)
	if not pid then
		return nil
	end
	return utils.morph(self, {
		pid = pid,
		outfd = outfd,
	})
end

function M:stop()
	return unix.kill(self.pid)
end

function M:status()
	local t = self:rpc('tellActive', {{
		'completedLength', 'totalLength', 'downloadSpeed', 'connections', 'files'
	}})
	if not t then
		return nil
	end
	for _, dl in ipairs(t) do
		dl.path = dl.files[1].path
		dl.uri = dl.files[1].uris[1].uri
		dl.files = nil
	end
	return t
end

function M:output()
	return unix.read(self.outfd)
end

function M:rpc(method, args)
	local url = string.format('http://127.0.0.1:%d/jsonrpc', self.port)
	args = args and args or {}
	if self.secret then
		table.insert(args, 1, 'token:' .. self.secret)
	end
	local success, response = jrpc.call(url, 'luaria2', 'aria2.' .. method, args)
	return success and response.result or nil
end

function M.mkconfig(port, secret)
	local config = pl.stringx.dedent[[
		enable-rpc=true
		rpc-listen-port=PORT
		rpc-secret=SECRET
		split=16
		max-connection-per-server=16
		min-split-size=1M
		max-tries=5
		retry-wait=10
		timeout=120
		connect-timeout=120
		allow-piece-length-change=true
		user-agent=Mozilla/5.0
		max-concurrent-downloads=1
		console-log-level=error
		show-console-readout=false
		summary-interval=0
		download-result=hide
	]]
	config = config:gsub('PORT', port)
	config = config:gsub('SECRET', secret)
	return unix.tempfile(config)
end

return M
