package Kliq::Worker::PushNotifier;

use utf8;
use namespace::autoclean;
use Moose;
use Scalar::Util 'blessed';
use Data::Dumper;

use URI;
use URI::QueryParam;
use LWP::UserAgent;
use HTTP::Request::Common qw/GET POST/;

use Try::Tiny;
use JSON;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithMessage
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::DoesShortener
    /;

sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    
    $self->logger->info("Starting PushNotifier: " . Dumper($data));

    try {
        # Prepare push data
        my $request_hash = $data->{request};
        if (!$request_hash) {
            $request_hash = $self->prepare_request_data($data);
        }

        # Check for mandatory params (to, payload)
        die "Missing 'to' param in request" if (!$request_hash->{to});
        die "Missing 'payload' param in request" if (!$request_hash->{payload});

        for my $os ('ios', 'android') {
            my $username = $config->{$os}->{bundle_id};
            my $password = $config->{$os}->{apikey};
            my $carnival_base_uri = $config->{$os}->{base_uri};

            my $ua  = LWP::UserAgent->new;
            my $uri = URI->new($carnival_base_uri . '/notifications');

            my $request_json = encode_json({ notification => $request_hash });
            my $request = POST($uri, "Content-type" => "application/json", Accept => "application/json", Content => $request_json);
            $request->authorization_basic($username, $password);

            $self->logger->info("Processing pull request for: " . $os);
            #$self->logger->debug("Raw request: " . Dumper($request)); 
            my $response = $ua->request($request);
            if ($response->is_success) {
                my $response_json = decode_json($response->content);
                #$self->logger->debug("Raw response: " . Dumper($response_json));
                $self->logger->info("Notification sent - Success");
            }
            else {
                # Something went wrong.
                $self->logger->error("Error: " . $response->status_line);
            }
        }
    } catch {
        my $err = $self->format_error($_);
        $self->logger->error("$err");
    };
}

sub prepare_request_data {
    my ($self, $data) = @_;

    my $request_hash;

    # Flare push notification
    if ($data->{action} && $data->{uid}) {
        my $evst = $data->{event_status};
        if (($data->{action} eq 'emergency_flare' or $data->{action} eq 'live_stream') and ($evst ne 'published')) {
            $self->logger->error(q{can't send message for event id }.$data->{event_id}
                .q{ with invalid event_status }.$evst);
            return;
        }

        my $stream_url = q{rtmp://api.tranzmt.it:1935/live/} . $data->{event_id};

        #$request_hash->{to} = '*'; # Leaving it here for initial testing
        $request_hash->{to} = [{ name => 'user_id', criteria => [$data->{uid}] }];
        $request_hash->{payload} = {
            alert    => "Live Event - " . $data->{title},
            badge    => 1,
            sound    => "event.wav",
            action   => $data->{action},
            location => $data->{location},
            live_stream_url => $stream_url,
        };

        # Emergency flare notification
        if ($data->{action} eq 'emergency_flare') {
            $request_hash->{payload}->{alert} = "Emergency Flare - incoming live video stream";
            $request_hash->{payload}->{sound} = "flare.wav";
        }

        # Parent pair flare notification
        if ($data->{action} eq 'parent_pair_flare') {
            $request_hash->{payload}->{alert}   = "Parent Pair Flare";
            $request_hash->{payload}->{kliq_id} = $data->{kliq_id};
        }
    }
    
    return $request_hash;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
