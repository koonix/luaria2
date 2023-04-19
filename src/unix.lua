local M = {}
local posix = {
	stdlib = require('posix.stdlib'),
	unistd = require('posix.unistd'),
	signal = require('posix.signal'),
	wait = require('posix.sys.wait'),
	poll = require('posix.poll'),
}

-- redirect stdout and stderr to the given file descriptor
local function redirect(fd)
	return
		posix.unistd.dup2(fd, posix.unistd.STDOUT_FILENO) ~= -1 and
		posix.unistd.dup2(fd, posix.unistd.STDERR_FILENO) ~= -1
end

-- fork and exec the given command
-- and return a file descriptor to read the command's output
function M.subprocess(cmd, args)
	local pipe_out, pipe_in = posix.unistd.pipe()
	local pid = pipe_out and pipe_in and posix.unistd.fork() or nil
	if pid == 0 then
		if redirect(pipe_in) then
			posix.unistd.execp(cmd, args)
			posix.unistd._exit(0)
		else
			posix.unistd._exit(1)
		end
	elseif pid > 0 then
		return pid, pipe_out
	else
		return nil
	end
end

-- return the data in the given file descriptor if there is any
function M.read(fd)
	return posix.poll.rpoll(fd, 0) == 1
		and posix.unistd.read(fd, 1000)
		or ''
end

-- make a temporary file, write the given string ot it and return it's path
function M.tempfile(data)
	local fd, path = posix.stdlib.mkstemp('/tmp/luaria2-XXXXXX')
	local success = fd and posix.unistd.write(fd, data) or nil
	return success and path or nil
end

function M.kill(pid)
	return posix.signal.kill(pid)
end

return M
