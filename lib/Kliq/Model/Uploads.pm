package Kliq::Model::Uploads;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'Upload' }
#sub path { 'uploads' }
sub method { 'uploads' }

around 'create' => sub {
    my ($orig, $self, $params) = @_;

    my $res = $self->$orig($params);
    return $res if $res->{error};
    
    $self->redis->rpush(zencode => to_json({
        id     => $params->{id},
        suffix => $params->{suffix},        
        user   => $self->user->id,
        type   => 'upload'
    }));

    return $res;
};

__PACKAGE__->meta->make_immutable;

1;
__END__