
package Kliq::Schema::Result::Share;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("shares");

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
    media_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
        is_foreign_key => 1,
        is_serializable => 0
    },
    upload_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1, # relax
        is_foreign_key => 1,
        is_serializable => 0
    },
    title => {
        data_type => "varchar",
        is_nullable => 1,
        size => 64
    },    
    message => {
        data_type => "varchar", 
        size => 1024, # tighten from 10000         
        is_nullable => 1 # relax
    },
    geo_location => {
        data_type => "varchar", 
        is_nullable => 1, 
        size => 256
    },
    offset => {
        data_type => "mediumint",
        extra => { unsigned => 1 },
        default_value => 0,
        is_nullable => 0
    },
    allow_reshare => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0
    },
    allow_location_share => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0
    },
    status => {
        data_type => "enum",
        default_value => "new",
        extra => { list => ["new", "processing", "error", "ready", "published"] },
        is_nullable => 0,
        #is_serializable => 0
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->belongs_to(
    media => 'Kliq::Schema::Result::CmsMedia', 'media_id'
    );

__PACKAGE__->belongs_to(
    upload => 'Kliq::Schema::Result::Upload', 'upload_id'
    );

__PACKAGE__->has_many(
    comments => 'Kliq::Schema::Result::Comment', 'share_id'
    );

__PACKAGE__->has_many(
    zencoder_outputs => 'Kliq::Schema::Result::ZencoderOutput', 'share_id'
    );

__PACKAGE__->has_many(
    assets => 'Kliq::Schema::Result::CmsAsset', 'share_id'
    );

#__PACKAGE__->has_many(
#    upload_assets => 'Kliq::Schema::Result::CmsAsset', 
#    { 'foreign.upload_id' => 'self.upload_id'  }
#    );

__PACKAGE__->has_many(contacts_map => 'Kliq::Schema::Result::ShareContact','share_id');
__PACKAGE__->many_to_many(contacts => 'contacts_map', 'contact' );

__PACKAGE__->has_many(kliqs_map => 'Kliq::Schema::Result::ShareKliq','share_id');
__PACKAGE__->many_to_many(kliqs => 'kliqs_map', 'kliq' );

sub _serializable_rels {
    return qw/+user +upload +kliqs +contacts +comments +assets +media/;
}


1;
__END__


=pod

=head1 NAME

Kliq::Schema::Result::Share

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<kliq_share_sent>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 batchid

  data_type: 'integer'
  is_nullable: 0

=head2 contactid

  data_type: 'integer'
  is_nullable: 0

=head2 entryid

  data_type: 'varchar'
  is_nullable: 0
  size: 150

=head2 mediaid

  data_type: 'integer'
  is_nullable: 1

=head2 networkid

  data_type: 'integer'
  is_nullable: 1

=head2 uploadid

  data_type: 'integer'
  is_nullable: 1

Associated with kliq_share_uploads for KM uploads

=head2 userid

  data_type: 'integer'
  is_nullable: 0

=head2 message

  data_type: 'varchar'
  is_nullable: 0
  size: 10000

=head2 shortmessage

  data_type: 'varchar'
  is_nullable: 1
  size: 2000

=head2 recipient

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 recipientname

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 method

  data_type: 'enum'
  extra: {list => ["twitter","facebook","im","email"]}
  is_nullable: 0

=head2 kliqs

  data_type: 'varchar'
  is_nullable: 0
  size: 200

Comma separated list of kliq ids this message was sent to.

=head2 link

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 hash

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 service

  data_type: 'enum'
  extra: {list => ["google","twitter","facebook","yahoo"]}
  is_nullable: 0

=head2 delivered

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

Time this message was created (before it was sent)


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
