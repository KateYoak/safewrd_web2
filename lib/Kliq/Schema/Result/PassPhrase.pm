package Kliq::Schema::Result::PassPhrase;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("passphrases");

__PACKAGE__->add_columns(
    id => { 
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    passphrase => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 255,
        is_serializable => 0
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

__PACKAGE__->add_unique_constraint("passphrase", ["passphrase"]);

1;
__END__


=head1 NAME

Kliq::Schema::Result::PassPhrases

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<passphrases>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 passphrase

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 data

  data_type: 'text'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<passphrase>

=over 4

=item * L</passphrase>

=back

=cut
