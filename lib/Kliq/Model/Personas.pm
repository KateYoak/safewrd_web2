package Kliq::Model::Personas;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'Persona' }
sub method { 'personas' }

__PACKAGE__->meta->make_immutable;

1;
__END__