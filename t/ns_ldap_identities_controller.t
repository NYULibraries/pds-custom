use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::NsLdapController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController' );

# Get an instance of NsLdapController
my $controller = NYU::Libraries::PDS::IdentitiesControllers::NsLdapController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a BaseController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController));

# Verify that this a NsLdapController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::NsLdapController));

# Verify methods
can_ok($controller, (qw(create)));


1;
