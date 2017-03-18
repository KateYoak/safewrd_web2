#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use REST::Client;
use JSON;
use URI;
 
my $params = {@ARGV};
my $client = REST::Client->new();

$client->addHeader('Content-Type', 'application/json');
$client->addHeader('charset', 'UTF-8');
$client->addHeader('Accept', 'application/json');

my $branchio_url    = 'https://api.branch.io/v1/url';
my $branchio_key    = q/key_test_kpvwfofzFhfw4LH9YBQRLkbhvFn4THkU/;
my $branchio_secret = q/secret_test_y95BwPdEzQFWZpHWeK9TD828mE8VdtYh/;
my $google_play_url = URI->new('https://play.google.com/store/apps/details');
my $app_id          = 'fr.simon.marquis.installreferrer';

my $referrer_params;
if (scalar keys(%{$params}) > 0) {
    # my $referrer_params = 'user_id=12345,kliq_id=54321';
    # join values by delimiter ','
    $referrer_params = join( ',', map { join('=',$_,$params->{$_}) } keys %{$params} );
}
else {
    die "Missing referrer parameters";
}

my $url_params = {
    id       => $app_id,
    referrer => $referrer_params,
};
$google_play_url->query_form($url_params);

print STDERR $google_play_url->as_string . "\n";
my $payload = {
    '$android_url' => $google_play_url->as_string,
};

my $request_params = {
    branch_key => $branchio_key,
    data       => $payload,
};

my $req = to_json($request_params);
my $endpoint_url=URI->new($branchio_url);

$client->POST($endpoint_url->canonical, $req);
if ($client->responseCode() =~ /^5\d{2}$/) {
    die "Server / Endpoint URL: " . $endpoint_url->canonical . ", Error: " . $client->responseCode();
}

my $response = from_json($client->responseContent());
if (exists $response->{'error'}) {
    my $details = $response->{'error'};
    die "Error Encountered, Code: " . $details->{'code'} .  ", Message: " . $details->{'message'};
}

print Dumper( from_json($client->responseContent()) ); 

