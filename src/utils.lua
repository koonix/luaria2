local M = {}
local pl = require('pl.import_into')()

-- use os.time() as the seed to the random number generator
math.randomseed(os.time())

-- return a random string with the given length
function M.rndstr(len)
	local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
	local t = {}
	for i = 1, len do
		local n = math.random(1, #charset)
		table.insert(t, charset:sub(n, n))
	end
	return table.concat(t)
end

-- return a deepcopy of 'original' merged with 'overrides'
function M.morph(original, overrides)
	local new = pl.tablex.deepcopy(original)
	if type(overrides) == 'table' then
		for k, v in pairs(overrides) do
			new[k] = pl.tablex.deepcopy(v)
		end
	elseif type(overrides) ~= 'nil' then
		error('the second argument to morph() should be a table or nil')
	end
	return new
end

-- convert the given number to a human-readable format (eg. 4560 -> 4K)
function M.humanize(n, decim)
	n = math.floor(n + 0.5) -- round the number
	local suffix
	if     n >= 10^9 then n, suffix = n / 10^9, 'G'
	elseif n >= 10^6 then n, suffix = n / 10^6, 'M'
	elseif n >= 10^3 then n, suffix = n / 10^3, 'K'
	else                  n, suffix = n, '' end
	return string.format('%.' .. (decim or 0) .. 'f%s', n, suffix)
end

return M
