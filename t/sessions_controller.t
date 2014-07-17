use strict;
use warnings;
use Test::More qw(no_plan);

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

use constant NYU_LOGIN => "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/nyu.css\" />
    <script src=\"/assets/javascripts/application.js\" type=\"text/javascript\"></script>
  </head>
  <body>
    <header id=\"header\" class=\"header\">
      <div class=\"parent\"><a href=\"http://library.nyu.edu\"><span>NYU Libraries</span></a></div>
      <div class=\"suite\"><span>BobCat</span></div>
      <div class=\"application\"><span>Login</span></div>
    </header>
    <nav id=\"nav1\" class=\"breadcrumb\">
      <ul class=\"nyu-breadcrumbs\">
        <li><a href=\"http://library.nyu.edu\">NYU Libraries</a></li>
        <li><a href=\"http://bobcat.library.nyu.edu\">BobCat</a></li>
        <li>Login</li>
      </ul>
    </nav>
    <section class=\"nyu-container container-fluid\">
      <div id=\"forms\" class=\"row-fluid\">
        <div id=\"shibboleth\" class=\"span5 well\">
          <h2>
            Login with an NYU NetID
            <a class=\"nyulibraries-help nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <p>
            <a href=\"/Shibboleth.sso/Login?target=http%3A%2F%2Flocalhost%2Fpds%3Ffunc%3Dsso%26institute%3DNYU%26calling_system%3Dprimo%26url%3Dhttp%253A%252F%252Fexample.com\" class=\"btn\">Click to Login</a>
          </p>
        </div>
        <div class=\"span5 well\">
          <h2>
            Login with a Consortium ID or a Bobst ID
            <a class=\"nyulibraries-help-snippet nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <form id=\"nyu_pds_login_form\" action=\"/pds\" method=\"post\">
            <fieldset>
              <input type=\"hidden\" name=\"func\" value=\"login\" />
              <input type=\"hidden\" name=\"calling_system\" value=\"primo\" />
              <input type=\"hidden\" name=\"institute\" value=\"NYU\" />
              <input type=\"hidden\" name=\"term1\" value=\"short\" />
              <input type=\"hidden\" name=\"selfreg\" value=\"\" />
              <input type=\"hidden\" name=\"url\" value=\"http://example.com\" />
              <input type=\"hidden\" name=\"pds_handle\" value=\"\" />
              <label for=\"bor_id\">Enter your ID Number</label>
              <input id=\"bor_id\" type=\"text\" name=\"bor_id\" value=\"\" placeholder=\"e.g. N12345678\" />
              <label for=\"bor_verification\">Password or first four letters of your last name</label>
              <input id=\"bor_verification\" type=\"password\" name=\"bor_verification\" placeholder=\"e.g. SMIT\" /><br/ >
              <button type=\"submit\" class=\"btn\">Login</button>
            </fieldset>
          </form>
        </div>
      </div>
    </section>
    <section class=\"nyu-container container-fluid\">
      <h3>
        Library services vary by institution. Please see the
        <a href=\"https://privileges.library.nyu.edu/\" target=\"_blank\">NYU Libraries Privileges Guide</a>.
      </h3>
    </section>
    <footer class=\"nyu-container\">NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
";
use constant NYU_LOGOUT => "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/nyu.css\" />
    <script src=\"/assets/javascripts/application.js\" type=\"text/javascript\"></script>
  </head>
  <body>
    <header id=\"header\" class=\"header\">
      <div class=\"parent\"><a href=\"http://library.nyu.edu\"><span>NYU Libraries</span></a></div>
      <div class=\"suite\"><span>BobCat</span></div>
      <div class=\"application\"><span>Logout</span></div>
    </header>
    <nav id=\"nav1\" class=\"breadcrumb\">
      <ul class=\"nyu-breadcrumbs\">
        <li><a href=\"http://library.nyu.edu\">NYU Libraries</a></li>
        <li><a href=\"http://bobcat.library.nyu.edu\">BobCat</a></li>
        <li>Logout</li>
      </ul>
    </nav>
    <h1 class=\"nyu-container container-fluid\"><a href=\"http://example.com\">Logout</a></h1>
    <footer class=\"nyu-container\">NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
