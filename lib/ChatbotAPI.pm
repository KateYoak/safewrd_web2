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
my $SOURCE = 'onboarding-chatbot';
my $MAX_SAFETYGROUP  = 5; # TODO: Config file
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

    my $result           = $req->{'result'};
    my $id               = $req->{'id'}; 
    my $api_session_id   = $req->{'sessionId'}; 
    my $timestamp        = $req->{'timestamp'};
    my $status           = $req->{'status'};
    my $original_request = $req->{'originalRequest'}; # data from client UI
    my $service          = $original_request->{'source'} || 'manual';
    my $handle           = ($service eq 'manual') ? join( '-', 'dev-api-ai', $api_session_id ) : _resolve_handle( $original_request );

    # capture user data
    _debug( 'Session Object: ' . Dumper(session) );
    _debug( 'User Data: ' . Dumper( $original_request ) );
    my $user;
    if (!session('user_id')) {
        # check persona, get user id using persona
        my $persona = Kliq::model('tokens')->get_persona( 
            $handle,
            $service,
        );
        # create user if persona does not exist
        # CAVEAT: Creates a user per persona, if you are on another service it will create a differen user
        if (!defined($persona)) {
            _debug( 'DEBUG: Creating a user for this persona' );
            eval {
                $user = Kliq::model('tokens')->create_user();
            };
            if ($@) {
                var error => "Unable to create user " . $@;
                request->path_info('/error');
            }
            _debug( 'Service: ' . $service );
            my $info = {
                service => $service,
                user_id => $user->id,
                handle  => $handle,
            }; 
            $persona = Kliq::model('tokens')->create_persona($info, { service => $service }, $user->id);
        }
        _debug( 'Persona ID: ' . $persona->id );
        session user_id => $persona->user_id;
    }

    _debug( 'Session User ID: ' . session->{'user_id'} );

    if (!defined($user)) {
        $user = schema->resultset('User')->find(session('user_id')); 
    }

    # check user and create user / session if it doesn't exist

    if ( $result->{'action'} =~ /^(greet\.)?add\.friend$/i ) {
        my $friend_name = $result->{'parameters'}->{'friend-name'};
        my $context_prefix = 'add-friend';
        if ( $friend_name !~ /^(No)$/i ) {
            _debug( 'Params: ' . Dumper( $result->{'parameters'} ) );

            # store friend if there is a friend, else prompt user
            if ($friend_name) {
                my $friend = schema->resultset('Contact')->create({
                    owner_id => $user->id,
                    handle   => join( ':', $SOURCE, $user->id, $friend_name),
                    name     => $friend_name,
                    service  => 'manual',
                });

                _debug( 'Contact ID: ' . $friend->id );
            }

            # get friend names
            my @friends = schema->resultset('Contact')->search({
                owner_id => $user->id,
                handle   => {
                    like => join( ':', $SOURCE, $user->id )  . '%',
                }
            })->all();

            # count friends and prompt for next friend 
            my @contexts;
            my $friend_count = int(scalar(@friends)) + 1;
            if ( $friend_count > $MAX_SAFETYGROUP ) {
                push @contexts, { 
                    name => 'yes-add-friend',
                    lifespan => 1,
                }; 
                push @contexts, {
                    name => 'no-create-safetygroup',
                    lifespan => 1,
                };
            }
            else {
                push @contexts, { 
                    name => join( "-", $context_prefix, $friend_count ),
                    lifespan => 1,
                }; 
            }

            # flow of control using contexts
            my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};
            my $request_params = {
                speech   => $fulfillment->{'speech'},
                contextOut  => \@contexts, 
            };
            return _process_request( $request_params );
        }
        else {
        
        }
    }
    elsif ( $result->{'action'} eq 'create.safetygroup' ) {
        my $group_name = $result->{'parameters'}->{'group-name'};
        if ( $group_name ) {
            my $kliq_group = schema->resultset('Kliq')->create({
                user_id      => $user->id,
                name         => $group_name,
                is_emergency => 1,
            });
            my @friends = schema->resultset('Contact')->search({
                owner_id => $user->id,
                handle   => {
                    like => join( ':', $SOURCE, $user->id )  . '%',
                }
            });
            foreach my $f (@friends) {
                my $kliq_map = schema->resultset('KliqContact')->create({
                    kliq_id    => $kliq_group->id,
                    contact_id => $f->id,
                });
            }
            my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};
            my $request_params = {
                speech   => $fulfillment->{'speech'},
                contextOut  => [ 
                    {
                        name     => 'create-safeword',
                        lifespan => 1,
                    }
                ],
            };
            return _process_request( $request_params );
        }
    }
    elsif ( $result->{'action'} eq 'create.safeword' ) {
        my $safeword = $result->{'parameters'}->{'safeword'};
        if ( $safeword ) {
            my $fulfillment = shift @{$result->{'fulfillment'}->{'messages'}};

            # interpolate friend count
            if ($fulfillment->{'speech'} =~ /{{friend-count}}/i) {
                my @friends = schema->resultset('Contact')->search({
                    owner_id => $user->id,
                    handle   => {
                        like => join( ':', $SOURCE, $user->id )  . '%',
                    }
                })->all();
                my $friend_count = scalar( @friends );
                $fulfillment->{'speech'} =~ s/{{friend-count}}/$friend_count/g;
            }
            else {
                $fulfillment->{'speech'} =~ s/{{friend-count}}//g;
            }

            # interpolate url 
            if ($fulfillment->{'speech'} =~ /{{tranzmt-url}}/i) {
                # generate url
                my $url = "";
                $fulfillment->{'speech'} =~ s/{{tranzmt-url}}/$url/g;
            }
            else {
                $fulfillment->{'speech'} =~ s/{{tranzmt-url}}//g;
            }

            my $request_params = {
                speech   => $fulfillment->{'speech'},
                # contextOut  => [ 
                #     {
                #         name     => 'create-safeword',
                #         lifespan => 1,
                #     }
                # ],
            };
            return _process_request( $request_params );
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
    else {
        var error => "Unable to resolve handle for " . $params->{'source'};
        request->path_info('/error');
    }
}

1;
__END__

