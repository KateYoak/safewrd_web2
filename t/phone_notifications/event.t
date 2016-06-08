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

$r->rpush(notifyEvent => to_json({
        event => '07F51300-5536-11E5-AA48-CD5C1B79AE7E'
    }));

ok(1);
done_testing();

1;
__END__
