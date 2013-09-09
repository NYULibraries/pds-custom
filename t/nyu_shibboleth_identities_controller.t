use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NsLdapController' );

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController' );

# Get an instance of NyuShibbolethController
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
my $controller = NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController->new($conf);

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a BaseController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController));

# Verify that this a NyuShibbolethController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController));

# Verify methods
can_ok($controller, (qw(target_url current_url new create redirect_to_target
  been_there_done_that institute)));

is($controller->create(), undef, 'Should short circuit for passive login');

# Set the enviromnent variables
$ENV{'uid'} = 'uid';
$ENV{'mail'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N123456789';
