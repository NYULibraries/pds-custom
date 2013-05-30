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
      # PDS Prereqs
      'XML::Simple' => '2.20',
      'CGI::Session' => '4.48'
    }
);

$builder->create_build_script();
