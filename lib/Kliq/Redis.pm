package Kliq::Redis;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Const::Fast;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::MySQL;
use JSON ();
use Redis;

our $VERSION = '0.001';

has 'connection' => (
    is       => 'ro',
    required => 0,
    isa      => 'Redis',
    default => sub { Redis->new() }
);

sub add_visit {
    my ($self, $short, $entry) = @_;

    die('No short or entry') unless($short && $entry);

    my $redis = $self->connection();

    my $date = $entry->{datetime} ?
        ($entry->{datetime} =~ /T/ ?
            DateTime::Format::ISO8601->parse_datetime( $entry->{datetime}  ) :
            DateTime::Format::MySQL->parse_datetime( $entry->{datetime}  ))
      : DateTime->now();


    #- convert entry to json

    my $log_str;
    eval {
        $entry->{ccode} = $short;
        $entry->{datetime} ||= $date->datetime();
        $log_str = JSON->new->utf8->encode($entry);
    };
    if($@) {
        $log_str = JSON->new->utf8->encode({
            id => 0, code => $short, error => $@
        });
    }

    #- publish json to queue

    $redis->publish('trzmt.it:visits', $log_str);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
