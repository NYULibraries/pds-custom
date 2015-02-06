use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# JSON functions
use JSON qw(decode_json);

use constant NYU_LOGIN => '/Location: https://dev.login.library.nyu.edu/';
use constant NS_LOGIN => '/Location: https://dev.login.library.nyu.edu/';
use constant NYU_LOGOUT => '/Location: https://dev.login.library.nyu.edu/logout/';

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of SessionController
my $conf;
if($ENV{'CONFIG_BASEPATH'}) {
  $conf = parse_conf($ENV{'CONFIG_BASEPATH'}."config/pds/nyu.conf");
} else {
  $conf = parse_conf("config/pds/nyu.conf");
}
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

# When there is no session just redirect to the target url
like($controller->sso(), '/Location: http:\/\/example.com/', "Should redirect to target url");

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
