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
    nickname => {
        data_type => 'varchar', 
        is_nullable => 1,  #set after hire
        size => 50,
    },
    firstName => { 
        data_type => "varchar", 
        is_nullable => 0,
        size => 50,
    },
    lastName => { 
        data_type => "varchar", 
        is_nullable => 0,
        size => 50,
    },
    email => { 
        data_type => "varchar", 
        is_nullable => 0, 
        size => 50 
    },
    phone => { 
        data_type => "varchar", 
        is_nullable => 0, 
        size => 15,
    },
    photo => {
        data_type => "varchar",  #local uri
        is_nullable => 1, 
        size => 255 
    },
    status => {
        data_type => "enum",
        extra => { list => [qw/pending hired rejected cancelled/] },
        is_nullable => 0,
        default_value => 'pending' 
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

__PACKAGE__->add_unique_constraint("email", [qw/email/]);

__PACKAGE__->has_many(
    lead => 'Kliq::Schema::Result::Lead', 'ambassador_id'
    );
__PACKAGE__->has_many(
    user => 'Kliq::Schema::Result::Persona', 'ambassador_id'
    );


1;
__END__