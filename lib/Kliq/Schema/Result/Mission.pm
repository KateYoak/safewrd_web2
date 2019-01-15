package Kliq::Schema::Result::Mission;

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
__PACKAGE__->belongs_to(event => 'Kliq::Schema::Result::Drone', 'event_id');


1;
__END__
