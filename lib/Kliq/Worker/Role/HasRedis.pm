package Kliq::Worker::Role::HasRedis;

use namespace::autoclean;
use Moose::Role;
use Redis;

has 'redis' => (
    is       => 'ro',
    required => 0,
    isa      => 'Redis',
    default => sub { Redis->new() }
);

no Moose::Role;

1;
__END__