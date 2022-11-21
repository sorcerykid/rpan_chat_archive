-----------------------------------------------------
-- RPAN Chat Archive (rpan_chat_archive)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2022, Leslie E. Krause
-----------------------------------------------------

package.path = package.path .. ";" ..
	( string.match( arg[ 0 ], "^(.+[\/])[^\/]+$" ) or "./" ) .. "?.lua"

local chatlib = require( "lib/chatlib" )
require( "lib/cmdlib" )

-----------------

local help = [[
Usage: <COMMAND> [OPTIONS] [FILENAME]
Parse the RPAN chatlog and generate a report in the specified format
  -m    whether to include member activity (boolean)
  -a    whether to include award history (boolean)
  -f    output filename of report (string)
  -z    timezone offset from UTC in hours (number)
  -t	output filetype of report: none, debug, txt, lua, csv, json, or html)

If output filename is unspecified or an empty string, then STDOUT will be used. 
The output fileneme may also consist of the following tokens:

  * %STREAM_ID% will be replaced with the stream ID
  * %SUBREDDIT% will be replaced with the subreddit
  * %POST_TITLE_PC% will be replaced with the post title (PascalCase)
  * %POST_TITLE_SC% will be replaced with the post title (snake_case)
  * %POST_TITLE_KC% will be replaced with the post title (kebab-case)
  * %POST_TITLE_TC% will be replaced with the post title (Train-Case)
  * %POST_DATE1% will be replaced with the post date (2022-04-15)
  * %POST_DATE2% will be replaced with the post date (15-Apr-2022)
  * %POST_DATE3% will be replaced with the post date (04-15-2022)

The post date is calculated according to the timezone offset, or 0 by default.

The member activity and award history are only available if the output filetype
is "none" or "debug", otherwise both are suppressed.]]
local example = [[
  Export messages in the default 'debug' format
  % <COMMAND> temp/yp9heq.html

  Same as above, but also include award history
  % <COMMAND> -a yes temp/yp9heq.html

  Only include member activity without messages
  % <COMMAND> -m yes -t none temp/yp9heq.html

  Export messages in plain-text format to 'output.txt'
  % <COMMAND> -t txt temp/yp9heq.html > output.txt

  Same as above, but using the post title for the output filename
  % <COMMAND> -t txt -f "%POST_TITLE_SC%.txt" temp/yp9heq.html]]
local version = "RPAN Chat Archive (Version 3.0)\nCopyright (c) 2022, Leslie E. Krause\nProject Homepage: https://github.com/sorcerykid/rpan_chat_archive"
local command = wrapper or "lua parse_chatlog.lua"

local params = InputParameters( { help = help, version = version, example = example }, command )
local has_users = params.get_boolean( "m", false )
local has_gold_list = params.get_boolean( "a", false )
local timezone = params.get_number( "z", 0 )
local target_filetype = params.get_string( "t", "debug" )
local target_filename = params.get_string( "f", "" )

-----------------

local source_filename = params.get_filename( )
local lines = { }

if source_filename == "-" then
	for line in io.lines( ) do
		 table.insert( lines, line )
	end
else
	local input = io.open( source_filename, "r" )
	assert( input, "Could not open file for reading: " .. source_filename )

	for line in input:lines( ) do
		 table.insert( lines, line )
	end

	input:close( )
end

local output
local function close_stream( ) end

