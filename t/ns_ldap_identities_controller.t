use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::NsLdapController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController' );

# Get an instance of NyuShibbolethController
my $controller = NYU::Libraries::PDS::IdentitiesControllers::NsLdapController->new();

1;
