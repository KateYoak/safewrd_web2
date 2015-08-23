package Kliq::Worker::ShareNotifier;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;
use JSON;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::HasRedis
    /;

# { share => $share->id }
sub work {
    my ($self, $data) = @_;

    my $share_id = $data->{share} or die("No share id");
    my $share = $self->schema->resultset('Share')->find($share_id) 
        or die("Share $share_id not found");
    my $user = $share->user;

    #-- send notifications) 

    my @twits    = ();
    my %personas = ();
    my $mailPushed = 0;

    foreach my $contact($share->contacts) {
        #print STDERR "CONTACT " . Dumper $contact->TO_JSON(1);
        if($contact->service =~ /^(google|yahoo)$/) {
            $mailPushed++;
            #-- register and cache name of sender on social network
            if(!$personas{$contact->service}) {
                my $persona = $user->personas({ service => $contact->service })->first
                    or die("No profile for " . $contact->service);
                $personas{$contact->service} = $persona->name || $persona->email;
            }
            # handle hash service name email
            $self->redis->rpush(notifyEmail => to_json({
                sender    => $personas{$contact->service},
                message   => $share->title,
                email     => $contact->email,
                media_id  => $share->id, # TODO MAKE SHARE_ID
                upload_id => $share->upload_id,
                contact_id => $contact->id
            }));
        }
        elsif($contact->service eq 'twitter') {
            push(@twits, [$contact->id, $contact->handle]);
        }
        else {
            #die("Unsupported service " . $contact->service);
            $self->logger->error("Unsupported service " . $contact->service);
        }
    }
    $self->logger->info("Shares pushed to email") if($mailPushed);

    if(scalar(@twits)) {
        my $token = $user->tokens({ service => 'twitter' })->first()
            or die("No Twitter token");
        my $persona = $user->personas({ service => 'twitter' })->first
            or die("No profile for twitter");

        $self->redis->rpush(notifyTwitter => to_json({
            sender     => $persona->name || $persona->screen_name,
            token      => $token->token,
            secret     => $token->secret,
            message    => $share->title,
            recipients => \@twits,
            media_id   => $share->id,  # TODO MAKE SHARE_ID
            upload_id  => $share->upload_id,
        }));
        $self->logger->info("Shares pushed to twitter");
    }
    $share->update({ status => 'published' });
}

__PACKAGE__->meta->make_immutable;

1;
__END__