package Kliq::Worker::KliqNotifier;

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

# { kliq => $kliq->id }
sub work {
    my ($self, $data) = @_;

    my $kliq_id = $data->{kliq} or die("No kliq id");
    my $kliq = $self->schema->resultset('Kliq')->find($kliq_id) 
        or die("Kliq $kliq_id not found");
    my $user = $kliq->user;

    #-- send notifications) 

    my %personas = ();
    my $mailPushed = 0;

$self->logger->debug("Trying to send kliq notification for: " . $kliq_id);
 
    foreach my $contact($kliq->contacts) {
        # Send invitation only for those users who hasn't installed the app
        next if ($contact->user_id);

        #print STDERR "CONTACT " . Dumper $contact->TO_JSON(1);
        $self->logger->debug("Trying to send kliq notification for: " . Dumper($contact->{_column_data}));
        if($contact->service =~ /^(google|yahoo)$/) {
            $mailPushed++;
            #-- register and cache name of sender on social network
            if(!$personas{$contact->service}) {
                my $persona = $user->personas({ service => $contact->service })->first
                    or die("No profile for " . $contact->service);
                $personas{$contact->service} = $persona->name || $persona->email;
            }
            # handle hash service name email
            $self->redis->rpush(notifyKliqEmail => to_json({
                email     => $contact->email,
                sender    => $personas{$contact->service},
                kliq_id   => $kliq->id,
                contact_id => $contact->id,
                contact_name => $contact->name,
            }));
        }
        else {
            # TODO: Add the other service types that Share supports.
            #die("Unsupported service " . $contact->service);
            $self->logger->error("Unsupported service " . $contact->service);
        }
    }

    $self->logger->info("Kliqs pushed to email") if($mailPushed);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
