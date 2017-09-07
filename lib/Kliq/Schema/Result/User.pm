
package Kliq::Schema::Result::User;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
    id => { 
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    username => {
        data_type => "varchar", 
        #default_value => "Anonymous", 
        is_nullable => 0, 
        size => 32,
        is_serializable => 0
    },
    password => {
        data_type        => 'text',
        is_nullable => 0,
        passphrase       => 'rfc2307',
        passphrase_class => 'SaltedDigest',
        passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
            },
        passphrase_check_method => 'check_passphrase',
        is_serializable => 0
    },
    email => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 128,
        is_serializable => 0
    },
    active => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
        is_serializable => 0
    },
    first_name => {
        data_type => "varchar", 
        default_value => "", 
        is_nullable => 0, 
        size => 32,
        is_serializable => 0
    },
    last_name => {
        data_type => "varchar", 
        default_value => "", 
        is_nullable => 0, 
        size => 32,
        is_serializable => 0
    },
    gender => {
        data_type => "enum",
        extra => { list => ["male", "female"] },
        is_nullable => 1,
        is_serializable => 0
    },
    profile_photo => {
        data_type => "blob", 
        is_nullable => 1, # relax
        is_serializable => 0
    },
    picture => {
        data_type => "varchar", 
        is_nullable => 1, 
        size => 500,
        is_serializable => 0
    },
    geo_location => {
        data_type => "varchar",
        is_nullable => 1,
        size => 255
    },
    email_verified => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 1,
        is_serializable => 0
    },
    paid => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
    },
    paid_before => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        is_nullable => 0
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

__PACKAGE__->add_unique_constraint("username", ["username"]);

__PACKAGE__->has_many(
    uploads => 'Kliq::Schema::Result::Upload', 'user_id'
    );

__PACKAGE__->has_many(
    contacts => 'Kliq::Schema::Result::Contact', 'owner_id'
    );

__PACKAGE__->has_many(
    kliqs => 'Kliq::Schema::Result::Kliq', 'user_id'
    );

__PACKAGE__->has_many(
    payments => 'Kliq::Schema::Result::Payment', 'user_id'
    );

__PACKAGE__->has_many(
    tokens => 'Kliq::Schema::Result::OauthToken', 'user_id'
    );

__PACKAGE__->has_many(
    shares => 'Kliq::Schema::Result::Share', 'user_id'
    );

__PACKAGE__->has_many(
    events => 'Kliq::Schema::Result::Event', 'user_id'
    );

__PACKAGE__->has_many(
    comments => 'Kliq::Schema::Result::Comment', 'user_id'
    );

__PACKAGE__->has_many(
    media => 'Kliq::Schema::Result::CmsMedia', 'user_id'
    );

__PACKAGE__->has_many(
    personas => 'Kliq::Schema::Result::Persona', 'user_id'
    );

__PACKAGE__->has_many(
    zencoder_outputs => 'Kliq::Schema::Result::ZencoderOutput', 'user_id'
    );

sub _serializable_rels {
    return qw/
        tokens contacts kliqs uploads shares comments +personas
    /;
}

1;
__END__


=head1 NAME

Kliq::Schema::Result::User

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<users>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 userid

  data_type: 'integer'
  is_nullable: 1

=head2 uname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 pass

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 accttype

  data_type: 'enum'
  extra: {list => ["noone","fan","coach","league","scout","lstat","tstat","superadmin","player","parent","pro_sponsor","vip","affiliate","tnt"]}
  is_nullable: 1

=head2 active

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 lastlogged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 lastip

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 15

=head2 fname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 lname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 roleid

  data_type: 'integer'
  is_nullable: 1

=head2 phone

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 ps

  data_type: 'enum'
  default_value: 1
  extra: {list => [0,1]}
  is_nullable: 0

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 mmscredits

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 mstype

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 authnumber

  data_type: 'integer'
  is_nullable: 1

=head2 msgauthorized

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 notify

  data_type: 'enum'
  default_value: 'realtime'
  extra: {list => ["realtime","halftime","fulltime"]}
  is_nullable: 1

=head2 mobileatlasdeviceid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 phoneorigincity

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 phoneoriginstate

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 phoneoriginlookupstatus

  data_type: 'enum'
  default_value: 'new'
  extra: {list => ["new","failed","success"]}
  is_nullable: 1

=head2 gender

  data_type: 'enum'
  extra: {list => ["male","female"]}
  is_nullable: 1

=head2 birthdate

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 authorizationdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 profile_photo

  data_type: 'blob'
  is_nullable: 0

=head2 picture

  data_type: 'varchar'
  is_nullable: 1
  size: 500

URL to the profile picture.

=head2 emailverified

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 dummy

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

If true, the userdata is dummy data, and the user is unrecoverable by the user. Is set on creation, and unset on profile update.

=head2 verifiedphone

  data_type: 'tinyint'
  is_nullable: 0

=head2 notifyemail

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

If true, provide notifications to the user by email

=head2 notifysms

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

If true, provide notifications to the user by sms

=head2 notifybrowser

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

If true, provide notifications to the user by browser extension

=head2 hash

  data_type: 'varchar'
  is_nullable: 1
  size: 100

A unique hash we use to lookup the user.

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<Phone>

=over 4

=item * L</phone>

=back

=head2 C<hash>

=over 4

=item * L</hash>

=back

=head2 C<uname>

=over 4

=item * L</uname>

=back

=head2 C<userID>

=over 4

=item * L</userid>

=back

=cut
