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
            $is_code_present->title($data->{title}) if ($data->{title});
            $is_code_present->parent_device_id($data->{parent_device_id});
            $is_code_present->parent_user_id($data->{parent_user_id});

            # Now lets create a kliq
            my $parent_contact_id = $self->schema->resultset('Contact')->find({
                    user_id  => $is_code_present->parent_user_id,
                    owner_id => $is_code_present->child_user_id,
                });

            my $kliq = $self->schema->resultset('Kliq')->create({
                    name => 'PAIR_KLIQ',
                    user_id => $is_code_present->child_user_id,
                    is_emergency => 1,
                    contacts_map => [
                        { contact_id => $parent_contact_id->id },
                    ]
                });
            $is_code_present->kliq_id($kliq->id);
            $is_code_present->update();

            return $is_code_present->id;
        }
    }

    return 0;
}

sub list {
    my ($self, $data) = @_;

    my @list;
    if ($data->{parent_device_id} or $data->{child_device_id}) {
        my $list = $self->schema->resultset('Pair')->search($data);
        while (my $pair = $list->next) {
            my %data = $pair->get_columns;
            push(@list, \%data);
        }

        return \@list;
    }

    return 0;
}


sub flare {
    my ($self, $data) = @_;

    if ($data->{pair_id}) {
        my $pair = $self->schema->resultset('Pair')->find({
                id => $data->{pair_id}
            });
        if ($pair) {
            $self->redis->rpush(notifyPush => to_json({
                type => 'push',
                carnival_payload => {
                    notification => {
                        to => [{ name => 'user_id', criteria => [$pair->child_user_id] }],
                        payload => {
                            action    => 'parent_pair_flare',
                            badge     => 1,
                            sound     => 'event.wav',
                            alert     => 'Parent Pair Flare',
                            kliq_id   => $pair->kliq_id,
                        },
                    },
                },
            }));

            return 1;
        }
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
