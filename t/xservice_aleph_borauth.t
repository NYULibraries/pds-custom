use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::XService::Aleph::BorAuth') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::XService::Aleph::BorAuth' );

# Get an instance of XService::Aleph::BorAuth
my $bor_auth = NYU::Libraries::XService::Aleph::BorAuth->new();

# Verify that this a XService::Aleph::Base
isa_ok($bor_auth, qw(NYU::Libraries::XService::Aleph::Base));

# Verify that this a XService::Aleph::BorAuth
isa_ok($bor_auth, qw(NYU::Libraries::XService::Aleph::BorAuth));
