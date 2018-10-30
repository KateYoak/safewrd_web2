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
    payload => {
        user_id            => "B0AFF068-EBD0-11E7-9A43-D1014BD6D9BE",
        action             => 'emergency_flare',
        sound              => "flare.wav",
        message            => "Notification from Perl Worker",
        notification_title => "Notification from Perl Worker",
    },
};

$r->rpush(notifyPhone => to_json($request_hash));

ok(1);
done_testing();

1;
__END__
