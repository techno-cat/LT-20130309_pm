use strict;
use warnings;

use Net::OpenSoundControl::Client;

my $client = Net::OpenSoundControl::Client->new(
    Host => "localhost",
    Port => 57120 ) or die "Could not start client: $@\n";

$client->send( ['/foo/bar', 'i', 0, 'f', 0.5] );

__END__
