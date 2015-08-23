package Kliq::Model::ZencoderOutput;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use JSON;

has 'schema' => (
    is => 'ro',
    #isa => 'Int'
    required => 1
    );

has 'redis' => (
    is => 'ro',
    isa => 'Redis',
    required => 1
    );

my %TYPES = (
    'clqs-media'   => 'media',
    'clqs-uploads' => 'upload',
    'clqs-clips'   => 'clip',
);

my %CDNBASE = (
    'clqs-media'   => 'http://ead54a85a0e71e8d6209-578e57646269a0417cf8d221c5ffac7c.r72.stream.cf1.rackcdn.com/',
    #'clqs-clips'   => 'http://ba20d13d0361554c0b18-3b81457645e7e1875ae377260f03675d.r53.stream.cf1.rackcdn.com/',
    'clqs-uploads' => 'http://7aa15ac0cfec6422a23a-12e7ceaa5ace449913f905b03e712ec3.r67.cf1.rackcdn.com/',
    'clqs-clips'   => 'http://60bb951eb1853fd1fbc7-3b81457645e7e1875ae377260f03675d.r53.cf1.rackcdn.com/'
);

sub process_output {
    my ($self, $json) = @_;
    
    my $job     = $json->{job} or die('Invalid job JSON');
    my $job_id  = $job->{id}   or die('Invalid job JSON - no job_id');

    my $out = $json->{output} or die('Invalid output JSON');
    my $out_id  = $out->{id}  or die('Invalid output JSON - no output_id');    
    
    die("Output failed: " . $out->{state}) unless $out->{state} eq 'finished';
    die("Job failed: " . $job->{state})    unless $job->{state} =~ /^(finished|processing)$/;

    my $output = $self->schema->resultset('ZencoderOutput')->find({
        state        => 'transcoding',
        zc_job_id    => $job_id,
        zc_output_id => $out_id
        }) or die("Output $out_id for job $job_id not found");

    my ($container, $file, $type, $method, $object);
    if($out->{url} =~ /\@(.*)\/(.*)/) {
        $container = $1;
        $file = $2;
        $type = $TYPES{$container} or die("Invalid CDN container " . $container);
        $method = $type . '_output_results';
    
        foreach(qw/id state url/) {
            delete $out->{$_};
        }
        $object = $self->$method($output, $out, $CDNBASE{$container}, $file);
    }
    else {
        die("Invalid CDN URL:" . $out->{url});
    }

    $output->update({ state => 'finished' });
    
    if($job->{state} eq 'finished') {
        my $job_method = $type . '_job_results';
        $self->$job_method($object);
    }
}

sub media_output_results {
    my ($self, $output, $meta, $url_base, $file) = @_;
    
    #-- add video (and possibly thumbnails) as media asset
    
    my $media = $output->media or die("Invalid Zencoder output - not a media");
    my $format = $output->assetformat;
    my $name = $media->type eq 'episode' ? 
        join(' - ', $media->name, $media->title) : $media->name;
    
    if($meta->{thumbnails}) {
        my $thumb_base = $url_base . $media->id;
        $self->add_thumbnails($meta->{thumbnails}, $media, $thumb_base, $name);
        delete $meta->{thumbnails};
    }
    
    my $asset = $media->add_to_assets({
        asset_format_id => $output->asset_format_id,
        name => join(' - ', $name, $format->name),
        url => $url_base . $file,
        width => $meta->{width} || 0,
        height => $meta->{height} || 0,
        meta => $meta
    });

    #-- download zencoded output, store in /assets for clipping if source-mp4,
    #-- fingerprint, update the database and POST the fingerprint to AM
    $self->redis->rpush(amdbPush => to_json({
        keep => $format->label eq 'source-mp4' ? 1 : 0,
        file => $file,
        guid => $asset->id
    }));

    return $media;
}

sub upload_output_results {
    my ($self, $output, $meta, $url_base, $file) = @_;

    #-- add video (and possibly thumbnails) as upload asset

    my $upload = $output->upload or die("Invalid Zencoder output - not an upload");
    my $name = $upload->title || '';
    
    if($meta->{thumbnails}) {
        my $thumb_base = $url_base . $upload->id;
        $self->add_thumbnails($meta->{thumbnails}, $upload, $thumb_base, $name);
        delete $meta->{thumbnails};
    }
    
    $upload->add_to_assets({
        asset_format_id => $output->asset_format_id,
        name => $name ? join(' - ', $name, $output->assetformat->name)
                      : $output->assetformat->name,
        url => $url_base . $file,
        width => $meta->{width} || 0,
        height => $meta->{height} || 0,
        meta => $meta
    });
    
    return $upload;
}

sub clip_output_results {
    my ($self, $output, $meta, $url_base, $file) = @_;
    
    my $share = $output->clip or die("Invalid Zencoder output - not a clip");
    my $name = $share->title || '';

    if($meta->{thumbnails}) {
        my $thumb_base = $url_base . $share->id;
        $self->add_thumbnails($meta->{thumbnails}, $share, $thumb_base, $name);
        delete $meta->{thumbnails};
    }
    
    $share->add_to_assets({
        asset_format_id => $output->asset_format_id,
        name => $name ? join(' - ', $name, $output->assetformat->name)
                      : $output->assetformat->name,
        url => $url_base . $file,
        width => $meta->{width} || 0,
        height => $meta->{height} || 0,
        meta => $meta
    });

    return $share;
}

sub add_thumbnails {
    my ($self, $thumbset, $up_or_med, $thumb_base, $name) = @_;

    foreach my $thumbset(@{ $thumbset }) {

        my $thumb = $thumbset->{images}->[0];
        my($w,$h) = split('x', $thumb->{dimensions}); # eg '240x160'
        die("Invalid thumbnail dimensions: " . $thumb->{dimensions}) unless($w && $h);

        my $label = $thumbset->{label} or die("Invalid thumnail set");

        my $asset_type = $label;
        $asset_type =~ s/^thumb-//;

        my $format = $self->schema->resultset('CmsAssetFormat')->find({ label => $label })
            or die("Invalid thumbset label");

        my %meta = map { $_ => $thumb->{$_} } grep { $thumb->{$_} } qw/dimensions format file_size_bytes/;
        $up_or_med->add_to_assets({
            asset_format_id => $format->id,
            name   => $name ? join(' - ', $name, $format->name) : $format->name,
            url    => $thumb_base . $format->file_extension,
            width  => $w,
            height => $h,
            type   => $asset_type,
            meta   => \%meta,
            is_preview => 1
        });
    }
}

sub upload_job_results {
    my ($self, $upload) = @_;
    
    # set upload state to 'active' (visible/playable in timelines)
    #-- if we have shares for this upload already, notifyShare
    #my $shares = $self->schema->resultset('Share')->search({ upload_id => $upload->id });
    my $shares = $upload->shares;
    while(my $share = $shares->next) {
        $self->redis->rpush(notifyShare => to_json({
            share => $share->id
        }));
    }
    
    $upload->update({ status => 'ready' });
}

sub media_job_results {
    my ($self, $media) = @_;
    
    $media->update({ status => 'ready' });
}

sub clip_job_results {
    my ($self, $share) = @_;
    
    $share->update({ status => 'ready' });
    
    $self->redis->rpush(notifyShare => to_json({
        share  => $share->id,
    }));
    # TODO: delete ZC feed original
}



__PACKAGE__->meta->make_immutable;

1;
__END__