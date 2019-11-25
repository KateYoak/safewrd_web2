package Kliq;

use strict;
use warnings;
use 5.010;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Email;
use Dancer::Plugin::REST;
use Dancer::Plugin::Redis;
use Dancer::Plugin::UUID;
use REST::Client;
use JSON::WebToken;
use MIME::Base64;
use Digest::HMAC_SHA1 'hmac_sha1_hex';
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
use Email::SendGrid::V3;

use Kliq::Model::ZencoderOutput;

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use JSON;

set serializer => 'JSON';
set logger     => 'log_handler';

our $VERSION = '0.001';
our $DEBUG = 0;

my $UG = new Data::UUID;
my $MT = MIME::Types->new;

#------ init -------------------------------------------------------------------

hook 'before' => sub {
    #$DB::single = 2;

    # Modify name of process
    $0 = join(' ', 'kliq worker', request->method, request->path);
    my $domain = request->host;
    $domain =~ s/:.*$//;
    $domain =~ s/^(.*)\.(.*)\.(.*)$/$2\.$3/g;
    var domain => $domain;

    header('Cache-Control' => 'no-store, no-cache, must-revalidate');
    header('Access-Control-Allow-Methods' => ['GET','POST','PUT','DELETE','OPTIONS']);

error('Got request ' . request->path . ' with session id ' . session('user_id'));

    #-- find user
    my $user = undef;
    if (session('user_id')) {
        $user = schema->resultset('User')->find(session('user_id'));
=pod
        unless($user) {
            var error => "Invalid user " . session('user_id') . " (stale cookie?)";
            request->path_info('/error');
            return;
        }
=cut
        if ($user) {
            var user => $user;
        }
    }
    elsif($DEBUG || params->{debug}) {
        my $uid = params->{user} || '94A4988D-93F8-1014-A991-F7EDC84F2656';
        $user = schema->resultset('User')->find($uid);
        var user => $user;
        session user_id => vars->{user}->id;
    }

    #-- set domain referer for postMessage
    
    # this assumes http, but what if some idiot app uses a non-standard referrer like android-app://com.Slack, I'm looking at you slack
    if(request->referer) {
        my $ref = URI->new(request->referer);
        # print STDERR Dumper( $ref );
        if ($ref->isa('URI::_foreign')) { #handle non-http uris
            session referer_domain => 'http://m.tranzmt.it';
        }
        else {
            session referer_domain 
                => 'http://' . ($ref->port == 80 ? $ref->host : $ref->host_port);
        }
    }
    else {
        session referer_domain => 'http://m.tranzmt.it';
    }

    ## development & testing
    if(request->path =~ '^/(v1/upload|v1/zencoded|v1/cors|v1)?$') {
        return;
    }
    elsif(request->path =~ '^/v1/email_whitepaper$') {
        return;
    }
    elsif(request->path =~ '^/v1/delete_user$') {
        return;
    }
    elsif(request->path =~ '^/v1/merge_users$') {
        return;
    }
    elsif(request->path =~ '^/v1/chat_user_friends$') {
        return;
    }
    elsif(request->path =~ '^/v1/verify_kliq_owner$') {
        return;
    }
    elsif(request->path =~ '^/v1/notify_contact_joined$') {
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
    elsif(request->path =~ '^/v1/webhook') {
        # let chatbot api handle this
        return;
    }
    elsif(request->path =~ '^/v1/rtmp_url') {    
        return;
    }
    elsif(request->path =~'^/v1/ambassador') {
        return; #this is currently in Chatbot
    }
    elsif(!$user) {
        request->path_info('/error/unauthorized');
    }
};

hook after => sub {
  # reset process name once finished
  $0 = 'kliq worker (idle)';
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

    my $credit = eval { sprintf(q{%.2f}, 0.0 + $user->eos_balance) };
    
    content_type 'application/json';
    return to_json({ uid => session('user_id'), drone_enabled => $user->drone_enabled, aireos_credit => $credit, aireos_user_id => $user->aireos_user_id });    
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

post '/update_swrve_user_id' => sub {
    my $args = dejsonify(body_params());
    my $user_id       = $args->{user_id} || session('user_id');
    my $swrve_user_id = $args->{swrve_user_id};

    my $success = 0;
    my $error = '';
    if ($user_id && $swrve_user_id) { 
        my $user = schema->resultset('User')->find({ id => $user_id });
        if ($user) {
            $user->update({
                swrve_user_id => $swrve_user_id
            });
            $success = 1;
        }
        else {
            $error = 'Could not find user with that user_id';
        }
    }
    else {
        $error = 'Missing user_id/swrve_user_id';
    }

    if ($success) { 
        content_type 'application/json';
        return to_json({ success => 1 });
    }
    else {
        content_type 'application/json';
        return to_json({ success => 0, error => $error });
    }
};

post '/merge_users' => sub {
    my $args = dejsonify(body_params());
    my $from_user_id = $args->{chat_id};
    my $kliq_id      = $args->{kliq_id};
    my $to_user_id   = $args->{app_user_id} || session('user_id');
    my $type         = $args->{type};

error('Got request to merge users. ' . $from_user_id . ' to ' . $to_user_id . ' - type - ' . $type, ' - kliq - ' . $kliq_id);

    my $kliq = schema->resultset('Kliq')->search({
        id => $args->{kliq_id}
    })->single();
    if (!$kliq) {
        return status_bad_request("Invalid kliq_id");
    }

    my $kliq_owner_user_id = $kliq->user_id;
    my $owner_persona = schema->resultset('Persona')->search({
        user_id => $kliq_owner_user_id,
    })->single();

    my $response = {};
    if ($type && $type eq 'friend') {
        # chat_id is contact_id. Add app_user_id to contact
        my $contact = schema->resultset('Contact')->find({ id => $from_user_id });
        if ($contact) {
            $contact->update({ user_id => $to_user_id });
            $response = { success => 1, user_id => $to_user_id };

            # Merge is done. Send push notifications
            my $member_persona = schema->resultset('Persona')->search({
                user_id => $to_user_id,
            })->single();

            # Send in-app messages
            my $request_hash_owner = {
                type => 'in-app',
                payload => {
                    user_id               => $kliq_owner_user_id,
                    notification_title    => $member_persona->name . " joined your Safety Group",
                    message               => $member_persona->name . " has just joined your Safety Group.",
                    type                  => "text_message",
                    action                => 'contact_joined_kliq_group',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    kliq_owner_user_id    => $kliq_owner_user_id,
                    kliq_contact_user_id  => $to_user_id,
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_owner));

            my $request_hash_member = {
                type => 'in-app',
                payload => {
                    user_id               => $to_user_id,
                    notification_title    => "You are officially in " . $owner_persona->name . "'s emergency Safety Group",
                    message               => "You are officially in " . $owner_persona->name . "'s emergency Safety Group, so if they are ever in trouble and they say their 'Safe word' you will be the first to know by getting an emergency live video stream.",
                    type                  => "text_message",
                    action                => 'contact_joined_kliq_group',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    kliq_owner_user_id    => $kliq_owner_user_id,
                    kliq_contact_user_id  => $to_user_id,
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_member));
        }
        else {
            $response = { success => 0, error => 'Invalid chat owner id. Could not find that contact' };
        }
    }
    else {
        my $to_user = schema->resultset('User')->find({ id => $to_user_id });
        my $from_user = schema->resultset('User')->find({ id => $from_user_id });
        if (!$to_user) {
            $response = { success => 0, error => 'Invalid app user id. Could not find that user' };

        }
        elsif (!$from_user) {
            $response = { success => 0, error => 'Invalid chat id. Could not find that user' };
        }
        elsif ($to_user->merged_chat_user_id) {
            $response = { success => 0, error => 'This user has already been merged' };
        }
        else {
            # All good. Merge users. chat_id is user_id
            my $final_user_id = model('tokens')->merge_user($to_user_id, $from_user_id, 1);
            if ($final_user_id) { 
                $response = { success => 1, user_id => $final_user_id };

                # Owner joined. Send all friends push notification
                my $kliq_contacts = schema->resultset('KliqContact')->search({
                    kliq_id => $kliq_id
                });
                while (my $kliq_contact = $kliq_contacts->next) {
                    my $contact = schema->resultset('Contact')->find({
                        id => $kliq_contact->contact_id, 
                    });

                    next if !$contact->user_id;

                    my $request_hash_member = {
                        type => 'in-app',
                        payload => {
                            user_id               => $contact->user_id,
                            notification_title    => "You are officially in " . $owner_persona->name . "'s emergency Safety Group",
                            message               => "You are officially in " . $owner_persona->name . "'s emergency Safety Group, so if they are ever in trouble and they say their 'Safe word' you will be the first to know by getting an emergency live video stream.",
                            type                  => "text_message",
                            action                => 'contact_joined_kliq_group',
                            badge                 => 1,
                            sound                 => "flare.wav",
                            kliq_owner_user_id    => $kliq_owner_user_id,
                            kliq_contact_user_id  => $contact->user_id,
                        },
                    };
                    redis->rpush(notifyPhone => to_json($request_hash_member));
                }
            }
            else {
                $response = { success => 0, error => 'Invalid chat owner id. Could not find that user' };
            }
        }
    }

error('Response: ' . Dumper($response));

    content_type 'application/json';
    return to_json($response);
};

post '/verify_kliq_owner' => sub {
    my $owner_id = params->{owner_id} || session('user_id');

    error('Got request to verify kliq owner: ' . $owner_id);
    my $verify_pin = schema->resultset('Kliq')->search({
        id      => params->{kliq_id},
        user_id => $owner_id,
        verification_pin => params->{verification_pin},
    })->single();

    my $verified = 0;
    $verified = 1 if $verify_pin;

    error('Verification response: ' . $verified);

    content_type 'application/json';
    return to_json({ verified => $verified });
};

get '/chat_user_friends' => sub {
    my $kliq_id = params->{kliq_id};

    my $friends = [];
    my $kliq = schema->resultset('Kliq')->find({
        id => $kliq_id
    });
    if ($kliq) {
        my $user = schema->resultset('User')->search({
            id => $kliq->user_id
        })->single;
        my $persona = schema->resultset('Persona')->search({
            user_id => $kliq->user_id
        })->single;
        push(@{$friends}, {
            type    => 'owner',
            chat_id => $user->id,
            name    => 'Safety Group Owner',
            profile_pic_url => $persona->profile_url,
            is_authorized => (defined $user->merged_chat_user_id ? 1 : 0),
        });
 
        # Add friends
        my $kliq_contacts = schema->resultset('KliqContact')->search({
            kliq_id => $kliq_id
        });
        while (my $kliq_contact = $kliq_contacts->next) {
            my $contact = schema->resultset('Contact')->find({
                id => $kliq_contact->contact_id, 
            });
            if ($contact) {
                push(@{$friends}, {
                    type    => 'friend',
                    chat_id => $contact->id,
                    name    => $contact->name,
                    profile_pic_url => $contact->image,
                    is_authorized => (defined $contact->user_id ? 1 : 0),
                });
            }
        }
    }

    content_type 'application/json';
    return to_json($friends);
};

post '/delete_user' => sub {
    my $user_id = params->{user_id};
    if (!$user_id) {
        my $persona = schema->resultset('Persona')->search({
           email => params->{email}
        })->single();
        $user_id = $persona->user_id if $persona;
    }

    my $user;
    if ($user_id) {
        $user = schema->resultset('User')->search({ id => $user_id })->single();
    }

    my $response = {};
    if ($user) {
        # Delete user details
        for my $table(qw/OauthToken Contact Event Kliq Upload Share Comment Persona CmsMedia/) {
            my $rs = schema->resultset($table)->search({ user_id => $user_id });
            while (my $rec = $rs->next) {
                $rec->delete();
            }
        }

        my $contacts = schema->resultset('Contact')->search({ owner_id => $user_id });
        while (my $rec = $contacts->next) {
            $rec->delete();
        }

        schema->resultset('User')->find($user_id)->delete();
        $response = { success => 1 };
    }
    else { 
        $response = { success => 0, error => 'Could not find that user' };
    }

    content_type 'application/json';
    return to_json($response);
};

get '/contacts_summary' => sub {
    my $summary = {};
    if (session('user_id')) {
        my $contacts_summary = schema->resultset('Contact')->search(
            {
                owner_id => session('user_id') 
            },
            {
                select   => [ 'service', { count => 'id' } ],
                as       => [qw/service cnt/],
                group_by => [qw/service/] 
            });
        while (my $row = $contacts_summary->next) {
            $summary->{$row->service} = $row->get_column('cnt');
        }
    }
    else {
        request->path_info('/error/unauthorized');
    }

    content_type 'application/json';
    return to_json($summary);
};

post '/email_whitepaper' => sub {
    my $args = dejsonify(body_params());

    # SendGrid api key. TODO: Move this to config.
    my $api_key     = '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';
    my $template_id = 'd-64c723e5061b480eae197d45758ef112';
    my $from_email  = 'info@aireos.io';

    my $response = {};
    if ($args->{email}) {
        my $sg     = Email::SendGrid::V3->new(api_key => $api_key);
        my $result = $sg->from($from_email)->template_id($template_id)->add_envelope(to => [ $args->{email} ])->send;
        if ($result->{success}) {
            $response = { success => 1 };
        }
        else {
            $response = { success => 0, error_message => $result->{reason} };
        }
    }
    else {
        $response = { success => 0, error_message => 'Missing email param' };
    }

    content_type 'application/json';
    header('Access-Control-Allow-Origin' => '*');
    return to_json($response);
};

get '/archives' => sub {
    my @archives = ();
    my $base_path = "/var/opt/clqs-api/media/archives";
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
        my @event_ids;
        while (my $event = $events->next) {
            next if (grep { $event->id eq $_ } @event_ids);
            push(@event_ids, $event->id);
            my $filename = $base_path . "/" . $event->id . ".flv";
            if (-e $filename) {
                my $archive_url = $archive_url_base . "/" . $event->id;

                my $event_type = 'live_event';
                if ($event->event_status eq 'test') {
                    $event_type = "emergency_test_flare";
                }
                elsif ($event->kliq->is_emergency) {
                    $event_type = "emergency_flare";
                }

                push(@archives, { event_id => $event->id, user_id => $event->user_id, event_title => $event->title, event_type => $event_type, location => $event->location, archive_url => $archive_url });
            }    
        }  
    }
    else {
        request->path_info('/error/unauthorized');
    }

    content_type 'application/json';
    return to_json(\@archives);
};

get '/rtmp_url' => sub {
    my $load_balancer_endpoint = URI->new('http://receiver.tranzmt.it:3030/freeserver');
    my $ua = LWP::UserAgent->new();
    my $response = $ua->get($load_balancer_endpoint->canonical);

    if($response->is_success()) {
        my $content  = $response->decoded_content();
        my $route    = from_json($content);
        my $rtmp_url = URI->new('rtmp://' . $route->{'ip'} . ':1935/live');
        content_type 'application/json';
        return to_json({
            rtmp_url => $rtmp_url->canonical,
        });
    }
    else {
        var error => 'resource unavailable, please retry';
        request->path_info('/error');
    }

};

post '/notify_video_view' => sub {
    my $args = dejsonify(body_params());

    if ($args->{stream_owner_user_id} && $args->{stream_viewer_user_id}) {
        my $owner_persona = schema->resultset('Persona')->search({
            user_id => $args->{stream_owner_user_id},
            service => 'google'
        })->single();
        my $viewer_persona = schema->resultset('Persona')->search({
            user_id => $args->{stream_viewer_user_id},
            service => 'google'
        })->single();

        if ($owner_persona && $viewer_persona) {
            # Send in-app messages
            my $request_hash_owner = {
                type => 'in-app',
                payload => {
                    user_id               => $args->{stream_owner_user_id},
                    notification_title    => $viewer_persona->name . " watched your Video Test",
                    message               => $viewer_persona->name . " have just confirmed they watched your emergency Flare video test.",
                    type                  => "text_message",
                    action                => 'test_video_viewed',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    stream_owner_user_id  => $args->{stream_owner_user_id},
                    stream_viewer_user_id => $args->{stream_viewer_user_id},
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_owner));

            my $request_hash_viewer = {
                type => 'in-app',
                payload => {
                    user_id               => $args->{stream_viewer_user_id},
                    notification_title    => "You are officially in " . $owner_persona->name . "'s emergency Flare group",
                    message               => "You are officially in " . $owner_persona->name . "'s emergency Flare group, so if they are ever in trouble and they say their 'Safe word' you will be the first to know by getting an emergency live video stream.",
                    type                  => "text_message",
                    action                => 'test_video_viewed',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    stream_owner_user_id  => $args->{stream_owner_user_id},
                    stream_viewer_user_id => $args->{stream_viewer_user_id},
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_viewer));
        }
        else {
            return status_bad_request("Invalid stream_owner_user_id/stream_viewer_user_id");
        }

        status_ok({ success => 1 });
    }
    else {
        return status_bad_request("Missing params stream_owner_user_id/stream_viewer_user_id");
    }
};

post '/notify_contact_joined' => sub {
    my $args = dejsonify(body_params());

    if ($args->{kliq_id} && $args->{kliq_contact_user_id}) {
        my $kliq = schema->resultset('Kliq')->search({
            id => $args->{kliq_id}
        })->single();
        if (!$kliq) {
            return status_bad_request("Invalid kliq_id");
        }

        my $kliq_owner_user_id = $kliq->user_id;
        my $owner_persona = schema->resultset('Persona')->search({
            user_id => $kliq_owner_user_id,
        })->single();
        my $member_persona = schema->resultset('Persona')->search({
            user_id => $args->{kliq_contact_user_id},
        })->single();

        if ($owner_persona && $member_persona) {
            # Send in-app messages
            my $request_hash_owner = {
                type => 'in-app',
                payload => {
                    user_id               => $kliq_owner_user_id,
                    notification_title    => $member_persona->name . " joined your Safety Group",
                    message               => $member_persona->name . " has just joined your Safety Group.",
                    type                  => "text_message",
                    action                => 'contact_joined_kliq_group',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    kliq_owner_user_id    => $kliq_owner_user_id,
                    kliq_contact_user_id  => $args->{kliq_contact_user_id},
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_owner));

            my $request_hash_member = {
                type => 'in-app',
                payload => {
                    user_id               => $args->{kliq_contact_user_id},
                    notification_title    => "You are officially in " . $owner_persona->name . "'s emergency Safety Group",
                    message               => "You are officially in " . $owner_persona->name . "'s emergency Safety Group, so if they are ever in trouble and they say their 'Safe word' you will be the first to know by getting an emergency live video stream.",
                    type                  => "text_message",
                    action                => 'contact_joined_kliq_group',
                    badge                 => 1,
                    sound                 => "flare.wav",
                    kliq_owner_user_id    => $kliq_owner_user_id,
                    kliq_contact_user_id  => $args->{kliq_contact_user_id},
                },
            };
            redis->rpush(notifyPhone => to_json($request_hash_member));
        }
        else {
            return status_bad_request("Invalid kliq_id/kliq_contact_user_id");
        }

        status_ok({ success => 1 });
    }
    else {
        return status_bad_request("Missing params kliq_id/kliq_contact_user_id");
    }
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
    #print STDERR Dumper { params };
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
    shares => { -desc => 'created' },
    tokens => { -desc => 'created' },
    uploads => { -desc => 'created' },
    events  => { -desc => 'created' },
    #timeline => { -desc => 'created' },
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

# EBANX routines
post '/purchase' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my $user = schema->resultset('User')->find({ id => session('user_id') });
    unless($user) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-1",
            status_message => "Invalid user, user with such ID is not found"
        });
    }

    my $payment = schema->resultset('Payment')->create({
            user_id =>  $user->id,
            payment_type => "money",
            cost => config->{subscription}->{amount}
    });        

    unless($payment) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-2",
            status_message => "Cannot create payment for user " . $user->id . " with cost $req->{amount_total}"
        });
    }

    my $data = {
        integration_key => config->{sites}->{ebanx}->{key},
        operation => "request",
        payment => {
            merchant_payment_code => $payment->id,
            amount_total => config->{subscription}->{amount},
            currency_code => config->{subscription}->{currency},
            name => $req->{name},
            email => $req->{email},
            birth_date => $req->{birth_date},
            document => $req->{document},
            address => $req->{address},
            street_number => $req->{street_number},
            street_complement => $req->{street_complement},
            city => $req->{city},
            state => $req->{state},
            zipcode => $req->{zipcode},
            country => $req->{country},
            phone_number => $req->{phone_number},
            payment_type_code => $req->{payment_type_code}
        }
    };
    if ($req->{payment_type_code} ne "boleto") {
        $data->{payment}->{creditcard} = {
            card_number => $req->{card_number},
            card_name => $req->{card_name},
            card_due_date => $req->{card_due_date},
            card_cvv => $req->{card_cvv}
        };
    }
    my $client = REST::Client->new();
    $client->addHeader('Content-Type', 'application/json');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');

    $client->POST('https://' . config->{sites}->{ebanx}->{host} . '.ebanx.com/ws/direct', to_json($data));
    if ($client->responseCode() =~ /^5\d{2}$/) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-3",
            status_message => "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]"
        });
    }

    if ($client->responseCode() == 403) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-4",
            status_message => "Server / Endpoint URL Failure, Error: [Auth failed]"
        });
    }

    my $response = from_json($client->responseContent());
    if ($response->{status} eq "ERROR" || $response->{status} eq "SUCCESS") {
        $payment->update({
            transaction_id => $response->{payment}->{hash} || '',
            status => $response->{payment}->{status} || $response->{status}
        });
        if ($response->{payment}->{status} eq "CO") {
            $user->update({
                paid => 1,
                paid_before => \'NOW()'
            });
        }
    }

    return to_json($response);
};

