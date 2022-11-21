@echo off
set TIMEZONE_OFFSET="-6"
set TARGET_FILETYPE="txt"
set TARGET_FILENAME="%%SUBREDDIT%%_%%POST_DATE3%%.txt"

echo "Creating output directory..."
mkdir ..\output

for %%f in (%*) do (
	echo "Converting '%%f'..."
	..\bin\parse_chatlog.exe -z %TIMEZONE_OFFSET% -t %TARGET_FILETYPE% -f %TARGET_FILENAME% ..\output\%%f
)
