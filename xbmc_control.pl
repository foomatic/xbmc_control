#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use Getopt::Long;

use XML::Simple;    # to fetch youtube-playlists
use LWP::Simple;

use JSON::RPC::Client;

my $xbmcurl="http://pi:8080/jsonrpc";
my $client = new JSON::RPC::Client;
my $options;    # hash holindg commandline arguments

my $DEBUG = 0;

#################################
# Doc
#################################
# Generische Kontrolle f. xbmc
# Funktionen:
#   * Play/Pause
#   * Stop
#   * vol up/down/value
#   * Play
#       * youtube-plugin
#       * file by url/path/whatever
#   * Append Playlist
#   * Delete Playlist
#   * Start Playlist
#       
# Library
#   *Get Playerid
#################################
#

sub debug{ #fs
    return if $DEBUG == 0;
    my $text = shift;
    foreach (split(/\n/, $text)) {
        print "[DEBUG] $_\n";
    }
} #fe

# get_args liesst kommandozeilenparameter.
# options = get_args(@ARGV)
#
sub get_args { #fs 
    #my @ARGV = shift;
    my $options;
    my $syntax_valid=1; # 0 => hilfe ausgeben, beenden.

    GetOptions(
        'help' => \$options->{help},
        'play'  => \$options->{play},
        'plstart:i'  => \$options->{plstart},
        'append'  => \$options->{append},
        'stop'  => \$options->{stop},
        'pause' => \$options->{pause},
        'seek=s'  => \$options->{seek},
        'input=s'  => \$options->{input},
        'notify=s' => \$options->{notify},
        'volume=i' => \$options->{volume},
        'youtube|yt'=> \$options->{youtube},
        'playlist'    => \$options->{plitems},
        'plclear'    => \$options->{plclear},
        'info|i'   => \$options->{info},
        'fullscreen'    => \$options->{fullscreen},
        'debug'    => \$options->{debug},
        #'mute'     => \$options->{mute},   # doesn't work (for now)
    );


    # Assign non-named arguments as to-play items
    $options->{items} = undef;
    $options->{items} = \@ARGV if (scalar @ARGV > 0);

    # check if arguments are valid (and print help otherwise)
    my $option; 
    my $options_set = 0;
    for (keys($options)) {
        if (defined $options->{$_}) {$options_set++;}
    }
    $syntax_valid = 0 if (defined $options->{help});    # specifically asked for help
    $syntax_valid = 0 if ($options_set == 0);           # no arguments given

    #print Dumper($options);

    # print help if required
    if ($syntax_valid != 1) {
        print <<EOHELP
xbmc remote control

Options:

  Actions:
    <url>                   - item to play
    --play                  - play item
    --append                - append item to playlist (excludes --play)
    --plstart[=pos]         - play the playlist. From <pos> if given, first item is 0.
    --insert=pos            - insert into playlist at pos [todo]
    --youtube --yt          - items are youtube-links or video-IDs

  Playlist Control:
    --playlist              - list playlist items
    --plClear               - clear playlist
    --plRemove=pos          - delete item from playlist [todo]
    --plSwap=pos1,pos2      - swap items on playlist positions pos1 and pos2 [todo]

  Player Control:
    --pause                 - (un-)pause playback
    --stop                  - stops playback
    --seek=[hh:][mm:]<ss>   - seek playback to position
    --input=<input>         - emulate keypress
        <input>:              available keys:
            Right
            Left
            Up
            Down
            Select
            Back
            ShowOSD
            ContextMenu
            ExecuteAction
            Home
    --fullscreen         - toggles fullscreen mode
    --notify=<title>#<message>  - prints onscreen Notification
    --volume=0..100         - sets playback volume

  Misc:
    --info|-i               - prints name of current video and playback time 
    --help                  - this text
    --debug
EOHELP
;
    exit(0);    # exit program after printing help
    }

    return($options);
} #fe

# Send request to player;
# Argument must be proper callobj.
sub send_request { #fs
    my $callobj = shift;
    
    my $res = $client->call($xbmcurl, $callobj);

    my $rv;

    if($res) {
        if ($res->is_error) {
            print "Error : ", Dumper($res->error_message);
        }
        else {
            debug Dumper($res->result);
            $rv = $res->result;
        }
    }
    else {
        debug $client->status_line;
        $rv = $client->status_line;
    }

    return($rv);
} #fe

