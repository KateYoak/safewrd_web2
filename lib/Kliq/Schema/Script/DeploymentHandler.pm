package Kliq::Schema::Script::DeploymentHandler;

use Moo;
use MooX::Options protect_argv => 0;
use Module::Runtime qw/ use_module /;
use DBIx::Class::DeploymentHandler;
use namespace::clean -except => [
  qw/ _options_data _options_config /
];

=head1 NAME

Kliq::Schema::Script::DeploymentHandler - Deploy script using DBIx::Class::DeploymentHandler

=head1 SYNOPSIS

  use Kliq::Schema::Script::DeploymentHandler;

  Kliq::Schema::Script::DeploymentHandler->new_with_options( schema_class => 'My::Schema' );

=head1 DESCRIPTION

This module is for deploying and maintaining the ddl files, created by
DBIx::Class::DeploymentHandler.

=head1 OPTIONS

These are the options available on the command line

=head2 --connection ( -c )

This option is the connection you wish to deploy against, for example:

  "DBI:mysql:database=<db name>;hostname=<host>"

This option is then provided to the Schema's 'connect' function.

=cut

option connection => (
  is       => 'ro',
  format   => 's',
  required => 1,
  short    => 'c',
  doc      => "The DBI connection string to use",
);

=head2 --force ( -f )

This option will force the action if required - for example when overwriting
the same version of ddl items.

=cut

option force => (
  is      => 'ro',
  default => sub { 0 },
  short   => 'f',
  doc     => "Force the action if required",
);

=head1 ATTRIBUTES

These are options which can be passed to the constructor of the script

=head2 schema_class

This is the class of the schema you would like to connect to. This is required
to be defined in the 'new_with_options' call.

=cut

has schema_class => (
  is => 'ro',
  required => 1,
);

=head2 schema

This is the connected schema. This uses the 'schema_class' attribute and
'connection' option to provide a DBIx::Class schema connection.

=cut

has schema => (
  is      => 'lazy',
  builder => sub {
    my $self = shift;
    my $connection = $self->connection;
    $connection =~ s/username=(.*?);//; my $user = $1;
    $connection =~ s/password=(.*?);//; my $pass = $1;
    return use_module( $self->schema_class )->connect(
      $connection,
      $user,
      $pass,
    );
  },
);

=head2 script_directory

This is the directory where the DeploymentHandler scripts will be put for all
versions. Defaults to 'share/ddl'.

=cut

has script_directory => (
  is      => 'ro',
  default => 'share/ddl',
);

=head2 databases

This is an arrayref of the database types to prepare ddl scripts for. This
defaults to returning the following:

  [
    'mysql',
  ]

=cut

has databases => (
  is      => 'ro',
  default => sub { [ 'PostgreSQL', 'MySQL' ] },
);

=head2 _dh

This returns the actual DeploymentHandler, set up using the 'schema',
'script_directory', and 'database' attributes, and the 'force' option.

=cut

has _dh => (
  is => 'lazy',
  builder => sub {
    my ( $self ) = @_;
    return DBIx::Class::DeploymentHandler->new({
      schema => $self->schema,
      force_overwrite => $self->force,
      script_directory => $self->script_directory,
      databases => $self->databases,
    });
  }
);

=head1 COMMANDS

These are the available commands

=head2 write_ddl

This will create the ddl files required to perform an upgrade.

=cut

sub cmd_write_ddl {
  my ( $self ) = @_;

  $self->_dh->prepare_install;
  my $v = $self->_dh->schema_version;

  if ( $v > 1 ) {
    $self->_dh->prepare_upgrade({
      from_version => $v - 1,
      to_version   => $v,
    });
  }
}

=head2 install_dh

This will install the tables required to use deployment handler on your
database. Only for use on a pre-existing database.

=cut

sub cmd_install_dh {
  my ( $self ) = @_;

  $self->_dh->install_version_storage;
  $self->_dh->add_database_version({
    version => $self->_dh->schema->schema_version,
  });
}

=head2 install

This command will install all the tables to the provided database

=cut

sub cmd_install {
  my ( $self ) = @_;

  $self->_dh->install;
}

=head2 upgrade

This command will upgrade all tables to the latest versions

=cut

sub cmd_upgrade {
  my ( $self ) = @_;

  $self->_dh->upgrade;
}

=head2 user_rights

This command will grant the correct user rights for tranzmt_api_user on all the
various tables etc.

=cut

sub cmd_user_rights {
  my ( $self ) = @_;

  $self->schema->storage->dbh_do( sub {
    my ($storage, $dbh, @cols) = @_;
    $dbh->do( "GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA PUBLIC TO tranzmt_api_user" );
    $dbh->do( "GRANT SELECT,UPDATE,USAGE ON ALL SEQUENCES IN SCHEMA PUBLIC TO tranzmt_api_user" );
  } );
}

=head1 MISC FUNCTIONS

These are misc details about this script item

=head2 new_with_actions

The build function is the actual magic behind the commands, allowing any
subroutine which exists with the prefix 'cmd_' to be ran from the command line.

=cut

sub new_with_actions {
  my $class = shift;
  my $self = $class->new_with_options( @_ );

  my ( $cmd, @extra ) = @ARGV;

  die "Must supply a command\n" unless $cmd;
  die "Extra commands found - Please provide only one!\n" if @extra;
  die "No such command ${cmd} \n" unless $self->can("cmd_${cmd}");

  $self->${\"cmd_${cmd}"};
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 SEE ALSO

* L<MooX::Options>
* L<DBIx::Class::DeploymentHandler>
* L<Module::Runtime>

=cut

1;
