package Kliq::Schema::Result::Lead;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("leads");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    handle => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    service => {
        data_type => "enum",
        extra => { list => [qw/google twitter facebook yahoo linkedin kliq manual twilio/] },
        is_nullable => 0,
    },
    ambassador_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1, # that means, no ambassador, direct lead
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    },
    persona_id => { #persona_id assigned when signup is completed
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');
__PACKAGE__->add_unique_constraint(handle => [qw/handle service/]);

__PACKAGE__->belongs_to(
    persona => 'Kliq::Schema::Result::Persona', 'persona_id'
    );


1;
__END__