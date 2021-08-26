local help = [[
	----------------------------------------------------------------------
	
	HELP:
		Parses through provided trth csv file,
		extracts messages for given symbol(s),
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
		symbol=desired_symbol_to_extract
		OR:	   comma,separated,list,of,symbols
		
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
	local symbol = arg.symbol or config.symbol
	if not symbol then return "Missing symbol...\n", true end
	
	local file_name = arg.file or config.file
	if not file_name then return "Missing file...\n", true end
	
	-- file shouldn't contain directory; directory argument should be used for that
	if file_name:match("/") then return "Filename should not contain directory!\n", true end
	
	local directory = arg.directory or config.directory or "./"
	if not directory then return "Missing directory...\n", true end
	
	if directory:sub(#directory,#directory) ~= "/" then 
		directory = directory.."/" 
	end
	
	
	-- output file will be called: <symbol_param>-<file_name> and created in directory
	local output_name = directory..symbol.."-"..file_name
	
	-- convert symbol to table, splitting by "," delimeter)
	local symbol_list = {}
	for str in utils.split_by(symbol) do 
		-- add "," to end of each symbol because we only want to extract exact symbol matches
		table.insert(symbol_list, { str..",", #str+1 }) 
	end	

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
		else
			-- if first characters match a symbol in symbol list, print this line and any continuous ones
			for _,symbol in ipairs(symbol_list) do
				-- length of each symbol is stored in a tuple
				if line:sub(1, symbol[2]) == symbol[1] then
					extract_message = true
					io.write("\n", line)
					break
				else
					extract_message = false
				end
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
