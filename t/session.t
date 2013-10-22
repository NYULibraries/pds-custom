use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);
use NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;

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
  givenname sn verification nyuidn nyu_shibboleth ns_ldap entitlements objectclass 
    ill_permission college_code college_name dept_code dept_name major_code major ill_library 
      session_id calling_system target_url new find to_xml remote_address)));


# Create a new session based on an Aleph Identity
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
my $controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);
my $identity = $controller->create("DS03D", "TEST");
my $new_session = NYU::Libraries::PDS::Session->new($identity);
is($new_session->to_xml(), 
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
  "<session>".
    "<id>DS03D</id>".
    "<email>DS03D\@nyu.edu</email>".
    "<givenname>TEST-RECORD</givenname>".
    "<cn>DS03D, TEST-RECORD</cn>".
    "<sn>DS03D</sn>".
    "<institute>NYU</institute>".
    "<bor_status>03</bor_status>".
    "<name>TEST-RECORD</name>".
    "<verification>TEST</verification>".
    "<ill_permission>N</ill_permission>".
    "<expiry_date>20330930</expiry_date>".
  "</session>", "Unexpected session xml");

$conf->{xserver_host} = undef;
$controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);
$identity = $controller->get("N12162279");
$new_session = NYU::Libraries::PDS::Session->new($identity);
is($new_session->to_xml(), 
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
  "<session>".
    "<id>N12162279</id>".
    "<email>std5\@nyu.edu</email>".
    "<givenname>SCOT THOMAS</givenname>".
    "<cn>DALTON,SCOT THOMAS</cn>".
    "<sn>DALTON</sn>".
    "<institute>NYU</institute>".
    "<bor_status>55</bor_status>".
    "<bor_type>CB</bor_type>".
    "<name>SCOT THOMAS</name>".
    "<verification>d4465aacaa645f2164908cd4184c09f0</verification>".
    "<ill_permission>N</ill_permission>".
    "<expiry_date>20140215</expiry_date>".
  "</session>", "Unexpected session xml");

# my $existing_session = NYU::Libraries::PDS::Session::find('27620139407145177581349399004532');
# print $existing_session;

# Test HSL patron session
$conf->{xserver_host} = undef;
$controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);
$identity = $controller->get("N18545480");
$new_session = NYU::Libraries::PDS::Session->new($identity);
is($new_session->ill_library, "ILL_MED", "Session should be have an HSL ILL library");
is($new_session->institute, "HSL", "Session should be have an HSL institute");

# NYU Shibboleth session
# Set the enviromnent variables
$ENV{'uid'} = 'uid';
$ENV{'email'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N12162279';
# Get a new instance of NyuShibbolethIdentity
$controller = NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController->new($conf);
$identity = $controller->create();
$controller = NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($conf);
my $aleph_identity = $controller->get($identity->aleph_identifier);
$new_session = NYU::Libraries::PDS::Session->new($identity, $aleph_identity);
is($new_session->entitlements, "some:entitlements", "Session should be have an edu person entitlement");
is($new_session->{entitlements}, "some:entitlements", "Session should be have an edu person entitlement");
