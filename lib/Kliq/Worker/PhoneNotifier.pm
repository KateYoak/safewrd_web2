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
        # Check for mandatory params (payload, type)
        die "Skipping notification. Failed data check" if (!$request_hash);
        die "Missing 'type' param in request" if (!$request_hash->{type});
        die "Missing 'payload' param in request" if (!$request_hash->{payload});

#        for my $app ('tranzmt', 'flare') {
        for my $app ('tranzmt') {
            my $action = $request_hash->{payload}->{action};
            if ($app eq 'flare' && $action eq 'live_event') {
                # Do not send live event notifications to Flare app
                next;
            }

            #my $end_point = "/push";
            #if ($request_hash->{type} eq 'in-app') {
            #    $end_point = "/push";
            #}

            my $form_params = [];
            my $url = "https://service.swrve.com/push";
            my $user = $self->schema->resultset('User')->find($request_hash->{payload}->{user_id}) or die("Invalid user " . $request_hash->{payload}->{user_id});
            $request_hash->{payload}->{user} = $user->swrve_user_id;
            $request_hash->{payload}->{push_key} = "254f755f-6227-4664-b8d6-1288c1d97e16";

            for my $key (keys %{$request_hash->{payload}}) {
                if (grep { $key eq $_ } ('push_key', 'user', 'sound', 'message', 'notification_title')) {
                    push(@{$form_params}, $key => $request_hash->{payload}->{$key});
                }
                else {
                    push(@{$form_params}, 'custom' => "$key=$request_hash->{payload}->{$key}");
                }
            }

            $self->logger->debug("Request payload: " . Dumper($request_hash)); 
            
            my $ua  = LWP::UserAgent->new;
            my $response = $ua->post($url, $request_hash->{payload});
            my $request  = POST( $url, $form_params );

$self->logger->debug("Request: " . Dumper($request)); 
 
            my $response = $ua->request($request);
            if ($response->is_success) {
                $self->logger->debug("Raw response: " . $response->content);
                $self->logger->info("Notification sent - Success");
            }
            else {
                # Something went wrong.
                $self->logger->debug("Raw response: " . $response->content);
                $self->logger->error("Error: " . $response->status_line);
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
