package Kliq::Util;

use utf8;
use strict;
use warnings;
use feature 'state';
use Exporter 'import';

use REST::Client;


our @EXPORT_OK = qw(fb_surrogate_id_from_picture);


sub fb_surrogate_id_from_picture {
  my $id = shift;
  state $rest_client = REST::Client->new;
  my $pic_url = eval {
    $rest_client->HEAD(qq{https://graph.facebook.com/v2.11/$id/picture})
      ->responseHeader('Location');
  } or return;
  return if $pic_url !~ /\.jpg/;
  my ($surrogate_id) = $pic_url =~ /\/([^\/]+?)\.jpg/g;
  return $surrogate_id;
}

1;
