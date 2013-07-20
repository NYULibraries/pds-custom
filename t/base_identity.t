use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::Base') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::Base' );

# Get an instance of Aleph identity
my $identity = NYU::Libraries::PDS::Identities::Base->new();

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a Identity::Base
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Base));

# Verify methods
can_ok($identity, (qw(error exists id email cn givenname sn
   new authenticate set_attributes get_attributes to_h to_xml)));
