
package Kliq::Schema::Result::Pair;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("pair");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0
    },
    title => {
        data_type => "VARCHAR",
        is_nullable => 1,
        size => 255
    },    
    parent_device_id => {
        data_type => 'VARCHAR',
        is_nullable => 1,
        size => 36,
    },    
    child_device_id => {
        data_type => 'VARCHAR',
        is_nullable => 1,
        size => 36,
    },    
    parent_user_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 1,
    },    
    child_user_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 1,
    },    
    kliq_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 1,
    },
    code => {
        data_type => "CHAR",
        is_nullable => 1,
        size => 8
    },    
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(parent_user => 'Kliq::Schema::Result::User', 'parent_user_id');
__PACKAGE__->belongs_to(child_user => 'Kliq::Schema::Result::User', 'child_user_id');
__PACKAGE__->belongs_to(kliq => 'Kliq::Schema::Result::Kliq', 'kliq_id');

sub _serializable_rels {
    return qw/+user +kliq/;
}


1;
__END__