";

sub nyu_login_screen_with_errors {
  my $error = shift;
  return "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/nyu.css\" />
    <script src=\"/assets/javascripts/application.js\" type=\"text/javascript\"></script>
  </head>
  <body>
    <header id=\"header\" class=\"header\">
      <div class=\"parent\"><a href=\"http://library.nyu.edu\"><span>NYU Libraries</span></a></div>
      <div class=\"suite\"><span>BobCat</span></div>
      <div class=\"application\"><span>Login</span></div>
    </header>
    <nav id=\"nav1\" class=\"breadcrumb\">
      <ul class=\"nyu-breadcrumbs\">
        <li><a href=\"http://library.nyu.edu\">NYU Libraries</a></li>
        <li><a href=\"http://bobcat.library.nyu.edu\">BobCat</a></li>
        <li>Login</li>
      </ul>
    </nav>
    <section class=\"nyu-container container-fluid\">
      <div id=\"forms\" class=\"row-fluid\">
        <div id=\"shibboleth\" class=\"span5 well\">
          <h2>
            Login with an NYU NetID
            <a class=\"nyulibraries-help nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <p>
            <a href=\"/Shibboleth.sso/Login?target=http%3A%2F%2Flocalhost%2Fpds%3Ffunc%3Dsso%26institute%3DNYU%26calling_system%3Dprimo%26url%3Dhttp%253A%252F%252Fexample.com\" class=\"btn\">Click to Login</a>
          </p>
        </div>
        <div class=\"span5 well\">
          <h2>
            Login with a Consortium ID or a Bobst ID
            <a class=\"nyulibraries-help-snippet nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <form id=\"nyu_pds_login_form\" action=\"/pds\" method=\"post\">
            <fieldset>
              <div class=\"alert alert-error\">
                $error
              </div>
              <input type=\"hidden\" name=\"func\" value=\"login\" />
              <input type=\"hidden\" name=\"calling_system\" value=\"primo\" />
              <input type=\"hidden\" name=\"institute\" value=\"NYU\" />
              <input type=\"hidden\" name=\"term1\" value=\"short\" />
              <input type=\"hidden\" name=\"selfreg\" value=\"\" />
              <input type=\"hidden\" name=\"url\" value=\"http://example.com\" />
              <input type=\"hidden\" name=\"pds_handle\" value=\"\" />
              <label for=\"bor_id\">Enter your ID Number</label>
              <input id=\"bor_id\" type=\"text\" name=\"bor_id\" value=\"\" placeholder=\"e.g. N12345678\" />
              <label for=\"bor_verification\">Password or first four letters of your last name</label>
              <input id=\"bor_verification\" type=\"password\" name=\"bor_verification\" placeholder=\"e.g. SMIT\" /><br/ >
              <button type=\"submit\" class=\"btn\">Login</button>
            </fieldset>
          </form>
        </div>
      </div>
    </section>
    <section class=\"nyu-container container-fluid\">
      <h3>
        Library services vary by institution. Please see the
        <a href=\"https://privileges.library.nyu.edu/\" target=\"_blank\">NYU Libraries Privileges Guide</a>.
      </h3>
    </section>
    <footer class=\"nyu-container\">NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
"
}

sub redirect_html {
  my $target_url = shift;
  return "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/nyu.css\" />
    <script src=\"/assets/javascripts/application.js\" type=\"text/javascript\"></script>
    <script type=\"text/javascript\">
      // Unescape the HTML entities that mustache escaped
      var target_url = \$(\"<var/>\").html(\"$target_url\").text();
      window.location = target_url;
    </script>
  </head>
  <body>
    <header id=\"header\" class=\"header\">
      <div class=\"parent\"><a href=\"http://library.nyu.edu\"><span>NYU Libraries</span></a></div>
      <div class=\"suite\"><span>BobCat</span></div>
      <div class=\"application\"><span>Login</span></div>
    </header>
    <nav id=\"nav1\" class=\"breadcrumb\">
      <ul class=\"nyu-breadcrumbs\">
        <li><a href=\"http://library.nyu.edu\">NYU Libraries</a></li>
        <li><a href=\"http://bobcat.library.nyu.edu\">BobCat</a></li>
        <li>Login</li>
      </ul>
    </nav>
    <h1 class=\"nyu-container container-fluid\"><a href=\"$target_url\">Click to continue</a></h1>
    <footer class=\"nyu-container\">NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
";
}

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of SessionController
my $conf = parse_conf("vendor/pds-core/config/pds/nyu.conf");
$conf->{ssl_cert_path} = undef;
my $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::SessionsController));

