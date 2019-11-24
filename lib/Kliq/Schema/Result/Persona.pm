
package Kliq::Schema::Result::Persona;

use utf8;
use strict;
use warnings;

use base 'Kliq::Schema::Result';

__PACKAGE__->table("personas");

__PACKAGE__->add_columns(
    id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 0,
    },
    user_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1, # for real, matched later
        is_foreign_key => 1
    },
    ambassador_id => {
        data_type => 'CHAR',
        size => 36,
        is_nullable => 1,
        is_foreign_key => 1,
    },
    handle => {
        data_type => "varchar",
        is_nullable => 0,
        size => 255,
    },
    service => {
        data_type => "enum",
        extra => { list => [qw/google twitter facebook yahoo linkedin kliq manual twilio/] },
        is_nullable => 0,
    },
    screen_name => {
        data_type => "varchar",
        is_nullable => 1,
        size => 75
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
    profile_url => {
        data_type => "varchar",
        is_nullable => 1, # relax
        size => 200,
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
        data_type         => 'timestamp',
        is_nullable       => 0,
        timezone          => 'UTC',
        datetime_undef_if_invalid => 1,
        default_value => \"current_timestamp",
        set_on_create     => 1,
    }
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->uuid_columns('id');

__PACKAGE__->belongs_to(
    user => 'Kliq::Schema::Result::User', 'user_id'
    );

__PACKAGE__->belongs_to(
    ambassador => 'Kliq::Schema::Result::User', 'ambassador_id'
    );

__PACKAGE__->has_many(
    tokens => 'Kliq::Schema::Result::OauthToken', 'persona_id'
    );

sub insert {
    my ( $self, @args ) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    #here we are looking for the lead in the leads table
    my $lead = $self->result_source->schema->resultset('Lead')->search_rs({ service => $self->service, handle => $self->handle } )->single();
    if ($lead) {
        $self->ambassador_id($lead->ambassador_id); #and using it to assign ambassador_id that signed us up
    }

    $self->next::method(@args);

    #-- update userids for each contact this persona represents
    my $crit = $self->service =~ /(twitter|facebook)/ ?
        { handle => $self->handle } : { email => $self->email };

    # Fix Added: do not resolve null handles or emails 
    my @ck = keys %{$crit};
    my $criteria_key = shift @ck; 

    my $known_contact = (defined($crit->{$criteria_key})) ? $self->result_source->schema->resultset('Contact')->search_rs($crit)->single() : undef;
    if (defined($known_contact)) {
        $known_contact->update({
            user_id => $self->user_id,
        });
    }
    if ($lead) {
        #if we had a lead, let's close it by assigning the new persona_id to it
        $lead->update( { persona_id => $self->id });
    } else {
        #otherwise, if there was no lead at all, we would still like to back-fill the lead as closed (with persona_id)
        #so we have them all in one place, and with a unique phone number.
        $self->result_source->schema->resultset('Lead')->create( { service => $self->service, handle => $self->handle, persona_id => $self->id } );
    }

    $guard->commit;

    return $self;
}

1;
__END__
