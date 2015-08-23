package Kliq::Schema::Result::ShareKliq;

use utf8;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime TimeStamp/);
__PACKAGE__->table("share_kliq_map");

__PACKAGE__->add_columns(
    share_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 0
        },
    kliq_id => {
        data_type => 'CHAR',
        size => 36,
        is_foreign_key => 1,
        is_nullable => 0
        },
    
    );

__PACKAGE__->set_primary_key(qw/ share_id kliq_id /);

__PACKAGE__->belongs_to(kliq => 'Kliq::Schema::Result::Kliq','kliq_id');
__PACKAGE__->belongs_to(share => 'Kliq::Schema::Result::Share','share_id');

1;
__END__