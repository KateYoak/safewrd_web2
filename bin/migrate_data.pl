#! /usr/bin/env perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

BEGIN {
  package Kliq::Schema::Script::Migration;

  use Moo;
  use MooX::Options;
  use Kliq::Schema;
  use DBIx::Class::Fixtures;

  option pg_con => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => "The PostgreSQL Connection String",
  );

  option my_con => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => "The MySQL Connection String",
  );

  has pg_schema => (
    is      => 'lazy',
    builder => sub {
      my $self = shift;
      my $connection = $self->pg_con;
      $connection =~ s/username=(.*?);//; my $user = $1;
      $connection =~ s/password=(.*?);//; my $pass = $1;
      return Kliq::Schema->connect(
        $connection,
        $user,
        $pass,
      );
    },
  );

  has my_schema => (
    is      => 'lazy',
    builder => sub {
      my $self = shift;
      my $connection = $self->my_con;
      $connection =~ s/username=(.*?);//; my $user = $1;
      $connection =~ s/password=(.*?);//; my $pass = $1;
      return Kliq::Schema->connect(
        $connection,
        $user,
        $pass,
      );
    },
  );

  sub BUILD {
    my $self = shift;
    print "Migrating data from MySQL to PostgreSQL\n\n";
    print "PostgreSQL Con: " . $self->pg_con . "\n";
    print "MySQL Con:      " . $self->my_con . "\n\n";

    print "Getting sorted array of sources...\n";
    my @sorted_sources = DBIx::Class::Fixtures::_get_sorted_sources( undef, $self->my_schema );

    print "Migrating Data from Source:\n";
    $self->pg_schema->storage->with_deferred_fk_checks( sub {
      for my $source_name ( @sorted_sources ) {
        print "    $source_name ... ";
        my $my_rs = $self->my_schema->resultset($source_name);
        $my_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my $pg_rs = $self->pg_schema->resultset($source_name);
        $pg_rs->populate([$my_rs->all]);
        print "Done\n";
      }
    });
  }

}

Kliq::Schema::Script::Migration->new_with_options;
