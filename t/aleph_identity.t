use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Identities::Aleph') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Identities::Aleph' );

# Get an instance of Aleph identity
my $identity = NYU::Libraries::PDS::Identities::Aleph->new({shared_secret => 'EncryptThis', lookup_only => 1}, "N12162279");

# Verify that this a Class::Accessor
isa_ok($identity, qw(Class::Accessor));

# Verify that this a Identity::Base
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Base));

# Verify that this a Aleph identity
isa_ok($identity, qw(NYU::Libraries::PDS::Identities::Aleph));

# Verify methods
can_ok($identity, (qw(error encrypt id email cn givenname sn bor_name
  verification barcode expiry_date bor_status bor_type ill_permission
    college_code college_name dept_code dept_name major_code major plif_status
      new authenticate set_attributes get_attributes to_h to_xml)));

# Verify identity is defined
ok(defined($identity->{'identity'}));
is($identity->{'identity'}->{'id'}, "N12162279", "Should have identity id");
is($identity->{'identity'}->{'email'}, "std5\@nyu.edu", "Should have identity mail");
is($identity->{'identity'}->{'plif_status'}, "PLIF LOADED", "Should have identity plif status");

# Verify attributes not yet set
is($identity->id, undef, "Should not have mail attribute");
is($identity->email, undef, "Should not have mail attribute");

# Verify attributes are set
$identity->encrypt(1);
$identity->set_attributes();
is($identity->id, "N12162279", "Should have id attribute");
is($identity->email, "std5\@nyu.edu", "Should have email attribute");
is($identity->plif_status, "PLIF LOADED", "Should have plif status attribute");
is($identity->verification, "85db3f2529a3e4e9a28135491006ce3f", "Should have encrypted verification");

# Get a new instance of Aleph identity
$identity = NYU::Libraries::PDS::Identities::Aleph->new({shared_secret => 'EncryptThis', lookup_only => 1}, "N12162279");

# Verify identity is defined
ok(defined($identity->{'identity'}));
is($identity->{'identity'}->{'id'}, "N12162279", "Should have identity id");
is($identity->{'identity'}->{'email'}, "std5\@nyu.edu", "Should have identity email");
is($identity->{'identity'}->{'plif_status'}, "PLIF LOADED", "Should have identity plif status");
is($identity->{'identity'}->{'bor_status'}, "51", "Should have identity bor status");

# Verify attributes not yet set
is($identity->id, undef, "Should not have id attribute");
is($identity->email, undef, "Should not have email attribute");

# Verify attributes are set
$identity->set_attributes();
is($identity->id, "N12162279", "Should have id attribute");
is($identity->email, "std5\@nyu.edu", "Should have email attribute");
is($identity->plif_status, "PLIF LOADED", "Should have plif status attribute");
is($identity->verification, "DALT", "Should have encrypted verification");

# Verify XML
is($identity->to_xml(), 
  "<aleph>".
    "<name>DALTON,SCOT THOMAS</name>".
    "<bor_name>DALTON,SCOT THOMAS</bor_name>".
    "<verification>DALT</verification>".
    "<expiry_date>20131031</expiry_date>".
    "<bor_status>51</bor_status>".
    "<bor_type>CB</bor_type>".
    "<ill_permission>N</ill_permission>".
    "<plif_status>PLIF LOADED</plif_status>".
  "</aleph>", "Should have XML");

# Get a new instance of Aleph identity
$identity = NYU::Libraries::PDS::Identities::Aleph->new(
  {shared_secret => 'EncryptThis', flat_file => "./t/support/patrons.dat", lookup_only => 1}, "N18158418");

# Verify identity is defined
ok(defined($identity->{'identity'}));
is($identity->{'identity'}->{'id'}, "N18158418", "Should have identity id");
is($identity->{'identity'}->{'email'}, "ba36\@nyu.edu", "Should have identity email");
is($identity->{'identity'}->{'plif_status'}, "PLIF LOADED", "Should have identity plif_status");
is($identity->{'identity'}->{'bor_status'}, "65", "Should have identity bor status");

# Verify attributes not yet set
is($identity->id, undef, "Should not have mail attribute");
is($identity->email, undef, "Should not have mail attribute");

# Verify attributes are set
$identity->encrypt(1);
$identity->set_attributes();
is($identity->id, "N18158418", "Should not have mail attribute");
is($identity->email, "ba36\@nyu.edu", "Should not have mail attribute");
is($identity->bor_status, "65", "Should not have bor status attribute");
is($identity->verification, "ALTE", "Should have unencrypted verification");

# Get a new instance of Aleph identity
$identity = NYU::Libraries::PDS::Identities::Aleph->new(
  {shared_secret => 'EncryptThis', flat_file => "./t/support/patrons.dat",
    xserver_host => 'http://alephstage.library.nyu.edu'}, "DS03D", "TEST");

# Verify identity is defined
ok(defined($identity->{'identity'}));
is($identity->{'identity'}->{'id'}, "DS03D", "Should have identity id");
is($identity->{'identity'}->{'email'}, "", "Should have identity email");
is($identity->{'identity'}->{'plif_status'}, "PLIF LOADED", "Should have identity birthplace");
is($identity->{'identity'}->{'bor_status'}, "03", "Should have identity bor status");

# Verify attributes not yet set
is($identity->id, undef, "Should not have id attribute");
is($identity->email, undef, "Should not have email attribute");

# Verify attributes are set
$identity->encrypt(1);
$identity->set_attributes();
is($identity->id, "DS03D", "Should have id attribute");
is($identity->bor_status, "03", "Should have bor status attribute");
is($identity->verification, "TEST", "Should have unencrypted verification since this is an authenticate");

# Get a new instance of Aleph identity
$identity = NYU::Libraries::PDS::Identities::Aleph->new(
  {shared_secret => 'EncryptThis', flat_file => "./t/support/patrons.dat",
    xserver_host => 'http://alephstage.library.nyu.edu'}, "DS03D", "FAIL");

# Verify identity is defined
ok(!defined($identity->{'identity'}));
is($identity->error, "Authentication error: Error in Verification", "Should have error");

# Verify attributes not yet set
is($identity->id, undef, "Should not have id attribute");
is($identity->email, undef, "Should not have email attribute");

# Verify attributes are set
$identity->encrypt(1);
$identity->set_attributes();
is($identity->id, undef, "Should not have id attribute");
is($identity->email, undef, "Should not have email attribute");
is($identity->bor_status, undef, "Should not have bor status attribute");
is($identity->verification, undef, "Should not have verification");
is($identity->error, "No identity set.", "Should have error");
