
package Kliq::Worker::AMDBPusher;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;
use IPC::Cmd qw/run/;
use HTTP::Request::StreamingUpload;
use WebService::Rackspace::CloudFiles;
use File::Basename;
use File::chdir;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithUserAgent
    /;

my $DEBUG = $^O =~ /Win32/ ? 1 : 0;

sub work {
    my ($self, $data) = @_;
    
    my $config   = $self->config or die("Missing config");
    my $basepath = $config->{asset_basepath} or die("Missing asset basepath");

    my $asset = $data->{file} or die("Missing file");
    my $guid  = $data->{guid} or die("Missing GUID");
    my $keep  = $data->{keep} || 0;

    my ($_name, $_path, $suffix) = fileparse($asset, '\.[^\.]*');

    my $src = $keep ? "$basepath/assets/$guid$suffix"
                    : "$basepath/tmp/$guid$suffix";
    my $trg = "$basepath/signatures";
    my $sig = join('', $trg, '/', $guid, '_a00_ADB.xml');    
    
    if($DEBUG) {
        $self->logger->warning("Download: $asset, destination: $src, signature: $sig - disabled on your platform");
        return;
    }

    try {
        #-- store local copy from Rackspace

        $self->download_rs($asset, $src);

        #-- create fingerprint
        
        local $CWD = "/usr/local/bin/amSigGen";
                
        my $cmd = "./amSigGen -i $src -s ADB -S -o $trg";
        my($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
            run(command => $cmd, verbose => 0);

        if($success) {
            die("Fingerprint not found") unless -f $sig;
            $self->logger->info("Video '$guid$suffix' fingerprinted (clipping source: $keep)");

            #-- post fingerprint to AudibleMagic

            if($self->post_fingerprint($sig) && $keep) {
                my $media = $self->schema->resultset('CmsAsset')->find($guid)->media
                    or die("Media for Asset '$guid' not found");
                $media->update({ status => 'published' });
            }
        }
        else {
            $self->logger->error("video $cmd NOT fingerprinted: " . join(' - ', $error_message, @{$stdout_buf}, @{$stderr_buf}));
        }

    } catch {
        my $err = $_;
        $self->logger->error("$err");
    };

}

sub download_rs {
    my ($self, $asset, $dest) = @_;
    
    die("Rackspace asset $asset already exists") if -f $dest;
    
    my $config = $self->config or die("Missing config");
    my $cloudfiles = WebService::Rackspace::CloudFiles->new(
        user => $config->{username},
        key  => $config->{apikey},
    );
    
    my $container = $cloudfiles->container(name => 'clqs-media'); # orig: clqs-media
    my $obj = $container->object(name => $asset);
    $obj->get_filename($dest);

    die("Failed downloading $asset from Rackspace") unless -f $dest;

    $self->logger->info("Video $asset downloaded from Rackspace");
}

sub post_fingerprint {
    my ($self, $sig) = @_;
    
    my $params   = 's=ADB&an=TestKliqMobileSC&ao=JxaHV6U&action=a';
    my $endpoint = "http://submit.audiblemagic.com/submittedcontent.ashx?$params";
    my $req = HTTP::Request::StreamingUpload->new(
        POST    => $endpoint,
        path    => $sig,
        headers => HTTP::Headers->new(
            'Content-Type'   => 'text/xml',
            'Content-Length' => -s $sig,
        ),
    );

    my $response = $self->ua->request($req); # HTTP::Response
    if ($response->is_success) {
        #my $res_data = $self->decode_json($response->decoded_content);
        $self->logger->info("Fingerprint pushed into AMDB");
    }
    else {
        $self->logger->error("Fingerprint not pushed into AMDB: " . $response->status_line);
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
