
package Kliq::Model::Role::UserInfo;

use Moose::Role;
use Data::Dumper;
use Furl;
use JSON;
use Net::Twitter;
use Net::Facebook::Oauth2;
use Net::OAuth::Yahoo;
use WWW::LinkedIn;

sub userinfo {
    my ($self, $data, $config) = @_;
    
    $data->{service} = lc($data->{service});
    my $method = '_' . $data->{service} . '_ui';
    return $self->$method($data, $config);
}

sub _facebook_ui {
    my ($self, $data, $config) = @_;
    
    my $token = $data->{token};
    my $fb = Net::Facebook::Oauth2->new(
        access_token => $token
    );
    
    my $info; 
    eval {
        my $fields = ''; #'?fields=id,name,username,email,gender,picture,link,website,locale,location,timezone';
        my $info_object = $fb->get("https://graph.facebook.com/me$fields") 
            or die("No facebook response");
        my $jstring = $info_object->as_json or die("No facebook profile json");
        $info = from_json($jstring) or die("Invalid json");
        if($info->{error}) {
            die($info->{error}->{message});
        }
    };
    if ($@) {
        die("Facebook profile error: " . $@);
    }

    return $self->_fb_data($info);
}

sub _yahoo_ui {
    my ($self, $data, $config) = @_;

    my $oauth = Net::OAuth::Yahoo->new({
        consumer_key => $config->{client_id},
        consumer_secret => $config->{client_secret},
        signature_method => "HMAC-SHA1",
        nonce => $config->{nonce},
        callback => 'http://api.tranzmt.it/oauth/yahoo/callback',
    });

    #$oauth->{ token } = $ref;
    my $token = $data->{info};
    my $purl = 'http://social.yahooapis.com/v1/user/'.$token->{xoauth_yahoo_guid}.'/profile?format=json';
    my $json = $oauth->access_api($token, $purl) or die($Net::OAuth::Yahoo::ERRMSG);
    
    return $self->_yh_data(from_json($json)->{profile});
}

sub _linkedin_ui {
    my ($self, $data, $config) = @_;

    my $li = WWW::LinkedIn->new(
        consumer_key    => $config->{client_id},        # Your 'API Key'
        consumer_secret => $config->{client_secret},    # Your 'Secret Key'
    );
    
    my $fields = 'id,first-name,last-name,headline,formatted-name,picture-url,location:(name,country:(code)),public-profile-url,email-address';
    my $profile;
    eval {     
        my $profilestr = $li->request(
            request_url => "https://api.linkedin.com/v1/people/~:($fields)",
            access_token        => $data->{token},
            access_token_secret => $data->{secret},
        ) or die("No profile from linkedin");
        $profile = from_json($profilestr);
        die($profile->{message}) if defined($profile->{errorCode});
    };
    if ($@) {
        die("no linkedin profile or error: " . $@);
    }

    return $self->_li_data($profile);
}

sub _google_ui {
    my ($self, $data, $config) = @_;
    
    my $token = $data->{token};
    my $url = 'https://www.googleapis.com/oauth2/v1/userinfo?alt=json';

    my $furl = Furl->new(
        timeout => 15,
        headers => [ 'Authorization' => "OAuth " . $token ],
    );

    my $res = $furl->get($url) or die("No response for google userprofile");
    die $res->status_line unless $res->is_success;

    return $self->_gl_data(from_json($res->content));
}

sub _twitter_ui {
    my ($self, $data, $config) = @_;
    
    my $twitter_user_hash = $data->{info};
    
    unless($twitter_user_hash) {
        my $token = $data->{token};
        my $secret = $data->{secret};

        my $nt = Net::Twitter->new(
            traits   => [qw/AutoCursor API::REST RetryOnError RateLimit OAuth/],
            consumer_key        => $config->{client_id},
            consumer_secret     => $config->{client_secret},
            access_token        => $token,
            access_token_secret => $secret,
            apiurl => 'https://api.twitter.com/1.1',
            ssl => 1
        );
        
        eval {
            $twitter_user_hash = $nt->verify_credentials()
                or die("No twitter profile response");
        };

        if ($@) {
            die("Twitter user profile error: ".$@);
        }
    }
    
    return $self->_tw_data($twitter_user_hash);
}

sub _tw_data {
    my ($self, $data) = @_;
    die("Invalid twitter profile data") unless($data && ref($data) eq 'HASH');

    return {
        handle      => $data->{id},
        name        => $data->{name},
        screen_name => $data->{screen_name},
        image       => $data->{profile_image_url},
        profile_url => 'https://twitter.com/' . $data->{screen_name},
        website     => $data->{url},
        language    => $data->{lang},
        location    => $data->{location},
        timezone    => $data->{time_zone},
    };
}

sub _li_data {
    my ($self, $data) = @_;
    die("Invalid linkedin profile data") unless($data && ref($data) eq 'HASH');
    
    my $location = undef;
    if($data->{location} && ref($data->{location}) eq 'HASH') {
        $location = $data->{location}->{name};
    }

    return {
        handle      => $data->{id},
        name        => ($data->{formattedName} && $data->{formattedName} ne 'private') ? $data->{formattedName} : undef,
        #screen_name => undef,
        email       => $data->{emailAddress},
        #gender     => undef,
        image       => $data->{pictureUrl},
        profile_url => $data->{publicProfileUrl},
        #language   => undef,
        location    => $location,
        #timezone   => undef,
    };
}

sub _yh_data {
    my ($self, $data) = @_;
    die("Invalid yahoo profile data") unless($data && ref($data) eq 'HASH');
    
    my $gender = undef;
    if($data->{gender}) {
        if($data->{gender} eq 'M') {
            $gender = 'male';
        }
        elsif($data->{gender} eq 'F') {
            $gender = 'female';
        }
    }

    my $name = ($data->{givenName} && $data->{familyName}) ?
        join(' ', $data->{givenName}, $data->{familyName}) :
        $data->{givenName} || $data->{familyName} || $data->{nickname} || undef;

    my $image = undef;
    if($data->{image}) {
        $image = $data->{image}->{imageUrl};
    }    

    return {
        handle      => $data->{guid},
        name        => $name,
        screen_name => $data->{nickname},
        #email       => undef,
        gender      => $gender,
        image       => $image,
        profile_url => $data->{profileUrl},
        language    => $data->{lang},
        location    => $data->{location},
        timezone    => $data->{timeZone},
    };
}

sub _fb_data {
    my ($self, $data) = @_;
    die("Invalid facebook profile data") unless($data && ref($data) eq 'HASH');    
    
    return {
        handle      => $data->{id},
        name        => $data->{name},
        screen_name => $data->{username},
        email       => $data->{email},
        gender      => $data->{gender},
        image       => $data->{picture} || ('https://graph.facebook.com/'.$data->{id}.'/picture?type=square'),
        profile_url => $data->{link},
        website     => $data->{website},
        language    => $data->{locale},
        location    => ref($data->{location}) ? $data->{location}->{name} : $data->{location},
        timezone    => $data->{timezone},
    };
}

sub _gl_data {
    my ($self, $data) = @_;
    die("Invalid google profile data") unless($data && ref($data) eq 'HASH');    
    
    return {
        handle      => $data->{id},
        name        => $data->{name},
        screen_name => $data->{email},
        email       => $data->{email},
        gender      => $data->{gender},
        image       => $data->{picture},
        profile_url => $data->{link},
        language    => $data->{locale},
        #location   => $data->{locale},
        #timezone   => $data->{timezone},
    };
}

no Moose::Role;

1;
__END__