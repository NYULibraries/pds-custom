use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Models::Session') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Models::Session' );

# Get an instance of Session
my $session = NYU::Libraries::PDS::Models::Session->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a Session
isa_ok($session, qw(NYU::Libraries::PDS::Models::Session));

# Verify methods
can_ok($session, (qw(id)));