local function open_stream( report )
	if target_filename == "" then return end

	local filespec = target_filename
	filespec = string.gsub( filespec, "%%STREAM_ID%%", report.stream_id )
	filespec = string.gsub( filespec, "%%SUBREDDIT%%", string.sub( report.subreddit, 3 ) )
	filespec = string.gsub( filespec, "%%POST_TITLE_PC%%", string.gsub( report.post_title, "[^A-Za-z0-9().,-_]", "" ) )
	filespec = string.gsub( filespec, "%%POST_TITLE_SC%%", string.gsub( string.lower( report.post_title ), "[^a-z0-9().,-_]", "_" ) )
	filespec = string.gsub( filespec, "%%POST_TITLE_KC%%", string.gsub( string.lower( report.post_title ), "[^a-z0-9().,-_]", "-" ) )
	filespec = string.gsub( filespec, "%%POST_TITLE_TC%%", string.gsub( report.post_title, "[^A-Za-z0-9().,-_]", "-" ) )
	filespec = string.gsub( filespec, "%%POST_DATE1%%", os.date( "%Y-%m-%d", report.post_created + timezone * 3600 ) )
	filespec = string.gsub( filespec, "%%POST_DATE2%%", os.date( "%d-%b-%Y", report.post_created + timezone * 3600 ) )
	filespec = string.gsub( filespec, "%%POST_DATE3%%", os.date( "%m-%d-%Y", report.post_created + timezone * 3600 ) )

	output = io.open( filespec, "w" )
	assert( output, "Could not open file for writing: " .. filespec )

	print = function ( str )
		output:write( str .. "\n" )  -- override builtin print function
	end

	close_stream = function ( )
		output:close( )
	end
end

-----------------

local _C = { }

local function is_match( text, pattern )
        local res = { string.match( text, pattern ) }
        setmetatable( _C, { __index = res } )
        return #res > 0
end

local function printf( ... )
	print( string.format( ... ) )
end

local function escape( str )
	return string.gsub( str, '"', '\\"' )
end

local function strip_markup( str )
	str = string.gsub( str, "<li>", "* " )
	str = string.gsub( str, "<.->", "" )
	str = string.gsub( str, "  +", " " )
	str = string.gsub( str, "&#(%d+);", function ( code )
		code = tonumber( code )
		return code < 255 and string.char( code ) or "?"
	end )
	return str
end

chatlib.parse_chatlog( lines, target_filetype == "debug" )
local report = chatlib.get_report( )

open_stream( report )

if target_filetype == "none" or target_filetype == "debug" then
	if has_users then
		print( "Member Activity:" )
		for k, v in pairs( report.users ) do
			print( string.format( "* %-20s  Chat: %-2s  Gold: %-2s",
				k, v.chat_count > 0 and v.chat_count or "-", v.gold_count > 0 and v.gold_count or "-" ) )
		end
	end

	if has_gold_list then
		print( "Award History:" )
		for i, v in ipairs( report.gold_list ) do
			print( string.format( "* Gave %s", v.award ) )
		end
	end

elseif target_filetype == "txt" then
	for i, v in ipairs( report.chat_list ) do
		if is_match( v.message, "^<p>Gave <strong>(.-)</strong></p>$" ) then
			printf( "[%s] *** %s gave %s award", os.date( "%X", v.created ), v.author, _C[ 1 ] )
		elseif is_match( v.message, "^<p>Gave <strong>(.-)</strong><br/>(.-)</p>$" ) then
			printf( "[%s] *** %s gave %s award with note: %s", os.date( "%X", v.created ), v.author, _C[ 1 ], strip_markup( _C[ 2 ] ) )
		else
			printf( "[%s] <%s> %s", os.date( "%X", v.created ), v.author, strip_markup( v.message ) )
		end
	end

elseif target_filetype == "json" then
	print( '{' )

	printf( '\t"subreddit": "%s",', report.subreddit )
	printf( '\t"post_url": "%s",', report.post_url )
	printf( '\t"post_title": "%s",', report.post_title )
	printf( '\t"post_created": %s,', report.post_created )
	printf( '\t"post_points": "%s",', report.post_author )
	printf( '\t"stream_id": "%s",', report.stream_id )
	printf( '\t"stream_url": "%s",', report.stream_url )

	print( '\t"chat_list": [' )
	for i, v in ipairs( report.chat_list ) do
		local delim = i < #report.chat_list and "," or ""
		if v.tree_id then
			printf( '\t\t{ "author": "%s", "created": %d, "message": "%s", "is_gold": %s, "leaf_id": "%s", "tree_id": "%s" }' .. delim,
				v.author, v.created, escape( v.message ), v.is_gold and "true" or "false", v.leaf_id, v.tree_id )
		else
			printf( '\t\t{ "author": "%s", "created": %d, "message": "%s", "is_gold": %s, "leaf_id": "%s" }' .. delim,
				v.author, v.created, escape( v.message ), v.is_gold and "true" or "false", v.leaf_id )
		end
	end
	print( '\t],' )

	print( '\t"gold_list": [' )
	for i, v in ipairs( report.gold_list ) do
		local delim = i < #report.gold_list and "," or ""
		printf( '\t\t{ "sender": "%s", "award": "%s" }' .. delim, v.sender, v.award )
	end
	print( '\t]' )

	print( '}' )

