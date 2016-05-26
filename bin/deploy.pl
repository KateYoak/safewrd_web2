#! /usr/bin/env perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/../lib";

use Kliq::Schema::Script::DeploymentHandler;

Kliq::Schema::Script::DeploymentHandler->new_with_options( schema_class => 'Kliq::Schema' );
