package Tokbox;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Dancer::Plugin::UUID;
use REST::Client;
use JSON::WebToken;
use MIME::Base64;
use URI;
use Digest::HMAC_SHA1 'hmac_sha1_hex';
use Kliq 'schema';

set serializer => 'JSON';

post '/start_videochat' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my ($sessionID, $error) = _create_session();
    unless ($sessionID) {
        var error => $error;
        request->path_info('/error');
    }

    my $tokenPub = _generate_token("publisher",$sessionID);

    my $users = schema->resultset('KliqContact')->search(
    {
        kliq_id => $req->{kliq_group_id}
    });
    while (my $row = $users->next) {
        my $tokenSub = _generate_token("subscriber",$sessionID);
        redis->rpush(notifyPhone => to_json({
            type => 'push',
            payload => {
                swrve_user_id         => $row->get_column('account_id'),
                notification_title    => "Citizen Witness Emergency - incoming live video chat",
                message               => "Citizen Witness Emergency - incoming live video chat",
                type                  => "text_message",
                action                => "emergency_CW",
                badge                 => 1,
                sound                 => "flare.wav",
                location              => $req->{location},
                session_id            => $sessionID,
                token                 => $tokenSub,
                app_key               => config->{sites}->{tokbox}->{key}
            },
        }));
    }

    my $data = {
        sessionID              => $sessionID,
        token                  => $tokenPub,
        app_key                => config->{sites}->{tokbox}->{key}
    };

    return to_json($data);
};

sub _create_session {
    my $client = REST::Client->new();

    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');
    $client->addHeader('X-OPENTOK-AUTH', _jwt());

    my $data = {
        'archiveMode'    => "always",
        'location'       => undef,
        'p2p.preference' => "disabled",
    };

    $client->POST('https://api.opentok.com/session/create', to_json($data));
    if ($client->responseCode() =~ /^5\d{2}$/) {
        return (undef, "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]")
    }

    if ($client->responseCode() == 403) {
        return (undef, "Server / Endpoint URL Failure, Error: [Auth failed]")
    }

    my $response = from_json($client->responseContent());
    if ($response->[0]->{session_id}) {
        return ($response->[0]->{session_id}, undef);
    }

    return (undef, "Server / Endpoint URL Failure, Error: [No session ID returned]")
}

sub _generate_token {
    my $role = shift;
    my $sessionID = shift;
    my $data = {
        sessionID              => $sessionID,
        createTime             => time,
        expireTime             => time + 24*60*60,
        role                   => $role,
        nonce                  => uuid,
    };

    my $uri = URI->new();
    $uri->query_form($data);
    my $payload = substr($uri,1);
    my $sig = hmac_sha1_hex($payload, config->{sites}->{tokbox}->{secret});

    my $response = {
        token => "T1==" . encode_base64("partner_id=" . config->{sites}->{tokbox}->{key} . "&sig=$sig:$payload")
    };
    return $response;
};

sub _jwt {
    return JSON::WebToken->encode({
        iss => config->{sites}->{tokbox}->{key},
        iat => time,
        exp => time + 180,
        ist => "project",
        jti => uuid
    }, config->{sites}->{tokbox}->{secret}, 'HS256');
}

1;
__END__

