package Kliq::Routes::Auth;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Twitter;
use Net::OAuth::Yahoo;
use Net::OAuth2::Client;
use WWW::LinkedIn;
use HTML::Entities;
use Data::Dumper;
use Try::Tiny;

#---- oAuth clients ------------------------------------------------------------

sub client {
    my $site_id = shift;
    
    my $cb = cb($site_id);
    
    return Net::OAuth2::Client->new(
        config->{sites}{$site_id}{client_id},
        config->{sites}{$site_id}{client_secret},
        site => config->{sites}{$site_id}{site},
        authorize_path => config->{sites}{$site_id}{authorize_path},
        access_token_path => config->{sites}{$site_id}{access_token_path},
        access_token_method => config->{sites}{$site_id}{access_token_method},
        access_token_param => config->{sites}{$site_id}{access_token_param},
        scope => config->{sites}{$site_id}{scope}
        )->web_server(redirect_uri => $cb);
}

sub li_client {
    return WWW::LinkedIn->new(
        consumer_key    => config->{sites}{linkedin}{client_id},     # API Key
        consumer_secret => config->{sites}{linkedin}{client_secret}, # Secret Key
    );
}

sub yh_client {
    my $args = {
        consumer_key => config->{sites}{yahoo}{client_id},
        consumer_secret => config->{sites}{yahoo}{client_secret},
        signature_method => "HMAC-SHA1",
        nonce => config->{sites}{yahoo}{nonce}, # random_string
        callback => cb('yahoo'),
    };

    return Net::OAuth::Yahoo->new($args);
}

sub cb {
    my $site = shift;
    my $prefix = request->secure ? 'https://' : 'http://';
    return $prefix . request->host . "/oauth/$site/callback";
}

auth_twitter_init();

#---- twitter ------------------------------------------------------------------

get '/auth/twitter' => sub {
    if (not session('twitter_user')) {
        redirect auth_twitter_authenticate_url;
    }
    else {
        redirect '/auth/twitter/success';
    }
};

get '/auth/twitter/success' => sub {
    my $twuser = session('twitter_user') or die("Invalid request");
    
    my $error;
    try {
        my ($token, $uid) = Kliq::model('tokens')->handle_token({
            service => 'twitter',
            token   => session('twitter_access_token'),
            secret  => session('twitter_access_token_secret'),
            session => session('id'),
            user    => vars->{user} ? vars->{user}->id : undef,
            #handle => $twuser->{id},
            info    => $twuser
        });
        die("No user created or found") unless $uid;    
        session user_id => $uid;
    } catch {
        $error = $_;
    };
    if($error) {
        return template "error", {
            resource => 'Auth', field => 'code', code => "invalid_grant",
            message =>  $error
        };
    }
    
    template "oauth_success", { 
        service => 'twitter',
        access_token => session('id')
        }, { layout => undef };
};

get '/auth/twitter/fail' => sub {
    #return send_error('Twitter FAIL');
    redirect '/auth/twitter';

};

#---- linkedin -----------------------------------------------------------------

get '/auth/linkedin' => sub {
    my $li = li_client();

    my $token = $li->get_request_token(
        callback => cb('linkedin')
    );

    #-- save $token->{token} and $token->{secret} for later:
    session li_request_token        => $token->{token};
    session li_request_token_secret => $token->{secret};
    
    redirect $token->{url};
};

get '/auth/linkedin/callback' => sub {
    my $li = li_client();

    my $access_token = $li->get_access_token(
        verifier             => params->{oauth_verifier},
        request_token        => session->{li_request_token},
        request_token_secret => session->{li_request_token_secret},
    );

    return redirect '/auth/linkedin' unless $access_token;

    my ($token, $uid) = Kliq::model('tokens')->handle_token({
        service => 'linkedin',
        token   => $access_token->{token},
        secret  => $access_token->{secret},
        session => session('id'),
        user    => vars->{user} ? vars->{user}->id : undef
    });
    die("No user created or found") unless $uid;
    session user_id => $uid;

    template "oauth_success", {
        service => 'linkedin',
        access_token => session('id')
        }, { layout => undef };
};

#---- yahoo --------------------------------------------------------------------

get '/auth/yahoo' => sub {
    my $oauth = yh_client();

    my ($error, $request_token, $url);
    try {
        #-- obtain the request token
        $request_token =  $oauth->get_request_token() 
            or die($Net::OAuth::Yahoo::ERRMSG);
        
        #-- fetch the OAuth URL to be presented to the user
        $url = $oauth->request_auth($request_token);
        session yahoo_request_token => $request_token;  

    } catch {
        $error = $_;
    };
    if(!defined $request_token || !$url || $error) {
        $error ||= 'Invalid grant';
        return template "error", {
            resource => 'Auth', field => 'code', code => "invalid_grant",
            message =>  $error
        };
    }
    
    redirect $url;
};

get '/auth/yahoo/callback' => sub {
    my $oauth = yh_client();
    $oauth->{request_token} = session('yahoo_request_token') or die("Invalid yahoo session");

    #-- get the token using the OAuth Verifier
    #-- params contain oauth_token and oauth_verifier    
    my $token = $oauth->get_token(params->{oauth_verifier});
    return redirect '/auth/yahoo' unless $token;

    my ($dbtoken, $uid) = Kliq::model('tokens')->handle_token({
        service => 'yahoo',
        token   => $token->{oauth_token},
        secret  => $token->{oauth_token_secret},
        session => session('id'),
        user    => vars->{user} ? vars->{user}->id : undef,
##DEPR        
        #handle  => $token->{xoauth_yahoo_guid},
        info    => $token
    });
    die("No user created or found") unless $uid;
    session user_id => $uid;

    template "oauth_success", {
        service      => 'yahoo',
        access_token => session('id')
        }, { layout => undef };
};

#---- google, facebook ---------------------------------------------------------

get '/auth/:site_id' => sub {
    redirect client(params->{site_id})->authorize_url;
};

get '/auth/:site_id/callback' => sub {
    
    # Use the auth code to fetch the access token
    if (!defined params->{code}) {
        return template "error", { 
            resource => 'Auth', field => 'code', code => "missing_field", 
            message =>  "Error: Missing access code"
        };
    }
    my ($error, $access_token);
    try {
        $access_token =  client(params->{site_id})->get_access_token(params->{code});
    } catch {
        $error = $_;
    };
    if($error) {
        return template "error", {
            resource => 'Auth', field => 'code', code => "invalid_grant",
            message =>  "Invalid grant"
        };
    }

    if ($access_token->{error}) {
        return template "error", {
            resource => 'Auth', field => 'code', code => $access_token->{error},
            message =>  $access_token->to_string
        };    
    }

    my $token = from_json($access_token->to_string);
    
    my ($dbtoken, $uid) = Kliq::model('tokens')->handle_token({
        service => params->{site_id},
        token => $token->{access_token},
        secret => ($token->{client} && $token->{client}->{secret}) ? $token->{client}->{secret} : undef,
        expires => $token->{expires_in} || undef,
        session => session('id'),
        user => vars->{user} ? vars->{user}->id : undef
    });
    die("No user created or found") unless $uid;
    session user_id => $uid;
    
    template "oauth_success", { 
        service => params->{site_id},
        access_token => session('id')
        }, { layout => undef };    
};

1;
__END__
