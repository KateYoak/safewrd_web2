
package Kliq::Schema::Result::Contact;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("contacts");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    user_id => { 
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1, # for real, matched later
        is_foreign_key => 1
    },
    owner_id => { 
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
        is_foreign_key => 1,
        is_serializable => 0
    },
## MOVE2PERSONA
    handle => {
        data_type => "varchar",
        is_nullable => 0,
        size => 255,
    },
    hash => {
        data_type => "varchar",
        is_nullable => 1, # relax
        size => 35,
        is_serializable => 0
    },
    service => {
        data_type => "enum",
        extra => { list => ["google", "twitter", "facebook", "yahoo", "linkedin", "manual"] },
        is_nullable => 0,
    },
    screen_name => {
        data_type => "varchar",
        is_nullable => 1,
        size => 75
    },
    name => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 50,
    },
    email => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 50 
    },
    phone => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 15,
        is_serializable => 0
    },
    website => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 200,
        is_serializable => 0
    },
    image => {
        data_type => "varchar", 
        is_nullable => 1, 
        size => 255 
    },
    gender => {
        data_type => "enum",
        extra => { list => ["male", "female"] },
        is_nullable => 1,
    },
    org_name => { 
        data_type => "varchar", 
        is_nullable => 1,  # relax
        size => 75,
        is_serializable => 0
    },
    org_title => { 
        data_type => "varchar", 
        is_nullable => 1,  # relax
        size => 75,
        is_serializable => 0
    },
    location => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 200,
        is_serializable => 0
    },
    timezone => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 75,
        is_serializable => 0
    },
    language => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 10,
        is_serializable => 0
    },
    # DEPRECATED. TODO many2many mapping table
    #kliq => { 
    #    data_type => "integer", 
    #    default_value => 0, 
    #    is_nullable => 0,
    #    is_serializable => 0,
    #},
    optedin => { 
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
        is_serializable => 0
    },
## /MOVE2PERSONA    
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');
__PACKAGE__->add_unique_constraint("owner_service_contact", [qw/owner_id handle service/]);

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->belongs_to( # imported_by
    owner => 'Kliq::Schema::Result::User', 'owner_id'
    );

__PACKAGE__->has_many(map_kliqs => 'Kliq::Schema::Result::KliqContact','contact_id');
__PACKAGE__->many_to_many(kliqs => 'map_kliqs', 'kliq' );

__PACKAGE__->has_many(map_shares => 'Kliq::Schema::Result::ShareContact','contact_id');
__PACKAGE__->many_to_many(shares => 'map_shares', 'share' );

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->next::method(@args);

    #-- find possible userid in persona or other contacts(?)
    my $crit = $self->service =~ /(twitter|facebook)/ ?
        { handle => $self->handle } : { email => $self->email };
    my $known_persona = $self->result_source->schema->resultset('Persona')->search_rs($crit)->single();
    if($known_persona) {
        $self->update({ user_id => $known_persona->user_id });
    }
    else {
        my @contacts = $self->result_source->schema->resultset('Contact')->search_rs(
            $crit, { group_by => 'user_id' }
        )->all();
        my $count = scalar(@contacts);
        if($count > 1) {
            die("Database inconsistent: multiple user_ids for same service handle");
        }
        elsif($count) {
            $self->update({ user_id => $contacts[0]->user_id });
        }
    }

    $guard->commit;

    return $self;
}

1;
__END__

=head1 NAME

Kliq::Schema::Result::Contact

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<Helper::Row::ToJSON>

=back

=head1 TABLE: C<kliq_share_contacts>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 userid

  data_type: 'integer'
  is_nullable: 1

If the contact has a user account, this is his userid in the Users table.

=head2 friendid

  data_type: 'integer'
  is_nullable: 0

=head2 entryid

  data_type: 'varchar'
  is_nullable: 0
  size: 300

=head2 hash

  data_type: 'varchar'
  is_nullable: 0
  size: 35

md5('entryid')

=head2 service

  data_type: 'enum'
  extra: {list => ["google","twitter","facebook","yahoo","manual"]}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 phone

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 website

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 150

=head2 orgname

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 orgtitle

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 handle

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 timezone

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 language

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 kliq

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 optedin

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

If the user is optedin, by responding to SMS.

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
