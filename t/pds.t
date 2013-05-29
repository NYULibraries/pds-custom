use strict;
use warnings;
use Test::More qw(no_plan);

# Include PDS core modules
use lib "lib/pds-core/program";

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS' );

# Get an instance of PDS::Session
my $controller = NYU::Libraries::PDS::controller();

# Verify that this a PDS::SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::SessionsController));