sub do_pause {   #fs
    debug('do_pause');
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.PlayPause',
        params  => {
            playerid => 1,
        },
    };

    send_request($callobj);
} #fe

sub do_seek { #fs
    my $pos = shift;
    
    my ($s, $m, $h);
    my @poslist = split(':', $pos);
    $h = $poslist[-3] || 0; # two before the last
    $m = $poslist[-2] || 0; # one before the last
    $s = $poslist[-1] || 0; # last entry

    debug("do_seek: pos: $pos;  h/m/s: $h/$m/$s");

    # {"jsonrpc": "2.0", "method": "Player.Seek", "params": {"value": 34, "playerid": 1}, "id": 1}    
    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Player.Seek",
        params  => {
            playerid => 1,
            value => {
                seconds => int($s),
                minutes => int($m),
                hours   => int($h),
            }
        },
    };

    send_request($callobj);
} #fe

sub do_stop {   #fs
    debug('do_pause');
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.Stop',
        params  => {
            playerid => 1,
        },
    };

    send_request($callobj);
} #fe

sub do_input { #fs
    my $input = shift;

    # {"jsonrpc":"2.0","method":"Input.Right","id":1}
    my $callobj = {
        jsonrpc => '2.0',
        method  => "Input.$input",
        id      => 1,
    };

    send_request($callobj);
} #fe

sub do_notify { #fs
    my $notification = shift;

    my ($title, $message);
    ($title, $message) = split(/#/, $notification);
    $message = $message || "";

    # {
    #   "id":1,
    #   "jsonrpc":"2.0",
    #   "method":"GUI.ShowNotification",
    #   "params":{
    #       "title":"0Dough",
    #       "message":"Gotcha"}}
    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "GUI.ShowNotification",
        params  => {
            title => $title,
            message => $message,
        },
    };

    send_request($callobj);
} #fe

sub do_fullscreen { #fs

    # {
    #   "id":1,
    #   "jsonrpc":"2.0",
    #   "method":"GUI.ShowNotification",
    #   "params":{
    #       "title":"0Dough",
    #       "message":"Gotcha"}}
    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "GUI.SetFullscreen",
        params  => {
            fullscreen => 'toggle',
        },
    };

    send_request($callobj);
} #fe

sub do_volume { #fs
    my $volume = shift;

    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Application.SetVolume",
        params  => {
            volume => $volume,
        },
    };

    send_request($callobj);
} #fe

sub do_mute { #fs

    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Application.SetMute",
        params  => {
            mute => 'toggle',
        },
    };

    send_request($callobj);
} #fe

sub do_play { #fs
    my $itemlist = shift;   # items come as reference to list
    my @items = @$itemlist; # dereference

    debug "Items for --play: \n". Dumper(@items);

    my $item;
    my $itemnum=0;
    while ($itemnum < (scalar @items)) {
        $item = $items[$itemnum];

        my $url;   
        # item is youtube-link (guessed from url) or video-id (hinted by cmdline-argument)
        if ($item =~ m/youtube.com/ || defined $options->{youtube}) {   # get plugin-url for video
            $url = get_youtube($item);
            if ((scalar @$url) > 1) {
                my @urllist = @$url;
                shift @urllist; # dump first item of list
                splice @items, $itemnum+1, 0, @urllist;
            }
            $url = $url->[0];   # current iteration: get first item from youtube playlist
        } else {
            $url = $item;
        }

        if (defined $options->{play}) {
            # warn user if more than one item to play is given.
            print "play processes only the first item.\n" if (scalar @items) > 1;
            print "Play item: $item\n";
            debug "item-url: $url";
            do_open($url);  # play item
            last;
        };
        if (defined $options->{append}) {
            print "append item: $item\n";
            debug "item-url: $url";
            do_append($url);
        }

        $itemnum++;
    }
} #fe

