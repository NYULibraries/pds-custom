use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::NyuShibboleth') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::NyuShibboleth' );

# Get an instance of NyuShibbolethIdentity
my $identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new();
is($identity->error, "No configuration set.", "Should be error on new");

# Get an instance of NyuShibbolethIdentity
$identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new({});

# Verify no error
is($identity->error, undef, "Should not be error on new");

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a NyuShibbolethIdentity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::NyuShibboleth));

# Verify methods
can_ok($identity, (qw(error exists id email givenname cn sn aleph_identifier
  edupersonentitlement new authenticate set_attributes get_attributes to_h
    to_xml)));

is($identity->exists, undef, "Identity should not exist");

# Set the enviromnent variables
$ENV{'uid'} = 'uid';
$ENV{'mail'}='email@nyu.edu';
$ENV{'eppn'}='some:entitlements';
$ENV{'nyuidn'}='N123456789';

# Get a new instance of NyuShibbolethIdentity
$identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new({});
is($identity->exists, 1, "Identity should exist");
is($identity->id, "uid", "Should have id attribute");
is($identity->email, "email\@nyu.edu", "Should have email attribute");
is($identity->edupersonentitlement, "some:entitlements", "Should have edupersonentitlement attribute");
is($identity->aleph_identifier, "N123456789", "Should have aleph identifier attribute");

