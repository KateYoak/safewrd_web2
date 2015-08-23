package Kliq::Model::Shares;

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Try::Tiny;
use Data::Dumper;
use JSON;
extends 'Kliq::Model::Base';

sub table { 'Share' }
#sub path { 'shares' }
sub method { 'shares' }

around 'search' => sub {
    my $orig = shift;
    my $self = shift;

    #-- all my shares
    my $res = $self->$orig(@_);

    #-- all shared with me

    return $res;
};

sub create {
    my ($self, $params) = @_;

    #-- save the share

    my ($share, $error);
    my $method = $self->method;
    try {
        $share = $self->user->add_to_shares($params);
    } catch {
        $error = $self->error($_, 'shares');
    };
    if($error || !$share) {
        return $error || $self->error(undef, 'shares');
    }

    if($share->media_id) {
        #-- splice the video, have Zencoder transcode the results and put it 
        #-- on Rackspace. Not implemented: having Zencoder create the clips instead.
        $self->redis->rpush(sliceVideo => to_json({
            share  => $share->id,
        }));  
    }
    elsif($share->upload_id) {
        #-- if all zencoder(upload.id)jobs have finished, notifyShare. 
        #-- otherwise, do nothing and let zencoderOutput model handle it when 
        #-- the job is finished
        #my $rs = $self->user->zencoder_outputs({ upload_id => $share->upload_id });
        #if($rs->count == $rs->search({ state => 'finished' })->count) {
        if($share->upload->status eq 'ready') {
            #-- send notifications
            $self->redis->rpush(notifyShare => to_json({
                share => $share->id
            }));
        }
    }
    else {
        #-- should never get here, Share addition should fail if no upload_id OR media_id
        die("Missing media_id or upload_id");
    }
    
    return $self->get($share->id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__
