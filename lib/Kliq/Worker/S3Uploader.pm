package Kliq::Worker::S3Uploader;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;
use Net::Amazon::S3;
use JSON;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::HasRedis
    /;

#id suffix path mimeType title
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    warn Dumper $config;

    my $s3 = Net::Amazon::S3->new({
        aws_access_key_id     => $config->{access_key},
        aws_secret_access_key => $config->{secret_key},
        retry                 => 1,
    });

    die("Not implemented");

}

__PACKAGE__->meta->make_immutable;

1;
__END__