post '/orderStatus' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my $payment = schema->resultset('Payment')->find({ transaction_id => $req->{transactionId} });
    unless($payment) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-2",
            status_message => "Cannot find payment with such transaction id $req->{transactionId}"
        });
    }

    my $client = REST::Client->new();
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');


    $client->GET("https://" . config->{sites}->{ebanx}->{host} . ".ebanx.com/ws/query?integration_key=" . config->{sites}->{ebanx}->{key} . "&hash=$req->{transactionId}");
    if ($client->responseCode() =~ /^5\d{2}$/) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-3",
            status_message => "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]"
        });
    }

    if ($client->responseCode() == 403) {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-4",
            status_message => "Server / Endpoint URL Failure, Error: [Auth failed]"
        });
    }

    my $response = from_json($client->responseContent());
    if ($response->{status} eq "ERROR" || $response->{status} eq "SUCCESS") {
        $payment->update({
            status => $response->{payment}->{status} || $response->{status}
        });
        if ($response->{payment}->{status} eq "CO") {
            my $user = schema->resultset('User')->find({ id => $payment->user_id });
            if ($user->paid == 0) {
                $user->update({
                    paid => 1,
                    paid_before => \'NOW()'
                });
            }
        }
    }

    return to_json($response);
};

# google payments
post '/checkSubscription' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my $servicetoken = schema->resultset('ServiceToken')->find({ service => "google", clientid => config->{sites}->{google}->{dev}->{clientid} });
    if ($servicetoken) {
        if ($servicetoken->expire < time.now()) {
            my $client = REST::Client->new();
            $client->addHeader('Content-Type', 'application/x-www-form-urlencoded');
            $client->addHeader('charset', 'UTF-8');
            $client->addHeader('Accept', 'application/json');

            $client->POST('https://accounts.google.com/o/oauth2/token', "grant_type=refresh_token&refresh_token=" . $servicetoken->refresh_token . "&client_id=" . config->{sites}->{google}->{dev}->{clientid} . "&client_secret=" . config->{sites}->{google}->{dev}->{secret});
            if ($client->responseCode() =~ /^5\d{2}$/) {
                return status_bad_request("Google returned 500 error on update");
            }

            if ($client->responseCode() == 403) {
                return status_bad_request("Google returned 403 error on update");
            }

            my $response = from_json($client->responseContent());
            if ($response->{access_token}) {
                $servicetoken->update({
                    accesstoken => $response->{access_token},
                    expire => \"DATE_ADD(NOW(),INTERVAL $response->{expires_id} SECOND)"
                });
            }
        }
        my $client = REST::Client->new();
        $client->addHeader('charset', 'UTF-8');
        $client->addHeader('Accept', 'application/json');
        $client->GET("https://www.googleapis.com/androidpublisher/v2/applications/" . config->{sites}->{google}->{dev}->{packagename} . "/purchases/subscriptions/" . config->{sites}->{google}->{dev}->{subscriptionid} . "/tokens/" . $req->{token}, "access_token=" . $servicetoken->access_token);
        if ($client->responseCode() =~ /^5\d{2}$/) {
            return status_bad_request("Google returned 500 error on update");
        }

        if ($client->responseCode() == 403) {
            return status_bad_request("Google returned 403 error on update");
        }

        my $response = from_json($client->responseContent());
        return to_json($response);
    } else {
        return to_json({
            status => "ERROR",
            status_code => "KLIQ-INT-1",
            status_message => "No service token found in DB for clientid"
        });
    }
};

