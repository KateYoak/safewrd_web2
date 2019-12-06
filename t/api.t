use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;


use_ok('Safewrd::API::ChatbotAPI', "Chatbot API compiles") 
&& use_ok('Safewrd::API::Ambassador', "Ambassador API compiles") 
|| BAIL_OUT("Unable to load module(s)");


my %cmd;
$cmd{ambassador} = <<'EOF';
'http://localhost/v1/ambassador' \
  -H 'Connection: keep-alive' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36' \
  -H 'Content-Type: application/json' \
  -H 'Accept: */*' \
  -H 'Sec-Fetch-Site: cross-site' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Referer: https://vip.safewrd.app/' \
  -H 'Accept-Encoding: gzip, deflate, br' \
  -H 'Accept-Language: en-US,en;q=0.9,pl-PL;q=0.8,pl;q=0.7,ru-RU;q=0.6,ru;q=0.5'  \
  --data-binary '{"firstName":"Kate","lastName":"Yoak","phone":"4242423784","email":"kate+test@yoak.com","photo":null}' --compressed
EOF
;

$cmd{lead} = <<'EOF'
'http://localhost/v1/ambassador/lead' \
   -H 'Connection: keep-alive'  \
   -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36' \
   -H 'Content-Type: application/json' \
   -H 'Accept: */*'  \
   -H 'Sec-Fetch-Site: cross-site' \
   -H 'Sec-Fetch-Mode: cors' \
   -H 'Referer: https://vip.safewrd.app/patron'  \
   -H 'Accept-Encoding: gzip, deflate, br'  \
   -H 'Accept-Language: en-US,en;q=0.9,pl-PL;q=0.8,pl;q=0.7,ru-RU;q=0.6,ru;q=0.5' \
   --data-binary '{"nickname":"kate","phone":"3108192233"}' --compressed
EOF
;

$cmd{contacts} = <<'EOF'
'http://localhost/v1/patron/contacts?user_id=94A4988D-93F8-1014-A991-F7EDC84F2656' \
   -H 'Connection: keep-alive'  \
   -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36' \
   -H 'Content-Type: application/json' \
   -H 'Accept: */*'  \
   -H 'Sec-Fetch-Site: cross-site' \
   -H 'Sec-Fetch-Mode: cors' \
   -H 'Referer: https://vip.safewrd.app/patron'  \
   -H 'Accept-Encoding: gzip, deflate, br'  \
   -H 'Accept-Language: en-US,en;q=0.9,pl-PL;q=0.8,pl;$=0.7,ru-RU;q=0.6,ru;q=0.5'  --compressed
EOF
;

$cmd{savecontacts} = <<'EOF'
'http://localhost/v1/patron/contacts' \
   -H 'Connection: keep-alive'  \
   -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36' \
   -H 'Content-Type: application/json' \
   -H 'Accept: */*'  \
   -H 'Sec-Fetch-Site: cross-site' \
   -H 'Sec-Fetch-Mode: cors' \
   -H 'Referer: https://vip.safewrd.app/patron'  \
   -H 'Accept-Encoding: gzip, deflate, br'  \
   -H 'Accept-Language: en-US,en;q=0.9,pl-PL;q=0.8,pl;q=0.7,ru-RU;q=0.6,ru;q=0.5' \
   --data-binary '{"User": {"id":"94A4988D-93F8-1014-A991-F7EDC84F2656", "email": "kate+patron@yoak.com"} }' --compressed
EOF
;

#cleanup first
# @todo: replace with ini file parameters and abstract
`mysql -ukliq_SSM -pself-expression kliq2 -e "DELETE FROM ambassadors WHERE email = 'kate+test\@yoak.com'"`;
`mysql -ukliq_SSM -pself-expression kliq2 -e "DELETE FROM leads WHERE service='twilio' and handle='3108192233'"`;

my $clean = `mysql -ukliq_SSM -pself-expression kliq2 -e "select * from ambassadors where email = 'kate+test\@yoak.com'"`;
if ($clean) {
  diag $clean;
  BAIL_OUT("Not clean");
} else {
  diag "CLEAN empty" , $clean;
}

if (0) {
  my $result = test_curl($cmd{ambassador});
  is($result->{Success}, 1, "New ambassador success") or diag Dumper $result;
  $result = test_curl($cmd{ambassador});
  is($result->{Success}, 0, "Duplicate failure") or diag Dumper $result;
  like($result->{Message}, qr/exists/, "Message to user");
}

if (0){
  my $result = test_curl($cmd{lead});
  is($result->{Success}, 1, "New lead success") or diag Dumper $result;
  $result = test_curl($cmd{ambassador});
  is($result->{Success}, 0, "Duplicate failure") or diag Dumper $result;
  like($result->{Message}, qr/exists/, "Message to user");
}

if (0) {
  my $result = test_curl($cmd{contacts});
  is($result->{Success}, 1, "Get contacts success") or diag Dumper $result;
  is(@{ $result->{Contacts} }, 2, "2 contacts") or diag Dumper $result;
}

{
  my $result = test_curl($cmd{savecontacts});
  is($result->{Success}, 1, "Get contacts success") or diag Dumper $result;
  $result = test_curl($cmd{contacts});
  is(@{ $result->{Contacts} }, 2, "2 contacts") or diag Dumper $result;
}





use JSON;
sub test_curl {
    my $cmd = shift;
    my $result = `curl -is $cmd`;
    my ($headers, $content) = split(/\n\s*\n/, $result);
    my @headers = split(/\n/, $headers);
    my @content = split(/\n/, $content);
    $headers[0] =~ /^HTTP\/1.1\s+(\d+)/;
    is($1, 200, "Checking server status: " . $headers[0]);
    ok(@content, "Got content") or 
      diag Dumper ($headers, $content);
    ;
    my $data;
    if ( 
      ! ok($data = eval { decode_json($content) }, "Valid JSON") 
    ){
      diag "ERROR: $@";
      diag "JSON\n". $content;
    }
    return $data;
}

done_testing();
