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

use Furl;

    my $furl = Furl->new(
        agent   => 'MyGreatUA/2.0',
        timeout => 10,
    );

    my $res = $furl->post(
        'http://trzmt.it/', # URL
        ['X-Requested-With' => 'XMLHttpRequest'],              # headers
        { url => 'http://sitecorporation.com' }, 
    );
    die $res->status_line unless $res->is_success;
    print $res->content;

ok(1);
done_testing;
