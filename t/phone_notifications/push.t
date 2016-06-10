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

# Send test push notification to Sachin's device
my $request_hash = {
    type => 'push',
    carnival_payload => {
        notification => {
            to => [{ name => 'user_id', criteria => ["8EC697DA-C653-11E5-B109-ECD18AB44419"] }],
            payload => {
                action    => 'test_action',
                badge     => 1,
                sound     => "Default.caf",
                alert     => "Notification from Perl Worker",
            },
        },
    },
};

$r->rpush(notifyPhone => to_json($request_hash));

ok(1);
done_testing();

1;
__END__