post '/start_videochat' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my ($sessionID, $error) = _create_session();
    unless ($sessionID) {
        my $data = {
            success => 0,
            error   => $error
        };
        return to_json($data);
    }

    my $tokenPub = _generate_token("publisher",$sessionID);

    my $users = schema->resultset('KliqContact')->search(
    {
        kliq_id => $req->{kliq_group_id}
    });
    while (my $row = $users->next) {
        my $contactID = $row->get_column('contact_id');
        my $tokenSub = _generate_token("publisher",$sessionID,$contactID);
        my $contact = schema->resultset('Contact')->find($contactID);
        redis->rpush(notifyPhone => to_json({
            type => 'push',
            payload => {
                user_id               => $contact->user_id,
                notification_title    => "Citizen Witness Emergency - incoming live video chat",
                message               => "Citizen Witness Emergency - incoming live video chat",
                type                  => "text_message",
                action                => 'emergency_CW',
                badge                 => 1,
                sound                 => "flare.wav",
                location  => $req->{location},
                session_id => $sessionID,
                token => $tokenSub,
                app_key => config->{sites}->{tokbox}->{key} 
            },
        }));
    }

    my $data = {
        success                => 1,
        session_id             => $sessionID,
        token                  => $tokenPub,
        app_key                => config->{sites}->{tokbox}->{key}
    };

    return to_json($data);
};

