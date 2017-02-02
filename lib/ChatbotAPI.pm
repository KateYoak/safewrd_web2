package ChatbotAPI;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Data::Dumper;

set serializer => 'JSON';

my $DEBUG = 1;
# test
get '/webhook' => sub {
    return "Hello World";
};

post '/webhook/echo' => sub {
    my $body = request->body();
    _debug( 'Request Body:' . Dumper($body) );
    my $req_json = from_json($body);
    _debug( 'Request Body (JSON):' . Dumper($req_json) );
    return $body;
};

sub _debug {
    if ($DEBUG) {
        my $debug = shift;
        print STDERR $debug;
    }
}

1;
__END__

