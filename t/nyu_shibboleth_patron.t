use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Models::NyuShibbolethPatron') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Models::NyuShibbolethPatron' );

# Get an instance of NyuShibbolethPatron
my $session = NYU::Libraries::PDS::Models::NyuShibbolethPatron->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a ShibbolethSession
isa_ok($session, qw(NYU::Libraries::PDS::Models::NyuShibbolethPatron));

# Verify methods
can_ok($session, (qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement)));
