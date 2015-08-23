use strict;
use warnings;
use Test::More;
use Test::Exception;

use IPC::Cmd qw/run/;


my $uuid = 'F7C93F00-0A70-11E2-9DD4-6C2E78395DFD'; # nogo
$uuid = 'D6AF0462-0A61-11E2-9DD4-6C2E78395DFD'; # nogo
#$uuid = 'EE3F72E4-0A69-11E2-9DD4-6C2E78395DFD'; # ok
my $suffix = '.mp4';
my $src = "/home/ubuntu/media/uservids/$uuid$suffix";
my $trg = "/home/ubuntu/media/userthumbs/ZZZ-$uuid.png";
my $cmd = "ThumbnailComposer -i $src -ss 2 -t 5 -w 240 -h 160 -interval 5 $trg";

    my($success, $error, $stdall, $stdout, $stderr) = run(command => $cmd, verbose => 0);
    if($success || -f $trg) {
       # return send_file($trg, system_path => 1);
       print "THumb generated\n";
    }


ok(-f $trg);


done_testing;