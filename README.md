xbmc_control
============

Command line tool to remote control xbmc using JSON with perl.


Required perl-modules
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


