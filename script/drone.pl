#!/usr/bin/env perl

# Start/Restart
#   hypnotoad drone.pl
#
# Stop:
#   hypnotoad -s drone.pl
use Mojolicious::Lite;
use signatures;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Redis;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Kliq::Schema;

app->config(hypnotoad => {proxy => 1, listen => ['http://*:4004']});

app->hook(
  before_dispatch => sub {
    my $c = shift;
    push @{$c->req->url->base->path->trailing_slash(1)},
      shift @{$c->req->url->path->leading_slash(0)};
  }
) if app->mode eq 'production';

helper redis_pubsub => sub { state $rr = Mojo::Redis->new };
helper redis        => sub { state $r  = Mojo::Redis->new };

helper schema => sub {
  state $s = Kliq::Schema->connect(

 q{dbi:mysql:database=kliq21;host=127.0.0.1;port=3306;user=kliq_SSM;password=self-expression}


  );
};
get '/' => sub {
  my $c = shift;
  $c->stash(
    missions => [
      $c->schema->resultset('Mission')
        ->search_rs(undef, {order_by => {-desc => 'created'}, rows => 10})->all
    ]
  );
}                       => 'index';
get '/mission/:mission' => 'mission';

post '/mission/:mission/position' => sub {
  my $c       = shift;
  my $mission = $c->param('mission');
  my $payload = $c->req->json;
  my $msg     = encode_json($payload);
  $c->redis->db->lpush_p("mission_path:$mission", $msg)->then(
    sub {
      $c->render(json => {ok => 1});
    }
  )->then(
    sub {
      $c->redis->pubsub->notify("mission:$mission" => $msg)->then(
        sub {
          warn "NOTIFIED 'mission:$mission': $msg ";
        }
      )->catch(
        sub {
          warn 'ERROR';
          $c->reply->exception(shift);
        }
      );
    }
  )->catch(
    sub {
      $c->reply->exception(shift);
    }
  );
} => 'mission_position';

get '/mission/:mission/path' => sub {
  my $c       = shift;
  my $mission = $c->param('mission');
  $c->redis->db->lrange_p("mission_path:$mission", 0, -1)->then(
    sub {
      my $path = shift;

      $c->render(json => [map { decode_json($_) } @{$path || []}]);

#      $c->render(json => [map { [split /\s*,\s*/, $_] } @{$path || []}]);
    }
  )->catch(
    sub {
      $c->reply->exception(shift);
    }
  );
} => 'mission_path';

websocket '/ws/mission/:mission' => sub {
  my $c       = shift;
  my $mission = $c->param('mission');
  my $queue   = "mission:$mission";
  my $pubsub  = $c->redis_pubsub->pubsub;
  warn "LISTENING 'mission:$mission'";
  my $cb = $pubsub->listen(
    $queue => sub {
      my ($pubsub, $msg) = @_;
      warn 'send';
      $c->send($msg);
    }
  );

  $c->inactivity_timeout(0);
  $c->on(finish => sub { warn 'finish'; $pubsub->unlisten($queue => $cb) });

} => 'mission_ws';


app->start;

# https://docs.mapbox.com/mapbox-gl-js/example/live-geojson/
# https://docs.mapbox.com/mapbox-gl-js/example/animate-a-line/
# https://docs.mapbox.com/mapbox.js/api/v3.1.1/l-polyline/

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mission</title>
  </head>
  <body>
    % if ( my @missions = @{$missions||[]}) {
    <h2> Latest missions </h2>
    <ul>
      % for my $mission (@missions) {
      <li> <a href="<%= url_for(mission => mission => $mission->id)->to_abs %>"> <%= $mission->created %>: <%= $mission->id %> </a> </li>
      % }
    </ul>
    % } else {
    <h2> No missions </h2>
    % }
  </body>
</html>

