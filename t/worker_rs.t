#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;

if ( $ENV{TRAVIS} ) {
  plan skip_all => "Test will not work under Travis";
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Kliq::Schema;
use Kliq::Worker::CloudFilesPusher;
use Dancer qw/:script !pass/;

my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

my $w = Kliq::Worker::CloudFilesPusher->new(schema => $schema, config => config->{sites}->{rackspace});

my @f = qw/
3FCBD172-05B3-11E2-BD50-A27A516FB52B-lg-thumb.png
3FCBD172-05B3-11E2-BD50-A27A516FB52B-thumb.png
10FA348E-D0A5-499E-B9D0-C95339ADC1C4-lg-thumb.png
10FA348E-D0A5-499E-B9D0-C95339ADC1C4-thumb.png
3FBB1D00-05B3-11E2-88F2-A27A516FB52B-lg-thumb.png
3FBB1D00-05B3-11E2-88F2-A27A516FB52B-thumb.png
3FC1F51C-05B3-11E2-905D-A27A516FB52B-lg-thumb.png
3FC1F51C-05B3-11E2-905D-A27A516FB52B-thumb.png
/;

foreach my $f(@f) {
$w->work({
    container => 'clqs-media',
    path => 'K:/KLIQ/media/_rs/' . $f
});
}

ok(1);

done_testing;
