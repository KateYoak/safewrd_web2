package Kliq::Model::Kliqs;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use DateTime;
use JSON ();
extends 'Kliq::Model::Base';

sub table { 'Kliq' }
#sub path { 'kliqs' }
sub method { 'kliqs' }


__PACKAGE__->meta->make_immutable;

1;
__END__