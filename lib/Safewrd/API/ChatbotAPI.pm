package Safewrd::API::ChatbotAPI;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Data::Dumper;
use REST::Client;
use URI;
use WWW::Google::Translate;

use Kliq::Util qw(fb_surrogate_id_from_picture);

set logger     => 'log_handler';
set serializer => 'JSON';

my $DEBUG  = 1;
my $SOURCE = 'onboarding-chatbot';
my $MAX_SAFETYGROUP  = 5; # TODO: Config file
my $rest_client = REST::Client->new;

# test
get '/webhook' => sub {
    _debug( 'GET on /webhook' );

    return "Hello World!\n";
};

post '/webhook' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);
    _debug( 'API.ai JSON Request: ' . to_json( $req, { pretty => 1 }) );

    my $result           = $req->{'queryResult'};
    my $id               = $req->{'responseId'}; 
    my $api_session      = $req->{'session'}; 
    my $timestamp        = $req->{'timestamp'};
    my $status           = $req->{'status'};
    my $original_request = $req->{'originalDetectIntentRequest'}; # data from client UI
    my $service          = $original_request->{'source'} || 'manual';
    #my $handle           = ($service eq 'manual') ? join( '-', 'dev-api-ai', $api_session ) : _resolve_handle( $original_request );
    my $handle           = _resolve_handle( $original_request );

    # capture user data
    _debug( 'User Data: ' . to_json( $original_request, { pretty => 1 } ) );
    _debug( 'Handle: ' . $handle );

    my $user;
    # check persona, get user id using persona
    my $persona = Kliq::model('tokens')->get_persona( 
        $handle,
        $service,
      );
    
    # create user if persona does not exist
    # CAVEAT: Creates a user per persona, if you are on another service it will create a different user
    if (!defined($persona)) {
        _debug( 'DEBUG: Creating a user for this persona' );
        eval {
            my $message = $original_request->{payload}->{'data'}->{message}->{text};
            $message = $original_request->{payload}->{inputs}->[0]->{arguments}->[0]->{text_value} if $service eq 'google';

            my $lang = _detect_lang($message);
            _debug( 'User lang detected: ' . $lang );

            $user = Kliq::model('tokens')->create_user($lang);
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

    _debug( 'Session Object: ' . Dumper(session) );
    _debug( 'Session User ID: ' . session->{'user_id'} );
    
    if (!defined($user)) {
        $user = schema->resultset('User')->find(session('user_id')); 
    }

    _debug( 'User ID: ' . $user->id );
    _debug( 'User lang: ' . $user->lang );

    # check user and create user / session if it doesn't exist

    #if ( $result->{'action'} =~ /^(greet\.)?add\.friend$/i ) {
    if ( $result->{'action'} eq 'add.friend' ) {
        my $friend_name = $result->{'parameters'}->{'friend-name'};
        my $context_prefix = 'add-friend';
        if ( $friend_name !~ /^(No)$/i ) {
            _debug( 'Params: ' . to_json( $result->{'parameters'}, { pretty => 1 } ) );

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
            my $friend_count = int(scalar(@friends));
            my $next_friend_count = int(scalar(@friends)) + 1;
            if ( $next_friend_count > $MAX_SAFETYGROUP ) {
                push @contexts, { 
                    name => "$api_session/contexts/" . 'yes-add-friend',
                    lifespanCount => 1,
                }; 
                push @contexts, {
                    name => "$api_session/contexts/" . 'no-create-safetygroup',
                    lifespanCount => 1,
                };
            }
            else {
                push @contexts, { 
                    name => "$api_session/contexts/" . join( "-", $context_prefix, $next_friend_count ),
                    lifespanCount => 1,
                }; 
            }

            # flow of control using contexts
            my $fulfillment_txt = $result->{fulfillmentMessages}[0]{text}{text}[0];
            my $request_params = {
                fulfillmentText   => $fulfillment_txt,
                outputContexts  => \@contexts,
                lang        => $user->lang
            };
            return _process_request( $request_params );
        }
        else {
            # do nothing 
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
            my $fulfillment_txt = $result->{fulfillmentMessages}[0]{text}{text}[0];
            my $request_params = {
                fulfillmentText   => $fulfillment_txt,
                outputContexts  => [ 
                    {
                        name     => "$api_session/contexts/" . 'create-safeword',
                        lifespanCount => 1,
                    }
                ],
                lang        => $user->lang
            };
            return _process_request( $request_params );
        }
    }
    elsif ( $result->{'action'} eq 'create.safeword' ) {
        my $safeword = $result->{'parameters'}->{'safeword'};
        if ( $safeword ) {
            my $kliq_group = schema->resultset('Kliq')->search({
                user_id  => $user->id,
            })->single();
            $kliq_group->update({
                safeword => $safeword,
            });
            _debug("Kliq Group ID: " . $kliq_group->id);
            my $fulfillment_txt = $result->{fulfillmentMessages}[0]{text}{text}[0];
            # interpolate friend count
            if ($fulfillment_txt =~ /{{friend-count}}/i) {
                my @kliq_members = schema->resultset('KliqContact')->search({
                    kliq_id => $kliq_group->id,
                })->all();
                _debug("Kliq Group Count: " . Dumper(scalar( @kliq_members )));
                my $friend_count = scalar( @kliq_members );
                $fulfillment_txt =~ s/{{friend-count}}/$friend_count/g;
            }
            else {
                $fulfillment_txt =~ s/{{friend-count}}//g;
            }

            # interpolate url 
            if ($fulfillment_txt =~ /{{tranzmt-url}}/i) {
                # generate url
                my $url = _resolve_url( {
                    owner_id => $user->id, 
                    kliq_id  => $kliq_group->id,
                } ); 
                $fulfillment_txt =~ s/{{tranzmt-url}}/$url/g;
            }
            else {
                $fulfillment_txt =~ s/{{tranzmt-url}}//g;
            }

            # interpolate url 
            if ($fulfillment_txt =~ /{{pin}}/i) {
                # generate pin
                my $pin = int(rand(100));
                $pin = '0' . $pin if $pin < 10;

                $kliq_group->update({
                    verification_pin => $pin,
                });

                $fulfillment_txt =~ s/{{pin}}/$pin/g;
            }
            else {
                $fulfillment_txt =~ s/{{pin}}//g;
            }

            my $request_params = {
                fulfillmentText   => $fulfillment_txt,
                # outputContexts  => [ 
                #     {
                #         name     => "$api_session/contexts/" . 'create-safeword',
                #         lifespanCount => 1,
                #     }
                # ],
                lang => $user->lang
            };
            return _process_request( $request_params );
        }
    }
    elsif ( $result->{'action'} eq 'input.welcome' ) {
        # flow of control using contexts
        my $fulfillment_txt = $result->{fulfillmentMessages}[0]{text}{text}[0];
        my $request_params = {
            fulfillmentText   => $fulfillment_txt,
            outputContexts  => [],
            lang => $user->lang,
        };
        return _process_request( $request_params );
    }
    # elsif ( $result->{'action'} eq 'input.unknown' ) {
    elsif ( $result->{'action'} =~ /^(greet\.add\.friend|input\.unknown)$/i ) {
        my $context_prefix = 'add-friend';
        my @contexts = ();

        # get friend names
        my @friends = schema->resultset('Contact')->search({
            owner_id => $user->id,
            handle   => {
                like => join( ':', $SOURCE, $user->id )  . '%',
            }
        })->all();

        my $message = '';
        # count friends and prompt for next friend 
        my $friend_count = int(scalar(@friends));
        my $next_friend_count = int(scalar(@friends)) + 1;
        my $is_complete = 0;
        if ( $friend_count > $MAX_SAFETYGROUP ) {

            # we got all the friends, check for the safety groupname
            my $kliq_group = schema->resultset('Kliq')->search({
                user_id      => $user->id,
                is_emergency => 1,
            })->single();

            if (!defined($kliq_group)) {
                $message = "Looks like you already have the minimum number of friends on your group, do you want to add anybody else to your group? (yes or no)";
                push @contexts, { 
                    name => "$api_session/contexts/" . 'yes-add-friend',
                    lifespanCount => 1,
                }; 
                push @contexts, {
                    name => "$api_session/contexts/" . 'no-create-safetygroup',
                    lifespanCount => 1,
                };
            }
            else {
                $message = 'Think of what you want your "SafeWord" to be, we recommend it be a phrase rather than a single word. Try to make it something you would rarely ever say - something so unique like "pink grasshoppers"';
                # safetygroup?  
                if (!defined($kliq_group->safeword)) {
                    push @contexts, {
                        name     => "$api_session/contexts/" . 'create-safeword',
                        lifespanCount => 1,
                    };
                }
                elsif (!defined($kliq_group->name)) {
                    $message = "Do you want to add anybody else to your group? (yes or no)";
                    push @contexts, { 
                        name => "$api_session/contexts/" . 'yes-add-friend',
                        lifespanCount => 1,
                    }; 
                    push @contexts, {
                        name => "$api_session/contexts/" . 'no-create-safetygroup',
                        lifespanCount => 1,
                    };
                }
                else {
                    # everythings there! 
                    $is_complete = 1;
                    my $url = _resolve_url( {
                        owner_id => $user->id, 
                        kliq_id  => $kliq_group->id,
                    } ); 

                    my $pin = $kliq_group->verification_pin;
                    $message = 'Looks like we are all good! You already have a named safety group "' . $kliq_group->name . '" and a safeword "' . $kliq_group->safeword . '". Click here '. $url .' to install and use your one time pin code '. $pin .' then come back here and COPY/SHARE the link only, with ONLY your '. $friend_count .' friends directly via SMS, DM or Private Message.';
                    @contexts = ();
                }
            }
        }
        else {
            my $ORDINAL_MAP = {
                1 => "first",
                2 => "second",
                3 => "third",
                4 => "fourth",
                5 => "fifth",
            };
            if ($friend_count > 1 && $friend_count < $MAX_SAFETYGROUP) {
                $message = "Looks like you've already added some friends. What's the name of your " . $ORDINAL_MAP->{$next_friend_count} . " friend?";
                push @contexts, { 
                    name => "$api_session/contexts/" . join( "-", $context_prefix, $next_friend_count ),
                    lifespanCount => 1,
                }; 
            }
            elsif ($friend_count < 1) {
                $message = "What's the name of the first friend you want to add to your group? (eg. Mike Brown, or Mike)";
                push @contexts, { 
                    name => "$api_session/contexts/" . join( "-", $context_prefix, $next_friend_count ),
                    lifespanCount => 1,
                }; 
            }
            else {
                $message = "Looks like you already have the minimum number of friends, do you want to add anybody else to your group? (yes or no)";
                push @contexts, { 
                    name => "$api_session/contexts/" . 'yes-add-friend',
                    lifespanCount => 1,
                }; 
                push @contexts, {
                    name => "$api_session/contexts/" . 'no-create-safetygroup',
                    lifespanCount => 1,
                };
            }
        }

        # flow of control using contexts
        my $fulfillment_txt = $result->{fulfillmentMessages}[0]{text}{text}[0];

        # twilio special case just for initial greeting
        if ($service eq 'twilio' && $friend_count < 1) {
            $fulfillment_txt = qq(With a "Safety group", your "safeword" and our App, your friends can receive a live video stream from you whenever you're in trouble and say your "safeword".\nSo, let's create your "Safety Group". You need a minimum of five friends or family members to create your group.);
        }

        my $request_params = {
            fulfillmentText   => ($is_complete) ? $message : $fulfillment_txt . " " . $message,
            outputContexts  => \@contexts,
            lang => $user->lang,
        };
        return _process_request( $request_params );
    }
};

post '/webhook/echo' => sub {
    content_type 'application/json';
    my $body = request->body();
    _debug( 'Request Body:' . to_json( $body, { pretty => 1 } ) );
    my $req = from_json($body);
    _debug( 'Request Body (JSON):' . to_json( $req, { pretty => 1 } ) );
    return status_ok($body);
};


# ----- helper scripts ----

sub _process_request {
    my $params = shift;

    my $fulfillmentText = $params->{'fulfillmentText'} || '';
    my $display_text = $params->{'displayText'};

    if ($fulfillmentText && $params->{lang} ne 'en') {
        $fulfillmentText = _translate_message($fulfillmentText, $params->{lang});
    }

    if ($display_text && $params->{lang} ne 'en') {
        $display_text = _translate_message($display_text, $params->{lang});
    }

    my $response = {
        fulfillmentText => $display_text || $fulfillmentText || '',
        outputContexts  => $params->{'outputContexts'},
        source      => $SOURCE,
    };

    _debug( "Response Sent to API.ai: " . to_json( $response, { pretty => 1 } ));
    return to_json($response);
}

sub _debug {
    if ($DEBUG) {
        my $debug = shift;
        warn $debug . "\n";
        error($debug . "\n");
    }
}

sub _detect_lang {
    my ($text) = @_;

    my $google_translate = WWW::Google::Translate->new({
        key            => 'AIzaSyCDxbHQdso9H1FSHfVWOkjKan0mW6j9tYM',
    });

    my $r = $google_translate->detect({ q => $text });
    my $lang = $r->{data}->{detections}->[0]->[0]->{language};
    return $lang;
}

sub _translate_message {
    my ($text, $to_lang) = @_;

    my $google_translate = WWW::Google::Translate->new({
        key            => 'AIzaSyCDxbHQdso9H1FSHfVWOkjKan0mW6j9tYM',
        default_source => 'en',
        default_target => $to_lang,
    });

    my $r = $google_translate->translate({ q => $text });
    my $translated_text = $r->{data}->{translations}->[0]->{translatedText} if scalar @{$r->{data}->{translations}};
    return $translated_text;
}

sub _resolve_handle {
    my $params = shift;

    _debug('**** in _resolve_handle(). source - ' . $params->{source});
    if ( $params->{'source'} eq 'facebook' ) {
        return fb_surrogate_id_from_picture($params->{'payload'}->{'data'}->{'sender'}->{'id'}) || $params->{'payload'}->{'data'}->{'sender'}->{'id'};
    }
    elsif ( $params->{'source'} eq 'twitter' ) {
        return $params->{'payload'}->{'direct_message'}->{'sender_id_str'};
    }
    elsif ( $params->{'source'} eq 'google' ) {
        #return $params->{'payload'}->{'user'}->{'user_id'};  Deprecated by google May 2019
        return $params->{'payload'}->{'conversation'}->{'conversationId'}; # NOTE: persists for ONLY a single conversation!
    }
    elsif ( $params->{'source'} eq 'twilio' ) {
        return $params->{'payload'}->{'data'}->{'From'};
    }
    else {
        var error => "Unable to resolve handle for " . $params->{'source'};
        request->path_info('/error');
    }
}

sub _resolve_url {
    my $params = shift;

    my $referrer_params;
    if (scalar keys(%{$params}) > 0) {
        # $referrer_params = 'owner_id=12345,kliq_id=54321';
        # join values by delimiter ','
        $referrer_params = join( ',', map { join('=',$_,$params->{$_}) } keys %{$params} );
    }
    else {
        var error => "Missing referrer parameters";
        request->path_info('/error');
    }

    _debug( "Referrer Parameters: " . $referrer_params );
    my $client = REST::Client->new();

    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');

    # TODO: Put in Configuration file
    my $branchio_url    = 'https://api.branch.io/v1/url';
    #my $branchio_key    = q/key_test_mfrDiacvwlh3JJTGhTTbvojnwzj6H2eH/;
    #my $branchio_secret = q/secret_test_KHAOHA4K6wMuuJfix2cQKFyEvCCIF9PW/;
    my $branchio_key    = q/key_live_aaxsnnkztel3KJHHmPQjrmnbBxf1M2p5/;
    my $branchio_secret = q/secret_live_ZCLNWTeLntTM3KGUTzsNDi0wFkZjrbLH/;
    my $google_play_url = URI->new('https://play.google.com/store/apps/details');
    # my $app_id          = 'fr.simon.marquis.installreferrer'; # TODO: Use real app ID
    my $app_id          = 'com.flare.app';
    my $ios_url         = 'http://example.com/tranzmt';
    my $ios_uri_scheme  = 'safewrd://';
    my $universal_linking_enabled = 1;
    my $ios_bundle_id   = 'it.tranzmt.flare';
    # TODO: Put in Configuration file

    my $url_params = {
        id       => $app_id,
        referrer => $referrer_params,
    };
    $google_play_url->query_form($url_params);

    _debug( "Google Play URL: " . $google_play_url->as_string);
    my $payload = {
        '$android_url' => $google_play_url->as_string,
        #'$ios_url'     => $ios_url,
        '$ios_uri_scheme' => $ios_uri_scheme,
        '$universal_linking_enabled' => $universal_linking_enabled,
        '$ios_bundle_id' => $ios_bundle_id,
    };

    my $request_params = {
        branch_key => $branchio_key,
        data       => $payload,
    };

    my $req = to_json($request_params);
    my $endpoint_url = URI->new($branchio_url);
    $client->POST($endpoint_url->canonical, $req);
    if ($client->responseCode() =~ /^5\d{2}$/) {
        var error => "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]";
        request->path_info('/error');
    }

    my $response = from_json($client->responseContent());
    if (exists $response->{'error'}) {
        my $details = $response->{'error'};
        var error => "Error Encountered, Code: [" . $details->{'code'} .  "], Message: [" . $details->{'message'} . "]";
        request->path_info('/error');
    }

    return $response->{'url'};
}

sub _resolve_user_details {
    my $params = shift;

    my $client = REST::Client->new();
    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');

    if (!$params->{'service'}) {
        var error => "_resolve_user_details(): missing parameter: service";
        request->path_info('/error');
    }
    if (!$params->{'handle'}) {
        var error => "_resolve_user_details(): missing parameter: handle";
        request->path_info('/error');
    }
        
    my $user_details;
    if ( $params->{'service'} eq 'facebook' ) {
        my $user_details = _get_facebook_user_details( $client, $params );
    }
    else {
        var error => "Unsupported service " . $params->{'service'};
        request->path_info('/error');
    }
    return $user_details;
}

sub _get_facebook_user_details {
    my $client = shift;
    my $params = shift;

    # TODO: Put in Configuration file
    my $graph_url    = join( '/', 'https://graph.facebook.com/v2.8', $params->{'handle'} );
    # Non-expiring Facebook Page / Application token generated via FB Graph Explorer
    # Guide here: https://www.rocketmarketinginc.com/blog/get-never-expiring-facebook-page-access-token/
    my $access_token = 'EAAKLaAfiAtcBAJRNmCuNjD5Xc7kyPNklyG7ZCdziPTHcFsZAEoodGBiJz8xzixjaqdrDrbYTt3rMJ3I1993JmZCz3hu8rZClIWndC3TErZBDa2VeVXpyvNw4eg6zNogoiynRCZAiGsyk2KHk5KBfbAOtk44h7JghgOHHZBfnhZAghAZDZD';
    # TODO: Put in Configuration file

    my @fields       = qw/
        first_name
        last_name
        profile_pic
        locale
        timezone
        gender
        is_payment_enabled
    /;
    my $url_params   = {
        access_token => $access_token,
        fields       => join(',', @fields),
    };
    my $endpoint_url = URI->new($graph_url);
    $endpoint_url->query_form($url_params);
    _debug( "Facebook Graph URL: " . $endpoint_url->as_string);

    $client->GET($endpoint_url->canonical);
    if ($client->responseCode() =~ /^5\d{2}$/) {
        var error => "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]";
        request->path_info('/error');
    }

    my $response = from_json($client->responseContent());
    if (exists $response->{'error'}) {
        my $details = $response->{'error'};
        var error => "Error Encountered, Code: [" . $details->{'code'} .  "], Message: [" . $details->{'message'} . "], FB Trace ID: [" . $details->{'fbtrace_id'} . "], Type: [" . $details->{'type'} . "]";
        request->path_info('/error');
    }

    _debug( "Facebook Graph JSON Response: " . to_json( $response, { pretty => 1 } ) );
    return $response;
}

1;
__END__

