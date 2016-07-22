package Kliq::Worker::PhoneNotifier;

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
    my ($self, $request_hash) = @_;

    my $config = $self->config or die("Missing config");
    
    $self->logger->info("Starting PhoneNotifier: " . Dumper($request_hash));

    try {
        # Check for mandatory params (carnival_payload, type)
        die "Skipping notification. Failed data check" if (!$request_hash);
        die "Missing 'type' param in request" if (!$request_hash->{type});
        die "Missing 'carnival_payload' param in request" if (!$request_hash->{carnival_payload});

        for my $app ('tranzmt', 'flare') {
            my $action = $request_hash->{carnival_payload}->{notification}->{payload}->{action};
            if ($app eq 'flare' && $action eq 'live_event') {
                # Do not send live event notifications to Flare app
                next;
            }

            for my $os ('ios', 'android') {
                my $username = $config->{$app}->{$os}->{bundle_id};
                my $password = $config->{$app}->{$os}->{apikey};
                my $carnival_base_uri = $config->{$app}->{$os}->{base_uri};

                my $ua  = LWP::UserAgent->new;
                my $end_point = "/notifications";
                if ($request_hash->{type} eq 'in-app') {
                    $end_point = "/messages";
                }
                my $uri = URI->new($carnival_base_uri . $end_point);

                my $request_json = encode_json($request_hash->{carnival_payload});
                my $request = POST($uri, "Content-type" => "application/json", Accept => "application/json", Content => $request_json);
                $request->authorization_basic($username, $password);

                $self->logger->info("Processing pull request for: " . $os);
                $self->logger->debug("Raw request: " . Dumper($request)); 
                my $response = $ua->request($request);
                if ($response->is_success) {
                    my $response_json = decode_json($response->content);
                    $self->logger->debug("Raw response: " . Dumper($response_json));
                    $self->logger->info("Notification sent - Success");
                }
                else {
                    # Something went wrong.
                    $self->logger->error("Error: " . $response->status_line);
                }
            }
        }
    } catch {
        my $err = $self->format_error($_);
        $self->logger->error("$err");
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