elseif target_filetype == "lua" then
	print( 'return {' )

	printf( '\tsubreddit = "%s",', report.subreddit )
	printf( '\tpost_url = "%s",', report.post_url )
	printf( '\tpost_title = "%s",', report.post_title )
	printf( '\tpost_created = %s,', report.post_created )
	printf( '\tpost_points = "%s",', report.post_author )
	printf( '\tstream_id = "%s",', report.stream_id )
	printf( '\tstream_url = "%s",', report.stream_url )

	print( '\tchat_list = {' )
	for i, v in ipairs( report.chat_list ) do
		if v.tree_id then
			printf( '\t\t{ author = "%s", created = %d, message = "%s", is_gold = %s, leaf_id = "%s", tree_id = "%s" },',
				v.author, v.created, escape( v.message ), v.is_gold and "true" or "false", v.leaf_id, v.tree_id )
		else
			printf( '\t\t{ author = "%s", created = %d, message = "%s", is_gold = %s, leaf_id = "%s" },',
				v.author, v.created, escape( v.message ), v.is_gold and "true" or "false", v.leaf_id )
		end
	end
	print( '\t},' )

	print( '\tgold_list = {' )
	for i, v in ipairs( report.gold_list ) do
		printf( '\t\t{ sender = "%s", award = "%s" },', v.sender, v.award )
	end
	print( '\t},' )

	print( '}' )

elseif target_filetype == "csv" then
	print( '"Created","Author","Message","IsGold","LeafID","TreeID"' )
	for i, v in ipairs( report.chat_list ) do
		printf( '"%s","%s","%s","%s","%s","%s"', 
			v.created, v.author, string.gsub( v.message, '"', '""' ), v.is_gold and "yes" or "no", v.leaf_id, v.tree_id or "" )
	end

elseif target_filetype == "html" then
	print( '<html>' )
	printf( '<head><title>%s</title></head>', report.post_title )
	print( '<body link="black" vlink="black" alink="gray">' )
	printf( '<h1>%s</h1>', report.post_title )
	printf( '<p>Submitted by <a href="https://www.reddit.com/u/%s">%s</a> on %s (%d points, %d awards)</p>', 
		report.post_author, report.post_author, os.date( "%c", report.post_created ), report.post_points, #report.gold_list )
	print( '<table border="0" cellpadding="0" cellspacing="12">' )

	for i, v in ipairs( report.chat_list ) do
		printf( '<tr><td valign="top"><a name="%s">%s</a></td>', v.leaf_id, os.date( "%X", v.created ) )
		if v.tree_id then
			printf( '<td><b><a href="https://www.reddit.com/u/%s">%s</a></b> (<a href="#%s">Jump to Parent</a>)<br>%s</td></tr>',
				v.author, v.author, v.tree_id, string.gsub( v.message, "</?p>", "" ) )
		else
			printf( '<td><b><a href="https://www.reddit.com/u/%s">%s</a></b><br>%s</td></tr>',
				v.author, v.author, string.gsub( v.message, "</?p>", "" ) )
		end
	end
	print( '</table>' )
	print( '</body>' )
	print( '</html>' )

else
	error( "Unknown output filetype" )
end

close_stream( )
