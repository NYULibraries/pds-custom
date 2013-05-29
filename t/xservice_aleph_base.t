use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::XService::Aleph::Base') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::XService::Aleph::Base' );

# Get an instance of XService::Aleph::Base
my $base = NYU::Libraries::XService::Aleph::Base->new();

# Verify that this a XService::Base
isa_ok($base, qw(NYU::Libraries::XService::Base));

# Verify that this a XService::Aleph::Base
isa_ok($base, qw(NYU::Libraries::XService::Aleph::Base));
