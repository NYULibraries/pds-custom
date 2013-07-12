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
    <meta name=\"viewport\" content=\"width=device-width; initial-scale=1; maximum-scale=1\" />
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
    <h1 class=\"container-fluid\">Please login to access library services.</h1>
    <section class=\"container-fluid\">
      <div class=\"row-fluid\">
        <div class=\"span5 well\">
          <h2>
            NYU Users with a NetID
            <a class=\"nyulibraries-help\" href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">
              <i class=\"icons-famfamfam-help\"></i>
            </a>
          </h2>
          <p>
            <a href=\"\" class=\"btn shibboleth\">SHIBBOLETH!</a>
          </p>
          <div>
            <a href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">Login help with an NYU NetID</a>
          </div>
          <div>
            <h3>Additional information:</h3>
            <ul class=\"unstyled\">
              <li><a href=\"http://library.nyu.edu/help/proxy.html\" target=\"_blank\">NYU</a></li>
              <li><a href=\"http://library.poly.edu/research/access/nyu\" target=\"_blank\">NYU-Poly</a></li>
              <li><a href=\"http://library.nyu.edu/ask/\" target=\"_blank\">Ask a Librarian</a></li>
            </ul>
          </div>
        </div>
        <div class=\"span5 well\">
          <h2>
            Consortium &amp; NYU Users without a NetID
            <a class=\"nyulibraries-help-snippet\" href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
              <i class=\"icons-famfamfam-help\"></i>
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
          <div>
            <a href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">Login help without an NYU NetID</a>
          </div>
          <div>
            <h3>Additional information:</h3>
            <ul class=\"unstyled\">
              <li><a href=\"http://library.cooper.edu/\" target=\"_blank\">Cooper Union</a></li>
              <li><a href=\"http://library.newschool.edu/login/ns\" target=\"_blank\">New School</a></li>
              <li><a href=\"http://nysidlibrary.org/logging-into-bobcat\" target=\"_blank\">NYSID</a></li>
            </ul>
          </div>
        </div>
      </div>
    </section>
    <section class=\"container-fluid\">
      <h3>
        Library services vary by institution. Please see the
        <a href=\"https://web1.library.nyu.edu/privileges_guide/\" target=\"_blank\">NYU Libraries Privileges Guide</a>.
      </h3>
    </section>
    <footer>NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
";

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
can_ok($controller, (qw(institute calling_system target_url session_id)));

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
    <meta name=\"viewport\" content=\"width=device-width; initial-scale=1; maximum-scale=1\" />
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
    <h1 class=\"container-fluid\">Please login to access library services.</h1>
    <section class=\"container-fluid\">
      <div class=\"row-fluid\">
        <div class=\"span5 well\">
          <h2>
            Consortium or New School Patrons
            <a class=\"nyulibraries-help-snippet\" href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
              <i class=\"icons-famfamfam-help\"></i>
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
        <div class=\"span5 well\">
          <h2>
            NYU Users with a NetID
            <a class=\"nyulibraries-help\" href=\"https://library.nyu.edu/info/bobcat/netid.html\" target=\"_blank\">
              <i class=\"icons-famfamfam-help\"></i>
            </a>
          </h2>
          <p>
            <a href=\"\" class=\"btn shibboleth\">SHIBBOLETH!</a>
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
    <section class=\"container-fluid\">
      <h3>
        Library services vary by institution. Please see the
        <a href=\"https://web1.library.nyu.edu/privileges_guide/\" target=\"_blank\">NYU Libraries Privileges Guide</a>.
      </h3>
    </section>
    <footer>BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
", "Unexpected login NS html");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test authenticate
is($controller->_authenticate("DS03D", "TEST"), "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
  "<session>".
    "<id>DS03D</id>".
    "<institute>NYU</institute>".
    "<bor_status>03</bor_status>".
    "<verification>TEST</verification>".
    "<ill_permission>N</ill_permission>".
  "</session>", "Authenticate should return xml");
# Test error undefined after authenticate
is($controller->error, undef, "Error should be undefined");
is(defined($controller->error), '', "Error should be undefined");

$controller = NYU::Libraries::PDS::SessionsController->new($conf, "NYU", "primo", "http://example.com");
# Test authenticate
is($controller->_authenticate("DS03D", "FAIL"), NYU_LOGIN, "Authenticate should be login screen");
# Test error undefined after authenticate
isnt($controller->error, undef, "Error should be defined");
isnt(defined($controller->error), '', "Error should be defined");
is($controller->error, "There seems to have been a problem logging in. ".
  "Please check your credentials.", "Error should be defined");
