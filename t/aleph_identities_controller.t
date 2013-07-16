use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::AlephController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::AlephController' );

# Get an instance of AlephController
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
my $controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a BaseController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController));

# Verify that this a AlephController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::AlephController));

# Verify methods
can_ok($controller, (qw(new create get)));

# Try a create with a valid password
my $identity = $controller->create("DS03D", "TEST");

# Verify that this an AlephIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify that this AlephIdentity exists
is($identity->exists, 1, "Should exist");

# Try a create with an invalid password
$identity = $controller->create("DS03D", "FAIL");

# Verify that this an AlephIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify that this AlephIdentity doesn't exist
is($identity->exists, undef, "Should not exist");

# Try a create with an invalid user
$identity = $controller->create("INVALID", "TEST");

# Verify that this an AlephIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify that this AlephIdentity doesn't exist
is($identity->exists, undef, "Should not exist");


# Try a get with a valid user
$identity = $controller->get("DS03D");

# Verify that this an AlephIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify that this AlephIdentity exists
is($identity->exists, 1, "Should exist");

# Try a get with an invalid user
$identity = $controller->get("INVALID");

# Verify that this an AlephIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify that this AlephIdentity doesn't exist
is($identity->exists, undef, "Should not exist");
