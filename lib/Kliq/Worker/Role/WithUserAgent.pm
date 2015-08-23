package Kliq::Worker::Role::WithUserAgent;

use namespace::autoclean;
use Moose::Role;
use LWP::UserAgent;

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    handles => [qw/timeout/],
    default => sub {
        my $ua = LWP::UserAgent->new(timeout => 20, agent => 'Kliq-Client');
        $ua->env_proxy;
        return $ua;
    },
);

no Moose::Role;

1;
__END__

SA
LWP::UserAgent::Determined
LWP::UserAgent::ExponentialBackoff
 MooseX::Types::LWP::UserAgent

HTTP::Tiny
 Role::REST::Client
 Opsview::REST::APICaller
 HTML::HTML5::Parser::UA