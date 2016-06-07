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

# Send test in-app notification to Sachin's device
my $request_hash = {
    type => 'in-app',
    carnival_payload => {
        message => {
            to => [{ name => 'user_id', criteria => ["8EC697DA-C653-11E5-B109-ECD18AB44419"] }],
            title => "Test in-app message",
            type => "text_message",
            text => "This is a test in-app message description",
            notification => {
                payload => {
                    action    => 'live_event',
                    badge     => 1,
                    sound     => "Default.caf",
                    alert     => "In-app notification from Perl Worker",
                },
            },
        },
    },
};

$r->rpush(notifyPhone => to_json({
        request => $request_hash
    }));

ok(1);
done_testing();

1;
__END__
