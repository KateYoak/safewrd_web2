package Kliq::Model::Media;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'CmsMedia' }
#sub path  { 'media' }
#sub method { 'media' }

around 'create' => sub {
    my ($orig, $self, $params) = @_;

    #-- media posts from SSM represent an initial asset outside the 'assets' 
    #-- array, coming in as 'source_video' and residing in the 
    #-- 'clqs-media' CloudFiles container

    $params->{user_id} ||= '94A4988D-93F8-1014-A991-F7EDC84F2656';
    
    my $res = $self->$orig($params);
    return $res if $res->{error};
    
    $self->redis->rpush(zencode => to_json({
        id     => $res->{id},
        user   => $params->{user_id},
        type   => 'media',
        source => $params->{source_video}
    }));

    return $res;
};


__PACKAGE__->meta->make_immutable;

1;
__END__
