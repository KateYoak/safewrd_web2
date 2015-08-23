package Kliq::Model::Users;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'User' }
#sub path { 'users' }
#sub method { 'profiles' }


__PACKAGE__->meta->make_immutable;

1;
__END__