Various text parsing utilities:

extractor - standalone executable compiled from src/extractor.lua (linux only)
	Reads a trth formatted raw csv file, extracts all messages with input symbol(s)
	Run with 'help' argument for instructions/arguments
	
timestamp_extractor - standalone executable compiled from src/timestamp_extractor.lua (linux only)
	Reads a trth formatted raw csv file, extracts all messages falling between start and end timestamps
	Run with 'help' argument for instructions/arguments
	
error_parser.py - python script (python 3+, requires click - install with pip)
	Reads any number of text files (specified in filelist parameter), summarizes their distinct error occurances in summary.csv, extracts all symbols with invalid characters in invalid_symbols.csv
	Run with '--help' argument for arguments
	
get_and_analyze_reports.py - python script (python 3+, requires click and boto3 - install with pip)
	Downloads MARKETPRICE-Report files from s3 for all venues in range between start_time and end_time, unzips them, then analyzes them, extracting the first and last message for each file.
	(Can be easily modified to download different types of files/change the processing function)
	Run with '--help' argument for arguments
	
