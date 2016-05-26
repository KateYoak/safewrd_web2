package Kliq;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use POSIX;
use Class::Load qw/load_class is_class_loaded/;
use String::CamelCase qw/decamelize/;
use Data::UUID;
use File::Basename qw/fileparse/;
use MIME::Types;
use Data::Dumper;
use File::Copy;
use URI;
use Try::Tiny;
use WWW::Mixpanel;
use IPC::Cmd qw/run/;
use Kliq::Model::ZencoderOutput;

set serializer => 'JSON';
#set logger     => 'log_handler';

our $VERSION = '0.001';
our $DEBUG = 0;

my $UG = new Data::UUID;
my $MT = MIME::Types->new;

#------ init -------------------------------------------------------------------

hook 'before' => sub {
    my $domain = request->host;
    $domain =~ s/:.*$//;
    $domain =~ s/^(.*)\.(.*)\.(.*)$/$2\.$3/g;
    var domain => $domain;

    header('Cache-Control' => 'no-store, no-cache, must-revalidate');
    header('Access-Control-Allow-Methods' => ['GET','POST','PUT','DELETE','OPTIONS']);

    #-- find user
    my $user = undef;
    if (session('user_id')) {
        $user = schema->resultset('User')->find(session('user_id'));
        unless($user) {
            var error => "Invalid user " . session('user_id') . " (stale cookie?)";
            request->path_info('/error');
            return;
        }
        var user => $user;
    }
    elsif($DEBUG || params->{debug}) {
        my $uid = params->{user} || '94A4988D-93F8-1014-A991-F7EDC84F2656';
        $user = schema->resultset('User')->find($uid);
        var user => $user;
        session user_id => vars->{user}->id;
    }

    #-- set domain referer for postMessage
    
    if(request->referer) {
        my $ref = URI->new(request->referer);
        session referer_domain 
            => 'http://' . ($ref->port == 80 ? $ref->host : $ref->host_port);
    }
    else {
        session referer_domain => 'http://m.tranzmt.it';
    }

    ## development & testing
    if(request->path =~ '^/(v1/upload|v1/zencoded|v1/cors|v1)?$') {
        return;
    }
    elsif(request->path =~ '^/v1/download$') {
        # Download the app
        return;
    }
    elsif(!$user && request->path eq '/v1/tokens' && request->method eq 'GET') {        
        request->path_info('/error/unauthorized');
    }
    elsif(request->path =~ '^/v1/(auth|tokens)') {    
        # GET /auth/:id/callback should always load or create a non-anon user 
        # and set session.user_id from the bg worker
        # GET /tokens may be anon, or using this session.user_id
        #print STDERR "Auth.Tokens path\n";
        return;
    }
    elsif(request->path =~ '^/v1/(assets|media|downloads|downloads2|uploads|streams|timeline|t)/') {
        return;
    }
    ## post from ssm
    elsif(request->path =~ '^/v1/media') {
        return;
    }    
    elsif(!$user) {
        request->path_info('/error/unauthorized');
    }
};

#------ /api -------------------------------------------------------------------
get '/' => sub {
    #header('X-RateLimit-Limit' => 5000);
    #header('X-RateLimit-Remaining' => 4999);
    
    #header('Location' => 'http://developers.' . vars->{domain});
    #return status_found();
 
    template "index", { }, { layout => undef };
};

get '/user' => sub {
    my $user = undef;
    if (session('user_id')) {
        $user = schema->resultset('User')->find(session('user_id'));
        unless($user) {
            var error => "Invalid user " . session('user_id') . " (stale cookie?)";
            request->path_info('/error');
            return;
        }
        var user => $user;
    }

    if(!$user) {
        request->path_info('/error/unauthorized');
    }

    content_type 'application/json';
    return to_json({ uid => session('user_id') });
};

get '/contact_id' => sub {
    my $contact = undef;
    if (session('user_id')) {
        $contact = schema->resultset('Contact')->find({ user_id => session('user_id') });
        unless($contact) {
            var error => "Invalid user " . session('user_id') . " (stale cookie?)";
            request->path_info('/error');
            return;
        }
    }

    if(!session('user_id')) {
        request->path_info('/error/unauthorized');
    }

    content_type 'application/json';
    return to_json({ contact_id => $contact->id });
};

