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
    'clqs-images'   => 'http://307edcdef10560aeb3d6-228b1cdf843d979ce51d9eef65a5a264.r72.cf1.rackcdn.com/',
    'clqs-media'    => 'http://ead54a85a0e71e8d6209-578e57646269a0417cf8d221c5ffac7c.r72.stream.cf1.rackcdn.com/',
    'kliqs-images'  => 'http://6d6e1e969306e7b0eaf9-802f7521bda7231b610a0373b059a61f.r35.cf1.rackcdn.com/',
    'events-images' => 'http://c1ded9f866a1e9987e67-37824ac133c6bd23c73910de2fd20b3f.r75.cf1.rackcdn.com/',
);

# { path container [id key] }
sub work {
    my ($self, $data) = @_;

    my $src = $data->{src} or die("Missing source src");
    my $dest = $data->{container} or die("Missing container");
    my $file = $data->{key} || fileparse($src);

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
        $object->put_filename($src); # 'Data corruption error'

        if($container eq 'kliqs-images') {
            my $id = $data->{id} || fileparse($src, qr/\.[^.]*/);
            my $kliq = $self->schema->resultset('Kliq')->find($data->{id})
                or die('Kliq ' . $data->{id} . ' not found');
            my $url = $CDNBASE{$container} . $file;
            $kliq->update({ image => $url }) or die("Invalid kliq update");
        }
        if($container eq 'events-images') {
            my $id = $data->{id} || fileparse($src, qr/\.[^.]*/);
            my $event = $self->schema->resultset('Event')->find($data->{id})
                or die('Event ' . $data->{id} . ' not found');
            my $url = $CDNBASE{$container} . $file;
            $event->update({ image => $url }) or die("Invalid event update");
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

