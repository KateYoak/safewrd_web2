
package Kliq::Worker::TwitterNotifier;

use utf8;
use namespace::autoclean;
use Moose;
use Net::Twitter;
use Scalar::Util 'blessed';
use Data::Dumper;
use Try::Tiny;
use JSON;
use Text::Unidecode qw/unidecode/; # alternative: Text::Iconv

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithMessage
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::DoesShortener
    /;

# token secret recipients message media_id upload_id
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    my $token  = $data->{token}  or die("Missing token");
    my $token_secret = $data->{secret} or die("Missing secret");

    try {
        my $nt = Net::Twitter->new(
            traits              => [qw/OAuth API::REST/],
            consumer_key        => $config->{client_id},
            consumer_secret     => $config->{client_secret},
            access_token        => $token,
            access_token_secret => $token_secret,
            apiurl => 'https://api.twitter.com/1.1',
            ssl => 1
        );
        
        foreach my $twit(@{$data->{recipients}}) {
            my ($contact_id, $twitter_id) = @{$twit};

            my $shortlink = $self->shorten($contact_id, $data->{media_id}) 
                or die("No short link");

            my $tw_utf = $self->message(
                $data->{sender}, $data->{message}, $data->{upload_id}, 
                $data->{media_id}, $contact_id, $shortlink
            );
            my $tw_dm = unidecode($tw_utf);
            $tw_dm =~ s/\n//g;
            #print STDERR "DM $token\n$token_secret\n$tw_dm\n" . length($tw_dm) . "\n";
            die("Message too long") if length($tw_dm) > 140;

            try {
                $nt->new_direct_message($twitter_id, $tw_dm);
            } catch {
                $self->logger->error(
                    "sending to $twitter_id: " . $self->format_error($_)
                );
            };
        }
        
        $self->logger->info("message sent");
    
    } catch {
        my $err = $self->format_error($_);
        $self->logger->error("$err");
    };
}

__PACKAGE__->meta->make_immutable;

1;
__DATA__
@@ body.html
I added you to my KLIQ, and I want to send you a video message. Click to accept the invitation: [% shortlink | url %]

__END__
