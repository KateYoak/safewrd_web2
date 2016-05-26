#!/usr/bin/perl -w

# {"title":"","contactsMap":[{"contactId":"BC979466-05B8-11E2-9911-AA7A516FB52B"}],
# "geoLocation":"35.0377969,-85.2629776",
# "kliqsMap":[{"kliqId":"59E24E46-05D2-11E2-BCD5-CF84516FB52B"}],
# "mediaId":"386A0F28-CE19-1014-AE65-A3EEC84F2656",
# "message":"Sherlock","offset":60,"allowReshare":"false","allowLocationShare":"false"}

use strict;
use warnings;
use Test::More;

plan skip_all => "Test is broken";

use FindBin;
use lib "$FindBin::Bin/../lib";

use Kliq::Schema;

use Dancer qw/:script !pass/;
my $connect_info = config->{plugins}->{DBIC}->{kliq};

$connect_info->{password} = delete $connect_info->{pass};
my $schema = Kliq::Schema->connect($connect_info) or die "Failed to connect";

#my $u = $schema->resultset('User')->search({ id => '94A4988D-93F8-1014-A991-F7EDC84F2656' })->single();
my $u = $schema->resultset('User')->search({ id => '09703238-56E9-11E4-9363-FA37C0C88090' })->single(); #nico
print $u;
print "\n";

#my $s = $u->add_to_shares({ media_id => "3FCBD172-05B3-11E2-BD50-A27A516FB52B" });
#print $s;

#I share to novamobi
#novamobi shares to me

my $ss = $schema->resultset('Share')->search({
-or => [
    'contacts_map.contact_id' => { -in => ['352A4113-7F93-1014-8DEB-1E09194F16F4','1A9F1F2B-A297-1014-8D7F-A3F7C84F2656'] },
    'user_id' => '94A4988D-93F8-1014-A991-F7EDC84F2656'
    ]
    },
    { join      => 'contacts_map',
      order_by  => { -desc => ['me.created'] },
      distinct => 1
    }
);
foreach my $sh($ss->all) {
print "SHARE " . $sh->id . ' - ' . "\n";
}


