#!/usr/bin/perl -w

# flush local development redis database

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long;
use Redis;

my ( $help, $force ) = ( 0, 1 );

GetOptions(
    'help|?'   => \$help,
    'force|f'  => \$force,
);

pod2usage(1) if $help;

if ($force) {
    my $redis = Redis->new(encoding => undef);
    my @k = $redis->keys('*');

    foreach my $key(@k) {
      warn "KEY $key";
      $redis->del("$key") || warn "key doesn't exist";
    }
}

1;

=pod

=head1 NAME

flush_redis.pl - Flush all Redis keys

=head1 SYNOPSIS

flush_redis.pl [options]

 Options:
   -? -help           display this help and exits

=head1 DESCRIPTION

Flush the Redis database.

DON'T DO THIS IN PRODUCTION!!!

=head1 AUTHOR

Peter de Vos, C<techie@sitetechie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, KLIQ Mobile LLC

=cut
