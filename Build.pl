use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'NYU::Libraries::PDS',
    license             => 'perl',
    dist_author         => 'Scot Dalton',
    dist_abstract       => 'NYU custom PDS controller.',
    build_requires => {
      # Testing Modules
      'Test::More' => '0.98',
      'Devel::Cover' => '1.03',
      'Test::Harness' => '3.28',
      'TAP::Harness::Archive' => '0.15',
      # PDS Prereqs
      'XML::Simple' => '2.20',
      'CGI::Session' => '4.48',
      'DBI' => '1.627',
      'Unicode::MapUTF8' => '1.11',
      'HTML::TagFilter' => '1.03',
      # LDAP Prereqs
      'Net::LDAP' => '0.56',
      'IO::Socket::SSL' => '1.951',
      # OAuth2 Prereqs
      'Dancer' => '1.1.3132',
      'Net::OAuth2' => '0.61'
    }
);

$builder->create_build_script();
