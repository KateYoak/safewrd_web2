package Kliq::Worker::EventNotifier;

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

# { event => $event->id }
sub work {
    my ($self, $data) = @_;

    my $event_id = $data->{event} or die("No event id");
    my $event = $self->schema->resultset('Event')->find($event_id) 
        or die("Event $event_id not found");
    my $user = $event->user;
    my $kliq = $event->kliq;

    #-- send notifications) 

    my @twits    = ();
    my %personas = ();
    my $mailPushed = 0;

    foreach my $contact($kliq->contacts) {
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
            $self->redis->rpush(notifyEventEmail => to_json({
                email     => $contact->email,
                sender    => $personas{$contact->service},
                title     => $event->title,
                when_occurs => ''.$event->when_occurs,
                location  => $event->location,
                price     => $event->price,
                event_id  => $event->id,
                event_status => $event->event_status,
                contact_id => $contact->id,
            }));

            # send push notifications
            $self->redis->rpush(notifyPush => to_json({
                action    => 'emergency_flare',
                sender    => $personas{$contact->service},
                when_occurs => ''.$event->when_occurs,
                location  => $event->location,
                event_id  => $event->id,
                event_status => $event->event_status,
                contact_id => $contact->id,
                uid        => $contact->user_id
            }));
        }
        else {
            # TODO: Add the other service types that Share supports.
            #die("Unsupported service " . $contact->service);
            $self->logger->error("Unsupported service " . $contact->service);
        }
    }
    $self->logger->info("Events pushed to email") if($mailPushed);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
