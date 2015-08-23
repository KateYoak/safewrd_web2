#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Dumper;

use Kliq;
use Kliq::Schema;
use Kliq::Model::Tokens;
my $schema = Kliq::Schema->connect({
    dsn => 'dbi:mysql:kliq2', user => 'kliq_SSM', password => 'self-expression'
});

my $data_tw = {
    service => 'twitter',
    token => 'twitter_access_token',
    secret => 'twitter_access_token_secret',
    handle => 12,
};
#$data->{user} = '94A4988D-93F8-1014-A991-F7EDC84F2656';

my $data_gl = {
    service => 'google',
    token => 'google_access_token',
};

my $tm = Kliq::Model::Tokens->new(schema => $schema, redis => '', session => 's1');

#-- 1. token not there yet, create token + user
my ($tok1, $uid1) = $tm->handle_token($data_tw);
$schema->resultset('User')->find($uid1)->add_to_kliqs({ name => 'TestKliq' });

#-- 2. next day: google first, create token + new user
my ($tok2, $uid2) = $tm->handle_token($data_gl);
isnt($uid1,$uid2);

my $count1 = $schema->resultset('User')->count;

#-- 3. then previous twitter, merge accounts
$data_tw->{user} = $uid2;
my ($tok3, $uid3) = $tm->handle_token($data_tw);

is($tok1->{id}, $tok3->{id});
is($schema->resultset('User')->find($uid3)->kliqs->count, 1);

my $count2 = $schema->resultset('User')->count;
is($count2, $count1 - 1);


# add_to_personas
#   if handle in contacts, set user_id
# add_to_contacts:
#   if email/twitter_id has persona, set user_id

done_testing();
