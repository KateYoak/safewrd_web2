package Kliq::Model::Assets;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'CmsAsset' }
#sub path { 'assets' }
#sub method { 'uploads' }

__PACKAGE__->meta->make_immutable;

1;
__END__