sub get_youtube { #fs
    my $videourl = shift;

    my ($listid, $videoid, $pluginurl);
    my $use_playlist = 0;
    my @pluginurls;     # list with urls for the xbmc-plugin. One for each video (multiple if playlist-link given)

    # typical playlist-url: http://www.youtube.com/playlist?list=PL4z4Yk1L4Qe6g61vwdhBN_sHJBwazAf1F
    # typical video-url: http://www.youtube.com/watch?v=lufk-R1cuok&list=SPFx-KViPXIkG98ljzGGAjpq_IeFnsy86z&index=1
    # test for playlist-url:
    if ($videourl =~ m/list=([^&]+)/)  { $listid = $1;  }  # get list-id (exists in list-views and in video-urls if started from listview)
    if ($videourl =~ m/v=([^&]+)/)    { $videoid = $1; }  # get video-id. Exists only in video-views.

    debug "videourl: $videourl\n";
    debug "listid:  $listid\n";
    debug "videoid: $videoid\n";

    # Link is playlist
    if ((defined $listid) && (not defined $videoid)) { 
        $use_playlist = 1;  # flag: play from playlist
    }

    # videoid could not be extracted. Assume a videoid was given.
    if ((not defined $listid) && (not defined $videoid)) { print "ignore id; use url\n"; $videoid = $videourl; }

    # no playlist from youtube: insert just the one url into list;
    if ($use_playlist == 0) {
        my $pluginurl="plugin://plugin.video.youtube/?action=play_video&videoid=$videoid";
        push @pluginurls, $pluginurl;
        debug("do_youtube: Pluginurl: $pluginurl\n");
    }


    my $rebuilt_playlist;
    if ($use_playlist == 1) { # retrieve list of playlist-videos
        my $apiurl = "http://gdata.youtube.com/feeds/api/playlists/$listid?v=2";    
        debug "Youtube Playlist-url: $apiurl\n";
        
        my $playlistxml = get $apiurl;

        my $xs = XML::Simple->new();
        my $pl = $xs->XMLin($playlistxml);
        
        debug "parse youtube playlist";
        for (keys($pl->{entry})) {
            my $curr_entry = $_;
            #print "entry: $curr_entry\n";
            #print Dumper($pl->{entry}->{$curr_entry});
            my $pos = $pl->{entry}->{$curr_entry}->{'yt:position'};
            my $link = $pl->{entry}->{$curr_entry}->{'media:group'}->{'media:player'}->{url};
            my $title = $pl->{entry}->{$curr_entry}->{'media:group'}->{'media:title'}->{content};
            $rebuilt_playlist->[$pos]->{link} = $link;
            $rebuilt_playlist->[$pos]->{title} = "$pos-$title";
            debug "entry:\n  pos $pos\n  title: $title\n  link: $link";
        }

        debug "process playlist-items";
        foreach (@$rebuilt_playlist) {
            next if not defined $_; # youtube-counts start at 1; perl-arrays at 0 => first item would be undef'd; skip that
            debug "item: $_->{title} \t($_->{link})\n";

            if ($_->{link} =~ m/v=([^&]+)/) { 
                $videoid = $1; 
                # title is not used by xbmc or the youtube-plugin. It's a trick to put the Video-Title from the ut-playlist to the xbmc-playlist
                my $title="&title=$_->{title}";
                $pluginurl = "plugin://plugin.video.youtube/?action=play_video&videoid=$videoid$title";
                debug "do_youtube: Pluginurl: $pluginurl\n";
                push @pluginurls, $pluginurl;
            }
            else {
                debug "playlist-entry could not extract video-id; ". Dumper($_);
            }
        }
    }

    return(\@pluginurls);
} #fe

sub do_open { #fs
    my $videourl = shift;


    # { "jsonrpc": "2.0", "method": "Player.Open", 
    #   "params": { "item": { "file": "smb://HP-MEDIA-SERVER/Photos/test3" } }, "id": 1 } 
    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Player.Open",
        params  => {
            item => {
                file => $videourl,
            },
        },
    };

    send_request($callobj);
} #fe

sub do_append { #fs
    debug ("do_append");
    my $videourl = shift;


    # { "jsonrpc": "2.0", "method": "Player.Open", 
    #   "params": { "item": { "file": "smb://HP-MEDIA-SERVER/Photos/test3" } }, "id": 1 } 
    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Playlist.Add",
        params  => {
            playlistid => 1,
            item => {
                file => $videourl,
            },
        },
    };

    send_request($callobj);
} #fe

