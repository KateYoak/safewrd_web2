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
    _debug( 'Request Object: ' . Dumper(request) );
    # _debug( 'Schema Object: ' . Dumper(schema) );
    my $req = from_json($body);
    _debug( 'Request Body (JSON):' . Dumper($req) );

    my $MAX_SAFETYGROUP  = 5;
    my $result           = $req->{'result'};
    my $id               = $req->{'id'}; 
    my $session_id       = $req->{'sessionId'}; 
    my $timestamp        = $req->{'timestamp'};
    my $status           = $req->{'status'};
    my $original_request = $req->{'originalRequest'}; # data from client UI
    my $service          = $original_request->{'source'};
    my $handle           = _resolve_handle( $original_request ), 

    # capture user data
    _debug( 'Session Object: ' . Dumper(session) );
    _debug( 'User Data: ' . Dumper( $original_request ) );
    # check persona, get user id using persona
    my $persona = Kliq::model('tokens')->get_persona( 
        $handle,
        $service,
    );
    my $user;
    my $user_id;
    # create user if persona does not exist
    if (!defined($persona)) {
        eval {
            $user = Kliq::model('tokens')->create_user();
        };
        if ($@) {
            var error => "Unable to create user " . $@;
            request->path_info('/error');
        }
        $user_id = $user->id; 
        _debug( 'Service: ' . $service );
        my $info = {
            user_id => $user->id,
            handle  => $handle,
        }; 
        $persona = Kliq::model('tokens')->create_persona($info, { service => $service }, $user_id);
    }
    _debug( 'User ID: ' . $user_id );
    _debug( 'Persona ID: ' . $persona->id );

    # check user and create user / session if it doesn't exist

    if ( $result->{'action'} eq 'add.friend' ) {
        my $friend_name = $result->{'parameters'}->{'friend-name'};
        my $context_prefix = 'add-friend';
        if ( ($friend_name) and $friend_name !~ /^(No)$/i ) {
            _debug( 'Params: ' . Dumper( $result->{'parameters'} ) );

            # get user
            my $current_user = ''; # fetch from DB
            # get friend names
            my @friends; # resolve from user
            # store friend

            # count friends
            my $friend_count = 6;  # resolve from user
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
    elsif ( $result->{'action'} eq 'input.welcome' ) {
        # flow of control using contexts
        my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};
        my $request_params = {
            speech   => $fulfillment->{'speech'},
            contextOut  => [],
        };
        return _process_request( $request_params );
    }
    elsif ( $result->{'action'} eq 'input.unknown' ) {
        # flow of control using contexts
        my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};
        my $request_params = {
            speech   => $fulfillment->{'speech'},
            contextOut  => [],
        };
        return _process_request( $request_params );
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

sub _resolve_handle {
    my $params = shift;
    if ( $params->{'source'} eq 'facebook' ) {
        return $params->{'data'}->{'sender'}->{'id'};
    }
    elsif ( !defined($params->{'source'}) ) {
        return 'API.ai';
    }
    else {
        var error => "Unable to resolve handle for " . $params->{'source'};
        request->path_info('/error');
    }
}

1;
__END__

