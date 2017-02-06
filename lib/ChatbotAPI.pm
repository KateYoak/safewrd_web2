package ChatbotAPI;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Data::Dumper;

set serializer => 'JSON';

my $DEBUG  = 1;
my $SOURCE = 'proto-onboarding-chatbotapi';
# test
get '/webhook' => sub {
    return "Hello World";
};

post '/webhook' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);
    _debug( 'Request Body (JSON):' . Dumper($req) );

    my $MAX_SAFETYGROUP  = 5;
    my $result           = $req->{'result'};
    my $id               = $req->{'id'}; 
    my $session_id       = $req->{'sessionId'}; 
    my $timestamp        = $req->{'timestamp'};
    my $status           = $req->{'status'};
    my $original_request = $req->{'originalRequest'};

    if ( $result->{'action'} eq 'add.friend' ) {
        my $friend_name = $result->{'parameters'}->{'friend-name'};
        my $context_prefix = 'add-friend';
        if ( $friend_name ne 'no' ) {
            _debug( 'Params: ' . Dumper( $result->{'parameters'} ) );

            # get user
            my $current_user = ''; # fetch from DB
            # get friend names
            my @friends      = ();  # resolve from user
            # store friend

            # count friends
            my $friend_count = '6';  # resolve from user
            my $context_out  = join( "-", $context_prefix, $friend_count ); 
            if ( $friend_count > $MAX_SAFETYGROUP ) {
                $context_out = join( "-", $context_prefix, 'more' ); 
            }

            # flow of control using contexts
            my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};
            my $request_params = {
                speech   => $fulfillment->{'speech'},
                contextOut  => [ 
                    { 
                        name     => $context_out, 
                        lifespan => 1,
                    },
                ],
            };
            return _process_request( $request_params );
        }
        else {
        
        }
    }


};

post '/webhook/echo' => sub {
    content_type 'application/json';
    my $body = request->body();
    _debug( 'Request Body:' . Dumper($body) );
    my $req = from_json($body);
    _debug( 'Request Body (JSON):' . Dumper($req) );
    return status_ok($body);
};

# ----- helper scripts ----

sub _process_request {
    my $params = shift;
    my $response = {
        speech      => $params->{'speech'} || '',  
        displayText => $params->{'displayText'} || $params->{'speech'} || '',
        contextOut  => $params->{'contextOut'},
        source      => $SOURCE,
    };

    _debug( "Response: " . Dumper($response));
    return to_json($response);
}

sub _debug {
    if ($DEBUG) {
        my $debug = shift;
        print STDERR $debug . "\n";
    }
}

1;
__END__

