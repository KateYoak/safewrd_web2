package Kliq::Worker::Zencoder;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;
use HTTP::Request;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::WithUserAgent
    /;

my $DEBUG = $^O =~ /Win32/ ? 1 : 0;

my %MODELS = (
    media  => 'CmsMedia',
    upload => 'Upload',
    clip   => 'Share',

);

my %FORMATS = (
    media  => [qw/source-mp4 web-mp4 web-webm web-3gp/],
    upload => [qw/source-mp4 web-mp4 web-webm web-3gp/],
    clip   => [qw/web-mp4 web-webm web-3gp/],
);

#id type user [suffix source]
sub work {
    my ($self, $data) = @_;

    my $config = $self->config->{zencoder} or die("Missing config");
    my $apikey = $config->{apikey} or die("Missing api key");

    foreach(qw/id type user/){
        die("Missing $_") unless $data->{$_};
    }
    my $json = $self->zencoder_json($data);
    
    my $object = $self->schema->resultset($MODELS{$data->{type}})->find($data->{id})
        or die($data->{type} . " object " . $data->{id} . "not found");

    #-- post job to Zencoder

    my $endpoint = #$^O =~ /Win32/ ? 'http://api.kliqmobile.com/v1/t/zcjobs' : 
        'https://app.zencoder.com/api/v2/jobs';
    my $req = HTTP::Request->new('POST' => $endpoint);
    $req->header('Zencoder-Api-Key' => $apikey);    
    $req->content_type('application/json');
    $req->content_length( do { use bytes; length($json) } );
    $req->content($json);

    my $response = $self->ua->request($req); # HTTP::Response

    if ($response->is_success) {
        
        #-- save all Zencoder outputs in state 'transcoding'
        
        my $idtype   = $data->{type} eq 'clip' ? 'share_id' : ($data->{type} . '_id');
        my $res_data = $self->decode_json($response->decoded_content);
        my $outputs  = $res_data->{outputs} or die("No outputs");

        foreach my $output(@{$outputs}) {
            die("Invalid Zencode output") unless $output->{label};
            my $format = $self->schema->resultset('CmsAssetFormat')->find({
                label => $output->{label}},{ key => 'label' })
                or die("No format found for label " . $output->{label});
            $self->schema->resultset('ZencoderOutput')->create({
                $idtype      => $data->{id},
                user_id      => $data->{user},
                zc_job_id    => $res_data->{id},
                zc_output_id => $output->{id},
                state        => 'transcoding',
                asset_format_id => $format->id
                });
            }
        $object->update({ status => 'processing' });
        $self->logger->info("Zencoder job created");
    }
    else {
        #-- TODO: When Zencoder returns a 403 with "Rate Limit Exceeded" in the 
        #-- body, retry the request after the the specified period of time.
        $self->logger->error("Zencoder job not created: " . $response->status_line);
    }
}

sub zencoder_json {
    my ($self, $data) = @_;

    my ($src, $dest) = $self->zencoder_io($data);
    my $id = $data->{id} or die("No upload- or media id");    
    my $formats = $FORMATS{$data->{type}} or die("No formats for type: " . $data->{type});

    my @outputs = ();
    my $rs = $self->schema->resultset('CmsAssetFormat')->search({ 
        label => { -in => $formats } 
    });
    
    while (my $format = $rs->next) {
        my $out = $format->zencoder_params();
        $out->{notifications} = [ $DEBUG ? 'http://zencoderfetcher/' : 'http://api.kliqmobile.com/v1/zencoded' ];
        $out->{url} = "$dest/$id" . $format->file_extension;
        
        #-- DEPR: we do our own clipping before sending it to Zencoder
        #if($data->{type} eq 'clip' && $data->{offset}) {
        #    $out->{start_clip} = $data->{offset};
        #    $out->{clip_length} = 60;
        #}

        if($format->label eq 'source-mp4' || ($data->{type} eq 'clip' && $format->label eq 'web-mp4')) {
            my @thumbs = ();
            my $rst = $self->schema->resultset('CmsAssetFormat')->search({
                label => { -in => ['thumb-cover','thumb-banner'] }
            });
            while (my $tformat = $rst->next) {
                my $suffix = $tformat->file_extension;
                $suffix =~ s/\.png$//;
                my $thumb = $tformat->zencoder_params();
                $thumb->{filename} = $id . $suffix;
                $thumb->{base_url} = $dest;
                push(@thumbs, $thumb);
            }
            $out->{thumbnails} = \@thumbs;
        }
        push(@outputs, $out);
    }

    return $self->encode_json({
        test          => $DEBUG ? \1 : \0,
        input         => $src,
        #notifications => [ 'http://api.kliqmobile.com/v1/zencoded' ],
        #notifications => [ 'sitetechie@gmail.com' ],
        output        => \@outputs
    });
}

sub zencoder_io {
    my ($self, $data) = @_;    
    
    my $config = $self->config->{rackspace} or die("Missing config");
    my $uname  = $config->{username} or die("Missing config.username");
    my $apikey = $config->{apikey} or die("Missing config.apikey");
    
    #-- find source url and destination container
    my ($src_file, $container);
    if($data->{type} eq 'media') {
        my $file = $data->{source} or die("No source file");
        $src_file = join('', 'cf://', $uname, ':', $apikey, '@', 'clqs-media', '/', $file);
        $container = 'clqs-media';
    }
    elsif($data->{type} eq 'upload') {
        my $id = $data->{id};
        my $suffix = $data->{suffix} or die("No suffix");
        $src_file = $DEBUG ? 
            'http://api.kliqmobile.com/uservids/AB8F6D16-1679-11E2-827A-A73178395DFD.mp4'
          : "http://api.kliqmobile.com/uservids/$id$suffix";
        $container = 'clqs-uploads';
    }
    elsif($data->{type} eq 'clip') {
        my $id = $data->{id};
        my $suffix = $data->{suffix} or die("No suffix");
        $src_file = $DEBUG ?
            'http://api.kliqmobile.com/uservids/AB8F6D16-1679-11E2-827A-A73178395DFD.mp4'
          : "http://api.kliqmobile.com/shares/$id$suffix";
        $container = 'clqs-clips';
    }
    else {
        die("Invalid type: " . $data->{type});
    }

    my $dest_dir = join('', 'cf://', $uname, ':', $apikey, '@', $container);
    
    return ($src_file, $dest_dir);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