# Verify methods
can_ok($controller, (qw(institute calling_system target_url current_url cleanup_url session_id error)));

# The following tests will only pass if the CI environment variable is set.
unless($ENV{'CI'}) {
  print STDERR "\nSet the CI ENV variable for these tests to pass.\n".
  "\n\te.g. export CI=true\n\n";
  isnt($ENV{'CI'}, undef, "CI environment variable should be defined");
  exit;
}

is($controller->_login_screen(), NYU_LOGIN, "Unexpected login html");

# Get another instance of SessionController
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NS", "primo", "http://example.com");

is($controller->_login_screen(), "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/ns.css\" />
    <script src=\"/assets/javascripts/application.js\" type=\"text/javascript\"></script>
  </head>
  <body>
    <header id=\"header\" class=\"header\">
      <div class=\"parent\"><a href=\"http://library.newschool.edu/\"><span>New School University Libraries</span></a></div>
      <div class=\"suite\"><span>BobCat</span></div>
      <div class=\"application\"><span>Login</span></div>
    </header>
    <nav id=\"nav1\" class=\"breadcrumb\">
      <ul class=\"nyu-breadcrumbs\">
        <li><a href=\"http://library.newschool.edu/\">New School University Libraries</a></li>
        <li><a href=\"http://bobcat.library.nyu.edu/newschool\">BobCat</a></li>
        <li>Login</li>
      </ul>
    </nav>
    <h1 class=\"nyu-container container-fluid\">Please login to access library services.</h1>
    <section class=\"nyu-container container-fluid\">
      <div id=\"forms\" class=\"row-fluid\">
        <div class=\"span5 well\">
          <h2>
            Consortium or New School Patrons
            <a class=\"nyulibraries-help-snippet nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <form id=\"nyu_pds_login_form\" action=\"/pds\" method=\"post\">
            <fieldset>
              <input type=\"hidden\" name=\"func\" value=\"login\" />
              <input type=\"hidden\" name=\"calling_system\" value=\"primo\" />
              <input type=\"hidden\" name=\"institute\" value=\"NS\" />
              <input type=\"hidden\" name=\"term1\" value=\"short\" />
              <input type=\"hidden\" name=\"selfreg\" value=\"\" />
              <input type=\"hidden\" name=\"url\" value=\"http://example.com\" />
              <input type=\"hidden\" name=\"pds_handle\" value=\"\" />
              <label for=\"bor_id\">Enter your NetID Username</label>
              <input id=\"bor_id\" type=\"text\" name=\"bor_id\" value=\"\" placeholder=\"e.g. ParsJ123\" />
              <label for=\"bor_verification\">Enter your NetID Password</label>
              <input id=\"bor_verification\" type=\"password\" name=\"bor_verification\" placeholder=\"\" /><br/ >
              <button type=\"submit\" class=\"btn\">Login</button>
            </fieldset>
          </form>
          <div>
            <h3>Need more information?</h3>
            <ul>
              <li><a href=\"http://library.newschool.edu/login/cu\" target=\"_blank\">Cooper Union</a></li>
              <li><a href=\"http://library.newschool.edu/login/nysid\" target=\"_blank\">NYSID</a></li>
              <li><a href=\"http://library.newschool.edu/login/ns\" target=\"_blank\">New School</a></li>
              <li><a href=\"http://library.newschool.edu/login/hu\" target=\"_blank\">Hebrew Union</a></li>
              <li><a href=\"http://answers.library.newschool.edu\" target=\"_blank\">New School Ask-A-Librarian Service</a></li>
            </ul>
          </div>
        </div>
        <div id=\"shibboleth\" class=\"span5 well\">
          <h2>
            Login with an NYU NetID
            <a class=\"nyulibraries-help nyulibraries-help-icon\" href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">
              help
            </a>
          </h2>
          <p>
            <a href=\"/Shibboleth.sso/Login?target=http%3A%2F%2Flocalhost%2Fpds%3Ffunc%3Dsso%26institute%3DNS%26calling_system%3Dprimo%26url%3Dhttp%253A%252F%252Fexample.com\" class=\"btn\">Click to Login</a>
          </p>
          <div>
            <h3>Need more information?</h3>
            <ul>
              <li><a href=\"http://library.newschool.edu/login/cu\" target=\"_blank\">Cooper Union</a></li>
              <li><a href=\"http://library.newschool.edu/login/nysid\" target=\"_blank\">NYSID</a></li>
              <li><a href=\"http://library.newschool.edu/login/ns\" target=\"_blank\">New School</a></li>
              <li><a href=\"http://library.newschool.edu/login/hu\" target=\"_blank\">Hebrew Union</a></li>
              <li><a href=\"http://answers.library.newschool.edu\" target=\"_blank\">New School Ask-A-Librarian Service</a></li>
            </ul>
          </div>
        </div>
      </div>
    </section>
    <section class=\"nyu-container container-fluid\">
      <h3>
        Library services vary by institution. Please see the
        <a href=\"https://privileges.library.nyu.edu/\" target=\"_blank\">NYU Libraries Privileges Guide</a>.
      </h3>
    </section>
    <footer class=\"nyu-container\">BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
", "Unexpected login NS html");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Should redirect to example.com through cleanup

SKIP: {
  skip(1,1);
  is($controller->authenticate("DS03D", "TEST"), 
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=http%3A%2F%2Fexample.com"),
        "Authenticate should return redirect to example dot com through cleanup");
}

# Test error undefined after authenticate
is($controller->error, undef, "Error should be undefined");
is(defined($controller->error), '', "Error should be undefined");

SKIP: {
  skip(1,1);
  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://bobcatdev.library.nyu.edu/primo_library/libweb/action/search.do");
  # Should redirect to BobCat login through cleanup and "goto"
  is($controller->authenticate("DS03D", "TEST"),
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=".
      "https%3A%2F%2Flogindev.library.nyu.edu%2Fgoto%2Flogon%2Fhttp%3A%2F%2Fbobcatdev.library.nyu.edu%2Fprimo_library%2Flibweb%2Faction%2Fsearch.do%26pds_handle%3D0123456789"),
        "Authenticate should redirect to 'goto URL' through cleanup");
}

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test authenticate
is($controller->authenticate("DS03D", "FAIL"),
  nyu_login_screen_with_errors("There seems to have been a problem logging in. Please check your credentials."),
    "Authenticate should be login screen");
