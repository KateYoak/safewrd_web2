
package Kliq::Schema::Result::Upload;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("uploads");

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
    title => {
        data_type => "varchar",
        is_nullable => 1,
        size => 64
    },
    suffix => {
        data_type => "varchar",
        is_nullable => 0,
        size => 6
    },    
    mime_type => {
        data_type => "varchar",
        is_nullable => 0,
        size => 64
    },    
    path => {
        data_type => "varchar", 
        is_nullable => 0, 
        size => 500,
        is_serializable => 0
    },
    status => {
        data_type => "enum",
        default_value => "new",
        extra => { list => ["new", "processing", "error", "ready", "published"] },
        is_nullable => 0,
        #is_serializable => 0
    },    
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 0,
        timezone          => 'UTC',
        datetime_undef_if_invalid => 1,
        set_on_create     => 1,
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->has_many(
    shares => 'Kliq::Schema::Result::Share', 'upload_id'
    );

__PACKAGE__->has_many(
    assets => 'Kliq::Schema::Result::CmsAsset', 'upload_id'
    );

__PACKAGE__->has_many(
    zencoder_outputs => 'Kliq::Schema::Result::ZencoderOutput', 'upload_id'
    );

sub _serializable_rels {
    return qw/+assets shares/;
}

1;
__END__

=pod

=head1 NAME

Kliq::Schema::Result::Upload

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=head1 TABLE: C<kliq_share_uploads>

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 mediaid

  data_type: 'integer'
  is_nullable: 0

=head2 networkid

  data_type: 'integer'
  is_nullable: 1

=head2 path

  data_type: 'varchar'
  is_nullable: 0
  size: 500

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut
