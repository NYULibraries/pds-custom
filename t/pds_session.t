use strict;
use warnings;
use Test::More qw(no_plan);

# Include PDS core modules
use lib "lib/pds-core/program";

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Session') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Session' );

# Get an instance of PDS::Session
my $session = NYU::Libraries::PDS::Session->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a PDS::Session
isa_ok($session, qw(NYU::Libraries::PDS::Session));

can_ok($session, (qw(pds_handle)));