post '/passphrase' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);
    my $res = {};

    my $user = schema->resultset('User')->find({ id => session('user_id') });
    unless($user) {
        var error => "Invalid user " . session('user_id') . " (stale cookie?)";
        request->path_info('/error');
        return;
    }

    my $passphrases = schema->resultset('PassPhrase')->search(
    {
        passphrase => $req->{passphrase}
    });

    my $row = $passphrases->next;
    unless ($row) {
        my $client = REST::Client->new();
        my $data = [
            {
                value => $req->{passphrase},
                synonyms => [
                    $req->{passphrase}
                ]
            }
        ];
        $client->addHeader('Content-Type', 'application/json');
        $client->addHeader('charset', 'UTF-8');
        $client->addHeader('Accept', 'application/json');
        $client->addHeader('Authorization', 'Bearer ' . config->{sites}->{apiai}->{devkey});

        $client->POST('https://api.api.ai/v1/entities/' . config->{sites}->{apiai}->{entity_id} . '/entries', to_json($data));

        if ($client->responseCode() =~ /^5\d{2}$/) {
            $res->{success} = JSON::false;
            $res->{message} = "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]";
        }

        if ($client->responseCode() == 403) {
            $res->{success} = JSON::false;
            $res->{message} = "Server / Endpoint URL Failure, Error: [Auth failed]";
        }

        my $response = from_json($client->responseContent());
        if ($response->{status}->{errorType} == "success") {
            $res->{success} = JSON::true;
        } else {
            $res->{success} = JSON::false;
            $res->{message} = $response->{status}->{errorDetails};
        }

        my $passphrase = schema->resultset('PassPhrase')->create({
            passphrase =>  $req->{passphrase}
        });        
    }

    return to_json($res);
};

