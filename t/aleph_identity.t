use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::Aleph') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::Aleph' );

# Get an instance of Aleph identity
my $identity = NYU::Libraries::PDS::Identities::Aleph->new({shared_secret => 'EncryptThis'}, "N12162279");

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a Aleph identity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify methods
can_ok($identity, (qw(error id encrypt barcode verification expiry_date birthplace bor_status
  bor_type bor_name mail ill_permission birthplace college_code college_name dept_code dept_name major_code major)));

# Verify identity is defined
ok(defined($identity->{'identity'}));
is($identity->{'identity'}->{'id'}, "N12162279", "Should have identity id");
is($identity->{'identity'}->{'mail'}, "std5\@nyu.edu", "Should have identity mail");
is($identity->{'identity'}->{'birthplace'}, "PLIF LOADED", "Should have identity mail");

# Verify attributes not yet set
is($identity->id, undef, "Should not have mail attribute");
is($identity->mail, undef, "Should not have mail attribute");

# Verify attributes are set
$identity->set_attributes();
is($identity->id, "N12162279", "Should not have mail attribute");
is($identity->mail, "std5\@nyu.edu", "Should not have mail attribute");

# Verify encryption attributes
is($identity->verification, "DALT", "Should have unencrypted verification");
$identity->encrypt(1);
$identity->set_attributes();
is($identity->verification, "85db3f2529a3e4e9a28135491006ce3f", "Should have encrypted verification");
