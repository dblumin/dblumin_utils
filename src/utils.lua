local utils = {}

-- wrapper for str.gmatch()
function utils.split_by(str, delim)
	delim = delim or ","
	return str:gmatch("([^"..delim.."]+)")
end

-- update table size
function utils.setn(t, n)
	setmetatable(t, { __len=function() return n end })
end

-- count elements in a dictionary/mixed index table
function utils.table_size(t)
	local i = 0
	for _,_ in pairs(t) do
		i = i + 1
	end
	utils.setn(t, i)
	return i
end

-- convert table to iterator function
local function list_iter(t)
	local i = 0
	local n = utils.table_size(t)
	return function()
		i = i + 1
		if i <= n then
			return t[i]
		end
	end
end

-- convert commandline/config file argument to k,v pair or flag
local function parameterize(t, entry, delim)
	local index, value
	for str in utils.split_by(entry, delim) do
		if index then
			value = str
			break
		else
			index = str
		end
	end
	-- supports k,v pair separated by delimeter, or single flag
	t[index] = value or true
end

-- initialize args table
function utils.parse_args(args, delim)
	if args then
		delim = delim or "="
		local t = {}
		if type(args) == "table" then
			args = list_iter(args)
		end
		for line in args do
			parameterize(t, line, delim)
		end
		return t
	else
		return {}
	end
end

return utils