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

    my %personas = ();
    my $mailPushed = 0;

    foreach my $contact($kliq->contacts) {
         #print STDERR "CONTACT " . Dumper $contact->TO_JSON(1);
         $self->logger->debug("Trying to send event notification for: " . Dumper($contact->{_column_data}));
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
        }
        else {
            # TODO: Add the other service types that Share supports.
            #die("Unsupported service " . $contact->service);
            $self->logger->error("Unsupported service " . $contact->service);
        }

        # Send push notifications if the contact is a user
        if ($contact->user_id) {
            $self->logger->info("Events created to send push notifications to: " . $contact->user_id);
            my $action = 'live_event';
            my $alert_message = "Live Event - " . $event->title;
            my $alert_sound   = "event.wav";
            if ($kliq->is_emergency) {
                $action = 'emergency_flare';
                $alert_message = "Emergency Flare - incoming live video stream";
                $alert_sound   = "flare.wav";
            }

            # Send push notifications only for published events
            if (($action eq 'emergency_flare' || $action eq 'live_event') && $event->event_status eq 'published') {
                my $stream_url = q{rtmp://api.tranzmt.it:1935/live/} . $event->id;
                $self->redis->rpush(notifyPhone => to_json({
                    type => 'push',
                    carnival_payload => {
                        notification => {
                            to => [{ name => 'user_id', criteria => [$contact->user_id] }],
                            payload => {
                                action    => $action,
                                badge     => 1,
                                sound     => $alert_sound,
                                alert     => $alert_message,
                                location  => $event->location,
                                live_stream_url => $stream_url,
                            },
                        },
                    },
                }));
            }
        }
        else {
            $self->logger->info("Not sending push notification. Missing user_id");
        } 
    }
    $self->logger->info("Events pushed to email") if($mailPushed);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
