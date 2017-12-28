package Kliq::Util;

use utf8;
use strict;
use warnings;
use feature 'state';
use Exporter 'import';
use JSON qw(decode_json);
use REST::Client;
use URI;

our @EXPORT_OK = qw(fb_surrogate_id_from_picture);

my $app_access_token
  = 'EAAKLaAfiAtcBAJRNmCuNjD5Xc7kyPNklyG7ZCdziPTHcFsZAEoodGBiJz8xzixjaqdrDrbYTt3rMJ3I1993JmZCz3hu8rZClIWndC3TErZBDa2VeVXpyvNw4eg6zNogoiynRCZAiGsyk2KHk5KBfbAOtk44h7JghgOHHZBfnhZAghAZDZD';

sub fb_surrogate_id_from_picture {
  my ($id, %args) = @_;
  state $rest_client = REST::Client->new;

  my $pic_url;
  if ($args{from_app}) {
    $pic_url = eval {
      $rest_client->HEAD(qq{https://graph.facebook.com/v2.11/$id/picture})
        ->responseHeader('Location');
    } or return;
  }
  else {
    my $uri = URI->new("https://graph.facebook.com/v2.11/$id");
    my $access_token = $args{user_token} || $app_access_token;

    $uri->query_form(fields => 'profile_pic', access_token => $access_token);

    $pic_url = eval {
      decode_json($rest_client->GET($uri->as_string)->responseContent)
        ->{profile_pic};
    } or warn $@, return;
  }
  return if $pic_url !~ /\.jpg/;

  my ($surrogate_id) = $pic_url =~ /\/([^\/]+?)\.jpg/g;
  $surrogate_id =~ s/^\d+_//;
  $surrogate_id =~ s/_\w$//;  
  return $surrogate_id;
}

1;
