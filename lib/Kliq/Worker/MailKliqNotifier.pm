package Kliq::Worker::MailKliqNotifier;

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
            . q{contactId%3D}.$data->{contact_id}
            . q{%26contactName%3D}.$data->{contact_name};

        my $common_body_top = $data->{sender} . q{ added you to his “Emergency Flare Group", so when ever he is in trouble and says his ‘Safe Word’, you will receive an emergency live video stream along with their GPS location. };

        my $plaintext_body =
            q{}
            . $common_body_top
            . q{Please accept this invitation at }.$store_url.qq{\n\n}
            ;

        my $htmltext_body =
            qq{<html><body>\n}
            . qq{<pre>\n}
            . $common_body_top
            . q{Please click <a href="}.$store_url.q{">Accept Invitation</a> }
            . qq{if you want to be in their Emergency group.</a>\n\n}
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
            from => ['live@tranzmt.it', 'TRANZMT.IT'],
            to => $data->{email},
            # reply => 'info@tranzmt.it',
            subject => $data->{sender} . ' invites you to try Tranzmt Flare',
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
