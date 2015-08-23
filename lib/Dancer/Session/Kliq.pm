package Dancer::Session::Kliq;

# ABSTRACT: Let Plack::Middleware::Session handle Dancer's session

use strict;
use warnings;
our $VERSION = '0.01';

use Dancer::SharedData;
use base 'Dancer::Session::Abstract';

sub init {
    my ($self) = @_;
    return $self;
}

sub create {
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    my $session_id = Dancer::SharedData->request->{env}->{'psgix.session.options'}->{'id'};
    
    #print STDERR "DancerSessionKliq.create $session_id\n";
    
    my $p = Dancer::Session::Kliq->new(%$session);
    $p->id($session_id);
    
    return $p;
}

sub retrieve {
    my ($class, $id) = @_;
    
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    my $session_id = Dancer::SharedData->request->{env}->{'psgix.session.options'}->{'id'};
    
    # id = as sent by client, session_id = maybe newly generated after sessiondb flush
    #print STDERR "DancerSessionKliq.retrieve $id = $session_id\n";
    
    my $p = Dancer::Session::Kliq->new(%$session);
    $p->id($session_id);
    
    return $p;
}

sub flush {
    my $self = shift;
    
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    map {$session->{$_} = $self->{$_}} keys %$self;

    #print STDERR "DancerSessionKliq.flush\n";

    return $self;
}

sub destroy {
}

sub write_session_id {
    # skip setting Dancer cookie
    #print STDERR "PSGI write_session_id\n";
}

1;
__END__