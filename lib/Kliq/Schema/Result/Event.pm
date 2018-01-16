
package Kliq::Schema::Result::Event;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("events");

__PACKAGE__->add_columns(
  id      => {data_type => 'CHAR', size => 36, is_nullable => 0},
  user_id => {
    data_type       => 'CHAR',
    size            => 36,
    is_nullable     => 0,
    is_foreign_key  => 1,
    is_serializable => 0
  },
  kliq_id =>
    {data_type => 'CHAR', size => 36, is_foreign_key => 1, is_nullable => 0},
  title => {data_type => "varchar", is_nullable => 0, size => 64},
  image => {data_type => "varchar", is_nullable => 1, size => 150},
  when_occurs =>
    {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 0},
  location => {data_type => "varchar", size => 64, is_nullable => 1},
  price        => {data_type => "decimal", size => [10, 2], is_nullable => 0,},
  event_status => {
    data_type     => "varchar",    # enum of {new,confirmed,deleted,published}
    size          => 20,
    is_nullable   => 0,
    default_value => "new",
  },
  rtmp_url => {data_type => "varchar", is_nullable => 1, size => 150},
  created  => {
    data_type                 => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value             => \"current_timestamp",
    is_nullable               => 0
  }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(user => 'Kliq::Schema::Result::User', 'user_id');
__PACKAGE__->belongs_to(kliq => 'Kliq::Schema::Result::Kliq', 'kliq_id');

sub _serializable_rels {
  return qw/+user +kliq/;
}

sub nearest_drone {
  my $self = shift;

  my ($lat, $lng) = @_;
  return $self->result_source->schema->resultset('Drone')->search(
    {location => {'!=' => undef}},
    {
      rows       => 1,
      '+columns' => [{lat => \'ST_Y(location)'}, {lng => \'ST_X(location)'},],
      order_by   => \[
        'ST_Distance_Sphere(location , ST_GeomFromText(?, 4326)) ASC',
        [_q => "POINT($lng $lat)"]
      ]
    }
  )->next;
}
1;
__END__