get '/archives' => sub {
    my @archives = ();
    my $base_path = "/var/opt/clqs-api/media/video_recordings";
    my $archive_url_base = "rtmp://api.tranzmt.it:1935/archives";
    if (session('user_id')) {
        my $user = schema->resultset('User')->find({ id => session('user_id') });
        unless($user) {
            var error => "Invalid user " . session('user_id') . " (stale cookie?)";
            request->path_info('/error');
            return;
        }

        # Get user owned events, and incoming events
        my $events = schema->resultset('Event')->search(
            [
                { 'contact.user_id' => $user->id },
                { 'me.user_id' => $user->id }
            ],
            { 
                join     => { kliq => { contacts_map => 'contact' } },
                order_by => { -desc => 'me.created' }
            });
        while (my $event = $events->next) {
            my $filename = $base_path . "/" . $event->id . ".flv";
            if (-e $filename) {
                my $archive_url = $archive_url_base . "/" . $event->id;
                my $event_type = $event->kliq->is_emergency ? "emergency_flare" : "live_event";
                push(@archives, { event_id => $event->id, event_title => $event->title, event_type => $event_type, location => $event->location, archive_url => $archive_url });
            }    
        }  
    }
    else {
        request->path_info('/error/unauthorized');
    }

    content_type 'application/json';
    return to_json(\@archives);
};

get '/upload' => sub {
    template "upload", { }, { layout => undef };
};

get '/cors' => sub {
    template "cors", { }, { layout => undef };
};

post '/cors' => sub {
    return status_ok({ message => params->{message} });
};

get '/download' => sub {
    my $ua = request->user_agent;
    my $url;
    if ($ua) {
        if ($ua =~ /android/i) {
            $url = "http://play.google.com";
            redirect $url;
        }
        elsif ($ua =~ /ipad|ipod|iphone/i) {
            $url = "http://itunes.apple.com";
            redirect $url;
        }
    }

    # Web request. Render download page
    template "download", { }, { layout => undef };
};

get '/error' => sub {
    #print STDERR Dumper { params };
    return status_bad_request(vars->{error});
};

get '/error/unauthorized' => sub {
    return status_unauthorized("Not authorized");
};

get '/t/logme/*' => sub {
    # Debugging test by Darren Duncan
    error("in /t/logme, request uri is [[".request->request_uri()."]]");
    error("in /t/logme, request body is [[".request->body()."]]");
};

get '/t/die' => sub {
    die("Die Test");
};

get '/t/error' => sub {
    return send_error("Access denied!", 403);
};

#------ utils ------------------------------------------------------------------

my %qparams = (
    contacts => ['service'],
    kliqs    => ['name'],
    events   => ['eventStatus'],
);

sub search_params {
    my $resource = shift;

    my $crit = {};
    foreach(@{ $qparams{$resource} }) {
        next unless params->{$_};
        if (params->{$_} =~ /\|/) {
            my @or_clause;
            for my $each_filter (split('\|', params->{$_})) {
                push(@or_clause, decamelize($_)  => $each_filter);
            };

            $crit->{-or} = \@or_clause; 
        }
        else {
            $crit->{decamelize($_)} = delete params->{$_};
        }
    }

    return $crit;
}

my %qorder = (
    contacts => 'name',
    kliqs => 'name',
    shares => 'created DESC',
    tokens => 'created DESC',
    uploads => 'created DESC',
    events  => 'created DESC',
    #timeline => 'created DESC',
);

sub query_filters {
    my $resource = shift;

    my $filters = {
        rows => params->{per_page} || 30,
        };

    if(params->{order} || params->{order_by}) {
        my $ob = params->{order_by} || params->{order};
        if($ob =~ /,/) {
            $ob = [split(',',$ob)];
        }
        $filters->{order_by} = $ob;
    }
    elsif($qorder{$resource}) {
        $filters->{order_by} = $qorder{$resource};
    }

    if(params->{page}) {
        $filters->{page} = params->{page};
    }
    elsif(params->{offset}) {
        $filters->{offset} = params->{offset};
    }
    else {
        $filters->{page} = 1;
    }

    return $filters;
}

