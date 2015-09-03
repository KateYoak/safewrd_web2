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

around 'search' => sub {
    my $orig = shift;
    my $self = shift;

    #-- all my events
    my $res = $self->$orig(@_);

    #-- all eventd with me

    return $res;
};

sub create {
    my ($self, $params) = @_;

    #-- save the event

    my ($event, $error);
    my $method = $self->method;
    try {
        $event = $self->user->add_to_events($params);
    } catch {
        $error = $self->error($_, 'events');
    };
    if($error || !$event) {
        return $error || $self->error(undef, 'events');
    }

    return $self->get($event->id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
