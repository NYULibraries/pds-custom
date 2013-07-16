use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);
use NYU::Libraries::PDS::IdentitiesControllers::AlephController;

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
can_ok($session, (qw(id institute barcode bor_status bor_type name uid email cn 
  givenname sn verification nyuidn nyu_shibboleth ns_ldap edupersonentitlement objectclass 
    ill_permission college_code college_name dept_code dept_name major_code major session_id
      calling_system target_url new find to_xml)));


# Create a new session based on an Aleph Identity
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
my $controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);
my $identity = $controller->create("DS03D", "TEST");
my $new_session = NYU::Libraries::PDS::Session->new($identity);
is($new_session->to_xml(), 
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
  "<session>".
    "<id>DS03D</id>".
    "<institute>NYU</institute>".
    "<bor_status>03</bor_status>".
    "<name>DS03D, TEST-RECORD</name>".
    "<verification>TEST</verification>".
    "<ill_permission>N</ill_permission>".
  "</session>", "Unexpected session xml");

# my $existing_session = NYU::Libraries::PDS::Session::find('27620139407145177581349399004532');
# print $existing_session;
