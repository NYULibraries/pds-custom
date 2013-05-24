use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'NYU::Libraries::PDS',
    license             => 'perl',
    dist_author         => 'Scot Dalton',
    dist_abstract       => 'NYU custom PDS controller.',
    build_requires => {
      'Test::More' => '0.98',
      'Devel::Cover' => '1.03',
      'Test::Harness' => '3.28'
    }
);

$builder->create_build_script();
