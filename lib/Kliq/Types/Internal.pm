package Kliq::Types::Internal;

use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.001';

use MooseX::Types::Moose -all; #qw/Str Int Object Bool ArrayRef ScalarRef HashRef/;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Common::Numeric qw/PositiveInt/;
use MooseX::Types -declare => [qw/
    PhoneNum Geo BirthDay Gender Url
    IsoDate DateTime EventDate
    ConnectInfo
    /];

use DateTime;

use Data::Validate::URI qw(is_uri is_http_uri is_https_uri is_web_uri);

#-- User fields ----------------------------------------------------------

subtype Url,
    as Uri,
    where { is_web_uri($_->as_string) },
    message { "$_ is not a valid url" };

coerce Url,
  from Str | HashRef | ScalarRef,
   via { to_Uri $_ };

subtype   PhoneNum,
       as Str,
    where { $_ =~ /^[0-9-\(\)\s\+]+$/ ? 1 : 0 },
  message { "$_ is not a valid phone number" };

subtype   BirthDay,
       as PositiveInt,
    where { $_ =~ /^\d{8}$/ },
  message { "$_ is not a valid birthday" };


enum Gender, ['m','f'];
#= subtype Gender, as Str, where { /^[mf]$/ };



#-- Dates ----------------------------------------------------------------------

subtype IsoDate,
  as Str,
  where { /^\d\d\d\d-\d\d-\d\d$/ }
;

subtype DateTime,
    as Object,
    where { $_->isa( 'DateTime' ) },
    message { "$_ is not a valid date" }
;

subtype EventDate,
    as DateTime,
    where { $_ >= DateTime->now },
    message { 'date must be >= today' }
;

#-- DBIC schema connect --------------------------------------------------------

subtype ConnectInfo,
    as      HashRef,
    where   { exists $_->{dsn} || exists $_->{dbh_maker} },
    message { 'Does not look like a valid connect_info' };

coerce ConnectInfo,
    from Str,      via(\&_coerce_connect_info_from_str),
    from CodeRef,  via { +{ dbh_maker => $_ } };

sub _coerce_connect_info_from_str {
    +{ dsn => $_, user => '', password => '' }
    }

1;
__END__

