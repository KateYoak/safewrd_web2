package Kliq::Schema::Result::ZencoderOutput;

use strict;
use warnings;
use base 'Kliq::Schema::Result';

__PACKAGE__->table("zencoder_outputs");

__PACKAGE__->add_columns(
    id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable => 0,
    },
    user_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
        is_foreign_key => 1
    },
    media_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
        is_foreign_key => 1
    }, 
    upload_id => {
        data_type      => 'CHAR',
        size           => 36,
        is_nullable    => 1,
        is_foreign_key => 1
    },
    share_id => { # media clip
        data_type      => 'CHAR',
        size           => 36,
        is_nullable    => 1,
        is_foreign_key => 1
    },
    asset_format_id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_nullable => 0,
        is_foreign_key => 1,
        is_serializable => 0
    },
    zc_job_id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_nullable => 0,
    },
    zc_output_id => {
        data_type => "integer",
        extra => { unsigned => 1 },
        is_nullable => 0,
    },    
    state => {
        data_type => "enum",
        extra => { list => [qw/pending submitting transcoding finished failed/] },
        default_value     => "pending",
        is_nullable => 0,
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

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
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

__PACKAGE__->belongs_to(
    assetformat => 'Kliq::Schema::Result::CmsAssetFormat', 'asset_format_id'
    );

1;
__END__

state:
    pending (not yet submitted to Zencoder)
    submitting (currently submitting to Zencoder)
    transcoding (successfully submitted to Zencoder)
    finished (Zencoder finished transcoding, and the job is done)
    failed (Zencoder was unable to transcode the video)