use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController' );

# Get an instance of NyuShibbolethController
my $controller = NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a NyuShibbolethController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController));

# Verify methods
can_ok($controller, (qw(target_url)));
