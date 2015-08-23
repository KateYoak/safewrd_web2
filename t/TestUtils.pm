package
  t::TestUtils;

use strict;
use warnings;
use File::Spec ();
use File::Copy ();
use Cwd ();
use Test::Requires 'DBD::SQLite';

use parent qw/Exporter/;
our @EXPORT = qw/ $dsn schema /;

my ($_schema, $_attr);
our ($dsn, $user, $password, $DEBUG) =
    @ENV{map { "KLIQTEST_${_}" } qw/DSN USER PASS KEEP/};

if($dsn && !$DEBUG) {
    $_attr = { RaiseError => 1, AutoCommit => 1 };
    }
else {
    $dsn = $DEBUG ?
        'dbi:SQLite:dbname=t/var/kliq.db' : 'dbi:SQLite::memory:';
    $user = '';
    $password = '';
    $_attr = { sqlite_unicode => 1 };
    }

sub _local_db {
    my $db_file = './t/var/kliq.db';
    if(-f $db_file) {
        unlink $db_file or warn "Could not unlink $db_file: $!";
        }
    my (undef, $path) = File::Spec->splitpath(__FILE__);
    $path = Cwd::abs_path($path);
    my $scaffold_db = File::Spec->catfile($path, 'var', 'kliq.test.db');
    die("Scaffold database not found") unless -f $scaffold_db;
    File::Copy::copy($scaffold_db, $db_file) or die "Copy failed: $!";
    }

sub schema {
    unless($_schema) {
        _local_db() if $DEBUG;
        eval "require Kliq::Schema" or die "failed to require schema: $@";
        $_schema = Kliq::Schema->connect($dsn, $user, $password, $_attr)
            or die "failed to connect to $dsn";
        $_schema->deploy({ add_drop_table => $_attr->{sqlite_unicode} ? 0 : 1 })
            unless $DEBUG;
        $_schema->seed();
        }

    return $_schema;
    }

1;
__END__

=pod

=head1 NAME

t::TestUtils - Test utitily functions for Kliq::Schema

=head1 SYNOPSIS

    use t::TestUtils;

    is($dsn, 'dbi:SQLite::memory:');

    isa_ok(schema(), 'Kliq::Schema');
    schema()->resultset('Blah')->create({ blah => '123' });

=head1 DESCRIPTION

Test utility functions for L<Kliq::Schema|Kliq::Schema> tests. See the F<*.t>
files for usage examples.

=head1 EXPORTED VARIABLE AND FUNCTIONS

=head2 $dsn

The dsn of the test database used.

=head2 schema

Creates a temporary SQLite database, deploys the
L<Kliq::Schema|Kliq::Schema> schema, and then connects to it.
Subsequent calls to C<schema()> will return the schema created on the first
call. Since you have a fresh database for every test, you don't have to worry
about cleaning up after your tests, ordering of tests affecting failure, etc.

Returns the L<Kliq::Schema|Kliq::Schema> instance connected and deployed to the 
test database. When your program exits, the temporary in-memory database will go 
away, unless KLIQTEST_KEEP is set.

=head1 ENVIRONMENT

You can control the behavior of this module at runtime by setting
environment variables.

  KLIQTEST_DSN=DBI:mysql:kliq2
  KLIQTEST_USER=root

=head2 KLIQTEST_KEEP

If this variable is true, then the test database will not be deleted at C<END>
time.  Instead, the database will be available as F<./t/var/kliq.db>.

This is useful if you want to look at the database your test generated, for
debugging. Note that the database will never exist on disk if you don't set this
to a true value.

=head2 KLIQTEST_DSN

If this variable is specified, this dsn will be connected to instead of the
in-memory or temporary SQLite database. This will only be used if KLIQTEST_KEEP
is false, and at least the KLIQTEST_USER is specified as well.

WARNING: This will drop all tables used on test deployment, and all data will be
lost. You do NOT ever want to set this to the production database's dsn.

=head2 KLIQTEST_USER

Username for the database connection specified by KLIQTEST_DSN

=head2 KLIQTEST_PASS

Password for the database connection specified by KLIQTEST_DSN

=head1 AUTHOR

Peter de Vos C<< <techie@sitetechie.com> >>

=cut