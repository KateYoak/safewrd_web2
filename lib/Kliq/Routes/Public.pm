package Kliq::Routes::Public;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use HTML::Entities;
use Data::Dumper;
use Try::Tiny;

#---- EBANX ------------------------------------------------------------------

post '/webhook/ebanx' => sub {
    my $req = request->params;

    if ($req->{hash_codes}) {
        my @hashCodes = split(",",$req->{hash_codes});
        foreach my $hash (@hashCodes) {
            my $payment = schema->resultset('Payment')->find({ transaction_id => $hash });
            if ($payment) {
                my $client = REST::Client->new();
                $client->addHeader('charset', 'UTF-8');
                $client->addHeader('Accept', 'application/json');

                $client->GET('https://' . config->{sites}->{ebanx}->{host} . '.ebanx.com/ws/query?integration_key=' . config->{sites}->{ebanx}->{key} . "&hash=$hash");
                if ($client->responseCode() =~ /^5\d{2}$/) {
                    return status_bad_request("EBANX query returned 500 error");
                }
                if ($client->responseCode() == 403) {
                    return status_bad_request("EBANX query returned 403 error");
                }

                my $response = from_json($client->responseContent());
                if ($response->{status} eq "ERROR" || $response->{status} eq "SUCCESS") {
                    $payment->update({
                        status => $response->{payment}->{status} || $response->{status}
                    });
                    if ($response->{payment}->{status} eq "CO") {
                        my $user = schema->resultset('User')->find({ id => $payment->user_id });
                        $user->update({
                            paid => 1,
                            paid_before => \'NOW()'
                        });
                    }
                }
            } else {
                return status_bad_request("EBANX sent unknown hash: $hash");
            }
        }
    } else {
        return status_bad_request("EBANX sent no hashes");
    }
    return status_ok({ message => "OK" });
};

1;
__END__
