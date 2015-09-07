use strict;
use warnings;

use inc::Module::Install;

name            'Kliq';
license         'commercial';
all_from        'lib/Kliq.pm';
homepage        'http://kliqmobile.com/';
readme_from;

author_requires 'Module::Install::AuthorRequires';
author_requires 'Module::Install::AutoManifest';
#author_requires 'Module::Install::AutoLicense';
author_requires 'Module::Install::AuthorTests';
author_requires 'Module::Install::ReadmeFromPod';
author_requires 'Module::Install::ExtraTests';
author_requires 'Module::Install::ManifestSkip';
#author_requires 'Module::Install::GithubMeta';
author_requires 'Module::Install::Repository';
author_requires 'Module::Install::VersionCheck';

author_requires 'Test::Pod'             => '1.14';
author_requires 'Test::Pod::Coverage';
author_requires 'Pod::Coverage::Moose';
author_requires 'Test::Perl::Critic'    => '1.02';
author_requires 'Perl::Critic'          => '1.11';

requires 'DateTime'                  => '0.66'; # 0.76
requires 'DateTime::Format::ISO8601' => '0.08';
requires 'DateTime::Format::MySQL'   => '0.04';
requires 'JSON'                      => '2.53';
requires 'String::CamelCase'         => '0.02';
requires 'Template'                  => '2.24';
requires 'Const::Fast'               => '0.012';
requires 'Try::Tiny'                 => '0.11';
requires 'YAML::XS'                  => '0.38';
requires 'namespace::autoclean'      => '0.13';
requires 'Moose'                     => '2.0603';
requires 'MooseX::StrictConstructor' => '0.19';
requires 'MooseX::Role::Parameterized' => '1.00';
requires 'MooseX::Types'             => '0.35';
requires 'MooseX::Types::Common::String' => '0.001';
requires 'MooseX::Types::Email'      => '0.004';
requires 'MooseX::Types::Varchar'    => '0.05';
requires 'MooseX::Types::Moose'      => '0.35';
requires 'MooseX::Types::URI'        => '0.03';
requires 'MooseX::Types::UUID'       => '0.03';
requires 'MooseX::Types::Varchar'    => '0.05';
requires 'MooseX::Types::DBIx::Class' => '0.05';
requires 'Data::Validate::URI'       => '0.06';
requires 'MooseX::NonMoose'          => '0.22';
requires 'DBD::mysql'                => '4.022';
requires 'DBIx::Class'               => '0.08198';
requires 'DBIx::Class::TimeStamp'    => '0.14';
requires 'DBIx::Class::Helpers'      => '2.015';
requires 'DBIx::Class::PassphraseColumn' => '0.02';
requires 'DBIx::Class::ResultSet::RecursiveUpdate' => '0.25';
requires 'DBIx::Class::InflateColumn::Serializer' => '0.03';
requires 'DBIx::Class::UUIDColumns'  => '0.02006';

requires 'Redis'                     => '1.904'; #'1.951';
requires 'Dancer'                    => '1.3099';
requires 'Dancer::Plugin::Email'     => '0.13';
requires 'Dancer::Plugin::DBIC'      => '0.1506';
requires 'Dancer::Plugin::REST'      => '0.07';
requires 'Dancer::Plugin::Redis'     => '0.2';
requires 'Dancer::Plugin::Auth::Twitter' => '0.02';
requires 'Dancer::Logger::LogHandler' => '0.01';
requires 'Dancer::Logger::PSGI'      => '0.04';
requires 'Net::OAuth2'               => '0.07';
requires 'Net::OAuth::Yahoo'         => '0.06';
requires 'HTML::Parser'              => '3.69';

requires 'Plack'                          => '1.0002';
requires 'Plack::Middleware::Session'     => '0.14';
requires 'Plack::Middleware::CrossOrigin' => '0.007';
requires 'Plack::Middleware::ETag'        => '0.03';
requires 'Plack::Middleware::Deflater'    => '0.08';
requires 'Plack::Middleware::OAuth'       => '0.10';
requires 'Plack::Middleware::Rewrite'     => '1.005';
requires 'Plack::Session::Store::Redis'   => '0.03';
requires 'Plack::Session::Store::Redis'   => '0.03';
requires 'Starman'                        => '0.3';

requires 'WWW::Mixpanel' => '0.07';

#-- worker dependencies
requires 'AnyEvent::Redis'                => '0.23';
requires 'Log::Dispatch'                  => '2.32';
requires 'Net::Twitter'                   => '3.18';
requires 'Furl'                           => '0.40';
requires 'Text::Unidecode'                => '0.04';
requires 'Data::Section::Simple'          => '0.03';
requires 'MooseX::LogDispatch'            => '1.2002';
requires 'Backticks'                      => '1.0.9';
requires 'Email::Simple'                  => '2.1';
requires 'Email::Sender'                  => '0.12';

test_requires 'Test::Fatal';
test_requires 'Test::Exception';
test_requires 'Test::Moose::More';
test_requires 'Test::MockTime';
test_requires 'Test::Script'         => '1.05';

test_requires 'Config::YAML::Modern';


author_tests 'xt';

manifest_skip;
auto_set_repository;
auto_manifest;
#auto_license;
auto_include;
version_check;

auto_include_deps;
auto_install;
WriteAll;

