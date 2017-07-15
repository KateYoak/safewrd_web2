#---------------------#
# Version Locked Deps #
#---------------------#

requires 'Mail::Internet'                 => '== 2.14';
requires 'Moose'                          => '== 2.1800';
requires 'MooseX::Types::Parameterizable' => '== 0.07';

#---------------#
# Standard Deps #
#---------------#

requires 'Const::Fast'                => '0.012';
requires 'DBD::Pg';
requires 'DBIx::Class'                => '0.08198';
requires 'DBIx::Class::Helpers'       => '2.015';
requires 'DBIx::Class::InflateColumn::Serializer'  => '0.03';
requires 'DBIx::Class::PassphraseColumn'           => '0.02';
requires 'DBIx::Class::ResultSet::RecursiveUpdate' => '0.25';
requires 'DBIx::Class::TimeStamp'     => '0.14';
requires 'DBIx::Class::UUIDColumns'   => '0.02006';
requires 'Dancer'                     => '1.3099';
requires 'Dancer::Logger::LogHandler' => '0.01';
requires 'Dancer::Logger::PSGI'       => '0.04';
requires 'Dancer::Plugin::Auth::Twitter' => '0.02';
requires 'Dancer::Plugin::DBIC'       => '0.1506';
requires 'Dancer::Plugin::Email'      => '0.13';
requires 'Dancer::Plugin::UUID';
requires 'Dancer::Plugin::REST'       => '0.07';
requires 'Dancer::Plugin::Redis'      => '0.2';
requires 'Data::Validate::URI'        => '0.06';
requires 'DateTime'                   => '0.66'; # 0.76
requires 'DateTime::Format::ISO8601'  => '0.08';
requires 'DateTime::Format::MySQL'    => '0.04';
requires 'File::chdir';
requires 'HTML::Parser'               => '3.69';
requires 'HTTP::Request::StreamingUpload';
requires 'Image::ExifTool';
requires 'Imager';
requires 'JSON'                       => '2.53';
requires 'Mail::Builder::Simple';
requires 'MooseX::Aliases';
requires 'MooseX::NonMoose'           => '0.22';
requires 'MooseX::Role::Parameterized' => '1.00';
requires 'MooseX::StrictConstructor'  => '0.19';
requires 'MooseX::Types'              => '0.35';
requires 'MooseX::Types::Common::String' => '0.001';
requires 'MooseX::Types::DBIx::Class' => '0.05';
requires 'MooseX::Types::Email'       => '0.004';
requires 'MooseX::Types::Moose'       => '0.35';
requires 'MooseX::Types::URI'         => '0.03';
requires 'MooseX::Types::UUID'        => '0.03';
requires 'MooseX::Types::Varchar'     => '0.05';
requires 'MooseX::Types::Varchar'     => '0.05';
requires 'Net::Amazon::S3';
requires 'Net::Facebook::Oauth2';
requires 'Net::OAuth2'                => '0.07';
requires 'Net::OAuth::Yahoo'          => '0.06';
requires 'Plack'                      => '1.0002';
requires 'Plack::Middleware::CrossOrigin' => '0.007';
requires 'Plack::Middleware::Deflater'    => '0.08';
requires 'Plack::Middleware::ETag'    => '0.03';
requires 'Plack::Middleware::OAuth'   => '0.10';
requires 'Plack::Middleware::Rewrite' => '1.005';
requires 'Plack::Middleware::Session' => '0.14';
requires 'Plack::Session::Store::Redis' => '0.03';
requires 'Redis'                      => '1.904'; #'1.951';
requires 'Starman'                    => '0.3';
requires 'String::CamelCase'          => '0.02';
requires 'Template'                   => '2.24';
requires 'Try::Tiny'                  => '0.11';
requires 'WWW::Mixpanel'              => '0.07';
requires 'WebService::Rackspace::CloudFiles';
requires 'YAML::XS'                   => '0.38';
requires 'namespace::autoclean'       => '0.13';
requires 'REST::Client';
requires 'JSON::WebToken';

#----------------#
# DH Script Deps #
#----------------#

requires 'DBIx::Class::DeploymentHandler' => '0.002218';
requires 'Module::Runtime';
requires 'Moo';
requires 'MooX::Options';
requires 'namespace::clean';
requires 'DBIx::Class::Fixtures';

#-------------#
# Worker Deps #
#-------------#

requires 'AnyEvent::Redis'       => '0.23';
requires 'Log::Dispatch'         => '2.32';
requires 'Net::Twitter'          => '3.18';
requires 'Furl'                  => '0.40';
requires 'Text::Unidecode'       => '0.04';
requires 'Data::Section::Simple' => '0.03';
requires 'MooseX::LogDispatch'   => '1.2002';
requires 'Backticks'             => '1.0.9';
requires 'Email::Simple'         => '2.1';
requires 'Email::Sender'         => '0.12';

on 'test' => sub {
  requires 'Test::Fatal';
  requires 'Test::Exception';
  requires 'Test::Moose::More';
  requires 'Test::MockTime';
  requires 'Test::Script'         => '1.05';
  requires 'Config::YAML::Modern';
}
