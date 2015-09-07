use 5.010;

package Kliq::Model::Events;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use JSON;
use WWW::Mixpanel;
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
    my $result = $self->$orig($params);
    track_event_request('New_Event_Created');
    return $result;
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
    track_event_request('Event_'.ucfirst($event_status));
    return $result;
};

around 'delete' => sub {
    my ($orig, $self, $id) = @_;
    return $self->update($id, {event_status => "deleted"});
};

sub track_event_request {
    my ($action_for_mixpanel) = @_;
    try {
        my $project_token = 'c068cca2163c8db05558cda7ff7bd733';  # TODO: put this in config file; multiple copies exist.
        my $mp = WWW::Mixpanel->new( $project_token, 1 );
        $mp->track($action_for_mixpanel);
    } catch {
        # error("Mixpanel failure: ".$@);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
