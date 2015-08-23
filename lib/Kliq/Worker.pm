package Kliq::Worker;

use Moose;
with 'MooseX::LogDispatch::Levels';

has json => (
    is      => 'ro',
    isa     => 'JSON' | 'JSON::XS',
    default => sub { JSON->new->utf8->relaxed->allow_nonref->allow_unknown; },
    handles => {
        encode_json => 'encode',
        decode_json => 'decode'
    },
);

sub format_error {
    my ($self, $error) = @_;

    if(blessed $error && $error->isa('Net::Twitter::Error')) {
        $error =
            'HTTP Status: ' . $error->code .
            ' - HTTP Message: ' . $error->message .
            ' - Twitter Error: ' . $error->error;
        #$self->logger->error("Worker::TwitterNotifier: Net::Twitter::Error $error");
    }

    return $error;
}


__PACKAGE__->meta->make_immutable;

1;
__END__


--------------------------------------------------------------------------------
Workers:
--------------------------------------------------------------------------------

importContacts
    google   => 'GoogleImporter',
    yahoo    => 'YahooImporter',
    twitter  => 'TwitterImporter',
    facebook => 'FacebookImporter',
    linkedin => 'LinkedInImporter'

sliceVideo      VideoClipper
  uploadS3        S3Uploader
    zencode         Zencoder
      notifyShare     ShareNotifier
          notifyEmail     MailNotifier
          notifyTwitter   TwitterNotifier
          notifyFacebook  FacebookNotifier
          notifyLinkedIn  LinkedInNotifier

--------------------------------------------------------------------------------
Worker workflow:
--------------------------------------------------------------------------------

CASE: SSM Publish Media

CASE: User-generated upload

CASE: Share usergen video

CASE: Share clip
