package Kliq::Worker::Role::WithSchema;

use namespace::autoclean;
use Moose::Role;
use Kliq::Types qw/ConnectInfo Schema/;
use Kliq::Schema;

has schema => (
    isa        => Schema['Kliq::Schema'],
    is         => 'ro',
    lazy_build => 1,
    predicate  => 'has_schema',
    );

has 'connect_info' => (
    is        => 'ro',
    isa       => ConnectInfo,
    coerce    => 1,
    required  => 0,
    predicate => 'has_connect_info',
    );

sub _build_schema {
    my $self = shift;
    return Kliq::Schema->connect($self->connect_info)
        or die("Could not connect to Store");
    }

sub BUILD {} after BUILD => sub {
    my $self = shift;

    confess "Invalid connection arguments - "
        . "either 'connect_info' or 'schema' must be supplied"
        unless ($self->has_connect_info || $self->has_schema);

    return;
    };

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $args = $orig->(@_);

    confess "Invalid connection arguments - "
        . "either 'connect_info' or 'schema' must be supplied"
        unless ($args->{connect_info} || $args->{schema});

    return $args;
    };

no Moose::Role;

1;
__END__