get '/contacts_test' => sub {
    content_type 'application/json';
    my $contacts = schema->resultset('Contact')->search(undef, { rows => 5000 });
    return to_json($contacts);
};

get '/webhook/ebanx' => sub {
    return status_ok({ message => "OK" });
};

post '/webhook/ebanx' => sub {
    my $req = request->params;

    if ($req->{hash_codes}) {
        my @hashCodes = split(",",$req->{hash_codes});
        foreach my $hash (@hashCodes) {
            my $payment = schema->resultset('Payment')->find({ transaction_id => $hash });
            if ($payment) {
                my $client = REST::Client->new();
                $client->addHeader('charset', 'UTF-8');
                $client->addHeader('Accept', 'application/json');

                $client->GET('https://' . config->{sites}->{ebanx}->{host} . '.ebanx.com/ws/query?integration_key=' . config->{sites}->{ebanx}->{key} . "&hash=$hash");
                if ($client->responseCode() =~ /^5\d{2}$/) {
                    return status_bad_request("EBANX query returned 500 error");
                }
                if ($client->responseCode() == 403) {
                    return status_bad_request("EBANX query returned 403 error");
                }

                my $response = from_json($client->responseContent());
                if ($response->{status} eq "ERROR" || $response->{status} eq "SUCCESS") {
                    $payment->update({
                        status => $response->{payment}->{status} || $response->{status}
                    });
                    if ($response->{payment}->{status} eq "CO") {
                        my $user = schema->resultset('User')->find({ id => $payment->user_id });
                        $user->update({
                            paid => 1,
                            paid_before => \'NOW()'
                        });
                    }
                }
            } else {
                return status_bad_request("EBANX sent unknown hash: $hash");
            }
        }
    } else {
        return status_ok({ message => "OK" });
        return status_bad_request("EBANX sent no hashes");
    }
    return status_ok({ message => "OK" });
};

