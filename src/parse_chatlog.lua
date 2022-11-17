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
Parse the RPAN chatlog and export messages using a builtin template.
  -m    include member activity (boolean)
  -a    include award history (boolean)
  -t	template to format messages: none, debug, txt, lua, csv, json, or html)]]
local example = [[
  Export messages with default 'debug' template
  % <COMMAND> temp/31-Oct-2022.txt

  Same as above, but also include award history
  % <COMMAND> -a yes temp/31-Oct-2022.txt

  Only include member activity without messages
  % <COMMAND> -m yes -t none temp/31-Oct-2022.txt]]
local version = "RPAN Chat Archive (Version 2.0)\nCopyright (c) 2022, Leslie E. Krause\nProject Homepage: https://github.com/sorcerykid/rpan_chat_archive"
local command = wrapper or "lua parse_chatlog.lua"

local params = InputParameters( { help = help, version = version, example = example }, command )
local has_users = params.get_boolean( "m", false )
local has_gold_list = params.get_boolean( "a", false )
local template = params.get_string( "t", "debug" )

-----------------

local filespec = params.get_filename( )
local lines = { }

if filespec == "-" then
	for line in io.lines( ) do
		 table.insert( lines, line )
	end
else
	local file = io.open( filespec, "r" )
	assert( file, "Could not read file." )

	for line in file:lines( ) do
		 table.insert( lines, line )
	end

	file:close( )
end

-----------------

chatlib.parse_oldchat( lines, template == "debug" )
local report = chatlib.get_report( )

local function escape( str )
	return string.gsub( str, ".",
		{ ["\""] = "&quot;", ["'"] = "&apos;", ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;", ["\\"] = "&bsol;" } )
end

if template == "none" or template == "debug" then
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
			print( string.format( "* Gave %s", v.gold ) )
		end
	end

elseif template == "txt" then
	for i, v in ipairs( report.chat_list ) do
		if v.is_gold then
			print( string.format( "*** %s gave %s", v.user, v.chat ) )
		else
			print( string.format( "<%s> %s", v.user, v.chat ) )
		end
	end

elseif template == "json" then
	io.write( "[\n" )
	for i, v in ipairs( report.chat_list ) do
		io.write( string.format( "\t{ \"user\": \"%s\", \"chat\": \"%s\", \"is_gold\": %s }",
			v.user, escape( v.chat ), v.is_gold and "true" or "false" ) )
		io.write( i < #report.chat_list and ",\n" or "\n" )
	end
	io.write( "]\n" )

elseif template == "lua" then
	print( "return {" )
	for i, v in ipairs( report.chat_list ) do
		print( string.format( "\t{ user = \"%s\", chat = \"%s\", is_gold = %s },",
			v.user, escape( v.chat ), v.is_gold and "true" or "false" ) )
	end
	print( "}" )

elseif template == "csv" then
	print( "\"Username\",\"MessageType\",\"MessageText\"" )
	for i, v in ipairs( report.chat_list ) do
		print( string.format( "\"%s\",\"%s\",\"%s\"", 
			v.user, v.is_gold and "gold" or "chat", escape( v.is_gold and "Gave " .. v.chat or v.chat ) ) )
	end

elseif template == "html" then
	local title = filespec == "-" and
		"RPAN Chatlog" or
		"RPAN Chatlog for " .. string.gsub( string.gsub( filespec, "^(.*)[\/]", "" ), "%.%w+$", "" )

	print( "<html>" )
	print( "<head><title>" .. title .. "</title></head>" )
	print( "<body>" )
	print( "<h1>" .. title .. "</h1>" )
	print( "<table border=\"1\">" )

	for i, v in ipairs( report.chat_list ) do
		if v.is_gold then
			print( string.format( "<tr><td><b>%s</b></td><td><i>Gave %s</i></td></tr>",
				v.user, escape( v.chat ) ) )
		else
			print( string.format( "<tr><td><b>%s</b></td><td>%s</td></tr>", 
				v.user, escape( v.chat ) ) )
		end
	end
	print( "</table>" )
	print( "</body>" )
	print( "</html>" )

else
	error( "Unknown template specified" )
end
