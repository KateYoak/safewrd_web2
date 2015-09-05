use 5.010;

package Kliq::Model::Events;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'Event' }
#sub path { 'events' }
sub method { 'events' }

around 'create' => sub {
    my ($orig, $self, $params) = @_;
    my $event_status = $params->{event_status} // 'new';
    unless ($event_status eq 'new')
    {
        return {error => {
            field => 'event_status',
            code => 'invalid_field_value',
            resource => 'Event',
        }};
    }
    return $self->$orig($params);
};

around 'update' => sub {
    my ($orig, $self, $id, $params) = @_;
    my $event_status = $params->{event_status} // '';
    unless ($event_status eq 'new' or $event_status eq 'confirmed'
        or $event_status eq 'deleted' or $event_status eq 'published')
    {
        return {error => {
            field => 'event_status',
            code => 'invalid_field_value',
            resource => 'Event',
        }};
    }
    # TODO: Consider validating whether other fields may be changed too or not.
    my $result = $self->$orig($id, {event_status => $event_status});
    if ($event_status eq 'confirmed' or $event_status eq 'published')
    {
        $self->redis->rpush(notifyEvent => to_json({event => $id}));
    }
    return $result;
};

around 'delete' => sub {
    my ($orig, $self, $id) = @_;
    return $self->update($id, {event_status => "deleted"});
};

__PACKAGE__->meta->make_immutable;

1;
__END__