@@ mission.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mission</title>
    <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' />

    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Roboto:300,300italic,700,700italic">
    <link rel="stylesheet" href="//cdn.rawgit.com/necolas/normalize.css/master/normalize.css">
    <link rel="stylesheet" href="//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css">

    <link href='https://api.tiles.mapbox.com/mapbox-gl-js/v0.52.0/mapbox-gl.css' rel='stylesheet' />
    <!-- <link href='https://api.mapbox.com/mapbox.js/v3.1.1/mapbox.css' rel='stylesheet' /> -->
    <style>
      body {
      }
      pre {
        padding: 0.2rem 0.5rem;
      }
      .wrapper {
        /* max-width: 35em;
           margin: 0 auto; */
      }
      #map { left: 40px;height: 600px;; width:90%; }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <h1>Mission</h1>
      <div id='map'></div>
    </div>
  </body>

  <!-- <script src='https://api.mapbox.com/mapbox.js/v3.1.1/mapbox.js'></script> -->
  <script src='https://api.tiles.mapbox.com/mapbox-gl-js/v0.52.0/mapbox-gl.js'></script>
  <script src='https://api.tiles.mapbox.com/mapbox.js/plugins/turf/v2.0.0/turf.min.js' charset='utf-8'></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/fetch/3.0.0/fetch.min.js"></script>
  <script>
    var ws = new WebSocket("<%= url_for('mission_ws', mission => $mission)->to_abs %>");
    /* L.mapbox.accessToken = 'pk.eyJ1IjoiZ2FiaXJ1aCIsImEiOiJjanJyMGw5cjQxdWxlNDRwbHNnYmc1NDMzIn0.MWrl0A-yORPez5t8afv18g';
     * var map = L.mapbox.map('map', 'mapbox.streets');
     * var polyline = L.polyline([L.latLng(-14.784265, -39.283135), L.latLng( -14.786495, -39.281590 ), L.latLng(-14.789073, -39.283746)], {color: 'red'}).addTo(map);
     * var lat = -14.784265;
     * var lng = -39.283135;
     * map.fitBounds(polyline.getBounds()); */


    var lat = 42.539958;
    var lng = -83.205757;

    mapboxgl.accessToken = 'pk.eyJ1IjoiZ2FiaXJ1aCIsImEiOiJjanJyMGw5cjQxdWxlNDRwbHNnYmc1NDMzIn0.MWrl0A-yORPez5t8afv18g';
    var map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v10',
      center: [lng, lat],
      zoom: 15
    });
    var geojson = {
      "type": "FeatureCollection",
      "features": [{
	"type": "Feature",
	"geometry": {
	  "type": "LineString",
	  "coordinates": [
	    [lng, lat]
	  ]
	}
      }]
    };

    var point = {
      "type": "FeatureCollection",
      "features": [{
	"type": "Feature",
	"properties": {},
	"geometry": {
	  "type": "Point",
	  "coordinates": [lng, lat]
	}
      }]
    };

    var prev_lat = lat;
    var prev_lng = lng;
    function fit(map, coordinates){
      var bounds = coordinates.reduce(function(bounds, coord) {
	return bounds.extend(coord);
      }, new mapboxgl.LngLatBounds(coordinates[0], coordinates[0]));

      map.fitBounds(bounds, {
	padding: 200
      });
    }

    function update_location(lat, lng){
      point.features[0].properties.bearing = turf.bearing(
	turf.point([prev_lng, prev_lat]),
	turf.point([lng, lat])
      );

      // updates line
      geojson.features[0].geometry.coordinates.push([ lng, lat]);
      map.getSource('line-animation').setData(geojson);
      // updates drone marker
      point.features[0].geometry.coordinates = [ lng, lat];
      map.getSource('drone').setData(point);
      fit(map,geojson.features[0].geometry.coordinates)

      prev_lat = lat;
      prev_lng = lng;

    }
    function end_mission(){
      return;
      geojson.features[0].geometry.coordinates = [];
      map.getSource('line-animation').setData(geojson);
    }

    ws.onopen = function(e) {
    };

    ws.onmessage = function(message) {
      var payload = JSON.parse(message.data);
      if(payload.landed){
        return end_mission()
      }
      return update_location(payload.location.lat, payload.location.lng);
    };



    map.on('load', function() {

      // add the line which will be modified in the animation
      fetch("<%= url_for('mission_path', mission => $mission)->to_abs %>").then(function(res){
	return res.json();
      }).then(function(json){
	var path = json.filter((item) => item.hasOwnProperty('location')).map((item) => [item.location.lng, item.location.lat]);
	if(path.length) {
	  geojson.features[0].geometry.coordinates = path.slice().reverse();
	}
      }).finally(function(){
	map.addLayer({
	  "id": "drone",
	  "type": "symbol",
	  'source': {
	    'type': 'geojson',
	    'data': point
	  },
	  "layout": {
	    "icon-image": "rocket-15",
	    "icon-rotate": ["get", "bearing"],
	    "icon-rotation-alignment": "map",
	    "icon-allow-overlap": true,
	    "icon-ignore-placement": true
	  }
	});
	map.addLayer({
	  'id': 'line-animation',
	  'type': 'line',
	  'source': {
	    'type': 'geojson',
	    'data': geojson
	  },
	  'layout': {
	    'line-cap': 'round',
	    'line-join': 'round',
	  },
	  'paint': {
	    'line-color': '#ed6498',
	    'line-width': 5,
	    'line-opacity': .8
	  }
	});

	//      geojson.features[0].geometry.coordinates.push([lng, lat ]);
	map.getSource('line-animation').setData(geojson);
	map.getSource('drone').setData(point);
	fit(map,geojson.features[0].geometry.coordinates)
      });

      /* setInterval(
	 function(){ return;
	 var x= prev_lng + (Math.random() - 0.5)/400;
	 var y = prev_lat + (Math.random() - 0.5)/400;
	 update_location(y, x);
	 },  Math.random() * 3 * 1000 + 2000
       * ); */
    });
  </script>
</html>
