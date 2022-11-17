-----------------------------------------------------
-- Short-Query POSIX Library (cmdlib.lua)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2022, Leslie E. Krause
------------------------------------------------------

local _C = { }

term_write = function ( text ) io.stderr:write( text ) end
term_flush = function ( ) io.stderr:flush( ) end

local function is_match( text, pattern )
        local res = { string.match( text, pattern ) }
        setmetatable( _C, { __index = res } )
        return #res > 0
end

local function tovector2d( v )
	if is_match( v, "^(-?%d+),(-?%d+)$" ) then
		return { x = tonumber( _C[ 1 ] ), y = tonumber( _C[ 2 ] ) }
	else
		return false
	end
end

local function tovector3d( v )
	if is_match( v, "^(-?%d+),(-?%d+),(-?%d+)$" ) then
		return { x = tonumber( _C[ 1 ] ), y = tonumber( _C[ 2 ] ), z = tonumber( _C[ 3 ] ) }
	else
		return false
	end
end

local function toboolean( v )
	return ( {
		["1"] = true, ["y"] = true, ["yes"] = true, ["on"] = true, ["true"] = true,
		["0"] = false, ["n"] = false, ["no"] = false, ["off"] = false, ["false"] = false
	} )[ v ]
end

-----------------------
-- ProgressBar Class --
-----------------------

function ProgressBar( width, total )
	local self = { }
	local count = 0
	local t1 = os.time( )

	term_write( "[" .. string.rep( " ", width ) .. "]" .. string.format( "%4d%%", 0 ) )
	term_flush( )

	self.on_step = function ( )
		-- show an animated progress indicator
		local t2 = os.time( )
		count = count + 1
		if t2 > t1 or count == total then
			local len1 = math.ceil( count / total * width )
			local len2 = width - len1

			term_write( "\27[" .. ( width + 6 ) .. "D" )
			term_write( string.rep( "#", len1 ) .. string.rep( " ", len2 ) .. "\27[1C" )
			term_write( string.format( "%4d%%", count / total * 100 ) )
			term_flush( )
			t1 = t2
		end
	end

	return self
end

-------------------------
-- StatusCounter Class --
-------------------------

function StatusCounter( )
	local self = { }
	local t1 = os.time( )

	term_write( "00:00" )
	term_flush( )

	self.on_step = function ( )
		local t2 = os.time( )
		if t2 > t1 then
			local td = t2 - t1
			term_write( "\27[5D" .. os.date( "%M:%S", td / 60, math.floor( td % 60 ) ) )
			term_flush( )
			t1 = t2
		end
	end

	return self
end

-------------------------
-- StatusSpinner Class --
-------------------------

function StatusSpinner( )
	local self = { }
	local frames = { "-", "\\", "|", "/" }
	local step = 1
	local t1 = os.time( )

	term_write( frames[ 1 ] .. "\b" )
	term_flush( )

	self.on_step = function ( )
		local t2 = os.time( )
		if t2 > t1 then
			local td = t2 - t1
			term_write( frames[ step % 4 + 1 ] .. "\b" )
			term_flush( )
			step = step + 1
			t1 = t2
		end
	end

	return self
end

---------------------------
-- InputParameters Class --
---------------------------

function InputParameters( results, command )
	local options = { }
	local filename = "-"

	local idx = 1
	while idx <= #arg do
		if is_match( arg[ idx ], "^%-%-(%S+)$" ) then
			local res = results[ _C[ 1 ] ] or results.help
			print( ( string.gsub( res, "<COMMAND>", command ) ) )
			os.exit( 0 )
		elseif is_match( arg[ idx ], "^%-(%S+)$" ) then 
			options[ _C[ 1 ] ] = arg[ idx + 1 ]
			idx = idx + 2
		elseif arg[ idx ] == "-" then
			-- abort if stdin explicitly specified
			break
		else
			-- anything that doesn't look like an option 
			-- is treated as the input filename
			filename = arg[ idx ]
			break
		end
	end

	local self = { }

	self.get_filename = function ( )
		return filename
	end

	self.get_boolean = function ( key, def )
		if options[ key or 0 ] then
			local res = toboolean( options[ key or 0 ] )
			assert( res ~= nil, "Invalid boolean, aborting." )
			return res
		else
			return def
		end
	end
	
	self.get_number = function ( key, def )
		if options[ key or 0 ] then
			local res = tonumber( options[ key or 0 ] )
			assert( res ~= nil, "Invalid number, aborting." )
			return res
		else
			return def
		end
	end

	self.get_vector2d = function ( key, def )
		if options[ key or 0 ] then
			local res = tovector3d( options[ key or 0 ] )
			assert( res, "Invalid 3d vector, aborting." )
			return res
		else
			return def
		end
	end

	self.get_vector3d = function ( key, def )
		if options[ key or 0 ] then
			local res = tovector2d( options[ key or 0 ] )
			assert( res, "Invalid 2d vector, aborting." )
			return res
		else
			return def
		end
	end

	self.get_string = function ( key, def )
		return options[ key or 0 ] or def
	end

	return self
end
