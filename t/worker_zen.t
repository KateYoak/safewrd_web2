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


use Kliq::Worker::Zencoder;

my $w = Kliq::Worker::Zencoder->new(
    schema => $schema,
    config => {
        zencoder => {
            apikey => 'cb2c6adc86bb5398949a9ab2e03647ea'
        },
        rackspace => {
            username => 'stormswiftmedia',
            apikey => '9080f48bc62504ff0ae33809c987ddca'

        }
    }
);

my $data = {
	id => '980FC4A9-0210-4B6B-9803-4D5E4F279B57',
	suffix => '.mp4',
	user => '94A4988D-93F8-1014-A991-F7EDC84F2656',
	type => 'media',
	source => '980FC4A9-0210-4B6B-9803-4D5E4F279B57-51_358.mp4'
};
$w->work($data);

ok(1);
done_testing;