# Test error undefined after authenticate
isnt($controller->error, undef, "Error should be defined");
isnt(defined($controller->error), '', "Error should be defined");
is($controller->error, "There seems to have been a problem logging in. ".
  "Please check your credentials.", "Error should be defined");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test logout screen
is($controller->_logout_screen(), NYU_LOGOUT, "Should be a logout screen.");

$ENV{'uid'} = 'uid';
$ENV{'email'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N12162279';
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezproxy", "http://login.library.nyu.edu/ezproxy?url=http://example.com");
# Should redirect to EZ proxy unauthorized page
is($controller->ezproxy, redirect_html("http://library.nyu.edu/errors/ezproxy-library-nyu-edu/login.html"),
  "Should redirect to ezproxy unauthorized");

SKIP: {
  skip(1,1);
  # Need to revisit
  $ENV{'entitlement'}='urn:mace:nyu.edu:entl:lib:eresources';
  $conf->{ezproxy_secret} = "SecretSauce";
  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezproxy", "http://login.library.nyu.edu/ezproxy?url=http://example.com");
  like($controller->ezproxy, '/https:\/\/ezproxydev\.library\.nyu\.edu\/login\?ticket=[a-z0-9]+%24u[0-9]+%24gDefault&user=uid&qurl=http%3A%2F%2Fexample.com/', "Should redirect to ezproxy");
}

$ENV{'nyuidn'}='DS03D';
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezborrow", "http://login.library.nyu.edu/ezborrow?query=ezborrow");
is($controller->ezborrow, redirect_html("http://library.nyu.edu/errors/ezborrow-library-nyu-edu/login.html"),
    "Should redirect to ezborrow unauthorized");

SKIP: {
  skip(1,1);
  $ENV{'nyuidn'}='N18158418';
  $conf->{flat_file} = "./t/support/patrons.dat";
  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "ezborrow", "http://login.library.nyu.edu/ezborrow?query=ezborrow");
  is($controller->ezborrow, 
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=".
      "https%3A%2F%2Fe-zborrow.relaisd2d.com%2Fservice-proxy%2F%3Fcommand%3Dmkauth%26LS%3DNYU%26PI%3D21142226710882%26query%3D"),
        "Should redirect to ezborrow through cleanup");
}

