use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::XService::Aleph::BorByKey') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::XService::Aleph::BorByKey' );

# Get an instance of XService::Aleph::BorByKey
my $bor_by_key = NYU::Libraries::XService::Aleph::BorByKey->new();

# Verify that this a XService::Aleph::Base
isa_ok($bor_by_key, qw(NYU::Libraries::XService::Aleph::Base));

# Verify that this a XService::Aleph::BorByKey
isa_ok($bor_by_key, qw(NYU::Libraries::XService::Aleph::BorByKey));
