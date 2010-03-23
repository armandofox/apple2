#!/usr/bin/perl

use AppleII::Disk;
use Device::SerialPort;
require 'cereal.pl';

$s = new Device::SerialPort('/dev/tty.usbserial');
$s->baudrate(115200);
$s->parity("none");
$s->databits(8);
$s->stopbits(1);

$SIG{INT} = \&finish;

$QUIET = 1;

$Last_block = 0;

sub cmdloop {
    my $cmd;
    my $count;
    while (1) {
        ($count,$cmd) = &read_n_bytes(1) until $count==1;
        &do_read if ($cmd == 'R') ;
        &do_read_2 if ($cmd == 'r');
        &debug("Bad command: $cmd");
    }
    # reset command state
}

# all of the command handlers are executed inside an eval() so they can
# use die() to throw an exception

sub do_read {
    # collect block# (2 bytes)
    my($count,$bytes) = &read_n_bytes(2);
    die "Can't collect 2 byte block num" unless $count==2;
    $Last_block = unpack('C2',$bytes);
    # echo '<nn' with nn=blocknum (lo,hi) to acknowledge
    my $data = pack('C3', ord('<'), $Last_block % 256, $Last_block >> 8);
    $count = &send_n_bytes($data);
    die "Can't send <nn ack" unless $count == 3;
    

sub main2 {
    my $wrote;
    while (1) {
        chomp($x = <STDIN>);
        $wrote = &send_one_byte($x);
        warn "Wrote $wrote" unless $wrote==1;
    }
}

sub main {
    my @ary;
    #@ary = (0..255);
    $ary[0] = 0xee;
    for ($i=1;$i<256;$i++) { $ary[$i] = 1; }
    my $e;

    while (1) {
        print STDERR "Press return...";
        chomp($_ = <STDIN>);
        ($s->close && die) if /q/;
        &dump(@ary);
        &send_block_with_checksum(pack('C256',@ary));
        $e = shift @ary;
        push(@ary,$e);
    }
}

sub dump {
    my $i;
    my @ary = @_;
    for ($i=0; $i<16; $i++) {
        printf(("%02x " x 16) . "\n", @ary[$i<<4 .. ($i<<4)+15]);
    }
}

sub finish {
    $s->close;
    die;
}

sub wait_for_ready {
    if ($s->can_modemlines) {
        &debug("Waiting for DCD...");
        1 until ($s->modemlines & $s->MS_RLSD_ON);
        &debug("got DCD");
    }
}

sub checksum {
    my $blk = shift;
    #my $ck = unpack("%8C*", pack("C1",0).$blk);
    my $ck = 0;
    my $i;
    my @bytes = unpack('C256',$blk);
    for ($i=0; $i<256; $i++) {
        $ck ^= $bytes[$i];
    }
    return (($blk . pack('C',$ck)), $ck);
}

sub send_block_with_checksum {
    my $blk = shift;
    my ($blk_with_cksum,$cksum) = &checksum($blk);
    my $count,$l;

    # (warn("No data") && return) unless length($blk) > 0;
    &wait_for_ready;

    $count = $s->write($blk_with_cksum);
    $l = length($blk_with_cksum);
    $s->write_drain();

    &debug(sprintf("Sent $count bytes out of $l with checksum \$%02x",$cksum));
}

sub send_one_byte {
    my $byte = shift;
    &wait_for_ready;
    return $s->write(pack("C",$byte));
}

sub send_n_bytes {
    my $bytes = shift;
    my $count = $s->write($bytes);
    $s->write_drain;
}

sub read_n_bytes {
    my $count = shift;
    my ($bytes,$bytes_read);
    &wait_for_ready;
    ($bytes_read,$bytes) = $s->read($count);
    return($bytes_read,$bytes);
}

sub debug {
    warn @_ unless $QUIET;
}

&main;



