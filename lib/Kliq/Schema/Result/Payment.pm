package Kliq::Schema::Result::Payment;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("payments");

__PACKAGE__->add_columns(
    id => { 
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    user_id => { 
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 0,
    },
    payment_type => {
        data_type => 'varchar',
        is_enum => 1,
        extra => {
            list => [qw/money promo free/]
        }
    },
    payment_promo => {
        data_type => "varchar", 
        is_nullable => 1,
        size => 30
    },
    cost => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00',
        is_currency    => 1
    },
    status => {
        data_type => "varchar", 
        is_nullable => 0,
        size => 30,
        default_value => "PROCESSING",
    },
    transaction_id => {
        data_type => "varchar", 
        is_nullable => 1,
        size => 100
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

__PACKAGE__->belongs_to(user => 'Kliq::Schema::Result::User','user_id');

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
