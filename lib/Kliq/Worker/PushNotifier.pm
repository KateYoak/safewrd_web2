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

# token secret recipients message media_id upload_id
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");
    
    # Check for mandatory params (to, payload)
    die "Missing 'to' param in request" if (!$data->{request}->{to});
    die "Missing 'payload' param in request" if (!$data->{request}->{payload});

    $self->logger->info("Starting PushNotifier: " . Dumper($data));

    try {
        my $username = $config->{bundle_id};
        my $password = $config->{apikey};
        my $carnival_base_uri = $config->{base_uri};

        my $ua  = LWP::UserAgent->new;
        my $uri = URI->new($carnival_base_uri . '/notifications');
        my $request_hash = $data->{request};

        my $request_json = encode_json({ notification => $request_hash });
        my $request = POST($uri, "Content-type" => "application/json", Accept => "application/json", Content => $request_json);
        $request->authorization_basic($username, $password);

        my $response = $ua->request($request);
        if ($response->is_success) {
            my $response_json = decode_json($response->content);
            $self->logger->info("Raw response: " . Dumper($response_json));
            $self->logger->info("Notification sent - Success");
        }
        else {
            # Something went wrong.
            $self->logger->error("Error: " . $response->status_line);
        }
    } catch {
        my $err = $self->format_error($_);
        $self->logger->error("$err");
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
