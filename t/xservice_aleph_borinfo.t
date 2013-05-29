use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::XService::Aleph::BorInfo') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::XService::Aleph::BorInfo' );

# Get an instance of XService::Aleph::BorInfo
my $bor_info = NYU::Libraries::XService::Aleph::BorInfo->new();

# Verify that this a XService::Aleph::Base
isa_ok($bor_info, qw(NYU::Libraries::XService::Aleph::Base));

# Verify that this a XService::Aleph::BorInfo
isa_ok($bor_info, qw(NYU::Libraries::XService::Aleph::BorInfo));
