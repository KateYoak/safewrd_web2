use Test::More tests => 1;
use strict;
use warnings;

# the order is important
use Kliq;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
#response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
