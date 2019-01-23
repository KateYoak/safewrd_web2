package Kliq::Schema::Result::Drone;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("drone");
__PACKAGE__->add_columns(
  "id",
  {data_type => "char", is_nullable => 0, size => 36},
  "created",
  {
    data_type                 => "timestamp",
    is_nullable               => 0,
    timezone                  => 'UTC',
    datetime_undef_if_invalid => 1,
    default_value             => \"current_timestamp",
    set_on_create             => 1,
  },
  "location",
  {data_type => "point", is_nullable => 1},
  "in_flight",
  {data_type => "tinyint", default_value => 0, is_nullable => 1},
  "vehicle_id",
  {data_type => "varchar", is_nullable => 1, size => 100},
  "access_token",
  {data_type => "text", is_nullable => 1},
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

use JSON;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new();

sub update_location {
  my ($self, $lat, $lng) = @_;
  $self->update(
    {location => \[q{ST_GeomFromText(?, 4326)}, [_q => "POINT($lng $lat)"]]});
}

sub update_destination {
  my ($self, $lat, $lng) = @_;
  $ua->post(
    'http://localhost:8888/update_location',
    'Content-Type' => 'application/json',
    Content        => JSON::encode_json(
      {
        access_token     => $self->access_token,
        vehicle_id       => $self->vehicle_id,
        mission_location => {lat => $lat + 0, lng => $lng + 0,}
      }
    )
  );
}

sub update_blockchain {
  my ($self, %payload) = @_;
  $ua->post(
    'https://air.eosrio.io/api/action',
    'Content-Type' => 'application/json',
    Content        => JSON::encode_json(\%payload)
  );
}

sub goto_mission {
  my ($drone, $mission) = @_;
  my $event = $mission->event;
  my ($lat, $lng) = $event->latlng;

  my $mission_hash = $mission->build_hash;

  $self->update_blockchain(
    user_id     => $event->user_id,
    action_name => 'newmission',
    data =>
      {user => $event->user->aireos_user_id, mission_hash => $mission_hash}
  );

  $ua->post(
    'http://localhost:8888/mission',
    'Content-Type' => 'application/json',
    Content        => JSON::encode_json(
      {
        vehicle_id       => $drone->vehicle_id,
        mission_wait     => 15,
        mission_location => {lat => $lat + 0, lng => $lng + 0,},
        home_location    => {
          lat => $drone->get_column('lat') + 0,
          lng => $drone->get_column('lng') + 0
        },
        "alt"       => 5,
        "wait_time" => 10,

        stream_url => $event->rtmp_url,

        # new parameters
        event_id   => $event->id,
        mission_id => $mission->id,
        event_type => 'find',

        # poi        => {
        #   wait_time => 15.0,
        #   clearance => 10.0,
        #   alt       => 5.0,
        #   lat       => $lat + 0,
        #   long      => $lng + 0,
        # },

        token           => $mission_hash,
        token_check_url => 'token_check_url',
      }
    )
  );

}

1;
__END__
