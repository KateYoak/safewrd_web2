package Kliq::Schema::Result::Mission;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("mission");
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
  "from_location",
  {data_type => "point", is_nullable => 1},
  "to_location",
  {data_type => "point", is_nullable => 1},
  "event_id",
  {data_type => "varchar", is_nullable => 1, size => 100},
  "drone_id",
  {data_type => "varchar", is_nullable => 1, size => 100},
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');


__PACKAGE__->belongs_to(drone => 'Kliq::Schema::Result::Drone', 'drone_id');
__PACKAGE__->belongs_to(event => 'Kliq::Schema::Result::Event', 'event_id');

use Digest::SHA qw(sha256_hex);
use JSON;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new();

sub build_hashes {
  my $self  = shift;
  my $event = $self->event;
  my ($lat, $lng) = $event->latlng;
  my $user_id = $event->user_id;
  my $mission_hash = lc sha256_hex(join(q{|}, $user_id, $event->id, $self->id));
  my $waypoint_hash = lc sha256_hex(join(q{|}, $mission_hash, $lat, $lng));
  return ($mission_hash, $waypoint_hash);
}

sub eos_info {
  my $self = shift;
  my ($mission_hash, $waypoint_hash) = $mission->build_hashes;
  my $user = $self->event->user;
  my $res =
    $ua->get('https://air.eosrio.io/api/missions/' . $user->aireos_user_id);
  if ($res->is_success) {
    my $info = JSON::from_json($res->decoded_content);
    my ($mission) =
      grep { lc $_->{mission_hash} eq lc $mission_hash } @{$info->{rows} || []};
    return $mission;
  }
  else {
    warn qq|ERROR fetching misson's EOS info: \n| . $res->content;
    return {};
  }
}

1;
__END__
