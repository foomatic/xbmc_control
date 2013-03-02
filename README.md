xbmc_control
============

Command line tool to remote control xbmc using JSON with perl.


Required perl-modules:
  * XML::Simple
  * LWP::Simple
  * JSON::RPC::Client

Install modules on a debia/ubuntu-system using:
> sudo apt-get install libxml-simple-perl libwww-perl libjson-rpc-perl 

Features:
  * Play files
  * Control playback (stop, pause)
  * Send keypresses
  * Seek in file (by timecode)
  * Modify playback volume
  * List and modify playlist (add, clear)
  * Retrieve information about currently playing file (title and position)
  * Handle URLs to youtube-videos and -playlists; rewrite them for the
    xbmc-youtube-plugin.
  * Send notification for xbmc to display

Bugs:
  * URL of xbmc-json-interface hard-coded (need to change source)
  * No authentication at youtube when fetching playlists. 
    Some Videos may not be included.
  * No authentication against xbmc (this may work just naturally when
    username and password is included in the xbmc-url, but it is untested)

Usage:
  xbmc_control.pl uses the JSON-RPC of xbmc to control it.
  See http://wiki.xbmc.org/index.php?title=JSON-RPC_API
  and http://wiki.xbmc.org/index.php?title=JSON-RPC_API/v6

  1. Enable XBMC's webserver.
  See http://wiki.xbmc.org/index.php?title=Webserver#Enabling_the_webserver

  2. Set xbmc-json-url
     Modify xbmc_control.pl, change
        my $xbmcurl="http://pi:8080/jsonrpc";
     to whatever points to your xbmc-host.
     Generic pattern:
        my $xbmcurl="http://<xbmc-ip>:<webserver-port>/jsonrpc";
     (better methods than changing the source code will be introduced later).       

  3. call xbmc_control.pl --help to get an overview over the command line arguments.
 

