package Kliq::Model::Tokens;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Dancer ':moose';
use Try::Tiny;
use Data::Dumper;

extends 'Kliq::Model::Base';
with 'Kliq::Model::Role::UserInfo';

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
    
    my $re_persona = $self->get_persona($info->{handle}, $data->{service});
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
        email     => "anonymous.$rand\@kliqmobile.com"
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