get '/webhook/googleauth' => sub {
    my $req = request->params;

    if ($req->{code}) {
        my $client = REST::Client->new();
        $client->addHeader('Content-Type', 'application/x-www-form-urlencoded');
        $client->addHeader('charset', 'UTF-8');
        $client->addHeader('Accept', 'application/json');

        $client->POST('https://accounts.google.com/o/oauth2/token', "grant_type=authorization_code&code=$req->{code}&client_id=" . config->{sites}->{google}->{dev}->{clientid} . "&client_secret=" . config->{sites}->{google}->{dev}->{secret} . "&redirect_uri=");
        if ($client->responseCode() =~ /^5\d{2}$/) {
            return status_bad_request("Google returned 500 error");
        }

        if ($client->responseCode() == 403) {
            return status_bad_request("Google returned 403 error");
        }

        my $response = from_json($client->responseContent());
        if ($response->{access_token} && $response->{update_token}) {
            my $servicetoken = schema->resultset('ServiceToken')->find({ service => "google", clientid => config->{sites}->{google}->{dev}->{clientid} });
            if ($servicetoken) {
                $servicetoken->update({
                    accesstoken => $response->{access_token},
                    updatetoken => $response->{update_token},
                    expire => \"DATE_ADD(NOW(),INTERVAL $response->{expires_id} SECOND)"
                });
            } else {
                my $passphrase = schema->resultset('ServiceToken')->create({
                    service => "google",
                    clientid => config->{sites}->{google}->{dev}->{clientid},
                    accesstoken => $response->{access_token},
                    updatetoken => $response->{update_token},
                    expire => \"DATE_ADD(NOW(),INTERVAL $response->{expires_id} SECOND)"
                });
            }
            return status_ok({ message => "Tokens has been set" });
        } else {
            return status_bad_request("Google didnt return tokens");
        }
    } else {
        return status_bad_request("Google sent no code");
    }
};

sub _create_session {
    my $client = REST::Client->new();

    $client->addHeader('Content-Type', 'application/x-www-form-urlencoded');
    $client->addHeader('charset', 'UTF-8');
    $client->addHeader('Accept', 'application/json');
    $client->addHeader('X-OPENTOK-AUTH', _jwt());

    $client->POST('https://api.opentok.com/session/create', "archiveMode=always&location=&p2p.preference=disabled");
    if ($client->responseCode() =~ /^5\d{2}$/) {
        return (undef, "Server / Endpoint URL Failure, Error: [" . $client->responseCode() . "]")
    }

    if ($client->responseCode() == 403) {
        return (undef, "Server / Endpoint URL Failure, Error: [Auth failed]")
    }

    my $response = from_json($client->responseContent());
    if ($response->[0]->{session_id}) {
        return ($response->[0]->{session_id}, undef);
    }

    return (undef, "Server / Endpoint URL Failure, Error: [No session ID returned]")
}

sub _generate_token {
    my $role = shift;
    my $sessionID = shift;
    my $contactID = shift;

    my $data = {
        session_id             => $sessionID,
        create_time            => time,
        expire_time            => time + 24*60*60,
        role                   => $role,
        nonce                  => $contactID . "_" . time . "_". int(rand(999)),
    };
    print Dumper($data);

    my $uri = URI->new();
    $uri->query_form($data);
    my $payload = substr($uri,1);
    my $sig = hmac_sha1_hex($payload, config->{sites}->{tokbox}->{secret});

    my $token = "T1==" . encode_base64("partner_id=" . config->{sites}->{tokbox}->{key} . "&sig=$sig:$payload");
    $token =~s/\n//g;
    return $token;
}

