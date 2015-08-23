
package Kliq::Worker::Role::WithLogger;

use Moose::Role;

with 'MooseX::LogDispatch';

has log_dispatch_conf => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    required => 1,
    default => sub {
        my $self = shift;
        return {
            class     => 'Log::Dispatch::File',
            min_level => 'debug',
            filename  => './logs/worker.log',
            mode      => 'append',
            format    => '%d [%p] %P - %m',  # %d{%Y%m%d} at %F line %L%n
            newline   => 1
        };
    },
);

no Moose::Role;

1;
__END__