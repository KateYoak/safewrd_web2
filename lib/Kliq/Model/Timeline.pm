package Kliq::Model::Timeline;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Data::Dumper;
use Try::Tiny;
extends 'Kliq::Model::Base';

sub table { 'FeedItem' }
#sub method { 'personas' }

sub search {
    my ($self, $params, $filters) = @_;
    unless($self->has_user) {
        return {
            meta => {},
            items => []
        }
    }
    
    # base list of contact ids
    my @contact_ids = (); #map { $_->id } $self->user->contacts->all;

    # add contact ids for handle/email for each persona
    foreach my $persona($self->user->personas) {
        my $crit = $persona->service =~ /(twitter|facebook)/ ?
            { handle => $persona->handle } : { email => $persona->email };
        # find all contacts for this persona
        my @contacts = $self->schema->resultset('Contact')->search($crit)->all;
        my @cids =  map { $_->id } @contacts;
        push(@contact_ids, @cids);
    }

    @contact_ids = keys %{{ map { $_ => 1 } @contact_ids }};
    
    #warn Dumper \@contact_ids;
    #foreach my $cid(@contact_ids) {
    #    my $c = $self->schema->resultset('Contact')->find($cid);
    #    print "CONT " . $c->name . " = " . $c->email . "\n";
    #}

    return $self->_shares([$self->user->id], [@contact_ids], $params, $filters);
}

sub get {
    my ($self, $contact_id) = @_;

    #-- build up a list of contact_ids + find user for this contact
    
    my $contact = $self->schema->resultset('Contact')->find($contact_id) 
        or return;

    #-- find related contactids + userids
    my $crit = $contact->service =~ /(twitter|facebook)/ ?
        { handle => $contact->handle } : { email => $contact->email };
    #-- find user personas with the same handle/email as this contact
    my @personas = $self->schema->resultset('Persona')->search($crit)->all;
    #-- find same contact in other users' contact lists 
    my @contacts = $self->schema->resultset('Contact')->search($crit)->all;
    my %cids = ();
    my @contact_ids = grep { !$cids{$_}++ } map { $_->id } @contacts;
    my @user_ids = map { $_->user_id } @personas;
    push(@user_ids, grep { $_ } map { $_->user_id } @personas);
    @user_ids = keys %{{ map { $_ => 1 } @user_ids }};

#print STDERR Dumper \@contact_ids;
#print STDERR Dumper \@user_ids;

    #-- find shares for this user+contact_ids

    return $self->_shares(\@user_ids, \@contact_ids)->{items};
}

sub _shares {
    my ($self, $users, $contacts, $params, $filters) = @_;
    
    $params ||= {};
    $filters ||= {};
    $filters->{rows} = 400; #||= 3000;
    $filters->{page} ||= 1;
    $filters->{order_by} = $filters->{order_by} ? 
        ('me.' . $filters->{order_by}) : 'me.created';  #{ -desc => ['me.created'] };
       
    my $result = $self->schema->resultset('Share')->search({
        %{$params},
        -or => [
            'contacts_map.contact_id' => { -in => $contacts },
            'user_id' =>  { -in => $users },
            ]
        },
        { %{$filters},
          join      => 'contacts_map',
          #distinct => 1
          group_by  => 'me.id'
        }
    );
    
    return $result->TO_JSON_PAGED();
}


sub create {
    return {};
}

sub update {
    return {};
}

sub delete {
    return 1;
}

sub related_contacts {
}

sub contacts_for_user {
}

__PACKAGE__->meta->make_immutable;

1;
__END__
