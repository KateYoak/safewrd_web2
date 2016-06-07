use strict;
use warnings;
use Test::More;

if ( $ENV{TRAVIS} ) {
  plan skip_all => "Test will not work under Travis";
}

use Test::Exception;

use FFmpeg::Thumbnail;

my $uuid = 'F7C93F00-0A70-11E2-9DD4-6C2E78395DFD';
$uuid = 'D6AF0462-0A61-11E2-9DD4-6C2E78395DFD';
#$uuid = 'EE3F72E4-0A69-11E2-9DD4-6C2E78395DFD';
my $suffix = '.mp4';
my $dest = "/home/ubuntu/media/uservids/$uuid$suffix";

my $thumb = FFmpeg::Thumbnail->new( { video => $dest, hide_log_output => 0 } );
$thumb->output_width(240);
$thumb->output_height(160);
$thumb->offset(2);
my $thumbfile = "/home/ubuntu/media/userthumbs/ZZZ-$uuid.png";
$thumb->create_thumbnail(2, $thumbfile);

ok(-f $thumbfile);


done_testing;
