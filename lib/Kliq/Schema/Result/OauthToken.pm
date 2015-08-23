
package Kliq::Schema::Result::OauthToken;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("oauth_tokens");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    user_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
        is_foreign_key => 1,
        is_serializable => 0
    },
    persona_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
        is_foreign_key => 1,
        is_serializable => 0
    },    
    token => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 4096, # relax
        #is_serializable => 0
    },
    secret => {
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 4096, # relax from 75
        #is_serializable => 0
    },
    service => {
        data_type => "enum",
        extra => { list => ["google", "twitter", "facebook", "yahoo", "linkedin"] },
        is_nullable => 0
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    },
    expires => {
        #data_type => "timestamp",
        #datetime_undef_if_invalid => 1,
        ##default_value => \"current_timestamp",
        data_type      => 'VARCHAR',
        size           => 64,
        is_nullable => 1
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

#TOO LONG
#__PACKAGE__->add_unique_constraint("user_service", [qw/user_id token service/]);

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->belongs_to(
    persona => 'Kliq::Schema::Result::User', 'user_id'
    );

1;
__END__

=pod

=head1 NAME

Kliq::Schema::Result::OauthToken - Stores the auth tokens for connecting to 
various services.

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<kliq_share_oauth_tokens>

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

Primary ID

=head2 token

  data_type: 'varchar'
  is_nullable: 0
  size: 75

Auth token

=head2 secret

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

Userid associated with this token.

=head2 service

  data_type: 'enum'
  default_value: 'google'
  extra: {list => ["google","twitter","facebook","yahoo"]}
  is_nullable: 0

The service this token is associated with.

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

Time the token was created.

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
