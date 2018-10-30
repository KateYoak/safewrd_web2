package Kliq::Model::Tokens;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Dancer ':moose';
use Try::Tiny;
use Data::Dumper;

extends 'Kliq::Model::Base';
with 'Kliq::Model::Role::UserInfo';

use Kliq::Util qw(fb_surrogate_id_from_picture);

sub table { 'OauthToken' }
#sub path { 'tokens' }
sub method { 'tokens' }

sub create {
    my ($self, $params) = @_;
    
    my ($res, $uid) = $self->handle_token({
        token   => $params->{token},
        secret  => $params->{secret},
        service => $params->{service},
        session => $self->session, #session('id'),
        user    => $self->has_user? $self->user->id : undef,
    });
    
    return ($res, $uid);
}

#token secret service session user [info]
sub handle_token {
    my ($self, $data) = @_;
    
    my $uid  = $data->{user};
    my $info = $self->userinfo($data, config->{sites}{$data->{service}});
    
    my ($user, $persona, $token, $do_import) = $self->user_persona($info, $data, $uid);

    #-- import contacts
    if($do_import) {
        $data->{user} ||= $user->id;
        $data->{handle} ||= $info->{handle};
        $self->redis->rpush(importContacts => to_json($data));
    }

    return ($self->get($token->id), $user->id);
}

sub user_persona {
    my ($self, $info, $data, $uid) = @_;

    my $re_persona;
    if( $data->{service} eq 'facebook'){
      my $fb_id = $info->{handle};
      # is it an app-scoped fb_id?
      if(my $surrogate_id = fb_surrogate_id_from_picture( $info->{handle}, from_app => 1)){
	# does this persona came from a previous chat and we used a surrogate ID?
        if($re_persona = $self->get_persona($surrogate_id, $data->{service})){
	  # then replace the previous surrogate ID with this app-scoped ID
	  $re_persona->update({ handle => $info->{handle}});
	}
      }
    }
    
    $re_persona = $self->get_persona($info->{handle}, $data->{service}) unless $re_persona;

    my $re_token   = $self->get_token($data->{token}, $data->{service});

    if($re_token && $re_persona) {
        die("Conflicting tokens") if($re_token->persona_id ne $re_persona->id);
    }

    my ($user, $persona, $do_import) = ();
    
    #-- known user, known persona
    if($uid && $re_persona) {
        #-- if from a diff user, merge accounts
        if ($re_persona->user_id ne $uid) {
            #-- merge accounts $uid + $token->user_id
            $self->merge_user($uid, $re_persona->user_id);
        }
        if($re_token) {
            # TODO update token expiration
            #$token = $re_token;
        }
    }
    
    #-- known user, new persona
    elsif($uid) {
        $persona = $self->create_persona($info, $data, $uid);
        $do_import++;
    }
    
    #-- anon user, known persona
    elsif($re_persona) {
        $uid = $re_persona->user_id;
    }
    
    #-- anon user, new persona    
    else {
        $user = $self->create_user() or die("User not created");
        $uid = $user->id;
        $persona = $self->create_persona($info, $data, $uid);
        $do_import++;

        # Lets send push notifications to all contacts who invited this user
        my $contacts = $self->schema->resultset('Contact')->search({
                user_id => $uid
            });
        my $contacts_flag;
        while (my $contact = $contacts->next) {
            if ($contact->owner_id) {
                # Skip duplicate contacts
                next if $contacts_flag->{$contact->owner_id};
                $contacts_flag->{$contact->owner_id} = 1;

                my $contact_name = $contact->name || $contact->email;
                $self->redis->rpush(notifyPhone => to_json({
                    type => 'in-app',
                    payload => {
                        user_id               => $contact->owner_id,
                        notification_title    => "Your friend $contact_name joined Tranzmt",
                        message               => "Your friend $contact_name joined Tranzmt",
                        type                  => "text_message",
                        action                => "contact_on_tranzmt",
                        badge                 => 1,
                        sound                 => "Default.caf",
                        contact_id            => $contact->id,
                    },
               }));
            }
        }
    }

    $do_import++;
    
    $user ||= $self->schema->resultset('User')->find($uid);
    $persona ||= $re_persona;
    my $token = $self->updated_token($user, $persona, $re_token, $data);

    return ($user, $persona, $token, $do_import);
}

sub create_persona {
    my ($self, $info, $data, $uid) = @_;
    $info->{service} = $data->{service};
    $info->{user_id} = $uid;
    return $self->schema->resultset('Persona')->create($info);
}

sub merge_user {
    my ($self, $uid, $tid) = @_; # newuser, uid-to-change

    my $is_old_user_available = $self->schema->resultset('User')->find($tid);
    return if !$is_old_user_available;

    my $is_new_user_available = $self->schema->resultset('User')->find($uid);
    return if !$is_new_user_available;

    #-- move all entities to the new user
    foreach my $table(qw/
        OauthToken Contact Kliq Upload Share Comment Persona CmsMedia
        /) {
        #$self->schema->resultset($table)->search({ user_id => $tid })->update({ user_id => $uid });
        my $rs = $self->schema->resultset($table)->search({ user_id => $tid });
        while (my $rec = $rs->next) {
            try {
                $rec->update({ user_id => $uid });
            } catch {
                # duplicate record, delete with user
            };
        }
    }
    #$self->schema->resultset('Contact')->search({ owner_id => $tid })->update({ owner_id => $uid });
    my $rs = $self->schema->resultset('Contact')->search({ owner_id => $tid });
    while (my $rec = $rs->next) {
        try {
            $rec->update({ owner_id => $uid });
        } catch {
            # duplicate record, delete with user
        };
    }    

    #-- delete previous user
    $self->schema->resultset('User')->find($tid)->delete();

    return $uid;
}

sub get_token {
    my ($self, $token, $service) = @_;
    return $self->schema->resultset('OauthToken')->search({
        service => $service, token => $token
    })->single();
}

sub get_persona {
    my ($self, $handle, $service) = @_;
    return $self->schema->resultset('Persona')->search({
        service => $service, handle => $handle
    })->single();
}

sub create_user {
    my $self = shift;

    my $rand = rand(1000);
    my $user = $self->schema->resultset('User')->create({
        username => "Anonymous.$rand",
        password  => "s3cr3t",
        email     => "anonymous.$rand\@tranzmt.it"
        }) or die("Unable to create user");

    return $user;
}

sub updated_token {
    my ($self, $user, $persona, $old_token, $data) = @_;

    # TODO update expiration of old token
    return $old_token if $old_token;

    my $token = $persona->tokens->first();
    
    if(!$token) {
        $token = $persona->add_to_tokens({
            token   => $data->{token},
            secret  => $data->{secret} || undef,
            service => $data->{service},
            user_id => $persona->user_id
            }) or die("Token not created");
    }            
    else {
        $token->update({
            token   => $data->{token},
            secret  => $data->{secret} || undef
        });
    }
    
    return $token;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
