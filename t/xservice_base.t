use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::XService::Base') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::XService::Base' );

# Get an instance of XService::Base
my $base = NYU::Libraries::XService::Base->new();

# Verify that this an Exporter
isa_ok($base, qw(Exporter));

# Verify that this a XService::Base
isa_ok($base, qw(NYU::Libraries::XService::Base));
