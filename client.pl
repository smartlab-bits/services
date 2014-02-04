use strict;
use warnings;
use IO::Socket::UNIX;

my $SOCKPATH = '/home/varad/SmartLAB/sock';
my $sock_addr = sockaddr_un($SOCKPATH);

my $socket = IO::Socket::UNIX->new(
   Type => SOCK_STREAM,
   Peer => $SOCKPATH,
);

#my $msg = 0x00;
#print $socket $msg."\n";

my @msg = 0x02."1;2;0:my room, living room:0:light, bulb:D1!1:fan, cool:D2";
print "@msg\n";
print $socket "@msg\n";

while(my $line = <$socket>){
        print "$line\n";
}