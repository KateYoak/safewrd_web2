
package Kliq::Schema::Result::CmsAsset;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("cms_asset");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0
    },
    type => {
        data_type => 'enum',
        extra => { list => [qw/clip video cover banner other/] },
        default_value => 'video',
        is_nullable => 0,
        #is_serializable => 0
    },
    asset_format_id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_nullable => 0,
        is_foreign_key => 1,
        is_serializable => 0
    },
## TODO normalize into CmsMediaAsset, CmsUploadAsset, CmsClipAsset
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
        is_nullable => 1,
        is_foreign_key => 1,
        is_serializable => 0
    },    
    share_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
        is_foreign_key => 1,
        is_serializable => 0
    },    
## /TODO
    name => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 255 
    },
    url => {
        data_type => "varchar",
        is_nullable => 0,
        size => 255, # relax
        #is_serializable => 1
    },    
    signature => {
        data_type => "varchar",
        is_nullable => 1,
        size => 512
    },    
    width => {
        data_type => "smallint",
        extra => { unsigned => 1 },
        default_value => 0, 
        is_nullable => 1 # relax
    },
    height => {
        data_type => "smallint",
        extra => { unsigned => 1 },
        default_value => 0, 
        is_nullable => 1 # relax
    },
    is_preview => {
        data_type => "tinyint",
        extra => { unsigned => 1 },
        size => 1,
        default_value => 0,
        is_nullable => 0    
    },
    is_active => {
        data_type => "tinyint",
        extra => { unsigned => 1 },
        size => 1,
        default_value => 1,
        is_nullable => 0,
        is_serializable => 0
    },
    meta => {
        data_type => 'text',
        is_nullable => 1,
        serializer_class => 'JSON'
    },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 0,
        timezone          => 'UTC',
        datetime_undef_if_invalid => 1,
        set_on_create     => 1,
    },
    last_modified => {
        data_type         => 'DATETIME',
        is_nullable       => 0,
        timezone          => 'UTC',
        datetime_undef_if_invalid => 1,
        set_on_create     => 1,
        set_on_update     => 1,
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    assetformat => 'Kliq::Schema::Result::CmsAssetFormat', 'asset_format_id'
);

__PACKAGE__->belongs_to(
    media => 'Kliq::Schema::Result::CmsMedia', 'media_id'
);

__PACKAGE__->belongs_to(
    upload => 'Kliq::Schema::Result::Upload', 'upload_id'
);

__PACKAGE__->belongs_to(
    clip => 'Kliq::Schema::Result::Share', 'share_id'
);

sub _serializable_rels {
    return qw/+assetformat media upload clip/;
}

1;
__END__

=head1 NAME

Kliq::Schema::Result::CmsAsset

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<cms_asset>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 assetformatid

  data_type: 'integer'
  is_nullable: 0

=head2 serverid

  data_type: 'integer'
  is_nullable: 0

=head2 mediaid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 filename

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 filelength

  data_type: 'integer'
  is_nullable: 0

=head2 width

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 height

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 videoframerate

  data_type: 'decimal'
  is_nullable: 0
  size: [10,2]

=head2 totalbitrate

  data_type: 'integer'
  is_nullable: 0

=head2 audiochannels

  data_type: 'integer'
  is_nullable: 0

=head2 audiosamplerate

  data_type: 'integer'
  is_nullable: 0

=head2 audiobitrate

  data_type: 'integer'
  is_nullable: 0

=head2 durationseconds

  data_type: 'integer'
  is_nullable: 0

=head2 videovbr

  data_type: 'tinyint'
  is_nullable: 0

=head2 ispreview

  data_type: 'tinyint'
  is_nullable: 0

=head2 audiovbr

  data_type: 'tinyint'
  is_nullable: 0

=head2 isactive

  data_type: 'tinyint'
  is_nullable: 0

=head2 filemodificationdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 lastmodifieddate

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back
