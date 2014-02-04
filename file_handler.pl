#/usr/bin/perl

#depends : JSON, List::MoreUtils

# Perl prints line by line. You will waste a lot time debugging if there's 
# no \n in print string.

# TODO: Store port statuses (stati?) in the same json, provide a way to 
# access them, or, let that be passed through 0x00

use warnings;
use strict;
use IO::Socket::UNIX;
use List::MoreUtils qw(any);
use JSON;

my @cmd_list = (0x00, 0x01, 0x02);

sub start_server{
    my $SOCKPATH = '/home/varad/SmartLAB/sock';
    unlink($SOCKPATH);
    my $MAXCON = 10;
    my $listener = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Local=>$SOCKPATH,
        Listen => $MAXCON
        ) or die("fatal: can't start server");
    
    while(1){   # loopback
        my $socket = $listener->accept() or die "fatal: can't accept()";
        my (@cmd) = unpack("AA*", <$socket>); # <COMMAND><PARAMS>
        # it all relies on a f.ing "\n"
        my @reply = process(@cmd) if any {$_ == $cmd[0]} @cmd_list;
        chomp(@reply);
        my $rep = "@reply\n";   # explicit stringification
        print $socket "$rep\n";
    }
}

sub process(){
    my @cmd = @_;
    my $FILEPATH = '/home/varad/SmartLAB/house_model.json';
    open(my $house_model, '<', $FILEPATH) or 
        die "fatal: can't load the house model";

    if($cmd[0] == 0x00){
        my @filelines = <$house_model>;
        return @filelines;
    }
    elsif($cmd[0] == 0x02){
        # now I wish I knew regexes :(
        my @data = split(';', $cmd[1], 3); #split into 3

        #my $nrooms = $data[0];
        #my $nports = $data[1];
        my @rooms_desc_list = split(';', $data[2]); # all room descs

        my @rooms = ();

        foreach(@rooms_desc_list){
            my @room_info = split(':', $_, 3);
            my $room_idx = $room_info[0];
            my @room_aliases = split(",", $room_info[1]);
            my @port_desc_list = split("!", $room_info[2]);
            my @ports = ();
            foreach(@port_desc_list){
                my @port_info = split(":", $_);
          #      print "PORT_INFO ".join(" PPP ", @port_info)."\n";
                my @port_aliases = split(",", $port_info[1]);
                my %port = ("port_id" => $port_info[0],
                        "port_aliases" => \@port_aliases,
                        "port_device" => $port_info[2]
                    );
                push(@ports, \%port); # TMFU, read on stackoverflow.com
          #      print "ports:".join(" ::: ", @ports)."\n";
               print "port JSON: ".encode_json(\@ports)."\n";
            }
            my %room = ("room_id" => $room_info[0],
                    "room_aliases" => \@room_aliases,
                    "ports" => \@ports
                );
            push(@rooms, \%room);   # \ pushes the address
            print "room JSON: ".encode_json(\@rooms)."\n";
        }
#        my @msg = 0x02."1;1;0:my room, living room:0:(light, bulb):
#        D1!1:(fan, cool):D2;1 ...";

        my %house = ("houses" => [{"house_id" => "H1", "rooms" => \@rooms}]);
        my $json_out = encode_json(\%house);
        print "house JSON: ".$json_out."\n";
        return 0;
        # TODO: write this json to file
    }
}

start_server();

__END__

- supported socket message formats:
  *  0x00 read json string
  *  0x02."1;2;0:my room, living room:0:light, bulb:D1!1:fan, cool:D2";