#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


use Kliq::Schema;
use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

#use YAML;
#my $config = load_yaml('./config.yml');

use Kliq::Worker::S3Uploader;

my $data = '/tmp/vid.mp4';
my $w = Kliq::Worker::S3Uploader->new(schema => $schema, config => config->{sites}->{'amazon-s3'});

$w->work($data);

ok(1);
done_testing;
