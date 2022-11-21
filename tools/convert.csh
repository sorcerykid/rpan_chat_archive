#!/bin/tcsh
set TIMEZONE_OFFSET = "-6"
set TARGET_FILETYPE = "txt"
set TARGET_FILENAME = "%SUBREDDIT%_%POST_DATE3%.txt"

if( ! -d ../output ) then
	echo "Creating output directory..."
	mkdir ../output
endif

foreach file ( $* )
	echo "Converting '$file'..."
	../bin/parse_chatlog -z $TIMEZONE_OFFSET -t $TARGET_FILETYPE -f ../output/$TARGET_FILENAME $file
end
