
use strict;
use warnings;

use lib './lib';
use Safewrd::SMS;


my $sender = new Safewrd::SMS;

my $sent = $sender->send_sms(
	text	=>	'This is a message sent from our Perl app',
	to	=>	'+16267056996',
);

if($sent){
	print "That appears to have gone well.\n";
}else{
	print "Well, darn.\n";
}




