
use strict;
use warnings;

use DBI;

use Data::Dumper;

my $cnt = shift || 10;	#The number of random records to insert

 
my $dsn = "DBI:mysql:database=kliq2;host=localhost";
my $user = 'kliq_SSM';
my $password = 'self-expression';
my $dbh = DBI->connect($dsn, $user, $password);


#Prepare a query to insert a value
my $query = "insert into leads set ";
my $val = {};
@$val{qw/id handle service ambassador_id/} = ();

foreach my $key (sort {$a cmp $b} keys %$val){
	$query .= "$key = ?,";
}
chop $query;


#Insert $cnt random values
my $sth = $dbh->prepare($query) or die "prepare statement failed: $dbh->errstr()";
for (1..$cnt){
	my $ambassador_id = 1;
	my $handle = int(rand(8000000000))+2000000000;
	my $id = int(rand(10000000000000000));
	my $service = "twilio";
	$sth->execute($ambassador_id,$handle,$id,$service) or die "execution failed: $dbh->errstr()";
}

