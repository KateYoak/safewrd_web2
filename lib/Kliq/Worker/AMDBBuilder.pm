
package Kliq::Worker::AMDBBuilder;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithSchema
    /;

sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    
    try {
        die("Missing local amdb file");
    } catch {
        my $err = $_;
        $self->logger->error("$err");
    };

}

__PACKAGE__->meta->make_immutable;

1;
__END__