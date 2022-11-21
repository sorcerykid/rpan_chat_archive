@echo off
set TIMEZONE_OFFSET=-6
set TARGET_FILETYPE=txt
set TARGET_FILENAME=%%SUBREDDIT%%_%%POST_DATE3%%.txt

echo Creating output directory...
mkdir ..\output

if "%1" == "" (
	set SOURCE_PATH=..\temp\*.*
	echo No arguments, defaulting to ..\temp\*.*
) else (
	set SOURCE_PATH=%*
)

for %%f in (%SOURCE_PATH%) do (
	echo Converting '%%f'...
	..\bin\parse_chatlog.exe -z %TIMEZONE_OFFSET% -t %TARGET_FILETYPE% -f ..\output\%TARGET_FILENAME% %%f
)
pause
