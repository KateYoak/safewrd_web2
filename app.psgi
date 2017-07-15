
use Dancer; # ':syntax';
use Plack::Builder;
use Plack::Middleware::Session;
use Plack::Session::State::Cookie;
use Plack::Session::Store::Redis;
use Plack::Session::Store::File;
use YAML;

set environment => "production";
set session => 'Kliq';

load_app 'Kliq'; #, prefix => '/api';
load_app 'Kliq::Routes::Auth';
load_app 'ChatbotAPI';
load_app 'Tokbox';

## reset asset_basepath for local testing
if($^O =~ /Win32/) {
    set asset_basepath => 'K:/KLIQ/media';
}
    
my $app = sub {
    my $env     = shift;
    my $request = Dancer::Request->new(env => $env );
    Dancer->dance($request);
};

my $home = sub {
    my $env = shift;
    return [ 200, ['Content-Type' => 'text/html'],  ['<a href="/v1">API V1</a>'] ];
};

builder {
    enable 'Session', store => 'Redis', state => Plack::Session::State::Cookie->new(session_key => 'access_token', httponly => 0, domain => '.tranzmt.it');
    enable 'CrossOrigin', origins => ['http://localhost:4242','http://m.tranzmt.it','http://api.tranzmt.it'], headers => '*', credentials => 1, expose_headers => '*', methods => '*';
    enable "Deflater";
    enable "JSONP", callback_key => 'callback';
    #enable "ConditionalGET";
    #enable "ETag", file_etag => "inode";
    enable 'Rewrite', rules => sub {
         return 301
             if s{^/oauth/}{/v1/auth/};
    };
    mount '/' => builder {
        $home;
    };
    mount '/v1' => builder {
        $app;
    };
};

