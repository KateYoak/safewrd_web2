package Kliq::Schema::Result::KliqContact;

use utf8;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp/);
__PACKAGE__->table("kliq_contact_map");

__PACKAGE__->add_columns(
    kliq_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 0
        },
    contact_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 0
        },
    );

__PACKAGE__->set_primary_key(qw/ kliq_id contact_id /);

__PACKAGE__->belongs_to(kliq => 'Kliq::Schema::Result::Kliq','kliq_id');
__PACKAGE__->belongs_to(contact => 'Kliq::Schema::Result::Contact','contact_id');

1;
__END__