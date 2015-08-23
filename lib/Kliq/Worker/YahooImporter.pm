package Kliq::Worker::YahooImporter;

use namespace::autoclean;
use Moose;
use Data::Dumper;
use Try::Tiny;
use Net::OAuth::Yahoo;
use JSON;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    /;

# token secret service session user handle
sub work {
    my ($self, $data) = @_;

    my $config = $self->config or die("Missing config");

    my $token  = $data->{token}  or die("Missing token");
    my $secret = $data->{secret} or die("Missing secret");
    my $userid = $data->{user}   or die("Missing user");

    try {
        my $user = $self->schema->resultset('User')->find($userid)
            or die("Invalid user $userid");

        my $oauth = Net::OAuth::Yahoo->new({
            consumer_key => $config->{client_id},
            consumer_secret => $config->{client_secret},
            signature_method => "HMAC-SHA1",
            nonce => $config->{nonce},
            callback => 'http://api.kliqmobile.com/oauth/yahoo/callback',
        });

        my $token = $data->{info};
        my $guid  = $token->{xoauth_yahoo_guid};
        my $purl  = "http://social.yahooapis.com/v1/user/$guid/contacts?format=json&count=max";
        my $json  = $oauth->access_api($token, $purl) or die($Net::OAuth::Yahoo::ERRMSG);

        my $data_obj = from_json($json);

        if(!ref($data_obj) || ref($data_obj ne 'HASH')) {
            die("Yahoo library error - $data_obj");
        }

        my $contacts = $data_obj->{contacts}->{contact} or die("Invalid data object");
        my $count = $data_obj->{contacts}->{count} || 0;

        foreach my $c(@$contacts) {
            try {
                $self->import_contact($user, $c, $guid);
            } catch {
                my $error = $_;
                if($error =~ /Duplicate entry/) {
                    #$self->logger->warning("duplicate contact ");
                }
                else {
                    $self->logger->error("contact not imported: $_");
                }
            };
        }

        $self->logger->info("$count contacts imported, uid: $userid");

    } catch {
        my $err = $_;
        $self->logger->error("$err (uid $userid)");
    };
}

sub import_contact {
    my ($self, $user, $contact, $guid) = @_;

    my $id = $guid . '-' . $contact->{id};
    my ($name, $email) = ();
    
    foreach my $field(@{$contact->{fields}}) {
        if($field->{type} eq 'name') {
            my $nh = $field->{value};
            $name = join(' ', grep { $_ } map { $nh->{$_} } 
                qw/prefix givenName middleName familyName suffix/);
        }
        elsif($field->{type} eq 'email') {
            $email = $field->{value};
        }
    }
    return unless($email);
    
    $user->add_to_contacts({
        handle  => $id,
        service => 'yahoo',
        name    => $name,
        email   => $email,
        screen_name => $email,
    }) or die ("Could not add contact");
}

1;
__END__

