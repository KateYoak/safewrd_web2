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
my $trg1 = "/home/ubuntu/media/uservids/YYY-$uuid.mp4";
my $trg2 = "/home/ubuntu/media/uservids/ZZZ-$uuid.mp4";

if (
     ! -X "/usr/bin/ffmpeg"
  || ! -e $src
) {
  plan skip_all => "No FFmpeg or target file";
}

process_vid();
#qt_vid();

sub process_vid {

my $cmd1 = "ffmpeg -i $src -s 432x320 -b 384k -vcodec h264 -flags +loop+mv4 -cmp 256 -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 -subq 7 -trellis 1 -refs 5 -bf 0 -flags2 +mixed_refs -coder 0 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10 -qmax 51 -qdiff 4 -acodec aac $trg1";
$cmd1 = "/usr/bin/ffmpeg -i $src -sameq $trg1";
    my($success, $error, $stdall, $stdout, $stderr) = run(command => $cmd1, verbose => 1);
    if($success || -f $trg1) {
       print "Vid encoded\n";
    }
    else {
    	die "Encoding fail $error = $stdall - $stdout - $stderr";
    }
}

sub qt_vid {
    # Quickstart the mp4 versions
    #qt-faststart "$filename" "$filename.fast"
	my $cmd = '/usr/bin/qt-faststart "' . $trg1 . '" "' . $trg2 . '"';

    my($success, $error, $stdall, $stdout, $stderr) = run(command => $cmd, verbose => 1);
    if($success || -f $trg2) {
       print "Vid faststarted\n";
    }
    else {
    	print "Nofaststart";
    }


              #  case "$?" in
              #         0 ) echo "Success - Overwriting Source"; mv "$filename.fast" "$filename";;
              #         * ) echo "Failure - Removing Destination"; rm "$filename.fast";;
}

done_testing;
