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
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');


sub update_location {
  my ($self, $lat, $lng) = @_;
  $self->update(
    {location => \[q{ST_GeomFromText(?, 4326)}, [_q => "POINT($lng $lat)"]]});
}

1;
__END__
