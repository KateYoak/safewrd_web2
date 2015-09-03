#!/usr/bin/perl -w

# ae_redis_blpop.pl
# AnyEvent Perl BLPOP loop. Has memory leak. 
# https://gist.github.com/653912

$|=1;
use strict;

use lib './lib';
use AnyEvent::Redis; # TODO: migrate to AnyEvent::Redis::Federated or AnyEvent::Redis::RipeRedis
use JSON;    
use Try::Tiny;

use Log::Dispatch;
use YAML;
use Class::Load qw/load_class is_class_loaded/;
use Kliq::Schema;

my $config = load_yaml('./config.yml');
my $schema = schema($config);

my $logger = Log::Dispatch->new(
      outputs => [
          [ 'File',   min_level => 'debug', mode => 'append', filename => './logs/worker.log', newline => 1, format => '%d [%p] %P - %m' ],
          [ 'Screen', min_level => 'debug', newline => 1 ],
      ],
);

my %IMPORTMAP = (
    google   => 'GoogleImporter',
    yahoo    => 'YahooImporter',
    twitter  => 'TwitterImporter',
    facebook => 'FacebookImporter',
    linkedin => 'LinkedInImporter'
);

#+ SMSNotifier
my %WORKERMAP = (
    importContacts => sub {
        my $data = shift;
        $logger->info("importContacts " . $data->{service} . ', user ' . $data->{user} . ', session ' . $data->{session} );
        return ($IMPORTMAP{$data->{service}}, $config->{sites}->{$data->{service}});
        },
    notifyEmail    => sub { ('MailNotifier',     $config->{plugins}->{Email})  },
    notifyEventEmail => sub { ('MailEventNotifier', $config->{plugins}->{Email})  },
    notifyTwitter  => sub { ('TwitterNotifier',  $config->{sites}->{twitter}) },
    notifyFacebook => sub { ('FacebookNotifier', $config->{sites}->{facebook}) },
    notifyLinkedIn => sub { ('LinkedInNotifier', $config->{sites}->{linkedin}) },
    sliceVideo     => sub { ('VideoClipper', { asset_basepath => $config->{asset_basepath} })  },
    uploadS3       => sub { ('S3Uploader', $config->{sites}->{'amazon-s3'}) },
    zencode        => sub { ('Zencoder', { zencoder => $config->{sites}->{'zencoder'}, rackspace => $config->{sites}->{'rackspace'} }) },
    notifyShare    => sub { 'ShareNotifier' },
    notifyEvent    => sub { 'EventNotifier' },
    amdbPush       => sub { ('AMDBPusher', { asset_basepath => $config->{asset_basepath}, %{$config->{sites}->{'rackspace'}} }) },
    amdbBuild      => sub { ('AMDBBuilder', $config->{sites}->{'rackspace'}) },
    cloudPush      => sub { ('CloudFilesPusher', $config->{sites}->{'rackspace'}) },    
);

my $host = 'localhost';
my $port = 6379;

my @channels = keys %WORKERMAP; # which queues/channels to check
my $command_timeout = 30; # how long to wait for a response

my $done_cv = AnyEvent->condvar;
$done_cv->begin;

my $redis = AnyEvent::Redis->new(
    host     => $host,
    port     => $port,
    on_error => sub { $logger->error(@_); $done_cv->end; }
);

sub handler;
sub handler {
    my ($stuff) = @_;
    if ($stuff) {
        my ($key, $msg) = @$stuff;
        try {
            my $data = decode_json($msg) or die("Missing message json");
            my $worker = worker($key, $data);
            #$logger->info("Working $key");
            $worker->work($data);

        } catch {
            $logger->error("$key WorkerError $_ " . $msg);
        };
    } else {
        #$logger->info("Worker: tick");
    }
    $redis->blpop(@channels, $command_timeout, sub { handler(@_); });
};

$logger->info("Starting Workers");

handler();

$done_cv->recv;

exit;


sub load_yaml {
    my ($file) = @_;

    my $config;

    eval { $config = YAML::LoadFile($file) };
    if (my $err = $@ || (!$config)) {
        die "Unable to parse the configuration file: $file: $@";
    }

    return $config;
}

sub schema {
    my $config = shift;
    my $connect_info = $config->{plugins}->{DBIC}->{kliq};
    $connect_info->{password} = delete $connect_info->{pass};
    return Kliq::Schema->connect($connect_info) or die "Failed to connect to database";
}


sub worker {
    my ($channel, $data) = @_;
    
    my ($type, $lconfig) = $WORKERMAP{$channel}($data);
    my $class = 'Kliq::Worker::' . $type;
    load_class($class) unless is_class_loaded($class);
    
    my %args = (schema => $schema); #, logger => $logger);
    $args{config} = $lconfig if $lconfig;
    
    return $class->new(%args);
}

