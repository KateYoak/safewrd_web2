package Kliq::Worker::Role::HasConfig;

use namespace::autoclean;
use Moose::Role;

has config => (
    is => 'ro',
    isa => 'HashRef'
);

no Moose::Role;

1;
__END__