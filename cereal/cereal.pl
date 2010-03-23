#!/usr/bin/perl

package SerialBlock;

sub new {
    my $data;
    if ($#_ > 1) {                          # array
        $data = pack('C256', @_);
    } else {
        $data = shift;
    }
    my $self = bless {
        'data' => $data,
        'checksum' => undef,
    };
    $self->{checksum} = $self->gen_checksum();
    return $self;
}

sub gen_checksum {
    my $ck = 0;
    my @data = unpack('C256', $self->{data});
    for (@data) {
        $ck ^= $_;
    }
    return $ck;
}



1;