sub _jwt {
    return JSON::WebToken->encode({
        iss => config->{sites}->{tokbox}->{key},
        iat => time,
        exp => time + 180,
        ist => "project",
        jti => uuid
    }, config->{sites}->{tokbox}->{secret}, 'HS256');
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

get '/subscriptions/status' => sub {
    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    my $response = { active => 0 };
    my $recurly_response;
    try {
        $recurly_response = make_recurly_request('GET', "/accounts/" . $user_id . "/subscriptions");
    }
    catch {
        error('Failed to fetch subscription: ' . $_);
        $response = { error => 'Failed to fetch subscription' };
    };
error('resonse: ' . Dumper($recurly_response));
    if (ref $recurly_response eq 'HASH' && $recurly_response->{subscription}) {
        if (ref $recurly_response->{subscription} eq 'HASH') {
            if ($recurly_response->{subscription}->{state} eq 'active') {
                $response->{active} = 1;
            } 
        }
        elsif (ref $recurly_response->{subscription} eq 'ARRAY') {
            for my $subscription (@{$recurly_response->{subscription}}) {
                if ($subscription->{state} eq 'active') {
                    $response->{active} = 1;
                    last;
                }
            }
        }
    }

    content_type 'application/json';
    return to_json($response);
};

get '/subscriptions' => sub {
    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    my $response = {};
    my $recurly_response;
    try {
        $recurly_response = make_recurly_request('GET', "/accounts/" . $user_id . "/subscriptions");
    }
    catch {
        error('Failed to fetch subscription: ' . $_);
        $response = { error => 'Failed to fetch subscription' };
    };

    if (ref $recurly_response eq 'HASH') {
        for my $subscription (@{$recurly_response->{subscription}}) {
            next if $subscription->{state} ne 'active';

            $response = {
                plan => $subscription->{plan}->{name},
                plan_code => $subscription->{plan}->{plan_code},
                current_term_ends_at => $subscription->{current_term_ends_at}->{content},
            };
            if ($subscription->{trial_ends_at}) {
                $response->{trial_ends_at} = $subscription->{trial_ends_at}->{content};
            }

            last; # Only one subscription for a user 
        }
    }

    content_type 'application/json';
    return to_json($response);
};

post '/subscriptions/terminate' => sub {
    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    my $response = {};
    my $recurly_response;
    my @recurly_subscription_ids;;
    try {
        $recurly_response = make_recurly_request('GET', "/accounts/" . $user_id . "/subscriptions");
        if (ref $recurly_response eq 'HASH') {
            for my $subscription (@{$recurly_response->{subscription}}) {
                next if $subscription->{state} ne 'active';
                push(@recurly_subscription_ids, $subscription->{uuid});
            }
        }
    }
    catch {
        error('Failed to fetch subscription: ' . $_);
        $response = { error => 'Failed to fetch subscription for that user' };
    };

    # Cancel all subscriptions
    if (scalar(@recurly_subscription_ids)) {
        try {
            for my $recurly_subscription_id (@recurly_subscription_ids) {
                $response = make_recurly_request('PUT', "/subscriptions/" . $recurly_subscription_id . "/terminate");
                if (ref $response eq 'HASH' && $response->{state} eq 'expired') {
                    $response = { success => 1 };
                }
                else {
                    $response = { error => 'Failed to cancel subscription' };
                } 
            }
        }
        catch {
            error('Failed to cancel subscription: ' . $_);;
        };
    }
    else {
        $response = { error => 'There are no active subscriptions for this user' };
    }

    content_type 'application/json';
    return to_json($response);
};

post '/subscriptions' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    #FIXME: This shouldn't just pick google
    my $persona = schema->resultset('Persona')->search({
        user_id => $user_id,
        service => 'google',
    })->single();
    my @names = split(/\s+/, $persona->name);
    my $first_name = shift(@names);
    my $last_name = join(' ', @names);
    my $content_hash = {
        subscription => {
            plan_code => $req->{plan_code},
            currency => 'USD',
            account => {
                account_code => $user_id,
                email        => $persona->email,
                first_name   => $first_name,
                last_name    => $last_name,
                billing_info => {
                    number   => $req->{card_number},
                    month    => $req->{expiry_month},
                    year     => $req->{expiry_year},
                    address1 => $req->{address},
                    city     => $req->{city},
                    state    => $req->{state},
                    zip      => $req->{zip},
                    country  => $req->{country},
                },
            },
            auto_renew => 'true',
        },
    };

    my $response = {};
    try {
        my $request_xml = XMLout($content_hash, NoAttr => 1, RootName => undef);
        $response = make_recurly_request('POST', "/subscriptions", $request_xml);
    }
    catch {
        error('Failed to create payment subscription: ' . $_);;
    };

    if (ref $response eq 'HASH' && $response->{uuid} && $response->{state} eq 'active') {
        $response = { success => 1 };
    }
    else {
        error('Failed to create payment subscription: ' . Dumper($response));

        my $error = 'Failed to create subscription';
        if (ref $response eq 'HASH' && $response->{error}) {
            $error = $response->{error}->{content};
        }

        $response = { success => 0, error => $error };
    }

    content_type 'application/json';
    return to_json($response);
};

