use strict;
use warnings;
use Test::More qw(no_plan);

# Include PDS core modules
use lib "lib/pds-core/program";

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of PDS::SessionController
my $controller = NYU::Libraries::PDS::SessionsController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a PDS::SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::SessionsController));

can_ok($controller, (qw(pds_handle institute calling_system target_url)));
