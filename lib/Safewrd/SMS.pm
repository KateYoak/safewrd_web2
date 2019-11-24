package Safewrd::SMS;

use strict;
use warnings;

use base 'SMS::Send';

sub new {

	my $package = shift;
		my $self = SMS::Send->new ('Twilio',
	        _accountsid => 'ACd9b164311d535228c4b7425a7dfc7e1e',
	        _authtoken  => '398fedc5eaed28271a86f09b38056653',
	        _from       => '+18885543995',
	);
	return bless $self, $package;

}

1;

