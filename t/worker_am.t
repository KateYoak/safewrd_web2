#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

###############
use Redis;
use JSON;
my $r = new Redis;

$r->rpush(amdbPush => to_json({
        keep => 1,
        file => '789E7AD1-32BB-4832-AD3D-4D8E242EB201-full.mp4',
        guid => '789E7AD1-32BB-4832-AD3D-4D8E242EB201'
    }));

ok(1);
done_testing();
exit;

1;
__END__

###############

use Kliq::Schema;
use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";


use Kliq::Worker::AMDBPusher;

my $w = Kliq::Worker::AMDBPusher->new(
    schema => $schema,
    config => { username => 'stormswiftmedia', apikey => '9080f48bc62504ff0ae33809c987ddca' }
);

my $data = {
	#source_video_path => '980FC4A9-0210-4B6B-9803-4D5E4F279B57-51_358.mp4',
	#suffix => '.mp4',
	#user => '94A4988D-93F8-1014-A991-F7EDC84F2656'
	file => '980FC4A9-0210-4B6B-9803-4D5E4F279B57-full.mp4',
	keep => 1
};
my $data2 = {
	file => '980FC4A9-0210-4B6B-9803-4D5E4F279B57-half.3gp',
	keep => 0
};

#/usr/local/bin/amSigGen
#./amSigGen -i /home/ubuntu/media/assets/789E7AD1-32BB-4832-AD3D-4D8E242EB201.mp4 -s ADB -S -o /home/ubuntu/media/signatures

my $data3 = {
	file => '789E7AD1-32BB-4832-AD3D-4D8E242EB201-full.mp4',
	keep => 1,
	guid => '789E7AD1-32BB-4832-AD3D-4D8E242EB201'
};

$w->work($data3);



ok(1);
done_testing;
