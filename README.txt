RPAN Chat Archive v3.0
By Leslie E. Krause

RPAN Chat Archive parses the RPAN chatlog from Old Reddit and generates a report in the
specified file format (e.g. txt, json, html, etc.). The report can optionally include
member activity and award history with the default 'debug' format.

The package consists of the following files:

  /rpan_chat_archive
  |- README.txt
  |- LICENSE.txt
  |- /tools
     |- chat_archive_wizard.html
     |- convert.csh
     |- convert.bat
  |- /bin
     |- parse_chatlog (binary for Linux)
     |- parse_chatlog.exe (binary for Windows)
  |- /src
     |- parse_chatlog.lua
     |- main_win32.lua (wrapper script for Windows binary)
     |- main_linux.lua (wrapper script for Linux binary)
     |- /lib
        |- chatlib.lua
        |- cmdlib.lua

If you have the Lua interpreter on your system, then you can run the script directly from
the 'src' directory. Otherwise, standalone binaries for Windows and Linux are available
under the 'bin' directory. The examples below assume a Linux installation.

The binaries were generated using Enceladus:

   https://github.com/ToxicFrog/Enceladus

Note: For convenience, you may wish to copy 'bin/parse_chatlog' into '/usr/local/bin' for 
global use rather than working within the project directory. Be sure to set the execute
permissions for the standalone binary.

To run the script directly:

  % lua src/parse_chatlog.lua ~/rpan/yp9heq.html

To run the standalone binary:

  % bin/parse_chatlog ~/rpan/yp9heq.html
  % cat ~/rpan/yp9heq.html | bin/parse_chatlog

For complete instructions and usage examples:

  % bin/parse_chatlog --help
  % bin/parse_chatlog --example

The chatlog must be supplied either as piped input or from an HTML file, as shown above.

To simplify the process of downloading the chatlogs from Old Reddit, a JavaScript-based 
wizard is included in the 'tools' subdirectory. It can be opened in your web browser.

For bulk conversions, a Windows batch file and a Linux shell script are both included in
the 'tools' subdirectory. You can drag-and-drop the chatlogs in Windows Explorer and they 
will be exported to the 'output' directory under the project.

In Linux, simply pass the list of chatlogs to be converted:

  % cd tools
  % ./convert.csh ~/rpan/*.html

You can change the variables at the head of the batch file and shell script to customize 
the output filename, output filetype, and timezone offset as well.
