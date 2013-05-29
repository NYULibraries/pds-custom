use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::Shibboleth::Session') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::Shibboleth::Session' );

# Get an instance of Shibboleth::Session
my $session = NYU::Libraries::Shibboleth::Session->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a Shibboleth::Session
isa_ok($session, qw(NYU::Libraries::Shibboleth::Session));

can_ok($session, (qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement)));
