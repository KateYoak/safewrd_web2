
use strict;
use warnings;

use DBI;

use Data::Dumper;

use lib '../lib';	# This probably doesn't have to happen in production, but probably also hurts nothing.
use Safewrd::SMS;

#Send a text every $period lead signups:
my $period = 25;

 
#Fetch the current counts for ambassadors
my $dsn = "DBI:mysql:database=kliq2;host=localhost";
my $user = 'kliq_SSM';
my $password = 'self-expression';
my $dbh = DBI->connect($dsn, $user, $password);

my $query = "select ambassadors.id, ambassadors.phone, ambassadors.nickname, count(*) as count, ambassadors.latest_signups_counted from ambassadors, leads where ambassadors.id = leads.ambassador_id group by ambassadors.id";


my $sth = $dbh->prepare($query) or die "prepare statement failed: $dbh->errstr()";
$sth->execute() or die "execution failed: $dbh->errstr()";

my @rows;
while (my $rec = $sth->fetchrow_hashref){
	push @rows, $rec;
}

# Figure out which ambassadors need a text, send it, and update the db.
foreach my $row (@rows){
	my $done = $row->{latest_signups_counted};
	my $count = $row->{count};

	my $threshold = int($count/$period) * $period;
	if($threshold > $done) { # This ambassador needs a text!

		# Send the text.
		$row->{phone} =~ s/\D//g;
		unless($row->{phone} =~ m/^\d{10}$/){
			warn "Ambassador: ", $row->{id}, " has a phone number that we can't parse.  Skipping...";
			next;
		}
		my $sender = new Safewrd::SMS;
		my $sent = $sender->send_sms(
			text	=>	"$row->{nickname} , you are credited for $count Sign-ups thus far.   Awesome job! Don't stop",
			to	=>	'+1'.$row->{phone},
		);
		unless ($sent){
			warn "SMS failed to send to ",$row->{phone}," to announce crossing the $threshold signup threshold";
		}

		# Update the new threshold for the db.
		my $query = "update ambassadors set latest_signups_counted = $threshold where ambassadors.id = \"".$row->{id}."\"";
		print $query,"\n";
		$sth = $dbh->prepare($query) or die "prepare statement failed: $dbh->errstr()";
		$sth->execute() or die "execution failed: $dbh->errstr()";
	}
}


print Dumper \@rows;

