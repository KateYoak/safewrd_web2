
package Kliq::Schema::Result::Comment;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("comments");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36, 
        is_nullable => 0 
    },
    user_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0, # tighten
        is_foreign_key => 1,
        is_serializable => 0
    },
    share_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
        is_foreign_key => 1
    },
    picture => {
        data_type => "varchar", 
        is_nullable => 1, 
        size => 500,
        is_serializable => 0
    },
    text => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 512 # tighten from 10000 
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->belongs_to(
    share => 'Kliq::Schema::Result::Share', 'share_id'
    );

sub _serializable_rels {
    return qw/share/;
}

1;
__END__

=head1 NAME

Kliq::Schema::Result::Comment

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<kliq_share_comments>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 userid

  data_type: 'integer'
  is_nullable: 1

If a registered user commented, this is their id

=head2 contactid

  data_type: 'integer'
  is_nullable: 1

If a registered contact commented, this is their id

=head2 sentid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: 'Unknown'
  is_nullable: 0
  size: 200

The displayed name for the comment

=head2 picture

  data_type: 'varchar'
  is_nullable: 1
  size: 500

The url of the commentor's picture

=head2 text

  data_type: 'varchar'
  is_nullable: 0
  size: 10000

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
