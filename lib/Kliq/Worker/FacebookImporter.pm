package Kliq::Worker::FacebookImporter;

use namespace::autoclean;
use Moose;
use Scalar::Util 'blessed';
use Data::Dumper;
use Try::Tiny;
#use HTML::Entities qw(encode_entities);
use JSON;
use Net::Facebook::Oauth2;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger    
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::HasConfig
    /;

# token secret service session user handle
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    my $token  = $data->{token}  or die("Missing token");
    my $userid = $data->{user}   or die("Missing user");

    try {
        my $user = $self->schema->resultset('User')->find($userid)
            or die("Invalid user $userid");

        my $fb = Net::Facebook::Oauth2->new(
            access_token => $token
        );

        my $friends = $fb->get('https://graph.facebook.com/me/friends', {
            fields => 'id,username,name,gender,location,email',
            limit => 5000
        });
        my $data_obj = from_json($friends->as_json) or die("Invalid facebook object");
        if(!ref($data_obj) || ref($data_obj ne 'HASH')) {
            die("Facebook library error - $data_obj");
        }
        elsif($data_obj->{error}) {
            die("Facebook OAuth error - " . $data_obj->{error}->{message});
        }
        
        my $contacts = $data_obj->{data} or die("Invalid data object");
        my $count = scalar(@{$contacts});
        foreach my $c(@{$contacts}) {
            try {
                $self->import_contact($user, $c);
            } catch {
                my $error = $_;
                if($error =~ /Duplicate entry/) {
                    #$self->logger->warning("duplicate contact " . $c->{name});
                }
                else {
                    $self->logger->error("contact " . $c->{name} . " not imported: $_");
                }
            };
        }

        $self->logger->info("$count contacts imported, uid: $userid");

    } catch {
        my $err = $_;
        $err =~ s/\n//;
        $self->logger->error("$err (uid $userid)");
    };
}

sub import_contact {
    my ($self, $user, $contact) = @_;
    
    my $location;
    if($contact->{location} && ref($contact->{location}) eq 'HASH') {
        $location = $contact->{location}->{name};
    }

    $user->add_to_contacts({
        service => 'facebook',        
        handle  => $contact->{id},
        name    => $contact->{name},
        location => $location,
        gender  => $contact->{gender},
        screen_name => $contact->{username},
        image => 'http://graph.facebook.com/' . $contact->{id} . '/picture?type=square',
    }) or die ("Could not add contact");

}

1;
__END__