package Kliq::Model::Contacts;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'Contact' }
#sub path { 'contacts' }
sub method { 'contacts' }


__PACKAGE__->meta->make_immutable;

1;
__END__