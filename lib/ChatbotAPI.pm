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

    my $message = ""; 
    my $request_params = {};
    if ( $req->{'result'}->{'action'} eq 'input.welcome' ) {
        my $code = $req->{'result'}->{'parameters'}->{'code'};
        if ( $code ) {
            _debug( 'Code: ' . $code );
            # do something with code
            $message = qq/Hi, I'm the Flarebot, I will help you create your own personal Flare safety group made up of 5 of your close friends or family. Okay, lets get started. Lets start with adding any FB Messenger friends to your Safety group. Whats the name of a FB friend you want to add to your Flare Safety Group?/;
            $request_params = {
                speech   => $message,
                contextOut  => [ 
                    { 
                        name     => 'facebook-friend-name',
                        lifespan => 5,
                    },
                ],
            };
        }
    }
    elsif ( $req->{'result'}->{'action'} eq 'facebook-add-friend' ) {
        my $friend_name = $req->{'result'}->{'parameters'}->{'given-name'};
        _debug( 'Friend Name: ' . $friend_name );
        if ( $friend_name ) {
            # do something with friend name (store)
            $message = qq/Okay, $friend_name, I found them... do you want to add another?/;
            $request_params = {
                speech   => $message,
                contextOut  => [ 
                    { 
                        name     => 'facebook-friend-name',
                        lifespan => 5,
                    },
                ],
            };
        }
    }
    else {
        $message = qq/Default/;
        $request_params = {
            speech   => $message,
            contextOut  => [ 
                { 
                    name     => 'input.unknown',
                },
            ],
        };
    }
    return _process_request( $request_params );

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

