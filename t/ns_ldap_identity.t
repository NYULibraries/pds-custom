use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Models::NsLdapIdentity') };

# Get an instance of NsLdapIdentity
my $identity = NYU::Libraries::PDS::Models::NsLdapIdentity->new();

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a NsLdapIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Models::NsLdapIdentity));

# Verify methods
can_ok($identity, (qw(id cn givenname sn mail role aleph_identifer error conf)));
