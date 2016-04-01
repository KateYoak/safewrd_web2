use 5.010;

package Kliq::Model::Pair;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'Pair' }
#sub path { 'events' }
sub method { 'pair' }

sub code {
    my ($self, $data) = @_;

    # Generate a code
    my $code;
    my @set = ('0' ..'9', 'A' .. 'Z');
    while (1) {
        $code = join '' => map $set[rand @set], 1 .. 8;

        # Make sure we haven't used this code before
        my $is_code_present = $self->schema->resultset('Pair')->find({
                code => $code
            });
        if(!$is_code_present) {
            last;
        }
    }

    $self->schema->resultset('Pair')->create({
            child_device_id => $data->{child_device_id},
            child_user_id   => $data->{child_user_id},
            code            => $code
        });

    return $code;
}

sub pair {
    my ($self, $data) = @_;

    if ($data->{code} and $data->{parent_device_id} and $data->{parent_user_id}) {
        my $is_code_present = $self->schema->resultset('Pair')->find({
                code => $data->{code}
            });
        if($is_code_present) {
            # We have the code, now lets update the pair
            $is_code_present->title($data->{title});
            $is_code_present->parent_device_id($data->{parent_device_id});
            $is_code_present->parent_user_id($data->{parent_user_id});

            $is_code_present->update();

            return $is_code_present->id;
        }
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
