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

#-- on new session, create an anonymous user
my $u = $schema->resultset('User')->create({
    user_name => 'CoolUser' . rand(100), # unique
    password => 'CoolPass',
    email => 'CoolMail',
    #contacts => [{
    #    handle => 11,
    #    hash => 1,
    #   name => 1
    #}]
});

#-- add network profiles
#-never used like this
$u->add_to_profiles({
    handle => 1, hash => 1, name => 1, owner_id => $u->id
});

my $c1 = $u->add_to_contacts({
    handle => 12, hash => 1, name => 1, owner_id => $u->id
});

is($u->profiles->count, 1);
is($u->contacts->count, 1);

#-but like this
$u->add_to_tokens({
    token => 'stuff',
    secret => 's3cr3t'
});

#-- import contacts
#$u->add_to_imports({
#    entryid => 1, hash => 1, name => 1
#});
my $c2 = $u->add_to_contacts({
    handle => 13, hash => 1, name => 1
});

#-- create a kliq with contacts
my $k = $u->add_to_kliqs({
    name => 'CoolKliq',
    contacts_map => [{
        #contact =#entry_id => 1, hash => 1, name => 1, user_id => $u->id
        contact_id => $c1->id
    }, { contact_id => $c2->id }]
});

#-- upload a video
my $v = $u->add_to_uploads({
    path => '/tmp/vid.mp4',
    suffix => '.mp4',
    mime_type => 'video/mp4'
});

#-- share
my $s = $u->add_to_shares({
    upload_id => $v->id,
    message => 'Check this cool vid',
    contacts_map => [{ contact_id => $c1->id, link => 1, hash => 1 }],
    kliqs_map => [{ kliq_id => $k->id }]
});

#-- comment on a share
$u->add_to_comments({
    share_id => $s->id,
    name => "",
    text => 'Wow'
});


exit;

# tokens
# profiles
# contacts
# kliqs
# shares
# comments
# 
# ratings
# buys
# subscriptions
# media
# notifications




# $destination = VIDEO_UPLOAD_PATH.'/'.$networkId.'_'.$media_id.'.'.$extension;
$schema->resultset('CmsMedia')->create({
    networkid => 1,
    title => 'CoolVid',
    sourcevideopath => '$destination',
    episodes => [{
        categoryid => 1,
        channelid => 1,
        networkid => 1
    }],
    uploads => [{
        networkid => 1,
        path => '$destination'
    }]
   
});

1;
