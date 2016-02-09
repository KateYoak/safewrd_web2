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

# NOTE: This sends notification to all the users.
my $request_hash = {
    to => "*",
    payload => {
        alert => "Notification from Perl Worker",
        badge => 1,
        sound => "Default.caf",
        any_key => "any_value"
    }
};

$r->rpush(notifyPush => to_json({
        request => $request_hash
    }));

ok(1);
done_testing();

1;
__END__
