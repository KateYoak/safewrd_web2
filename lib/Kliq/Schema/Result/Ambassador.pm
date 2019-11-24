package Kliq::Schema::Result::Ambassador;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("ambassadors");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    name => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 50,
    },
    email => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 50 
    },
    phone => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 15,
        is_serializable => 0
    },
    website => { 
        data_type => "varchar", 
        is_nullable => 1, # relax
        size => 200,
        is_serializable => 0
    },
    image => {
        data_type => "varchar", 
        is_nullable => 1, 
        size => 255 
    },
    gender => {
        data_type => "enum",
        extra => { list => ["male", "female"] },
        is_nullable => 1,
    },
    org_name => { 
        data_type => "varchar", 
        is_nullable => 1,  # relax
        size => 75,
        is_serializable => 0
    },
    org_title => { 
        data_type => "varchar", 
        is_nullable => 1,  # relax
        size => 75,
        is_serializable => 0
    },
    location => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 200,
        is_serializable => 0
    },
    timezone => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 75,
        is_serializable => 0
    },
    language => { 
        data_type => "varchar", 
        is_nullable => 1, 
        size => 10,
        is_serializable => 0
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

__PACKAGE__->has_many(
    lead => 'Kliq::Schema::Result::Lead', 'ambassador_id'
    );
__PACKAGE__->has_many(
    user => 'Kliq::Schema::Result::Persona', 'ambassador_id'
    );


1;
__END__