sub body_params {
    #-- uploads to Dancer (kliq images + test videos)
    if(my $upload = request->upload('upload')) {
        my ($_name, $_path, $suffix) = fileparse($upload->filename, qr/\.[^.]*/);
        die("Invalid format $suffix") unless $suffix =~ /^\.(png|jpg|jpeg|gif|mp4|m4v|mpeg|mpg|3gp|webm)$/;

        my ($uuid, $dest);
        if(request->path =~ /^\/v1\/kliqs\/(.*)/) {
            $uuid = $1;
            $dest = config->{asset_basepath} . "/kliqs/$uuid$suffix";
        }
        if(request->path =~ /^\/v1\/events\/(.*)/) {
            $uuid = $1;
            $dest = config->{asset_basepath} . "/events/$uuid$suffix";
        }
        else {
            $uuid = $UG->create_str();
            $dest = config->{asset_basepath} . "/uservids/$uuid$suffix";
        }

        $upload->copy_to($dest);
        delete params->{upload};

        return {
            id       => $uuid,
            suffix   => $suffix,
            path     => $dest,
            mimeType => $upload->type,
            title    => params->{title}
        };
    }
    #-- uploads to Nginx (user audio/videos)
    elsif(params->{'upload.size'} && params->{'upload.path'} && params->{'upload.name'}) {
        my ($_name, $_path, $suffix) = fileparse(params->{'upload.name'}, qr/\.[^.]*/);
        my $uuid = $UG->create_str();

        my $dest;
        if ($suffix =~ /^\.(mp4|m4v|mpeg|mpg|3gp|webm)$/) {
            $dest = config->{asset_basepath} . "/uservids/$uuid$suffix";
            move(params->{'upload.path'}, $dest);

            eval {
                thumb_vid($dest, $uuid);
            };
        }
        elsif ($suffix =~ /^\.(mp3|wav)$/) {
       	    $dest = config->{asset_basepath} . "/useraudio/$uuid$suffix";
            move(params->{'upload.path'}, $dest);
        }
        else {
            die("Invalid format $suffix");
        }

        return {
            id       => $uuid,
            suffix   => $suffix,
            path     => $dest, # params->{'upload.path'},
            mimeType => params->{'upload.content_type'},
            title    => params->{title}
        };
    }
    else {
        return from_json(request->body());
    }
}

sub thumb_vid {
    my ($src, $uuid) = @_;
    my $trg = config->{asset_basepath} . "/userthumbs/$uuid.png";

    my $cmd = 'ffmpeg -i "' . $src . '" -y -vframes 1 -an -s 240x160 "' . $trg . '"';

    my($success, $error, $stdall, $stdout, $stderr) = run(command => $cmd, verbose => 0);
    if($success || -f $trg) {
        # all ok, thumb created
    }
    else {
       copy(config->{asset_basepath} . "/defaults/video.png", $trg);
    }
}

sub dejsonify {
    my $args = shift;

    if(!ref($args)) {
        return $args;
    }
    elsif(ref($args) eq 'ARRAY') {
        my @finals = ();
        foreach my $arg(@{$args}) {
            push(@finals, ref($arg) ? dejsonify($arg) : $arg);
        }
        return \@finals;
    }
    elsif(ref($args) eq 'HASH') {
        my %params = %{$args};
        my $result = {};
        foreach my $key(keys %params) {
            my $val = $params{$key};
            $result->{decamelize($key)} = ref($val) ? dejsonify($val) : $val;
        }
        return $result;
    }
    elsif(JSON::is_bool($args)) {
        return "$args";
    }
    else {
        die("Wrong arguments $args");
    }
}

sub paged_link {
    my ($res, $crit, $page) = @_;

    my %params = %{$crit};
    $params{page} = $page;
    $params{per_page} = params->{per_page} if params->{per_page};
    $params{callback} = params->{callback} if params->{callback};

    return request->uri_for($res, \%params);
}

sub model {
    my $res = shift;

    my $class = 'Kliq::Model::' . ucfirst($res);
    load_class($class) unless is_class_loaded($class);

    my $opts = {
        session => session('id'),
        schema  => schema,
        redis   => redis
    };
    if(vars->{user}) {
        $opts->{user} = vars->{user};
    }
    return $class->new($opts);
}

sub track_client_request {
    # Debugging by Darren Duncan
    error("HTTP [[".request->method()."]] from ip [[".request->env()->{HTTP_X_REAL_IP}."]] to url [[".request->request_uri()."]] was with body [[".request->body()."]]");

    try {
        my $project_token = 'c068cca2163c8db05558cda7ff7bd733';  # TODO: put this in config file; multiple copies exist.
        my $mp = WWW::Mixpanel->new( $project_token, 1 );
        $mp->track('any_kliq_api_call',
            session_id => session('id'),
            client_ip_addr => request->env()->{HTTP_X_REAL_IP},
        );
        $mp->track(request->path().'_'.request->method(),
            session_id => session('id'),
            client_ip_addr => request->env()->{HTTP_X_REAL_IP},
        );
    } catch {
        error("Mixpanel failure: ".$@);
    }
}

