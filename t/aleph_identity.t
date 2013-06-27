use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::Aleph') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::Aleph' );

# Get an instance of AlephIdentity
my $patron = NYU::Libraries::PDS::Identities::Aleph->new();

# Verify that this a Class::Accessor
isa_ok($patron, qw(Class::Accessor));

# Verify that this a AlephIdentity
isa_ok($patron, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify methods
can_ok($patron, (qw(error id encrypt barcode verification expiry_date birthplace bor_status
  bor_type bor_name mail ill_permission birthplace college_code college_name dept_code dept_name major_code major)));
