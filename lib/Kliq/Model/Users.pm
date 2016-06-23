package Kliq::Model::Users;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'User' }
#sub path { 'users' }
#sub method { 'profiles' }

around update => sub {
  my ($orig, $self) = (shift, shift);
  my @user_stuff = Kliq::Schema::Result::User->_serializable_rels;
  s/^\+// for @user_stuff;
  no warnings 'redefine';
  local *Kliq::Schema::Result::User::_serializable_rels = sub { () };
  my $result = $self->$orig(@_);
  unless ($result->{error}) {
    $result->{$_} = [] for @user_stuff;
  }
  return $result;
};


__PACKAGE__->meta->make_immutable;

1;
__END__