post '/family_pair/code' => sub {
    my $args = dejsonify(body_params());

    my $code = model('pair')->code($args) 
        or die("Invalid code generated");
 
    if ($code) {
        content_type 'application/json';
        return to_json({ code => $code });
    }
    else {
        status_bad_request($code);
    }
};

post '/family_pair/list' => sub {
    my $args = dejsonify(body_params());

    my $list = model('pair')->list($args) 
        or die("Error generating pair list");
 
    if ($list) {
        content_type 'application/json';
        return to_json($list);
    }
    else {
        status_bad_request($list);
    }
};


post '/family_pair/pair' => sub {
    my $args = dejsonify(body_params());

    my $pair_id = model('pair')->pair($args) 
        or die("Error generating pair_id");
 
    if ($pair_id) {
        content_type 'application/json';
        return to_json({ pair_id => $pair_id });
    }
    else {
        status_bad_request($pair_id);
    }
};

post '/family_pair/flare' => sub {
    my $args = dejsonify(body_params());

    my $response = model('pair')->flare($args) 
        or die("Error trying to send push notification for parent_pair_flare");
 
    if ($response) {
        content_type 'application/json';
        return status_ok($response);
    }
    else {
        status_bad_request($response);
    }
};


#------ /api/* -----------------------------------------------------------------

foreach my $resource(qw/
    users tokens personas contacts kliqs uploads shares events
    timeline comments media assets pair
    /) {
    my $entity = $resource;
    $entity =~ s/s$//g;

    #my $resource = $_resource;
    #my $resourcep = 'users/:uid/' . $resource;
    # print STDERR "USER " . params->{uid} . "\n";    
    
    get '/' . $resource => sub {
        #content_type('application/json');

        track_client_request();

        my $filters  = query_filters($resource);
        my $criteria = search_params($resource);
        my $result   = model($resource)->search($criteria, $filters);

        #-- add link headers
        my $base = "https://api.tranzmt.it/v1/$resource";
        my @links  = ();
        my @plinks = ();
        if($result->{meta}->{currentPage} && $result->{meta}->{currentPage} != 1) {
            push(@links, '<' . paged_link($resource, $criteria, 1) . '>; rel="first"');
            push(@links, '<' . paged_link($resource, $criteria, $result->{meta}->{previousPage}) . '>; rel="prev"');
            push(@plinks, [paged_link($resource, $criteria, 1), { rel=> "first" }]);
            push(@plinks, [paged_link($resource, $criteria, $result->{meta}->{previousPage}), { rel=> "prev" }]);
        }
        if($result->{meta}->{nextPage}) {
            push(@links, '<' . paged_link($resource, $criteria, $result->{meta}->{nextPage}) . '>; rel="next"');
            push(@links, '<' . paged_link($resource, $criteria, $result->{meta}->{lastPage}) . '>; rel="last"');
            push(@plinks, [paged_link($resource, $criteria, $result->{meta}->{nextPage}), { rel=> "next" }]);
            push(@plinks, [paged_link($resource, $criteria, $result->{meta}->{lastPage}), { rel=> "last" }]);
        }
        header('Link' => join(', ', @links));
        header('TotalEntries' => $result->{meta}->{totalEntries} || 0);

        if(params->{callback} || params->{meta}) {
            return status_ok({
                meta => {
                    status => 200,
                    TotalEntries => $result->{meta}->{totalEntries} || 0,
                    Link => \@plinks
                },
                $resource => $result->{items}
            });
        }
        else {
            return status_ok($result->{items});
        }
    };

    resource $resource =>
        get => sub {
            track_client_request();
            my $rec = model($resource)->get(params->{'id'});
            return status_not_found("$entity doesn't exist") unless $rec;
            return status_ok($rec);
        },

        create => sub {
            track_client_request();
            my ($row, $uid, $error);
            eval {
                my $args = dejsonify(body_params());
                ($row, $uid) = model($resource)->create($args) 
                    or die("Could not create $entity");
                if($uid) {
                    session user_id => $uid;
                }
                else {
                    #print STDERR "no user\n";
                }
            };
            if($@) {
                my $exception = $@;
                warning "Create $resource exception: $exception";
                return status_bad_request($exception);
            }
            if(my $error = $row->{error}) {
                warning "Create $resource error: " . (ref($error) ? to_json($error) : $error);
                return status_bad_request($error);
                }
            return status_created($row);
        },

        update => sub {
            track_client_request();
            my $row;
            eval {
                my $args = dejsonify(body_params());
                my $id = params->{'id'} or die("No ID");
                $row = model($resource)->update($id, $args) or die("Invalid update");
            };
            if($@) {
                my $exception = $@;
                warning "Update $resource exception: $exception";
                return status_bad_request($exception);
            }
            if(my $error = $row->{error}) {
                if($error->{code} eq 'missing') {
                    return status_not_found($error);
                }
                warning "Update $resource error: " . (ref($error) ? to_json($error) : $error);
                return status_bad_request($error);
            }
            return status_accepted($row);
        },

        delete => sub {
            track_client_request();
            my $id = params->{'id'};
            #my @ids = split(/,/, $id);
            if(model($resource)->delete($id)) {
                return status_no_content();
            }
            else {
                return status_not_found("$entity $id doesn't exist");
            }
        };
}

