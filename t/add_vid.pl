#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


use Kliq::Schema;
use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};
$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

my $u = $schema->resultset('User')->find('94A4988D-93F8-1014-A991-F7EDC84F2656');

    #-- media and assets

    my @vids = ({
        id => 'A32B5B8B-5D96-4237-B959-4B445E80CC38',
        title => 'Suits',
        mdesc => 'Suits is about people wearing suits talking to other people who are also wearing suits.',
        epstitle => 'Season 2, Episode 9 "Asterisk"',
        epsdesc => "Harvey Specter is the best closer in New York City. He's at the top of his game closing mergers, acquisitions and even divorces; it's in his blood.",
        file => 'Suits S02E09 Asterisk-ffmpeghb-iphone',
        format => 4,        
    });

    my @medias = qw/
        10FA348E-D0A5-499E-B9D0-C95339ADC1C4
    /;

    foreach my $vid(@vids) {
        #-- add media
        my $m = $u->add_to_media({
            id => shift(@medias),
            network_id => 1,
            title => $vid->{title},
            description => $vid->{mdesc},
            source_video_path => $vid->{id} . ($vid->{format} == 4 ? '.mp4' : '.webm')
        });
        
        #-- add thumbnails as media assets
        
        my @t = ();
        foreach my $size('240x160','160x90') {
            my $type = $vid->{epstitle} ? 'Episode' : 'Movie';
            my $thumb = $m->add_to_assets({
                asset_format_id => $size eq '160x90' ? 2 : 7,
                width => $size eq '160x90' ? 160 : 240,
                height => $size eq '160x90' ? 90 : 160,
                name => "$type thumbnail $size",
                is_preview => 1,
                server_id => 1,
                url => 'http://developers.tranzmt.it/media/thumbs/' . $size . '/' . $vid->{id} . '.png',
            });
            push(@t, $thumb);
        }
        
        if($vid->{epstitle}) {
            my $e = $m->create_related('episode', {
                category_id => 1,
                channel_id => 1,
                network_id => 1,
                title => $vid->{epstitle},
                description => $vid->{epsdesc},
                cover_asset_id => $t[0]->id,
                banner_asset_id => $t[1]->id
            });
        }
        
        #-- add video as media asset
        
        $m->add_to_assets({
            id => $vid->{id},
            asset_format_id => $vid->{format},
            server_id => 1,
            name => $vid->{epstitle} || $vid->{title}, # substr($vid->{file}, 0, 30),
            url => 'http://media.tranzmt.it/' . $u->id . '/' . $vid->{id} . ($vid->{format} == 4 ? '.mp4' : '.webm'),
        });

    }

ok(1);
done_testing();