$ENV{'uid'} = 'uid';
$ENV{'email'}='email@nyu.edu';
$ENV{'entitlement'}='some:entitlements';
$ENV{'nyuidn'}='N12162279';

SKIP: {
  skip(1, 5);
  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
  # Should redirect to example.com through cleanup
  is($controller->sso,
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=http%3A%2F%2Fexample.com"),
      "SSO should redirect to example dot com through cleanup");

  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
  # Should redirect to example.com through cleanup
  is($controller->load_login,
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=http%3A%2F%2Fexample.com"),
      "Load login should redirect to example dot com through cleanup");

  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://bobcatdev.library.nyu.edu/primo_library/libweb/action/search.do");
  # Should redirect to BobCat login through cleanup and "goto"
  is($controller->sso,
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=".
      "https%3A%2F%2Flogindev.library.nyu.edu%2Fgoto%2Flogon%2Fhttp%3A%2F%2Fbobcatdev.library.nyu.edu%2Fprimo_library%2Flibweb%2Faction%2Fsearch.do%26pds_handle%3D0123456789"),
        "SSO should redirect to 'goto URL' through cleanup");

  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://bobcatdev.library.nyu.edu/primo_library/libweb/action/search.do");
  # Should redirect to BobCat login through cleanup and "goto"
  is($controller->load_login,
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=".
      "https%3A%2F%2Flogindev.library.nyu.edu%2Fgoto%2Flogon%2Fhttp%3A%2F%2Fbobcatdev.library.nyu.edu%2Fprimo_library%2Flibweb%2Faction%2Fsearch.do%26pds_handle%3D0123456789"),
        "Load login should redirect to 'goto URL' through cleanup");
  
  $controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://bobcatdev.library.nyu.edu:80/primo_library/libweb/action/login.do");
  # Should redirect to BobCat login through cleanup and "goto"
  is($controller->load_login,
    redirect_html("http://bobcatdev.library.nyu.edu/primo_library/libweb/custom/cleanup.jsp?url=".
      "https%3A%2F%2Flogindev.library.nyu.edu%2Fgoto%2Flogon%2Fhttp%3A%2F%2Fbobcatdev.library.nyu.edu%3A80%2Fprimo_library%2Flibweb%2Faction%2Flogin.do%26pds_handle%3D0123456789"),
        "Load login should redirect to 'goto URL' through cleanup");
        
}
  
# What about if Aleph is down.
$conf->{ xserver_host } = "http://library.nyu.edu/errors/bobcatstandard-library-nyu-edu/?";
$conf->{lookup_only} = 0;
$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Should notify users that Aleph is down
is($controller->authenticate("DS03D", "TEST"), 
  nyu_login_screen_with_errors("We&#39;re sorry for the inconvenience, but BobCat login services are down at the moment.
                <a href=\"http://library.nyu.edu/ask/\" target=\"_blank\">
                  Please contact Ask a Librarian for more information.
                </a>"),
  "Authenticate should present login screen with Aleph down message.");
  

