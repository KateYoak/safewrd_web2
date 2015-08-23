package Kliq::Worker::CloudFilesPusher;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use WebService::Rackspace::CloudFiles;
use Try::Tiny;
use File::Basename;
use MIME::Types;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithSchema
    /;

my $MT = MIME::Types->new;

my %CDNBASE = (
    'clqs-images' => 'http://307edcdef10560aeb3d6-228b1cdf843d979ce51d9eef65a5a264.r72.cf1.rackcdn.com/',
    'clqs-media'  => 'http://ead54a85a0e71e8d6209-578e57646269a0417cf8d221c5ffac7c.r72.stream.cf1.rackcdn.com/',
);

# { path container [id key] }
sub work {
    my ($self, $data) = @_;

    my $path = $data->{path} or die("Missing source path");
    my $dest = $data->{container} or die("Missing container");
    my $file = $data->{key} || fileparse($path);    
    
    my $config = $self->config or die("Missing config");
    my $apikey = $config->{apikey} or die("Missing api key");
    my $uname  = $config->{username} or die("Missing username");        
    
    try {
        my $cloudfiles = WebService::Rackspace::CloudFiles->new(
            user => $uname,
            key  => $apikey,
        );

        my $container = $cloudfiles->container(name => $dest);

        #-- create a new object with the contents of a local file

        my $mime = $MT->mimeTypeOf($file);
        my $object = $container->object(
            name => $file, 
            content_type => $mime ? $mime->type() : 'application/octet-stream'
        );
        $object->put_filename($path); # 'Data corruption error'

        if($container eq 'clqs-images') {
            my $id = $data->{id} || fileparse($path, qr/\.[^.]*/);
            my $kliq = $self->schema->resultset()->find($data->{id})
                or die('Kliq ' . $data->{id} . ' not found');
            my $url = $CDNBASE{$container} . $file;
            $kliq->update({ image => $url }) or die("Invalid kliq update");
        }
        elsif($container eq 'clqs-media') {
            # add amdb Media asset?
        }
        
        $self->logger->info("CloudFile '$file' saved in '$dest'");
    
    } catch {
        my $err = $_;
        $self->logger->error("CloudFile '$file' not saved in '$dest': $err");
    };

}

__PACKAGE__->meta->make_immutable;

1;
__END__


