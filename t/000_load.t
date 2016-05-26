#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

if ( $ENV{TRAVIS} ) {
  plan skip_all => "Test will not work under Travis";
}

use File::Find;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, './lib' );
@modules = grep { !/ShipIt/} @modules;

plan tests => scalar @modules + 1;

# Check the perl version
ok( $] >= 5.005, "Your perl is new enough" );

use_ok($_) for sort map { s!/!::!g; s/\.pm$//; s/\.:://; s/^lib:://; $_ } @modules; ## no critic (MutatingListFunctions)
