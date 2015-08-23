
package Kliq::Worker::VideoClipper;

use utf8;
use namespace::autoclean;
use Moose;
use JSON;
use Try::Tiny;
use IPC::Cmd qw/run/;
extends 'Kliq::Worker';
with qw/
    Kliq::Worker::Role::WithSchema
    Kliq::Worker::Role::WithLogger
    Kliq::Worker::Role::HasConfig
    Kliq::Worker::Role::HasRedis
    /;

my $DEBUG = $^O =~ /Win32/ ? 1 : 0;

# { share => $share->id }
sub work {
    my ($self, $data) = @_;

    my $config   = $self->config or die("Missing config");
    my $basepath = $config->{asset_basepath} or die("Missing asset basepath");
    
    my $share_id = $data->{share} or die("Need share id");    
    my $share = $self->schema->resultset('Share')->find($share_id)
        or die("Share $share_id not found");

    my $media_id = $share->media_id or die("Need media id");
    my $offset = $share->offset || 10;
    
    my $asset = $self->schema->resultset('CmsAsset')->find({
        media_id => $media_id, is_preview => 0, asset_format_id => 11
    }) or die("Original asset for media $media_id not found");
    my $asset_id = $asset->id;

    my $dur = sprintf "%02d:%02d:%02d",(gmtime $offset)[2,1,0];
    my $src = "$basepath/assets/$asset_id.mp4";
    my $trg = "$basepath/shares/$share_id.mp4";
    die("Source $src not found") unless -f $src;
    die("Target $trg exists") if -f $trg;

    try {
        my $cmd = "VISlicer -i $src -ss $dur -t 60 -s 720x480 1 $trg";
        
        my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
            run( command => $cmd, verbose => 0 );

        if( $success ) {
            $self->logger->info("video '$asset_id' clipped as '$share_id'");
    
            #-- create 3 web-optimized formats + thumbnails through Zencoder
            #-- and let the clip stream from Rackspace
            $self->publish($share);
        }
        else {
            $self->logger->error(
                "video '$asset_id' NOT clipped as '$share_id', '$cmd' error: "
                 . join(' - ', $error_message, @{$stderr_buf})
            );
        }
    
    } catch {
        my $err = $self->format_error($_);
        $self->logger->error("$err");
    };

}

sub publish {
    my ($self, $share) = @_;
    
    $self->redis->rpush(zencode => to_json({
        id     => $share->id,
        suffix => '.mp4',
        user   => $share->user_id,
        type   => 'clip'
    }));
}

__PACKAGE__->meta->make_immutable;

1;
__END__