package Kliq::Worker::LinkedInImporter;

use namespace::autoclean;
use Moose;
use Scalar::Util 'blessed';
use Data::Dumper;
use Try::Tiny;
#use HTML::Entities qw(encode_entities);
use JSON;

extends 'Kliq::Worker';
with 'Kliq::Worker::Role::WithSchema';

# token secret service session user
sub work {
    my ($self, $data) = @_;

    warn Dumper $data;
}

1;
__END__

url = "http://api.linkedin.com/v1/people/~/connections?count=10";