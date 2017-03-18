#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use REST::Client;
use JSON;
use URI;
 
# $0 <service> <handle>
my ( $service, $handle ) = @ARGV;
# my $handle  = '1227913313929598';
# my $service = 'facebook';

my $user_details = _resolve_user_details({
    handle  => $handle,
    service => $service,
});

sub _resolve_user_details {
    my $params = shift;

    my $client = REST::Client->new();
    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');

    ($params->{'service'})
        or die "missing parameter: service";
    ($params->{'handle'})
        or die "missing parameter: handle";
        
    my $user_details;
    if ( $params->{'service'} eq 'facebook' ) {
        my $user_details = _get_facebook_user_details( $client, $params );
    }
    else {
        die "Unsupported service " . $params->{'service'};
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
    print STDERR $endpoint_url->as_string . "\n";

    $client->GET($endpoint_url->canonical);
    if ($client->responseCode() =~ /^5\d{2}$/) {
        die "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]";
    }

    my $response = from_json($client->responseContent());
    if (exists $response->{'error'}) {
        my $details = $response->{'error'};
        die "Error Encountered, Code: [" . $details->{'code'} .  "], Message: [" . $details->{'message'} . "], FB Trace ID: [" . $details->{'fbtrace_id'} . "], Type: [" . $details->{'type'} . "]";
    }

    print to_json( $response, { pretty => 1 } );
    return $response;
}
