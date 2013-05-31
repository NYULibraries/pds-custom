use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Controllers::NyuShibbolethPatronsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Controllers::NyuShibbolethPatronsController' );

# Get an instance of NyuShibbolethPatronsController
my $controller = NYU::Libraries::PDS::Controllers::NyuShibbolethPatronsController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a NyuShibbolethPatronsController
isa_ok($controller, qw(NYU::Libraries::PDS::Controllers::NyuShibbolethPatronsController));

# Verify methods
can_ok($controller, (qw(mode session idp_url target_url)));
