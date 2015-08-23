package Kliq::Model::Comments;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'Comment' }
#sub path { 'comments' }
sub method { 'comments' }

__PACKAGE__->meta->make_immutable;

1;
__END__