
package Kliq::Schema::Result::CmsMedia;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp UUIDColumns/);
__PACKAGE__->table("cms_media");

__PACKAGE__->add_columns(
    id => { 
        data_type => 'CHAR',
        size => 36, 
        is_nullable => 0 
    },
    type => {
        data_type => "enum",
        extra => { list => ["movie", "episode"] },
        default_value => "movie",
        is_nullable => 0,
        #is_serializable => 0
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
        size => 256 
    },
    title => {
        data_type => "varchar",
        is_nullable => 0,
        size => 256
    },    
    description => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 512 
    },
    status => {
        data_type => "enum",
        default_value => "new",
        extra => { list => ["new", "processing", "error", "ready", "published"] },
        is_nullable => 0,
        #is_serializable => 0
    },
    source_video => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 256,
        is_serializable => 0
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

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->has_many(
    shares => 'Kliq::Schema::Result::Share', 'media_id'
    );

__PACKAGE__->has_many(
    zencoder_outputs => 'Kliq::Schema::Result::ZencoderOutput', 'media_id'
    );

__PACKAGE__->has_many(
    assets => 'Kliq::Schema::Result::CmsAsset', 'media_id'
    );

sub _serializable_rels {
    return qw/assets/;
}

1;
__END__

=head1 NAME

Kliq::Schema::Result::CmsMedia

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<cms_media>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 networkid

  data_type: 'integer'
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 longdescription

  data_type: 'text'
  is_nullable: 0

=head2 copyright

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 keywords

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 publishdate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '2001-01-01 00:00:00'
  is_nullable: 0

=head2 isactive

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 lastmodifieddate

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 status

  data_type: 'enum'
  default_value: 'new'
  extra: {list => ["new","processing","error","ready","published"]}
  is_nullable: 0

=head2 sourcevideopath

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 adid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 titleabove

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 titlebelow

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut