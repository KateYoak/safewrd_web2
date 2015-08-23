package Kliq::Worker::Role::WithMessage;

use namespace::autoclean;
use Moose::Role;
with 'Kliq::Worker::Role::WithTemplate';

sub message {
    my ($self, $sender, $msg, $upload, $media, $contact, $link) = @_;
    my $type = 'body.html';
    my $content = $self->template($type, { 
        sender => $sender, msg => $msg, upload_id => $upload, 
        media_id => $media, contact_id => $contact, shortlink => $link
        }
    );
    return $content;
}

no Moose::Role;

1;
__END__