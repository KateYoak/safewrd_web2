use strict;
use warnings;
use Test::More;

plan skip_all => "Test is broken";

use Test::Exception;
use JSON;
use t::TestUtils;
use Data::Dumper;

my $schema   = schema();
my $user  = $schema->resultset('User')->create({
    uname => 'sitetechie',
    pass => 'pAssW0rd',
    email => 'techie@sitetechie.com',
    });

my $json = JSON->new->utf8->allow_nonref->convert_blessed;

foreach my $entity($user) {
    my $data = $entity->TO_JSON;
#warn Dumper $data;    
    my $json_text = $json->encode($data);
    my $roundtrip = $json->decode($json_text);
    is_deeply($data, $roundtrip);
    }

done_testing;
