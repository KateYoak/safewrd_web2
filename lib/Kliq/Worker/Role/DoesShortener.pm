package Kliq::Worker::Role::DoesShortener;

use namespace::autoclean;
use Moose::Role;
use Furl;
use JSON;

sub shorten {
    my ($self, $cid, $share_id) = @_;
    die("Need contact id") unless $cid;
    die("Need share id") unless $share_id;
    my $furl = Furl->new(
        agent   => 'KLIQ-UA/0.1',
        timeout => 10,
    );
    my $base = 'https://play.google.com/store/apps/details?id=com.tranzmt.app&referrer=contactId%3D';
    my $url = $base . $cid;
    my $res = $furl->post('http://cl.gs/',
        ['X-Requested-With' => 'XMLHttpRequest'],
        { url => $url }, 
    );
    #die $res->status_line 
    return $url unless $res->is_success;
    
    my $data = from_json($res->content);
    $self->schema->resultset('ShareContact')
        ->search({ share_id => $share_id, contact_id => $cid })
        ->update({ hash => $data->{code} });
    
    return $data->{short_url} || $url;
}

no Moose::Role;

1;
__END__

#[% hlink = BLOCK %]https://play.google.com/store/apps/details
?id=com.kliq.test&referrer=contactId%3D[% contact_id %][% END %]
#https://play.google.com/store/apps/details?id=com.kliq.test&referrer=contactId%3D[% contact_id %]

{"url":"http://sitecorporation.com","stats_url":"http://cl.gs/tafy+",
 "short_url":"http://cl.gs/tafy","code":"tafy"}

