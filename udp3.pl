use strict;
use warnings;

use Term::ReadKey;
use Net::OpenSoundControl::Client;

# アルファベットと+/-で表現した音程から周波数に変換する
sub note_to_freq {
    my $note = shift;

    # オクターブ = +3, ラの音の周波数
    my $FREQ_OF_A3 = 440.0;

    my %NOTE_TO_OFFSET = (
        C => -9,
        D => -7,
        E => -5,
        F => -4,
        G => -2,
        A =>  0,
        B =>  2
    );

    # MIDIだとオクターブは-2から+8まであるが、
    # 0から+8までサポートする
    my $freq = 0;
    if ( $note =~ /^[A-G][+|-]?[0-8]?/ ) {
        my @tmp = split //, $note;
        my $idx = $NOTE_TO_OFFSET{ shift @tmp };

        # A3の場合、$idx=0で440Hzが算出される
        foreach my $ch (@tmp) {
            if ( $ch eq '+' ) {
                $idx++;
            }
            elsif ( $ch eq '-' ) {
                $idx--;
            }
            else { 
                $idx += ( (int($ch) - 3) * 12 );
            }
        }

        $freq = $FREQ_OF_A3 * ( 2 ** ($idx / 12.0) );
    }
    else {
        warn '"' . $note . '" is not note.';
    }

    return $freq;
}

my %key_to_freq_table = (
    s  => note_to_freq('C4' ),
     e => note_to_freq('C4+'),
    d  => note_to_freq('D4' ),
     r => note_to_freq('D4+'),
    f  => note_to_freq('E4' ),
    g  => note_to_freq('F4' ),
     y => note_to_freq('F4+'),
    h  => note_to_freq('G4' ),
     u => note_to_freq('G4+'),
    j  => note_to_freq('A4' ),
     i => note_to_freq('A4+'),
    k  => note_to_freq('B4' ),
    l  => note_to_freq('C5' )
);

my $client = Net::OpenSoundControl::Client->new(
    Host => "localhost",
    Port => 57120 ) or die "Could not start client: $@\n";

ReadMode 4; # Turn off controls keys
while ( 1 ) {
    my $key;
    while ( not defined($key = ReadKey(-1)) ) {
        # No key yet
    }

    if ( $key eq 'q' ) {
        last;
    }

    if ( exists $key_to_freq_table{$key} ) {
        #printf( "freq: %.2f\n", $key_to_freq_table{$key} );
        my $freq = $key_to_freq_table{$key};
        $client->send( ['/1/osc', 'i', 1, 'f', $freq, 'f', 200] );
    }
}

ReadMode 0; # Reset tty mode before exiting

print 'done.';

__END__
