package Safewrd::API::Ambassador;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Data::Dumper;

set logger     => 'log_handler';
set serializer => 'JSON';

my $DEBUG  = 1;

use MIME::Base64 qw/decode_base64/;

post '/ambassador' => sub {

    my $ambassador = eval {

        content_type 'application/json';
        my $body = request->body();
        #_debug( 'Request Body:' . to_json( $body, { pretty => 1 } ) );
        my $args = from_json($body);
        #_debug( 'Request Body (JSON):' . to_json( $args, { pretty => 1 } ) );

        my @expected = qw/firstName lastName nickname phone email photo suffix/; #fields that we expect to receive from ambassador form
        my %ambassador;
        @ambassador { @expected } = @$args{ @expected }; # cleaned up hash

        my $photo = delete $ambassador{photo}; #process photo later
        my $suffix = delete $ambassador{suffix};

        _debug(to_json({ "Database Ready" => \%ambassador } ));

        my $result;
        $result = schema->resultset('Ambassador')->create( { %ambassador } );

        ## and now let's upload the image
        if ($photo) { 
            $photo =~ s/^data:image\/(.+?);base64,//; #if we receive image this way
            $suffix = $1 if $1;
            $suffix ||= 'png'; #good default just in case
            my $uuid = $result->id;
            my $dest = "ambassadors/$uuid.$suffix";
            my $uri = '/' . $dest;

            $dest = config->{asset_basepath} . '/' . $dest;
            open (my $fh, '>', $dest) or die "Unable to write to $dest: $!";
            print $fh decode_base64($photo);
            _debug("Photo saved to $dest");

            $result->update({ photo => $uri });
        }

        return  { $result->get_columns };
    };
    my $message;
    if ($@) {
       if ($@ =~/Duplicate entry/) {
           $@ =~/entry '(.+?)' for key '(.+?)'/;
           $message = "Ambassador with $2 $1 exists";
       } else {
           $message = "System error";
       }
    }
    my $ret =  to_json (
        $@ ? 
             { Success => 0, Message => $message , Error => ref $@? Dumper($@): $@ } : 
             { Success => 1, Ambassador => $ambassador }
    );
    _debug("Sending json $ret");
    return $ret;
};

post '/ambassador/lead' => sub {

    content_type 'application/json';
    my $result = 
    eval {
        my $body = request->body();
        _debug( 'Request Body:' .  $body);
        my $args = from_json($body);

        my @expected = qw/nickname phone handle service/; 
        my %lead;
        @lead { @expected } = @$args{ @expected }; # cleaned up hash
        if ($lead{phone}) {
            $lead{handle} = delete $lead{phone}; #either handle + service or phone acceptable
            $lead{service} = 'twilio';
        }
        my $ambassador = schema->resultset('Ambassador')->find( {nickname => $lead{nickname} } );
        if (!$ambassador) {
            die { Message => "Unable to find ambassador $lead{nickname}"};
        } 
        $lead{ambassador_id} = $ambassador->id;
        delete $lead{nickname};
        _debug("Ambassador found $lead{ambassador_id} Phone: $lead{handle}");

        send_lead_sms($lead{handle}, 
            'JOIN THE MOVEMENT #STREAM4HELP , by texting Hi to create your safeword + Safety group',
        );
        my $result =  { schema->resultset('Lead')->create( { %lead } )->get_columns } ;

        $result->{sent} = 1;
        return $result;

    };

    # @todo here we'd like to also kick off the Twilio SMS

    if ($@){
        if ($@ =~ /Duplicate/){
            return to_json ( { Success => 0, Message => 'Phone number exists', Error => $@});
        } elsif (ref $@ && $@->{Message}) {
            return to_json( { Success => 0, Message => $@->{Message}, Error => $@->{Error} });
        } else {
            return to_json ( { Success => 0, Message => 'System error', Error => $@});
        }
    }
    return to_json({ Success => 1, Lead =>  $result });
};
use Safewrd::SMS;

sub send_lead_sms {
    my $theirphone = shift;
    my $text = shift;
    my $phone = $theirphone;

    $phone =~ s/\D//g;
    _debug($phone . ' length: ' . length($phone) );
    if (length($phone) == 10) {
        $phone = '+1' . $phone;
    } elsif (length($phone) == 11 && $phone =~ /^1/) {
        $phone = '+' . $phone;
    } else {
        die "Not a valid US phone number";
    }
    my $sender = new Safewrd::SMS;
    
    my $sent = $sender->send_sms(
        text    =>      $text,
        to      =>      $phone,
    );  
    if (!$sent) {
        die "Unable to send an SMS to " . $theirphone;
    }

}

sub _debug {
    if ($DEBUG) {
        my $debug = shift;
        warn $debug . "\n";
        error($debug . "\n");
    }
}

get '/patron/contacts' => sub {

    content_type 'application/json';
    my $args = params;
    _debug("Getting contacts ". Dumper($args));
    my $result = 
    eval {
        return [ 
            map { { $_->get_columns } }
            schema->resultset('Contact')->search( { owner_id => $args->{user_id} } ) 
        ] ;
    };

    return to_json (return_error() ||  { Success => 1, User => { user_id => $args->{user_id} }, Contacts => $result });

};

post '/patron/contacts' => sub {

    content_type 'application/json';
    my $result = 
    eval {
        my $body = request->body();
        my $args = from_json($body);

        my %user = map { $_ => $args->{User}->{$_} } qw/id email/;
        my $updated;
        $updated->{User} = schema->resultset('User')->find( {id => $user{id} } )->update( { %user } );

        $updated->{Contacts} = [];
        foreach my $row ( @{ $args->{Contacts} || [] } ){
            eval {
                send_lead_sms($row->{phone}, "You are about to see a video");
                my %contact = 
                map { $_ => $row->{$_}} qw/id phone/;
                push $updated->{Contacts}, schema->resultset('Contact')->find( {id => $contact{id} } )->update( {%contact});
            };
            if (my $error = return_error()) {
                push $updated, { %$error, Contact => $row } if $error;
            }
        }
        return $updated;
    };

};

sub return_error {
    if ($@){
        if (ref $@ && $@->{Message}) {
            return  { Success => 0, Message => $@->{Message}, Error => $@->{Error} };
        } else {
            return  { Success => 0, Message => 'System error', Error => [$@]};
        }
    }
    return; #no error
};