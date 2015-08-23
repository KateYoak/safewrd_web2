package Kliq::Worker::TwitterImporter;

use namespace::autoclean;
use Moose;
use Net::Twitter;
use Scalar::Util 'blessed';
use Data::Dumper;
use Try::Tiny;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    /;

# token secret service session user handle
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    
    my $token  = $data->{token}  or die("Missing token");
    my $secret = $data->{secret} or die("Missing secret");
    my $userid = $data->{user}   or die("Missing user");
    my $handle = $data->{handle} or die("Missing handle");

    try {    
        my $user = $self->schema->resultset('User')->find($userid)
            or die("Invalid user $userid");

        
        my $nt = Net::Twitter->new(
            traits   => [qw/API::REST RetryOnError RateLimit OAuth/], # AutoCursor
            consumer_key        => $config->{client_id},
            consumer_secret     => $config->{client_secret},
            access_token        => $token,
            access_token_secret => $secret,
            apiurl => 'https://api.twitter.com/1.1',
            ssl => 1
        );

        my $followers = $nt->followers_ids($handle);
        $followers = $followers->{ids} unless(ref($followers) eq 'ARRAY');

        my $fcount = scalar(@{$followers});        
        
        $self->import_contacts($nt, $user, $followers);

        $self->logger->info("$fcount contacts imported, uid: $userid");
    
    } catch {
        my $err = $_;
        if(blessed($err) && $err->isa('Net::Twitter::Error')) {
            my $error = 
                'HTTP Status: ' . $err->code .
                ' - HTTP Message: ' . $err->message .
                ' - Twitter Error: ' . $err->error;
            $self->logger->error("Net::Twitter::Error $error (uid $userid)");        
        }
        else {
            $self->logger->error("$err (uid $userid)");        
        }
    };
}

sub import_contacts {
    my ($self, $nt, $user, $follower_ids) = @_;

    while(@{ $follower_ids }) {
        my @ids = splice(@{ $follower_ids }, 0, 100);
        
        my $friends;
        eval {        
            # get a result set of users
            $friends = $nt->lookup_users({ user_id => \@ids });
        }; 
        if($@) {
            $self->logger->error("lookup_users error: $@");
            if ($@ =~ /Rate limit/) {
                sleep $nt->until_rate(1.0);
            }
        }
        elsif($friends) {
            # import this batch of max 100 followers
            foreach my $friend(@$friends) {
                try {
                    $self->import_contact($user, $friend);
                } catch {
                    my $error = $_;
                    if($error =~ /Duplicate entry/) {
                        #$self->logger->warning("duplicate contact " . $friend->{screen_name});
                    }
                    else {
                        $self->logger->error("contact " . $friend->{screen_name} . " not imported: $_");
                    }
                };
            }
        }
    }
}

sub import_contact {
    my ($self, $user, $contact) = @_;

    $user->add_to_contacts({
        handle => $contact->{id},
        screen_name => $contact->{screen_name},
        service => 'twitter',
        name => $contact->{name},
        image => $contact->{profile_image_url},
        location => $contact->{location},
        language => $contact->{lang},
        website => $contact->{url},
        timezone => $contact->{time_zone},
    }) or die ("Could not add contact");
}

1;
__END__
