#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
#use Kliq::Worker::TwitterImporter;
#use Kliq::Worker::MailImporter;
use Kliq::Worker::MailNotifier;
#use Kliq::Worker::TwitterNotifier;
#use Kliq::Worker::VideoClipper;
use Kliq::Schema;
my $s = Kliq::Schema->connect({ dsn => 'dbi:mysql:kliq2', user => 'kliq_SSM', password => 'self-expression' });

use Log::Dispatch;

my $logger = Log::Dispatch->new(
      outputs => [
          [ 'File',   min_level => 'debug', filename => './logs/workers.log', newline => 1 ],
          [ 'Screen', min_level => 'debug', newline => 1 ],
      ],
);

my $data = {
        service => 'twitter',
        token => 'twitter_access_token',
        secret => 'twitter_access_token_secret',
        session => 'id',
        user => '94A4988D-93F8-1014-A991-F7EDC84F2656',
        handle => 12,
        info => {
            id => 12,
            name => 'username',
            screen_name => 'screen_name'
        }
    };

use YAML;
my $config = load_yaml('./config.yml');


#Kliq::Worker::TwitterImporter->new(schema => $s)->work($data);
#Kliq::Worker::MailImporter->new(schema => $s)->work($data);

$data = {
    sender => 'Some Cool Guy',
    message => 'Hello World',
    email => 'peter@sitecorporation.com',
    media_id => 1,
    upload_id => undef
};


#Kliq::Worker::MailNotifier->new(schema => $s, config => $config->{plugins}->{Email})->work($data);
#Kliq::Worker::TwitterNotifier->new(schema => $s, logger => $logger)->work({
#    token => '46722818-tlQvHw6NrHuTrhJuyoeXeCE5n9X6RTj6EfEiCg71J',
#    secret => 'DEs3c5hAZMpkNJzHOQve353iCCdxi1PihjPsbWB0iU',
#    recipients => ['513795868'],
#    message => 'Hi from workr.t Number3.'
#});

#Kliq::Worker::VideoClipper->new(schema => $s, logger => $logger)->work({
#    media => '8D42CB1B-8A8C-1014-BD9A-1207194F16F4',
#    share => '3C3CB47C-A297-1014-93D2-A3F7C84F2656',
#    offset => 115
#});

use Kliq::Worker::VideoProcessor;
Kliq::Worker::VideoProcessor->new(schema => $s, config => $config->{sites}->{rackspace})->work($data);

ok(1);
done_testing;



sub load_yaml {
    my ($file) = @_;

    my $config;

    eval { $config = YAML::LoadFile($file) };
    if (my $err = $@ || (!$config)) {
        die "Unable to parse the configuration file: $file: $@";
    }

    return $config;
}