sub do_plStart { #fs
    debug ("do_plStart");
    my $plpos = shift;


    my $callobj = {
        id      => 1,
        jsonrpc => '2.0',
        method  => "Player.Open",
        params  => {
            item => {
                playlistid => 1,
                position   => $plpos,
            }
        },
    };

    send_request($callobj);
} #fe

sub do_getActivePlayers {   #fs
    debug('do_getActivePlayers');
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.GetActivePlayers',
        #params  => {
        #    playerid => 1,
        #},
    };

    return(send_request($callobj));
} #fe

sub do_getItem {   #fs
    debug('do_getItem');
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.GetItem',
        params  => {
            playerid => 1,
        },
    };

    return(send_request($callobj));
} #fe

sub do_info {   #fs
    debug('do_info');
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.GetItem',
        params  => {
            playerid => 1,
        },
    };

    my $item = send_request($callobj)->{item}->{label};
    print "Title: '$item'\n";

    # All properties:
    #  type partymode speed time percentage totaltime playlistid position repeat shuffled canseek 
    #  canchangespeed canmove canzoom canrotate canshuffle canrepeat currentaudiostream audiostreams subtitleenabled 
    #  currentsubtitle subtitles live/;

    # List of properties we request from xbmc
    my @reqproperties=qw/type partymode speed time percentage totaltime playlistid position repeat shuffled canseek 
        canshuffle canrepeat currentaudiostream audiostreams subtitleenabled currentsubtitle subtitles live/;

    # recieved properties (used often, therefore abreviated)
    my $p;
    $p = do_getProperty(@reqproperties);

    #print "canrepeat: $p->{canrepeat}\n";

    my $time;       # current time in item
    my $totaltime;  # total length of item
    my $percentage; # current time as percentage (cut to int);
    $time = sprintf("%02d:%02d:%02d", $p->{time}->{hours}, $p->{time}->{minutes}, $p->{time}->{seconds});
    $totaltime = sprintf("%02d:%02d:%02d", $p->{totaltime}->{hours}, $p->{totaltime}->{minutes}, $p->{totaltime}->{seconds});
    $percentage = int($p->{percentage});
    print "Time: $time ($totaltime) ($percentage%)\n";

} #fe

sub do_getProperty {   #fs
    debug('do_getProperty');
    my @properties = @_;
    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Player.GetProperties',
        params  => {
            playerid => 1,
            properties => [@properties],
        },
    };

    return(send_request($callobj));
} #fe

sub do_plItems {   #fs
    debug('do_plItems');

    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Playlist.GetItems',
        params  => {
            playlistid => 1,
            properties => [qw/title file/],
        },
    };

    my $playlist = send_request($callobj);
    my $items = $playlist->{items} || [];
    print "Items in Playlist: ". scalar @$items. "\n";
    #print Dumper($items);
    my $num=0;
    while ($num < (scalar @$items)) {
        printf("%02d: %s\n", $num, $items->[$num]->{file});
        $num++;
    }


    return($items);
} #fe

sub do_plClear {   #fs
    debug('do_plClear');

    my $callobj = {
        id      => '1',
        jsonrpc => '2.0',
        method  => 'Playlist.Clear',
        params  => {
            playlistid => 1,
        },
    };

    return(send_request($callobj));
} #fe

# xbmc json examples:
# {"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 1}
# {"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 0 }, "id": 1}


# Process Commandline-arguments
sub main {
    $options = get_args;

    if (defined $options->{debug})  { $DEBUG=1; };
    if (defined $options->{pause})  { do_pause; };
    if (defined $options->{stop})   { do_stop; };
    if (defined $options->{seek})   { do_seek($options->{seek}); };
    if (defined $options->{input})  { do_input($options->{input}); };
    if (defined $options->{notify}) { do_notify($options->{notify}); };
    if (defined $options->{fullscreen})   { do_fullscreen; };
    if (defined $options->{volume}) { do_volume($options->{volume}); };
    if (defined $options->{mute})   { do_mute(); };
    if (defined $options->{play})   { do_play($options->{items}); };
    if (defined $options->{append}) { do_play($options->{items}); };
    if (defined $options->{info})    { do_info; };
    if (defined $options->{plitems}) { do_plItems; };
    if (defined $options->{plclear}) { do_plClear; };
    if (defined $options->{plstart}) { do_plStart($options->{plstart}); };

}

main;