foreach my $resource (qw/kliqs events/) {
    post '/' . $resource . '/:id' => sub {
        my $resource_id = params->{id};
        my $args = dejsonify(body_params());
        my $id = $args->{id};
        my $suffix = $args->{suffix} || '.png';
        my $url = "http://api.tranzmt.it/$resource/$id$suffix";

        my $row = model($resource)->update($resource_id, { image => $url })
            or die("Invalid $resource update");

        if(my $error = $row->{error}) {
            if($error->{code} eq 'missing') {
                return status_not_found($error);
            }
            warning "Upload $resource image error: " . (ref($error) ? to_json($error) : $error);
            return status_bad_request($error);
        }
        else {
            redis->rpush(cloudPush => to_json({
                id        => $resource_id,
                key       => "$id$suffix",
                src       => $args->{path},
                container => $resource . '-images'
            }));
            return status_accepted($row);
        }
    };
}

#-------------------------------------------------------------------------------
# ThumbnailComposer -i input.mp4 -ss 5 -t 15 -w 240 -h 160 -interval 5 thumb.jpg
#
#  -i  inputfile name
#  -ss starttime in seconds (integer), it does not support HH:MM:SS format now. 
#  -t  duration in seconds
#  -w  width of the single thumbnail
#  -h  height of the single thumbnail
#  -interval one thumbnail every N seconds
#  thumb.jpg the filename of the composed thumbnails. It contains a one
#  row image that has duration/interval thumbnails, starting
#  from -ss and in the size of -w*-h.
#-------------------------------------------------------------------------------
get '/assets/:id/sprite/:offset' => sub {
    params->{start} = params->{offset} * 60;
    #redirect '/assets/' . params->{id} . '/sprite';
    return thumb_sprite();
};

get '/assets/:id/sprite' => sub {
    return thumb_sprite();
};

sub thumb_sprite {
    my $id = params->{id};
    my $asset = schema->resultset('CmsAsset')->find($id)
        or return status_not_found({ error => 'asset not found', code => 'missing' });

    if($asset->asset_format_id != 11) {
        my $media = $asset->media or return status_bad_request('Not a media asset');
        my $def_asset = $media->assets->find({
            asset_format_id => 11
        });
        return status_not_found("Default asset not found") unless $def_asset;
        $id = $def_asset->id;
    }

    my $src = join('', config->{asset_basepath}, '/assets/', $id, '.mp4');
    unless(-f $src) {
        return status_not_found({ error => 'asset not found', code => 'missing' });
    }

    my $ss = params->{start} || 0;
    my $t  = params->{duration} || 60;
    my $wh = params->{size} || '240x160';
    my $i  = params->{interval} || 10;
    return status_bad_request('invalid size') unless $wh =~ /\d+x\d+/;
    my ($w, $h) = split(/x/, $wh);

    my $sprite = join('-', $id, $ss, $t, $wh, $i) . '.png';
    my $trg = config->{asset_basepath} . "/sprites/$sprite";
    
    if(-f $trg) {
        return send_file($trg, system_path => 1)
    }
    else {
        my $cmd = "ThumbnailComposer -i $src -ss $ss -t $t -w $w -h $h -interval $i $trg";

        my($success, $error, $stdall, $stdout, $stderr) = run(command => $cmd, verbose => 0);
        if($success || -f $trg) {
            return send_file($trg, system_path => 1);
        }
        else {
            return send_error("Thumbnail sprite error: $error ($stderr)");
        }
    }
}

