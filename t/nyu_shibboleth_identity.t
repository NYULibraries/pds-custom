use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Models::NyuShibbolethIdentity') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Models::NyuShibbolethIdentity' );

# Get an instance of NyuShibbolethIdentity
my $patron = NYU::Libraries::PDS::Models::NyuShibbolethIdentity->new();

# Verify that this a Class::Accessor
isa_ok($patron, qw(Class::Accessor));

# Verify that this a NyuShibbolethIdentity
isa_ok($patron, qw(NYU::Libraries::PDS::Models::NyuShibbolethIdentity));

# Verify methods
can_ok($patron, (qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement)));
