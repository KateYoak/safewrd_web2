package Kliq::Schema::ResultSet;

use strict;
use String::CamelCase qw/camelize/;
use parent 'DBIx::Class::ResultSet::RecursiveUpdate';

sub TO_JSON {
    my ($self) = @_;
    my @results = ();
    while (my $data = $self->next) {
        push (@results, $data->TO_JSON(0));
        }
    return \@results;
}

sub TO_JSON_PAGED {
    my $self = shift;
    my $rspager = $self->pager();
    my %pager = map
        { lcfirst(camelize($_)) =>
            defined($rspager->$_) ? ($rspager->$_ + 0) : undef
        } qw/
        total_entries entries_per_page current_page entries_on_this_page
        last_page last first previous_page next_page
        /;

    return {
        meta => \%pager,
        items => $self->TO_JSON(0),
    };
}

1;
__END__
