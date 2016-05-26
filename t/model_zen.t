#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;

if ( $ENV{TRAVIS} ) {
  plan skip_all => "Test will not work under Travis";
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Redis;
my $r = Redis->new();

use Kliq::Schema;
use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

use Data::Dumper;
use Kliq::Model::ZencoderOutput;

my $z = Kliq::Model::ZencoderOutput->new(schema => $schema, redis => $r);
$z->upload_output_results();

ok(1);

done_testing();
