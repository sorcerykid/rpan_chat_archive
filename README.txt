RPAN Chat Archive v2.0
By Leslie E. Krause

RPAN Chat Archive parses the RPAN chatlog from Old Reddit and exports messages using a
builtin template (e.g. HTML, JSON, Lua, etc.). The output can optionally include member 
activity and award history with the default 'debug' template.

The package consists of the following files:

  /rpan_chat_archive
  |- README.txt
  |- LICENSE.txt
  |- /bin
  |  |- parse_chatlog (binary for Linux)
  |  |- parse_chatlog.exe (binary for Windows)
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

  % lua src/parse_chatlog.lua ~/rpan/31-Oct-2022.txt

To run the standalone binary:

  % bin/parse_chatlog ~/rpan/31-Oct-2022.txt
  % cat ~/rpan/31-Oct-2022.txt | bin/parse_chatlog

The chat log must be supplied either as piped input or from a plain-text file, as shown.
In most cases, the file name does not matter (e.g. stream date, stream ID, etc.), but in
the case of the HTML template, it will determine the page title.

Note: The chat log must be copied from old.reddit.com, excluding the header and footer 
portions of the page, otherwise parsing will fail.

For additional features, use the command-line option '--help'.
