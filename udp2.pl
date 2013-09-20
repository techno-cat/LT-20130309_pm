use strict;
use warnings;

use Net::OpenSoundControl::Client;
use AnyEvent; 

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

my $bpm = 180;
my @pattern = (
    [ 0, 0, 'D4',   7 ],
    [ 0, 4, 'D4',   7 ],
    [ 0, 8, 'D4',   7 ],

    [ 1, 0, 'D4',  28 ],

    [ 2, 0, 'C4',  22 ],

    [ 3, 0, 'E4',  22 ],

    [ 4, 0, 'D4',  84 ],

    [ 999, 0, 'C4', 0x10 ] # 不正参照しないためだけのダミーデータ
);
my $pattern_length = 7 * 12;

# 4分音符の長さを以下の値で分割すると、3倍すると16分音符, 4倍すると3連符の間隔になる
my $resolution = 12;

# コールバック間隔 = 1秒間に4分音符が鳴る間隔 / 分解能（単位はsec）
my $interval = (60 / $bpm) / $resolution;

my $client = Net::OpenSoundControl::Client->new(
    Host => "localhost",
    Port => 57120 ) or die "Could not start client: $@\n";

my $cv = AnyEvent->condvar;

my $time = 0;
my $data;

my $w; $w = AnyEvent->timer(
    after => 0,
    interval => $interval,
    cb => sub {
        my $time_note_on = ($pattern[0][0] * $resolution) + $pattern[0][1];
        if ( 999 <= $time_note_on ) {
            undef $w; 
            $cv->send;

            return;
        }

        if ( $time_note_on < $time ) {
            $data = shift @pattern;
            my $freq = note_to_freq( $data->[2] );
            my $gate_time = (1000 / $bpm) * $resolution * ($data->[3] / 16);
            $client->send( ['/1/osc', 'i', 1, 'f', $freq, 'f', $gate_time] );
            #printf( "%3d: note on, %.1f, %.1f\n", $time, $freq, $gate_time );
        }

        $time++;
    }
);

$cv->recv;
print "done!\n";

__END__
