
package Kliq::Schema;

use utf8;
use strict;
use warnings;

use JSON;
use base 'DBIx::Class::Schema';

our $VERSION = 1;

__PACKAGE__->load_namespaces(
    default_resultset_class => 'ResultSet',
);

sub seed {
    my $schema = shift;

    #-- stem data
    my @zc_params = ();
    my %zc_params = ();
    $zc_params{orig} = to_json({
        label       => 'source-mp4',
        #url         => "$dest/$id-orig.mp4",
        format      => "mp4",
        video_codec => "h264",
        audio_codec => "aac",
        #notifications => [ 'sitetechie@gmail.com' ],
    });

    $zc_params{'mp4'} = to_json({
        label       => 'web-mp4',
        format      => "mp4",
        video_codec => "h264",
        audio_codec => "aac",
        size        => "480x320",
        aspect_mode => "preserve",
    });

    $zc_params{'mp4l'} = to_json({
        label       => 'web-mp4',
        format      => "mp4",
        video_codec => "h264",
        audio_codec => "aac",
        size        => "960x640",
        aspect_mode => "preserve",
        quality       =>  4,
        audio_quality =>  4,
        audio_bitrate =>  160,
        max_video_bitrate =>  5000,
        max_frame_rate =>  30,
        audio_sample_rate => 48000,
        audio_channels => 2,
        h264_profile => "main",
        h264_level => 3.1
    });

    $zc_params{webm} = to_json({
        label         => 'web-webm',
        #url           => "$dest/$id.webm",
        format        => 'webm',
        video_codec   => "vp8",
        audio_codec   => "vorbis",
        quality       => 5,
        audio_quality => 5,
        speed         => 3,
        hint          => \1,
        mtu_size      => 1450,
        #notifications => [ 'sitetechie@gmail.com' ],
    });

    $zc_params{'3gp'} = to_json({
        label         => 'web-3gp',
        #url           => "$dest/$id.3gp",
        format        => "3gp",
        video_codec   => "h264",
        audio_codec   => "aac",
        #notifications => [ 'sitetechie@gmail.com' ],
    });
    
    $zc_params{'screen'} = to_json({
        label       => 'thumb-screen',
        number      => 1,     
    });    
    
    $zc_params{'banner'} = to_json({ # '160x90'
        label       => 'thumb-banner',
        number      => 1, 
        aspect_mode => 'crop',
        size        => '160x90'
    });
    
    $zc_params{'cover'} = to_json({ # '240x160'
        label       => 'thumb-cover',
        number      => 1,
        aspect_mode => 'crop',
        size        => '240x160'
    });
    
    $schema->populate('CmsAssetFormat', [
        [qw/ id name description label mime_type file_extension zencoder_params /],
        [ 1, 'Small 3GP', 'Small 3GP File', 'small3gp', 'video/3gpp', '-small.3gp', undef],
        [ 3, 'Large 3GP', 'Large 3GP File', 'large3gp', 'video/3gpp', '-large.3gp', undef],
        [ 4, 'iPhone MP4', 'iPhone MP4 File', 'iphone', 'video/mp4', '-iphone.mp4', undef],
        [ 6, 'Flash Version', 'Flash Version', 'flash', 'video/x-flv', '.flv', undef],
        [ 8, 'MPEG2', 'MPEG2 Format (for combining)', 'mpeg2', 'video/mpeg2', '.mpg', undef],
        
        [ 5, 'Image', 'Fullsize Screen Image', 'thumb-screen', 'image/png', '-screen.png', $zc_params{screen}],
        [ 2, 'Small Thumbnail', 'Small Thumbnail', 'thumb-banner', 'image/png', '-thumb.png', $zc_params{banner}],
        [ 7, 'Large Thumbnail', 'Large Thumbnail', 'thumb-cover', 'image/png', '-lg-thumb.png', $zc_params{cover}],
    
        [ 11, 'Source', 'Original transcoded','source-mp4', 'video/mp4', '-full.mp4', $zc_params{orig}],
        [ 12, 'Web MP4', 'Web MP4','web-mp4', 'video/mp4', '.mp4', $zc_params{'mp4'}],
        [ 13, 'Web Webm', 'Web Webm','web-webm', 'video/webm', '.webm', $zc_params{webm}],
        [ 14, 'Web 3gp', 'Web 3gp','web-3gp', 'video/3gpp', '.3gp', $zc_params{'3gp'}],
    ]);
#        [ 15, 'Web MP4 Large', 'Large Web MP4','web-mp4-large', 'video/mp4', '-lg.mp4', $zc_params{'mp4l'}],

    #-- seed data

    my $u = $schema->resultset('User')->create({
        id => '94A4988D-93F8-1014-A991-F7EDC84F2656',
        username => 'Anonymous.' . rand(1000), # unique
        password => 's3cr3t',
        email => 'test@tranzmt.it',
        #contacts => [$dc] #OK
    });

    my $p = $u->add_to_personas({
        service      => 'twitter',
        handle      => 46722818,
        name        => 'Peter de Vos',
        screen_name => 'sitetechie',
        image       => 'http://a0.twimg.com/sticky/default_profile_images/default_profile_2_normal.png',
        profile_url => 'https://twitter.com/sitetechie',
        website     => 'http://sitetechie.com',
        language    => 'en',
        location    => '',
        timezone    => 'Greenland',
    });

    $u->add_to_tokens({
        persona_id => $p->id,
        service => 'twitter',
        token => '46722818-j52ulamjTjo98RLc7uTqh1PxOci5pjlxlfut5nKZ0',
        secret => 'dOlV1mYrOVVZ6bKJWGYB9iEaKLmbX6m08bYM5x4ASw',
    });

    my $c1 = $u->add_to_contacts({
        id => '1A9F1F2B-A297-1014-8D7F-A3F7C84F2656',
        handle => 'peter@peterdevos.com',
        name => 'Peter de Vos',
        email => 'peter@peterdevos.com',
        service => 'google'
    });
    
    my $c2 = $u->add_to_contacts({
        id => "352A4113-7F93-1014-8DEB-1E09194F16F4",
        name => "novamobi",    
        service => "twitter",
        image => "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",
        handle => 513795868,
        screen_name => 'novamobi',
    });

    my $k = $u->add_to_kliqs({
        id => '31269EE0-A297-1014-BB8E-A3F7C84F2656',
        name => 'CoolKliq'
    });    
    
    #$k->add_to_map_contacts({ contact_id => 1 }); # same as:
    $k->add_to_contacts($c1);

    #-- media and assets

    my @vids = ({
        id => '344A454A-CE19-1014-AE65-A3EEC84F2656',
        name => 'Suits',        
        title => 'Season 1, Episode 8 "LOL"',
        description => "Harvey Specter is the best closer in New York City. He's at the top of his game closing mergers, acquisitions and even divorces; it's in his blood.",
        file => 'suits.110.hdtv-lol.mp4',
        format => 4,
        type => 'episode'
    },{
        id => '35A8FCC9-CE19-1014-AE65-A3EEC84F2656',
        name => 'Pulp Fiction',        
        title => 'Pulp Fiction',
        description => "The lives of two mob hit men, a boxer, a gangster's wife, and a pair of diner bandits intertwine in four tales of violence and redemption.",
        file => 'Royale With Cheese - Pulp Fiction (212) Movie CLIP (1994) HD.mp4',
        format => 4,
        type => 'movie'
    },{
        id => '386A0F28-CE19-1014-AE65-A3EEC84F2656',
        name => 'Sherlock',        
        title => 'Season 1, Episode 2 "The Blind Banker"',
        description => 'At the National Antiquities Museum, Chinese pottery expert Soo Lin Yao (Gemma Chan) sees something that frightens her, and disappears. Meanwhile, John is having financial problems, and needs to find a paying job. Sherlock takes him to "the bank", which turns out to be a high-powered international finance house.',
        file => 'Sherlock.1x02.The.Blind.Banker.HDTV.XviD-FoV.mp4',
        format => 4,
        type => 'episode'
    },{
        id => 'A32B5B8B-5D96-4237-B959-4B445E80CC38',
        name => 'Suits',
        title => 'Season 2, Episode 9 "Asterisk"',        
        description => "Harvey Specter is the best closer in New York City. He's at the top of his game closing mergers, acquisitions and even divorces; it's in his blood.",
        file => 'Suits S02E09 Asterisk-ffmpeghb-iphone',
        format => 4,
        type => 'episode'
    });

    my @medias = qw/
        3FBB1D00-05B3-11E2-88F2-A27A516FB52B
        3FC1F51C-05B3-11E2-905D-A27A516FB52B
        3FCBD172-05B3-11E2-BD50-A27A516FB52B
        10FA348E-D0A5-499E-B9D0-C95339ADC1C4
    /;

    # clqs-media
    my $media_base = 'http://ead54a85a0e71e8d6209-578e57646269a0417cf8d221c5ffac7c.r72.stream.cf1.rackcdn.com/';
    foreach my $vid(@vids) {
        
        #-- add media

        my $m = $u->add_to_media({
            id => shift(@medias),
            type => $vid->{type},
            name => $vid->{name},
            title => $vid->{title},
            description => $vid->{description},
            source_video => $vid->{id} . ($vid->{format} == 4 ? '.mp4' : '.webm'),
            status => 'published'
        });
        
        #-- add thumbnails as media assets
        
        my @ttypes = qw/banner cover/;
        foreach my $size('160x90', '240x160') {
            my $thumb = $m->add_to_assets({
                type => shift(@ttypes),
                asset_format_id => $size eq '160x90' ? 2 : 7,
                width => $size eq '160x90' ? 160 : 240,
                height => $size eq '160x90' ? 90 : 160,
                name => $vid->{type} eq 'episode' ? 
                    join(' - ', $vid->{name}, $vid->{title}, $size eq '160x90' ? 'Small Thumbnail' : 'Large Thumbnail')
                  : join(' - ', $vid->{name}, $size eq '160x90' ? 'Small Thumbnail' : 'Large Thumbnail'),
                is_preview => 1,
                #url => 'http://developers.tranzmt.it/media/thumbs/' . $size . '/' . $vid->{id} . '.png',
                url => $media_base . $m->id . ($size eq '160x90' ? '-thumb.png' : '-lg-thumb.png')
            });
        }
        
        #-- add videos as media asset

        $m->add_to_assets({
            id => $vid->{id},
            type => 'video',
            asset_format_id => 11,
            name => $vid->{type} eq 'episode' ?
                join(' - ', $vid->{name}, $vid->{title}, 'Source') :
                join(' - ', $vid->{name}, 'Source'),
            url => $media_base . $m->id . '-full.mp4',
            signature => $media_base . $vid->{id} . '.amdb',
        });

        #$m->add_to_assets({
        #    id => $vid->{id},
        #    type => 'video',
        #    asset_format_id => $vid->{format},
        #    name => $vid->{type} eq 'episode' ?
        #        join(' - ', $vid->{name}, $vid->{title}, 'iPhone MP4') :
        #        join(' - ', $vid->{name}, 'iPhone MP4'),
        #    #url => 'http://media.tranzmt.it/' . $u->id . '/' . $vid->{id} . ($vid->{format} == 4 ? '.mp4' : '.webm'),
        #    url => $media_base . $m->id . '-iphone.mp4'
        #});

        ### 3FC6D60E-05B3-11E2-B158-A27A516FB52B
        if($m->id eq '3FC1F51C-05B3-11E2-905D-A27A516FB52B') {
            $m->add_to_assets({
                id => '37076A92-CE19-1014-AE65-A3EEC84F2656',
                type => 'video',
                asset_format_id => 3,
                name => join(' - ', $vid->{name}, 'Large 3GP'),
                url => $media_base . $m->id . '-large.3gp',
                signature => $media_base . '37076A92-CE19-1014-AE65-A3EEC84F2656' . '.amdb',
            });
        }


    }

}


1;
__END__