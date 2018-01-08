use 5.010;

package Kliq::Model::Events;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use JSON;
use WWW::Mixpanel;
use LWP::UserAgent;

use URI;
extends 'Kliq::Model::Base';

sub table {'Event'}

#sub path { 'events' }
sub method {'events'}

around 'create' => sub {
  my ($orig, $self, $params) = @_;
  my $event_status = $params->{event_status} // 'new';
  unless ($event_status eq 'new') {
    return {
      error => {
        field    => 'event_status',
        code     => 'invalid_field_value',
        resource => 'Event',
      }
    };
  }
  my $live_url = _build_rtmp_url();
  if ($live_url) {
    $params->{rtmp_url} = $live_url;
  }
  else {
    return {
      error => {
        field    => 'rtmp_url',
        code     => 'unable_to_resolve_url',
        resource => 'Event',
      }
    };
  }
  my $result = $self->$orig($params);
  track_event_request('New_Event_Created');
  return $result;
};

sub _build_rtmp_url {
  my $load_balancer_endpoint
    = URI->new('http://receiver.tranzmt.it:3030/freeserver');
  my $ua       = LWP::UserAgent->new();
  my $response = $ua->get($load_balancer_endpoint->canonical);

  if ($response->is_success()) {
    my $content  = $response->decoded_content();
    my $route    = from_json($content);
    my $rtmp_url = URI->new('rtmp://' . $route->{'ip'} . ':1935/live');
    return $rtmp_url->canonical;
  }
  else {
    return undef;
  }
}

sub _call_drone {
  my ($self) = @_;
  my $ua = LWP::UserAgent->new();
  my ($lat, $lng) = map { s/^\s+|\s+$//g; $_ } split(/,/, $self->location);
  my $response = $ua->post(
    'http://localhost:8899',
    Content_Type => 'application/json',
    Content      => JSON::encode_json(
      {
        "drone_id"  => 1,
        "lat"       => $lat,
        "lng"       => $lng,
        "alt"       => 5,
        "wait_time" => 10,
        stream_url  => $self->rtmp_url,

        # token => $smart_contract_token
      }
    )
  );
}

around 'update' => sub {
  my ($orig, $self, $id, $params) = @_;

  # Do not process further for image upload
  if ($params->{image}) {
    my $ret_result = $self->$orig($id, $params);
    return $ret_result;
  }

  my $event_status = $params->{event_status} // '';
  unless ($event_status eq 'new'
    or $event_status eq 'test'
    or $event_status eq 'confirmed'
    or $event_status eq 'deleted'
    or $event_status eq 'published')
  {
    return {
      error => {
        field    => 'event_status',
        code     => 'invalid_field_value',
        resource => 'Event',
      }
    };
  }

  # TODO: Consider validating whether other fields may be changed too or not.
  my $result = $self->$orig($id, {event_status => $event_status});
  if ( $event_status eq 'confirmed'
    or $event_status eq 'published'
    or $event_status eq 'test')
  {
    $self->_call_drone
      if $event->kliq->is_emergency && $self->kliq->drone_enabled;
    $self->redis->rpush(notifyEvent => to_json({event => $id}));
  }
  track_event_request('Event_' . ucfirst($event_status));
  return $result;
};

around 'delete' => sub {
  my ($orig, $self, $id) = @_;
  return $self->update($id, {event_status => "deleted"});
};

sub track_event_request {
  my ($action_for_mixpanel) = @_;
  try {
    my $project_token = 'c068cca2163c8db05558cda7ff7bd733'
      ;    # TODO: put this in config file; multiple copies exist.
    my $mp = WWW::Mixpanel->new($project_token, 1);
    $mp->track($action_for_mixpanel);
  }
  catch {
    # error("Mixpanel failure: ".$@);
  }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
