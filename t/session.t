use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Session') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Session' );

# Get an instance of Session
my $session = NYU::Libraries::PDS::Session->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a Session
isa_ok($session, qw(NYU::Libraries::PDS::Session));

# Verify methods
can_ok($session, (qw(id)));

# my $existing_session = NYU::Libraries::PDS::Session->find('27620139407145177581349399004532');
# print $existing_session;
