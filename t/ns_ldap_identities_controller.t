use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::IdentitiesControllers::NsLdapController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::IdentitiesControllers::NsLdapController' );

# Get an instance of NsLdapController
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
$conf->{ssl_cert_path} = undef;
my $controller = NYU::Libraries::PDS::IdentitiesControllers::NsLdapController->new($conf);

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a BaseController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController));

# Verify that this a NsLdapController
isa_ok($controller, qw(NYU::Libraries::PDS::IdentitiesControllers::NsLdapController));

# Verify methods
can_ok($controller, (qw(create error)));

# Try a create with an invalid password
my $identity = $controller->create("ajones", "FAIL");

# Verify that this an NsLdapIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::NsLdap));

# Verify that this NsLdapIdentity doesn't exist
is($identity->exists, undef, "Should not exist");

