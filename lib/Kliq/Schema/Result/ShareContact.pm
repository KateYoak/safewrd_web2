package Kliq::Schema::Result::ShareContact;

use utf8;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp UUIDColumns/);
__PACKAGE__->table("share_contact_map");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0
    },
    share_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key    => 1,
        is_nullable       => 0
    },
    contact_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key    => 1,
        is_nullable       => 0
    },
    hash => {
        data_type => "varchar",
        is_nullable => 1, # relax
        size => 100
    },
    link => {
        data_type => "varchar",
        is_nullable => 1, # relax
        size => 200
    },
    method => {
        data_type => "enum",
        extra => { list => ["twitter", "facebook", "im", "email"] },
        is_nullable => 0
    },
    service => {
        data_type => "enum",
        extra => { list => ["google", "twitter", "facebook", "yahoo"] },
        is_nullable => 0,
    },
    delivered => {
        data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0
    },
    created => {
        data_type => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        is_nullable => 0
    }
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(share => 'Kliq::Schema::Result::Share','share_id');
__PACKAGE__->belongs_to(contact => 'Kliq::Schema::Result::Contact','contact_id');

1;
__END__