package Kliq::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw/ MooseX::Types::Common::String
        MooseX::Types::Common::Numeric
        MooseX::Types::Email
        MooseX::Types::Moose
        MooseX::Types::URI
        MooseX::Types::UUID
        MooseX::Types::DBIx::Class
        Kliq::Types::Internal
    /);

1;
__END__


=pod

=head1 NAME

Kliq::Types - Exports Kliq internal types as well as Moose types

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=cut

