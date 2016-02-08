#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";


use Kliq::Schema;
use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";
my $user = $schema->resultset('User')->find('94A4988D-93F8-1014-A991-F7EDC84F2656');
use Kliq::Model::Timeline;

if(0) {
my $u2 = $schema->resultset('User')->create({
        id => '0FD39ACF-F769-456D-94ED-CE0FFDDD9C37',
        user_name => 'Anonymous.' . rand(1000), # unique
        password => 's3cr3t',
        email => 'test2@tranzmt.it',
        #contacts => [$dc] #OK
    });
}

# add a contact for which u1 has a persona
#http://api.tranzmt.it/v1/timeline/012E68C4-0B96-11E2-BECB-043578395DFD

my $uid = 'FD90B51E-0B95-11E2-A772-003A78395DFD'; # JR
$uid = '94A4988D-93F8-1014-A991-F7EDC84F2656';
$user = $schema->resultset('User')->find($uid);

my $tm = Kliq::Model::Timeline->new({
	user => $user,
	session => '',
	redis => '',
	schema => $schema
	});    

my $data = $tm->search();
warn Dumper $data;
ok(1);
done_testing;