post '/zencoded' => sub {
    track_client_request();
    eval {
        my $json = from_json(request->body());
        my $zco = Kliq::Model::ZencoderOutput->new({
            schema  => schema,
            redis   => redis
        });
        $zco->process_output($json);
    };
    if($@) {
        error("Zencoded POST not processed: $@");
    }
    return status_ok({ message => 'Thank you' });
};

#---- Extra paths developers can use to test calling the API; it echos back what they submitted. ------------------------------

get '/ddtemp1' => sub {
    return status_ok({ message => "get to url [[".request->request_uri()."]] was with body [[".request->body()."]]"});
};

post '/ddtemp1' => sub {
    return status_ok({ message => "post to url [[".request->request_uri()."]] was with body [[".request->body()."]]"});
};

1;
__END__

=pod

=head1 NAME

Kliq - KLIQ Mobile REST API

=head1 VERSION

0.001

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders

=head1 WARNING

Developer Preview, does not do much yet.

=head1 SYNOPSIS

    use Dancer;
    use Kliq;
    dance;

=head1 DESCRIPTION

Kliq is the tranzmt.it REST API implementation built on top of Redis and 
the L<Dancer> framework.

All submissions are welcome.

=head2 Routes

=over 4

=item GET /

Redirects to L<http://developers.tranzmt.it|http://developers.tranzmt.it>.

=back

-- ( work in progress ) --

=head1 INSTALLATION

You must first install the dependencies:

    $ perl Makefile.PL
    $ make
    $ make test

Kliq uses a MySQL database called C<kliq2>. Create this database first:

    CREATE DATABASE kliq21;
    USE kliq21;
    GRANT ALL ON kliq21.* TO 'kliq_SSM'@'localhost' IDENTIFIED BY 'self-expression';
    FLUSH PRIVILEGES;

Then create the tables using:

    $ perl bin/kliq_spawndb.pl -deploy

You can also easily create the database schema with L<kliq_spawndb.pl>, run it 
without options to see the documentation. Also, make sure you have Redis running. 
Then, run the Plack server on localhost, port 5000:

You can also run the Dancer development server at port 3004, but the routes will
be different:

    $ perl bin/kliq.pl

=head1 CONFIGURATION

Configuration can be achieved via the F<config.yml> file or via the C<set> 
keyword. To use the config.yml approach, you will need to install L<YAML>. See 
the L<Dancer> documentation for more information.

You can alternatively configure the server via the C<set> keyword in the source
code. This approach does not require a config file.

    use Dancer;
    use Kliq;

    # Dancer specific config settings
    set logger      => 'file';
    set log         => 'debug';
    set show_errors => 1;

    dance;

=head1 DEPLOYMENT

Deployment is very flexible. It can be run on a web server via CGI or FastCGI.
It can also be run on any L<Plack> web server. See L<Dancer::Deployment> for
more details.

=head2 FastCGI

Kliq can be run via FastCGI. This requires that you have the L<FCGI> and
L<Plack> modules installed. Here is an example FastCGI script.
It assumes your KLIQ server is in the file F<kliq.pl>.

    #!/usr/bin/env perl
    use Dancer ':syntax';
    use Plack::Handler::FCGI;

    my $app = do "/path/to/kliq.pl";
    my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);
    $server->run($app);

Here is an example lighttpd config. It assumes you named the above file kliq.fcgi.

    fastcgi.server += (
        "/" => ((
            "socket" => "/tmp/fcgi.sock",
            "check-local" => "disable",
            "bin-path" => "/path/to/kliq.fcgi",
        )),
    )

Now Kliq will be running via FastCGI under /.

=head2 Plack

Kliq can be run with any L<Plack> web server.  Just run:

    $ plackup bin/kliq.pl

You can change the Plack web server via the -s option to plackup.

=head1 CONTRIBUTING

This module is developed in a KLIQ repo at Assembla:

L<https://www.assembla.com/code/kliq-m/git-7/repo/instructions?empty=true>

Feel free to fork the repo and submit pull requests!

  git clone git@git.assembla.com:kliq-m.kliq-api.git

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc lib/Kliq

=head2 Website

L<http://tranzmt.it>

=head2 Email

You can email the author of this module at C<techie at sitetechie.com> asking 
for help with any problems you have.

=head1 AUTHOR

Peter de Vos <peter@sitecorporation.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by KLIQ Mobile, LLC.

=cut
