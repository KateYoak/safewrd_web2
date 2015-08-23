package Kliq::Worker::GoogleImporter;

use namespace::autoclean;
use Moose;

# WWW::Contact documentation can be found at http://search.cpan.org/perldoc?WWW::Contact
# This requires the google-oauth branch of WWW-Contact Available here:
# https://github.com/throughnothing/perl-www-contact/tree/google-oauth
use WWW::Contact 0.49;
use Data::Dumper;
use JSON;
use Furl;
use Try::Tiny;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    /;

# token secret service session user handle
sub work {
    my ($self, $data) = @_;

    my $token = $data->{token};

    try {
        my $user = $self->schema->resultset('User')->find($data->{user})
            or die("Invalid user " . $data->{user});
        
        my $wc = $self->www_contact_instance($data->{service});

        #-- Email address doesn't matter since we're using OAuth, but it
        #-- must be '@gmail.com' for WWW::Contact to use the appropriate provider
        my $contacts = $wc->get_contacts('test@gmail.com', $token) 
            or die("No contacts response");
        
        my $errstr   = $wc->errstr;
        if ($errstr) { # like 'Wrong Username or Password'
            $self->logger->error("WWW::Contact error: $errstr");
        } 
        else {
            foreach my $c(@$contacts) {
                next unless $c->{email};
                try {
                    $self->import_contact($user, $c);
                } catch {
                    my $error = $_;
                    if($error =~ /Duplicate entry/) {
                        #$self->logger->warning("duplicate contact " . $c->{email});
                    }
                    else {
                        $self->logger->error("contact " . $c->{email} . " not imported: $_");
                    }
                };
            }
            $self->logger->info("contacts imported");
        }
    } catch {
        $self->logger->error("exception: $_");
    };
}

sub www_contact_instance {
    my ($self, $service) = @_;
    
    my $wc = WWW::Contact->new();

    if($service eq 'google') {
        # Update the gmail known supplier to use OAuth2 for gmail
        my $ks = $wc->known_supplier;
        $ks->{'gmail.com'} = 'GoogleContactsAPIOAuth2';
        $wc->known_supplier( $ks );
    }
    else {
        die("Email service $service not supported");
    }
    
    return $wc;
}

sub import_contact {
    my ($self, $user, $contact) = @_;
    
    $user->add_to_contacts({
        handle  => $contact->{email},
        service => 'google',
        name    => $contact->{name},
        email   => $contact->{email},
        screen_name => $contact->{email},    
    }) or die ("Could not add contact");
}

1;
__END__