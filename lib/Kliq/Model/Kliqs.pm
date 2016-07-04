package Kliq::Model::Kliqs;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use DateTime;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'Kliq' }
#sub path { 'kliqs' }
sub method { 'kliqs' }

around 'create' => sub {
    my ($orig, $self, $params) = @_;

    my $res = $self->$orig($params);

    # Invite users to the app for those users who doesn't have the app installed
#    if ($res->{is_emergency}) {
        $self->redis->rpush(notifyKliq => to_json({
            kliq  => $res->{id},
        }));
#    }

    return $res;
};

__PACKAGE__->meta->make_immutable;

1;
__END__
