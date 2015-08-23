
package Kliq::Schema::Result::CmsAssetFormat;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("cms_asset_format");

__PACKAGE__->add_columns(
    id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable => 0,
        is_serializable => 0
    },
    name => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 64
    },
    label => {
        data_type => "varchar",
        is_nullable => 0,
        size => 16
    },    
    description => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 128,
        is_serializable => 0
    },
    mime_type => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 64 
    },
    file_extension => {
        data_type => "varchar",
        is_nullable => 1,
        size => 16
    },
    zencoder_params => {
        data_type => 'text',
        is_nullable => 1,
        serializer_class => 'JSON',
        is_serializable => 0
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('label', ['label']);
__PACKAGE__->add_unique_constraint('file_extension', ['file_extension']);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'idx_label', fields => ['label']);
}

1;
__END__

=head1 NAME

Kliq::Schema::Result::CmsAssetformat

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<cms_assetformat>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 networkid

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 shortname

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 mimetype

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 defaultserverid

  data_type: 'integer'
  is_nullable: 0

=head2 lastmodifieddate

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 ffmpegcreationcommand

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 512

=head2 fileextension

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 faststartrequired

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
