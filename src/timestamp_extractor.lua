local help = [[
	----------------------------------------------------------------------
	
	HELP:
		Parses through provided trth csv file,
		extracts messages falling between start_time and end_time,
		prints them to output file in given directory
		(Output will be named: <list,of,symbols>-<input_file>)
	
	ARGUMENTS:
	Commandline only:
		config=path/to/config_file/to_use (OPTIONAL)
		(Can be relative or absolute)
		<default=="extractor_config.txt">
		
		help
		Shows this screen without executing
		
		silent
		Suppresses most console output
		(should result in ~5% faster execution)
	
	Commandline or config file (commandline takes priority):
		start_time=YYYYmmddHHMMSS
		end_time=YYYYmmddHHMMSS
		
		directory=directory/to/look/for/file/and/print/output/ (OPTIONAL)
		(Can be relative or absolute)
		
		file=name_of_file_to.parse 
		(relative path from directory)
	
	----------------------------------------------------------------------
]]
local function extract()
	-- import utils module
	local utils = require("utils")
	
	-- convert commandline arguments to dictionary
	arg = utils.parse_args(arg)
	
	-- if arg flag was manually set, just display help message instead of executing
	if arg.help then return help end
	
	-- look for config file at passed in location (if present) or default location
	local config = arg.config or "extractor_config.txt"
	local exists, config_file = pcall(io.lines, config)
	
	-- if config file was found at location, set config based on generated dictionary, or empty table
	config = exists and utils.parse_args(config_file) or {}
	
	-- commandline args take priority over config file, if they are present
	local start_time = arg.start_time or config.start_time
	local end_time = arg.end_time or config.end_time
	
	local file_name = arg.file or config.file
	if not file_name then return "Missing file...\n", true end
	
	if file_name:match("/") then return "Filename should not contain directory!\n", true end
	
	local directory = arg.directory or config.directory or "./"
	if not directory then return "Missing directory...\n", true end
	
	if directory:sub(#directory,#directory) ~= "/" then 
		directory = directory.."/" 
	end
	
	-- output file will be called: <start_time>-<end_time>-<file_name> and be created in directory
	local output_name = directory..start_time.."-"..end_time.."-"..file_name
	local formatted_start = os.time({
		year = start_time:sub(1,4),
		month = start_time:sub(5,6),
		day = start_time:sub(7,8),
		hour = start_time:sub(9, 10),
		min = start_time:sub(11,12),
		sec = start_time:sub(13,14)
	})
	local formatted_end = os.time({
		year = end_time:sub(1,4),
		month = end_time:sub(5,6),
		day = end_time:sub(7,8),
		hour = end_time:sub(9, 10),
		min = end_time:sub(11,12),
		sec = end_time:sub(13,14)
	})

	-- file_name should be relative path from directory
	file_name = directory..file_name

	-- open/create output file and assign it to program output
	local output = io.open(output_name, "w+")
	if not output then return "No such directory:\n"..directory, false end
	io.output(output)

	local silent = arg.silent
	--[[ 
		Error will be thrown if file can't be found:
		delete the unnecessarily generated output file
		and return error message.
		Otherwise, proceed to reading file
	--]]
	local exists, file = pcall(io.lines, file_name)
	if not exists then
		os.remove(output_name)
		return "No such file:\n"..file_name, false
	end
	
	local i = 0
	local header_lines = 1
	local extract_message
	
	for line in file do
		i = i + 1
		-- Always write first line (header)
		if header_lines and header_lines <= i then
			io.write(line)
			if header_lines == i then
				header_lines = nil
			end
		end
		if not silent and i % 100000 == 0 then
			print("processed", i, "rows")
		end
		
		-- If first character is comma, this line is a continuation of previous symbol
		if line:sub(1,1) == "," then
			-- print it if it belongs to a desired symbol
			if extract_message then
				io.write("\n", line)
			end
		elseif line:match(":") then
			-- timestamp line
			local first_colon = line:find(":")
			local formatted_ts = os.time({
				year = line:sub(first_colon - 13, first_colon - 10),
				month = line:sub(first_colon - 8, first_colon - 7),
				day = line:sub(first_colon - 5, first_colon - 4),
				hour = line:sub(first_colon - 2, first_colon - 1),
				min = line:sub(first_colon + 1,first_colon + 2),
				sec = line:sub(first_colon + 4,first_colon + 5)
			})

			if formatted_ts >= formatted_start and formatted_ts <= formatted_end then
				io.write("\n", line)
			end
		end
	end
	
	return "Success!"
end
	
local start = os.clock()
local message, show_help = extract()
local prepend = "ERROR:\n"

-- unless show_help flag is completely ommitted from the return,
if show_help ~= nil then
	-- message was an error
	message = prepend..message
	-- if flag was true, also show help screen (missing arguments)
	if show_help == true then
		message = message..help
	end
end

-- default to unspecified error + help screen if program terminated unexpectedly
print(message or prepend..help)
print("Exectuted in", os.clock() - start, "seconds")
