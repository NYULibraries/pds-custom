use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::NsLdap') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::NsLdap' );

# Get an instance of NsLdapIdentity
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
$conf->{ssl_cert_path} = undef;
my $identity = NYU::Libraries::PDS::Identities::NsLdap->new($conf, "jonesa", "FAIL");

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a NsLdapIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::NsLdap));

# Verify methods
can_ok($identity, (qw(error exists id email cn givenname sn aleph_identifer
  role new authenticate set_attributes get_attributes to_h to_xml)));

is($identity->error, "User bind failed. Invalid credentials", "Should have error");

$identity = NYU::Libraries::PDS::Identities::NsLdap->new($conf, "dalton", "FAIL");

is($identity->error, "No record returned for given id.", "Should have error");
