use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::Util') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::Util' );
