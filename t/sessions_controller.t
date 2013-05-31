use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Controllers::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Controllers::SessionsController' );

# Get an instance of SessionController
my $controller = NYU::Libraries::PDS::Controllers::SessionsController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::Controllers::SessionsController));

# Verify methods
can_ok($controller, (qw(pds_handle institute calling_system target_url)));
