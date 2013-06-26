use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Models::NsLdapIdentity') };

# Get an instance of NsLdapIdentity
my $patron = NYU::Libraries::PDS::Models::NsLdapIdentity->new();

# Verify that this a Class::Accessor
isa_ok($patron, qw(Class::Accessor));

# Verify that this a NsLdap
isa_ok($patron, qw(NYU::Libraries::PDS::Models::NsLdapIdentity));

# Verify methods
can_ok($session, (qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement)));
