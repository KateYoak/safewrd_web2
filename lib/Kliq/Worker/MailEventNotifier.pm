package Kliq::Worker::MailEventNotifier;

use namespace::autoclean;
use Moose;
use Try::Tiny;
use Mail::Builder::Simple;

extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::WithSchema
    /;

sub work {
    my ($self, $data) = @_;
    my $config = $self->config;

    try { 
        my $store_url = q{https://play.google.com/store/apps/details}
            . q{?id=com.tranzmt.app&referrer=}
            . q{contactId%3D}.$data->{contact_id}.q{%26eventId%3D}.$data->{event_id};

        my $stream_url = q{rtmp://api.kliqmobile.com:1935/live/} . $data->{event_id};

        my $plaintext_body =
            $data->{sender} . qq{ wants to stream a live event to you.\n\n}
            . q{Event Title: } . $data->{title} . qq{\n}
            . q{Event Date: } . $data->{when_occurs} . qq{\n}
            . q{Event Location: } . $data->{location} . qq{\n\n}
            . q{Live Stream at } . $stream_url . qq{\n\n}
            . q{Get the Kliq App at }.$store_url.qq{\n\n}
            ;

        my $htmltext_body =
            qq{<html><body>\n}
            . qq{<pre>\n}
            . q{Event Title: } . $data->{title} . qq{\n}
            . q{Event Date: } . $data->{when_occurs} . qq{\n}
            . q{Event Location: } . $data->{location} . qq{\n\n}
            . q{Live Stream at <a href="}.$stream_url.q{">}.$stream_url.qq{</a>\n\n}
            . q{Get the Kliq App at <a href="}.$store_url.q{">}.$store_url.qq{</a>\n\n}
            . qq{</pre>\n}
            . qq{</body></html>\n}
            ;

        my $mail = Mail::Builder::Simple->new;

        $mail->send(
            mail_client => {
                mailer => 'SMTP',
                mailer_args => {
                    ssl           => defined($config->{ssl}) ? $config->{ssl} : 0,
                    host          => $config->{host} || 'smtp.sendgrid.net',
                    port          => $config->{port} || 465,
                    sasl_username => $config->{user}, 
                    sasl_password => $config->{pass},
                    timeout       => 20   
               },
               #live_on_error => 1,
            },
            from => ['kliq@kliqmobile.com', 'KLIQ Mobile'], 
            to => $data->{email},
            # reply => 'info@kliqmobile.com',
            subject => $data->{sender} . ' shared a live event stream with you',
            plaintext => $plaintext_body,
            htmltext => $htmltext_body,
            priority => 1,
            mailer => 'KLIQ Mailer 0.01',
        );
    
    } catch {
        my $error = $_;
        $self->logger->error($error);
    };
    $self->logger->info("message sent");

}

__PACKAGE__->meta->make_immutable;

1;
__DATA__