post '/enable_drone' => sub {
    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    #TODO: Confirm that the user has a subscription

    my $response = {};

=pod
#Commented out just to avoid last minute changes before demo
    if (defined $user->aireos_user_id) {
        # Aireos user exists. Set drone enabled in DB.
        $user->update({
            drone_enabled  => 1,
        });

        $response = { success => 1 };
        content_type 'application/json';
        return to_json($response);
    }
=cut

    # Create Aireos account
    my $aireos_response;
    try {
        my $request_json = encode_json({ user_id => $user_id });
        $aireos_response = make_aireos_request('POST', '/account', $request_json);
    }
    catch {
        error('Exception in creating Aireos account: ' . $_);
        $response = { success => 0, error => 'Failed to create Aireos account' };
    };

    if (!defined $response->{error} && ref $aireos_response eq 'HASH' &&  $aireos_response->{status} eq 'OK' && $aireos_response->{eos_account}) {
        $user->update({
            drone_enabled  => 1,
            aireos_user_id => $aireos_response->{eos_account},
        });
        $response = { success => 1 };
    }
    else {
        error('Failed to create Aireos account: ' . Dumper($aireos_response));
        my $message = 'Failed to create Aireos account';
        if (ref $aireos_response eq 'HASH' && $aireos_response->{status} eq 'ERROR') {
            $message .= ' - ' . $aireos_response->{message};
        }
        $response = { success => 0, error => $message };
    }

    content_type 'application/json';
    return to_json($response);
};

post '/add_aireos_credit' => sub {
    content_type 'application/json';
    my $body = request->body();
    my $req = from_json($body);

    my $amount = $req->{amount} || 25;

    my $user_id = session('user_id');
    my $user = schema->resultset('User')->find({ id => $user_id });
    unless ($user) {
        return to_json({
            error => "Invalid user. No user found with id - " . $user_id 
        });
    }

    #FIXME: Confirm that the user has drone enabled and has a  subscription
    unless ($user->drone_enabled) {
        return to_json({
            error => "Drone is not enabled for this user"
        });
    }

    if (!defined $user->aireos_user_id) {
        return to_json({
            error => "There is no Aireos account for this user"
        });
    }

    # Process payment
    my $content_hash = {
        purchase => {
            collection_method => 'automatic',
            currency => 'USD',
            account => {
                account_code => $user_id,
            },
            adjustments => [{
                revenue_schedule_type => 'at_invoice',
                unit_amount_in_cents  => $amount * 100,
                description           => 'Credit for Aireos drone',
            }],
        },
    };

    my $response = {};
    my $recurly_response;
    try {
        my $request_xml = XMLout($content_hash, NoAttr => 1, RootName => undef, GroupTags => { adjustments => 'adjustment' });
        $recurly_response = make_recurly_request('POST', "/purchases", $request_xml);
    }
    catch {
        error('Exception in processing Aireos drone enable payment: ' . $_);
        $response = { success => 0, error => 'Failed to process payment' };
    };

    if (!defined $response->{error} && ref $recurly_response eq 'HASH' && $recurly_response->{charge_invoice}->{uuid} && $recurly_response->{charge_invoice}->{state} eq 'paid') {
        # Payment was successful.
        my $aireos_response;
        try {
            my $request_json = encode_json({ user_id => $user_id, payment_amount => $amount });
            $aireos_response = make_aireos_request('POST', '/payment', $request_json);
        }
        catch {
            error('Exception in posting payment to Aireos: ' . $_);
            $response = { success => 0, error => 'Failed to post payment to Aireos' };
        };

        if (!defined $response->{error} && ref $aireos_response eq 'HASH' &&  $aireos_response->{status} eq 'OK' && $aireos_response->{transaction}->{transaction_id}) {
            #FIXME: Call end-point to fetch credit
            my $updated_credit = $user->aireos_credit + $amount;
            $user->update({
                aireos_credit => $updated_credit,
            });

            # All done.
            $response = { success => 1, available_credit => $updated_credit };
        }
        else {
            error('Failed to post payment to Aireos: ' . Dumper($aireos_response));
            $response = { success => 0, error => 'Failed to post payment to Aireos' };
        }
    }
    else {
        error('Failed to process Aireos drone enable payment: ' . Dumper($recurly_response));

        my $error = 'Failed to process payment';
        if (ref $recurly_response eq 'HASH' && $recurly_response->{error}) {
            $error = $recurly_response->{error}->{content};
        }

        $response = { success => 0, error => $error };
    }

    content_type 'application/json';
    return to_json($response);
};

sub make_recurly_request {
    my ($type, $path, $content) = @_;

    #TODO: Move to config
    my $api_endpoint = 'https://safewrd.recurly.com/v2';
    my $api_key      = 'aa889fb521ed4449a4d7ba8048ae1d3b';
    my $api_version  = '2.17';

    my $url = $api_endpoint . $path;
    my $req = HTTP::Request->new($type => $url);
    $req->authorization_basic($api_key);
    $req->header('Accept' => 'application/xml');
    $req->header('X-Api-Version' => $api_version);
    $req->content($content) if $content;

#error('recurly request xml: ' . $content);

    my $ua = LWP::UserAgent->new();
    $ua->protocols_allowed(['https']);

    my $resp = $ua->request($req);
    my $code = $resp->code;
    if ($code == 200 || $code == 201 || $code == 422) {
        return XMLin($resp->content);
    }

    die "Recurly call to $url failed - $code - " . $resp->content;
}

sub make_aireos_request {
    my ($type, $path, $content) = @_;

    #TODO: Move to config
    my $api_endpoint = 'https://air.eosrio.io/api';

    my $url = $api_endpoint . $path;
    my $req = HTTP::Request->new($type => $url);
    $req->header('Content-Type' => 'application/json');
    $req->content($content) if $content;

#error('Aireos request json: ' . $content);

    my $ua = LWP::UserAgent->new();
    $ua->protocols_allowed(['https']);

    my $resp = $ua->request($req);
    my $code = $resp->code;
    if ($code == 200 || $code == 201 || $code == 422) {
        return decode_json($resp->content);
    }

    die "Aireos call to $url failed - $code - " . $resp->content;
}

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
