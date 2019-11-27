use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

use Data::Dumper;

my $api_endpoint = 'https://safewrd.recurly.com/v2';
my $api_key      = 'ed783b56892d4bd2896e821041fec80e';
my $api_version  = '2.17';

my $account_code = 'C664D06E-159A-11E9-ADD6-7B31CEE8E88F';

my $payment = add_new_payment();
print Dumper($payment);

sub add_new_payment {
    my $content_hash = {
        purchase => {
            collection_method => 'automatic',
            currency => 'USD',
            account => {
                account_code => $account_code,
            },
            adjustments => [{
                    revenue_schedule_type => 'at_invoice',
                    unit_amount_in_cents => 2500,
                    description => 'Credit for Aireos drone',
                }],
        },
    };
    my $request_xml = XMLout($content_hash, NoAttr => 1, RootName => undef, GroupTags => { adjustments => 'adjustment' });
    return make_request('POST', "/purchases", $request_xml);
}

sub make_request {
    my ($type, $path, $content) = @_;

    my $url = $api_endpoint . $path;
    my $req = HTTP::Request->new($type => $url);
    $req->authorization_basic($api_key);
    $req->header('Accept' => 'application/xml');
    $req->header('X-Api-Version' => $api_version);
    $req->content($content);
    my $ua = _build_ua();
    my $resp = $ua->request($req);
    my $code = $resp->code;
    if ($code == 200 || $code == 201) {
        return XMLin($resp->content);
    }
    die "Recurly call to $url failed ($code - " . $resp->content . ")\n";
}

sub _build_ua {
    my $ua = LWP::UserAgent->new();
    $ua->protocols_allowed(['https']);
    return $ua;
}


