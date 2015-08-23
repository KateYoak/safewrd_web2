use strict;
use warnings;
use Test::More;

use Kliq;
use Dancer::Test;
use JSON qw/from_json to_json/;

response_status_is [GET => '/v1'], 200, "GET / is found";
response_content_like [GET => '/v1'], qr/uploads/, "content looks good for /";


#-- ILLEGAL -> 405
#response_status_is [ILLEGAL => '/'], 405, "Method not implemented";

require HTTP::Headers;
my $h = HTTP::Headers->new(
 'X-Requested-With' => 'XMLHttpRequest'
);

my %data = (
    kliqs => { name => "Cool Kliq" }, # '{ "name": "Cool Kliqqer" }'
    shares => { mediaid => 1, batchid => 1, entryid => 1, contactid => 1, uploadid => 1, message => 0, recipient => 0, kliqs => 0, link => 0, hash => 0 },
    networks => { token => "B", secret => "A" },
    users => { uname => rand(100), pass => "A", email => 'C' },
    media => { title => 'CoolVid'},
    contacts => { entry_id => 1, hash => 1, name => 0 },
);
my %extra = ();

#------------------------------------------------------------------------
# collection methods
#------------------------------------------------------------------------

foreach my $base (qw/media users kliqs contacts uploads assets shares comments/) { # imports
    
    %extra = (
        headers => [$h]
    );
    if($base eq 'media') {
        $extra{files} = [{ filename => './t/avatar.png', name => 'filename' }];
        $extra{params} = $data{$base};
    }
    else {
        $extra{body} = to_json($data{$base});
    }

    #-- GET -> 200

    response_status_is [GET => "/v1/$base"], 200, "GET /$base is found";
    response_content_like [GET => "/v1/$base"], qr/created|lastModified/, "content looks good for /";

    #-- POST -> 201/202

    my $response = dancer_response POST => "/v1/$base", { %extra };
    is $response->{status}, 201, "response for POST $base is 201";
    like($response->{content}, qr/created|lastModified/, "response content looks good for first POST /$base");

    my $id = from_json($response->{content})->{id} or die("Nothing created");

    #warn "NEWID $id";

    #------------------------------------------------------------------------
    # entity methods
    #------------------------------------------------------------------------

    #-- GET -> 200

    response_status_is [GET => "/v1/$base/$id"], 200, "GET /$base/$id is found";
    response_content_like [GET => "/v1/$base/$id"], qr/created|lastModifiedDate/, "GET /$base/$id content looks good";

    #-- PUT -> 201/202

    $response = dancer_response PUT => "/v1/$base/$id", { %extra };
    is $response->{status}, 202, "response for PUT /$base/$id is 202";
    like($response->{content}, qr/created|lastModified/, "response content looks good for first PUT /$base/$id");

    #-- GET -> 200
    #response_content_like [GET => "/v1/$base/$id"], qr/created/, "content looks good";

    #-- DELETE -> 204

    response_status_is [DELETE => "/v1/$base/$id"], 204, "DELETE /$base/$id is found";
    response_status_is [GET => "/v1/$base/$id"], 404, "GET /$base/$id is not found";

}


done_testing();

exit;
