use Kliq::Schema;
use feature 'say';
use DDP;
use JSON qw(decode_json);
use Coro;
use FurlX::Coro;
my $s
  = Kliq::Schema->connect(
  q{dbi:mysql:database=kliq2;host=127.0.0.1;port=3306;user=kliq_SSM;password=self-expression}
  );

while (1) {
  my @coros = ();
  foreach my $drone ($s->resultset('Drone')->all) {
    push @coros, async {
      my $ua  = FurlX::Coro->new();
      my $res = $ua->get(
        'http://dev.flytbase.com/rest/ros/flytsim/mavros/global_position/global',
        [
          'Authorization' => 'Token ' . $drone->access_token,
          VehicleID       => $drone->vehicle_id
        ]
      );
      my $json = decode_json($res->decoded_content);
      return unless $json->{latitude} && $json->{longitude};
      return {
        id       => $drone->id,
        location => [$json->{latitude}, $json->{longitude}]
      };
    };
  }
  _update_drone_location($_->join) for @coros;
  sleep(5);
}

sub _update_drone_location {
  my $args = shift;
  return unless $args;
  p($args);
  $s->resultset('Drone')->find($args->{id})
    ->update_location(@{$args->{location}});
}

