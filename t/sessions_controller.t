use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

use JSON qw(decode_json);

use constant NYU_LOGIN => '/Location: https://dev.login.library.nyu.edu/';
use constant NS_LOGIN => '/Location: https://dev.login.library.nyu.edu/';
use constant NYU_LOGOUT => '/Location: https://dev.login.library.nyu.edu/logout/';

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of SessionController
my $conf = parse_conf("custom/vendor/pds-core/config/pds/nyu.conf");
$conf->{ssl_cert_path} = undef;
my $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::SessionsController));

# Verify methods
can_ok($controller, (qw(institute calling_system target_url current_url cleanup_url session_id error)));

# The following tests will only pass if the CI environment variable is set.
if($ENV{'CI'}) {
  print STDERR "\nSet the CI ENV variable for these tests to pass.\n".
  "\n\te.g. export CI=true\n\n";
  isnt($ENV{'CI'}, undef, "CI environment variable should be defined");
  exit;
}

like($controller->_login_screen(), NYU_LOGIN, "Unexpected login redirect");

# Get another instance of SessionController
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NS", "primo", "http://example.com");
like($controller->_login_screen(), NS_LOGIN, "Unexpected login NS html");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test error undefined after authenticate
is($controller->error, undef, "Error should be undefined");
is(defined($controller->error), '', "Error should be undefined");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test logout screen
like($controller->_logout_screen(), NYU_LOGOUT, "Should be a logout screen.");

my $entitlements = 'urn:mace:nyu.edu:entl:its:wikispriv;urn:mace:nyu.edu:entl:its:classes;urn:mace:nyu.edu:entl:its:qualtrics;urn:mace:nyu.edu:entl:lib:eresources;urn:mace:nyu.edu:entl:its:wikispub;urn:mace:nyu.edu:entl:its:lynda;urn:mace:nyu.edu:entl:lib:ideaexchange;urn:mace:nyu.edu:entl:its:files;urn:mace:incommon:entitlement:common:1';
my $json_response = '{"id":1,"username":"xx10","email":"dev@library.nyu.edu","admin":true,"created_at":"2014-02-24T22:13:00.529Z","updated_at":"2015-02-04T21:36:34.275Z","institution_code":"NYU","provider":"nyu_shibboleth","identities":[{"id":17,"user_id":1,"provider":"aleph","uid":"1234567890","properties":{"type":"","major":"Web Services","status":"51","college":"Division of Libraries","department":"IT Services \u0026 Media Services","identifier":"1234567890","ill_library":"","patron_type":"","plif_status":"PLIF LOADED","patron_status":"51","ill_permission":"Y","institution_code":"NYU"},"created_at":"2014-10-17T17:38:43.095Z","updated_at":"2015-02-03T17:23:15.150Z"},{"id":1,"user_id":1,"provider":"nyu_shibboleth","uid":"xx10","properties":{"uid":"xx10","name":"Dev Eloper","email":"dev@lirbary.nyu.edu","extra":{"raw_info":{"nyuidn":"1234567890","entitlement":"'.$entitlements.'"}},"nyuidn":"1234567890","nickname":"Mickie","last_name":"Eloper","first_name":"Dev","entitlement":"'.$entitlements.'","institution_code":"NYU"},"created_at":"2014-02-24T22:13:00.565Z","updated_at":"2015-02-04T21:36:34.307Z"}]}';
my $decoded_json = decode_json($json_response);
my $identities = $decoded_json->{'identities'};
my $aleph_identity = $controller->_aleph_identity($identities);
is($aleph_identity->{'provider'}, "aleph", "Should return aleph identity");
my $nyu_shibboleth_identity = $controller->_nyu_shibboleth_identity($identities);
is($nyu_shibboleth_identity->{'provider'}, "nyu_shibboleth", "Should return NYU Shibboleth identity");

$ENV{'uid'} = 'uid';
$ENV{'email'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N12162279';
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezproxy", "http://login.library.nyu.edu/ezproxy?url=http://example.com");
# Should redirect to EZ proxy unauthorized page
# is($controller->ezproxy, redirect_html("http://library.nyu.edu/errors/ezproxy-library-nyu-edu/login.html"), "Should redirect to ezproxy unauthorized");

$ENV{'nyuidn'}='DS03D';
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezborrow", "http://login.library.nyu.edu/ezborrow?query=ezborrow");
# is($controller->ezborrow, redirect_html("http://library.nyu.edu/errors/ezborrow-library-nyu-edu/login.html"), "Should redirect to ezborrow unauthorized");

$ENV{'uid'} = 'uid';
$ENV{'email'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N12162279';
