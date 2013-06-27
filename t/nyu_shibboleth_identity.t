use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::NyuShibboleth') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::NyuShibboleth' );

# Get an instance of NyuShibbolethIdentity
my $identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new();

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a NyuShibbolethIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::NyuShibboleth));

# Verify methods
can_ok($identity, (qw(error id index authentication_instance authentication_method 
  context_class identity_provider aleph_identifier uid givenname mail cn sn edupersonentitlement)));
