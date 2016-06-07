package Kliq::Schema::Result::Kliq;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("kliqs");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0
    },
    user_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
        is_foreign_key => 1,
        is_serializable => 0
    },
    name => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 100 
    },
    image => {
        data_type => "varchar",
        is_nullable => 1,
        size => 150
    },
    is_emergency => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0,
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to( user => 'Kliq::Schema::Result::User', 'user_id' );

__PACKAGE__->has_many(contacts_map => 'Kliq::Schema::Result::KliqContact','kliq_id');
__PACKAGE__->many_to_many(contacts => 'contacts_map', 'contact' );

__PACKAGE__->has_many(
    events => 'Kliq::Schema::Result::Event', 'kliq_id'
    );

sub _serializable_rels {
    return qw/+contacts/;
}

1;
__END__

=pod

=head1 NAME

Kliq::Schema::Result::Kliq

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<Helper::Row::ToJSON>

=back

=head1 TABLE: C<kliq_share_kliqs>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 userid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
