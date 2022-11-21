-----------------------------------------------------
-- RPAN Chatlog Parser Library (chatlib.lua)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2022, Leslie E. Krause
-----------------------------------------------------

local users
local chat_list
local gold_list
local subreddit
local post_url
local post_title
local post_created
local post_author
local post_points
local stream_id
local stream_url

---------------------
-- Private Methods --
---------------------

local _C = { }

local function is_match( text, pattern )
        local res = { string.match( text, pattern ) }
        setmetatable( _C, { __index = res } )
        return #res > 0
end

local function insert_chat( author, created, message, is_gold, leaf_id, tree_id )
	table.insert( chat_list, { author = author, created = created, message = message, is_gold = is_gold, leaf_id = leaf_id, tree_id = tree_id } )
	if not users[ author ] then
		users[ author ] = { gold_count = 0, chat_count = 1 }
	else
		users[ author ].chat_count = users[ author ].chat_count + 1
	end
end

local function insert_gold( sender, award )
	table.insert( gold_list, { sender = sender, award = award } )
	if not users[ sender ] then
		users[ sender ] = { gold_count = 1, chat_count = 0 }
	else
		users[ sender ].gold_count = users[ sender ].gold_count + 1
	end
end

local function to_timestamp( str )
	-- convert from 2016-08-13T17:27:06.886Z
	assert( is_match( str, "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)" ) )
	return os.time( {
		year = tonumber( _C[ 1 ] ),
		month = tonumber( _C[ 2 ] ),
		day = tonumber( _C[ 3 ] ),
		hour = tonumber( _C[ 4 ] ),
		min = tonumber( _C[ 5 ] ),
		sec = tonumber( _C[ 6 ] ),
	} )
end

local function from_timestamp( timestamp )
	return os.date( "%c UTC", timestamp )
end

--------------------
-- Public Methods --
--------------------

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

local function parse_chatlog( lines, is_debug )
	local print = is_debug and print or function ( ) end
	local idx = 2

	assert( is_match( lines[ 1 ], '<link rel="canonical" href="(.-)"' ) )
	post_url = string.gsub( _C[ 1 ], "//www%.", "//old." )

	assert( is_match( lines[ 1 ], '<time datetime="(.-)"' ) )
	post_created = to_timestamp( _C[ 1 ] )

	assert( is_match( lines[ 1 ], '<meta property="og:title" content="(.-)"' ) )
	post_title = _C[ 1 ]

	assert( is_match( lines[ 1 ], '<meta property="og:description" content="Posted in (.-) by (.-) • (.-) points? and (.-) comments?"' ) )
	subreddit = _C[ 1 ]
	post_author = _C[ 2 ]
	post_points = tonumber( _C[ 3 ] )

	assert( is_match( lines[ 1 ], '<link rel="shorturl" href="https://redd.it/(.-)"' ) )
	stream_id = _C[ 1 ]
	stream_url = string.format( "https://www.reddit.com/rpan/%s/%s", subreddit, _C[ 1 ] )

	print( "meta-subreddit: " .. subreddit )
	print( "meta-post-url: " .. post_url )
	print( "meta-post-title: " .. post_title )
	print( "meta-post-created: " .. from_timestamp( post_created ) )
	print( "meta-post-author: " .. post_author )
	print( "meta-post-points: " .. post_points )
	print( "meta-stream-id: " .. stream_id )
	print( "meta-stream-url: " .. stream_url )
	print( "=====" )

	while not string.find( lines[ idx ], '^</p><table class="md">' ) do
		-- advance to first message
		idx = idx + 1  
	end

	users = { }
	chat_list = { }
	gold_list = { }

	while not string.find( lines[ idx ], '<script id="message%-report%-template"' ) do
		local author = "[deleted]"
		if is_match( lines[ idx ], 'data%-author="(.-)"' ) then
			author = _C[ 1 ]
		end

		assert( is_match( lines[ idx ], 'datetime="(.-)"' ) )
		local created = to_timestamp( _C[ 1 ] )

		assert( is_match( lines[ idx ], 'data%-permalink=".-/(.......)/"' ) )
		local leaf_id = _C[ 1 ]

		assert( is_match( lines[ idx ], '<div class="md">(.+)' ) )
		local message = _C[ 1 ]

		idx = idx + 1
		while not string.find( lines[ idx ], '^</div>$' ) do
			-- message can span multiple lines
			message = message .. " " .. lines[ idx ]
			idx = idx + 1
		end

		local is_gold = false
		if is_match( message, '^<p>Gave <strong>(.-)</strong>' ) then
			insert_gold( author, _C[ 1 ] )
			is_gold = true
		end

		idx = idx + 1
		if string.find( lines[ idx ], '^</div><div class="usertext%-edit md%-container"' ) then
			-- skip over message submission form
			idx = idx + 2
		end

		print( "author: " .. author )
		print( "created: " .. from_timestamp( created ) )
		print( "message: " .. message )
		print( "leaf_id: " .. leaf_id )

		if is_match( lines[ idx ], '<a href="#(.-)" data%-event%-action="parent"' ) then
			print( "tree_id: " .. _C[ 1 ] )
			insert_chat( author, created, message, is_gold, leaf_id, _C[ 1 ] )
		else
			insert_chat( author, created, message, is_gold, leaf_id )
		end

		print( "=====" )
	end

	-- lastly sort by message creation
	table.sort( chat_list, function ( a, b ) return a.created < b.created end )
end

local function get_report( )
	return { 
		users = users,
		chat_list = chat_list,
		gold_list = gold_list,
		subreddit = subreddit,
		post_url = post_url,
		post_title = post_title,
		post_created = post_created,
		post_author = post_author,
		post_points = post_points,
		stream_id = stream_id,
		stream_url = stream_url,
	}
end

return {
	splitlines = splitlines,
	get_report = get_report,
	parse_chatlog = parse_chatlog,
}
