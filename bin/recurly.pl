use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

use Data::Dumper;

my $api_endpoint = 'https://safewrd.recurly.com/v2';
my $api_key      = 'ed783b56892d4bd2896e821041fec80e';
my $api_version  = '2.17';
my $plan_code = 'annual_subscription_with_free_trial';

my $content_hash = {
    subscription => {
        plan_code => $plan_code,
        currency => 'USD',
        account => {
            account_code => rand(10000),
            email => 'sachinjsk@gmail.com',
            first_name => 'Sachin',
            last_name  => 'Sebastian',
            billing_info => {
                number => '4111-1111-1111-1111',
                month => '12',
                year => '2021',
                address1 => '123 Main',
                city => 'Chicago',
                state => 'IL',
                zip => '94105',
                country => 'US',
            },
        },
        auto_renew => 'true',
    },
};

my $request_xml = XMLout($content_hash, NoAttr => 1, RootName => undef);
#print $request_xml;
 
my $subscription = add_new_subscription($request_xml);
print Dumper($subscription);

sub add_new_subscription {
    my $request_xml = shift;           
    return make_request('POST', "/subscriptions", $request_xml);
}

exit;
my $create_account = create_account();
print "Create account resp: " . Dumper($create_account);

my $add_billing_info = add_billing_info();
print "Return from add_billing_info: " . Dumper($add_billing_info);

sub add_billing_info {
my $request_xml = q~
<billing_info>
  <first_name>Verena</first_name>
  <last_name>Example</last_name>
  <address1>123 Main St.</address1>
  <address2 nil="nil"></address2>
  <city>San Francisco</city>
  <state>CA</state>
  <zip>94105</zip>
  <country>US</country>
  <number>4111-1111-1111-1111</number>
  <verification_value>123</verification_value>
  <month>11</month>
  <year>2019</year>
  <ip_address>127.0.0.1</ip_address>
</billing_info>
~;
return make_request('POST', '/accounts/109/billing_info', $request_xml);
}

sub create_account {
    my $request_xml = q~
<account>
  <account_code>109</account_code>
  <email>verenasss@example.com</email>
  <first_name>Verena</first_name>
  <last_name>Example</last_name>
  <preferred_locale>en-US</preferred_locale>
</account>
~;
    return make_request('POST', '/accounts', $request_xml);
}

sub get_accounts {
    return make_request('GET', "/accounts");
}

sub get_account {
    my $acct_code = shift;
    return make_request("/accounts/$acct_code");
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


