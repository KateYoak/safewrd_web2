#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Pod::Usage;
use Getopt::Long;

use Kliq::Schema;
use Dancer qw/:script !pass/;

my ( $help, $deploy, $ddl, $drop_tables, $file ) = ( 0, 0, 0, 0, 0 );

GetOptions(
    'help|?'   => \$help,
    'deploy|d' => \$deploy,
    'ddl'      => \$ddl,
    'drop'     => \$drop_tables,
    'file=s'   => \$file,
);

pod2usage(1) if $help;

my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

if ($ddl) {
    $schema->create_ddl_dir(
        [ 'SQLite', 'MySQL' ],
        $Kliqs::Schema::VERSION,
        "$FindBin::Bin/../var"
        );
    print "DDL files created in ./var \n";
    }
elsif ($deploy) {
    $schema->deploy({ add_drop_table => $drop_tables });
    $schema->seed();
    print "Schema deployed and seeded\n";
    }
else {
    pod2usage(1);
    }
        
$schema->storage->disconnect if $connect_info->{dsn} =~ /mysql/;

1;

=pod

=head1 NAME

kliq_spawndb.pl - Spawn a KLIQ MySQL database

=head1 SYNOPSIS

kliq_spawndb.pl [options]

 Options:
   -? -help           display this help and exits
   -ddl               create DDL files
   -deploy            deploy tables into existing database
   -drop              drop existing database/tables when deploying
   -file              specific configuration file to load connection
                      info from. defaults to CMT_WEB_CONFIG or CATALYST_CONFIG env var.

 For example, to replace a mysql database:

   perl bin/kliq_spawndb.pl -drop -deploy -file etc/kliq_mysql.conf

 See also:

   perldoc Kliq::Schema

=head1 DESCRIPTION

Spawn a database for Kliq.

If no -file is provided, the file specified as the KLIQ_CONFIG
environment variable or the default 'config.yaml' is used.

=head1 AUTHOR

Peter de Vos, C<techie@sitetechie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, KLIQ Mobile LLC

=cut    
