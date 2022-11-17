-----------------------------------------------------
-- RPAN Chatlog Parser Library (chatlib.lua)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2022, Leslie E. Krause
-----------------------------------------------------

local users = { }
local chat_list = { }
local gold_list = { }

---------------------
-- Private Methods --
---------------------

local function no_op ( ) end

local function splitlines( str, has_blanks )
	res = { }
	str = string.gsub( str, "\r\n", "\n" )  -- normalize CRLF (used by Windows OS)
	str = string.gsub( str, "\r", "\n" )    -- normalize CR (used by Macintosh OS)

	if str ~= "" then
		str = string.gsub( str, "\n$", "" )     -- ignore trailing newline
		for val in string.gmatch( str .. "\n", "(.-)\n" ) do
			if val ~= "" or has_blanks then
				table.insert( res, val )
			end
		end
	end
	return res
end

local function insert_chat( user, chat )
	table.insert( chat_list, { user = user, chat = chat, is_gold = false } )
	if not users[ user ] then
		users[ user ] = { gold_count = 0, chat_count = 1 }
	else
		users[ user ].chat_count = users[ user ].chat_count + 1
	end
end

local function insert_gold( user, gold )
	table.insert( gold_list, { user = user, gold = gold } )
	table.insert( chat_list, { user = user, chat = gold, is_gold = true } )
	if not users[ user ] then
		users[ user ] = { gold_count = 1, chat_count = 0 }
	else
		users[ user ].gold_count = users[ user ].gold_count + 1
	end
end

--------------------
-- Public Methods --
--------------------

local function get_report( )
	return { users = users, chat_list = chat_list, gold_list = gold_list }
end

local function parse_newchat( lines, is_debug )
	local print = is_debug and print or no_op
	local idx = 1

	-- skip to first message
	while idx < #lines and not ( string.byte( lines[ idx ], 1 ) == 239 and string.byte( lines[ idx ], 2 ) == 191 ) do
		idx = idx + 1
	end

	idx = idx + 1

	while idx <= #lines do
		local user = lines[ idx ]
		print( "user: [" .. user .. "]" )
		idx = idx + 1

		if string.byte( lines[ idx ], 1 ) == 239 and string.byte( lines[ idx ], 2 ) == 191 then
			local gold = string.sub( lines[ idx ], 9 )
			print( "gold: [" .. gold .. "]" )
			insert_gold( user, gold )
			idx = idx + 3
		else
			local chat = lines[ idx ]
			idx = idx + 2
			while idx <= #lines and not ( string.byte( lines[ idx ], 1 ) == 239 and string.byte( lines[ idx ], 2 ) == 191 ) do
				chat = chat .. " " .. lines[ idx ]
				idx = idx + 2
			end
			print( "chat: [" .. chat .. "]" )
			insert_chat( user, chat )
			idx = idx + 1
		end

		print( "=====" )
	end
end

local function parse_oldchat( lines, is_debug )
	local print = is_debug and print or no_op
	local idx = 1

	while idx <= #lines do
		-- print( lines[ idx ] )
		local user = string.match( lines[ idx ], "^%[.-%]([a-zA-Z0-9_-]+)" ) or string.match( lines[ idx ], "^%[.-%](%[deleted%])" )
		print( "user: [" .. user .. "]" )
		idx = idx + 1

		if user == "exclaim_bot" then
			idx = idx + 2
		end

		if string.find( lines[ idx ], "^Gave " ) then
			local gold = string.sub( lines[ idx ], 6 )
			print( "gold: [" .. gold .. "]" )
			insert_gold( user, gold )

			if lines[ idx + 1 ] ~= "" then
				idx = idx + 4
			else
				idx = idx + 3
			end
		else
			local chat = lines[ idx ]
			idx = idx + 2

			while idx <= #lines and not string.match( lines[ idx ], "^permalink.+reply$" ) do
				chat = chat .. " " .. lines[ idx ]
				idx = idx + 2
			end

			print( "chat: [" .. chat .. "]" )
			insert_chat( user, chat )
			idx = idx + 1
		end

		if lines[ idx ] == "continue this thread" then
			idx = idx + 2
		else
			idx = idx + 1
		end

		print( "=====" )
	end
end

return {
	splitlines = splitlines,
	get_report = get_report,
	parse_newchat = parse_newchat,
	parse_oldchat = parse_oldchat,
}
