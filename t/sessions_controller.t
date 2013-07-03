use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of SessionController
my $controller = NYU::Libraries::PDS::SessionsController->new({}, "nyu", "primo", "http://example.com");

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a SessionController
isa_ok($controller, qw(NYU::Libraries::PDS::SessionsController));

# Verify methods
can_ok($controller, (qw(institute calling_system target_url session_id)));

is($controller->login(), "<!DOCTYPE html>
<html>
  <head>
    <title>BobCat</title>
    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />
    <meta http-equiv=\"Cache-Control\" content=\"no-cache\" />
    <meta http-equiv=\"Pragma\" content=\"no-cache\" />
    <meta http-equiv=\"Expires\" content=\"Sun, 06 Nov 1994 08:49:37 GMT\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"/assets/css/nyu.css\" />
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
    <div class=\"nyu-container\">
      <div class=\"container-fluid\">
        <div class=\"row-fluid\">
          <h1>Please login to access library services.</h1>
          <div class=\"span4 offset1 well\">
            SHIBBOLETH!
          </div>
          <div class=\"span4 well\">
          <form id=\"nyu_pds_login_form\" class=\"form-horizontal\" action=\"/pds\" method=\"post\">
            <fieldset>
              <legend>
                Consortium &amp; NYU Users without a NetID
                <a href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">
                  &nbsp;<i class=\"icons-famfamfam-help\"></i>
                </a>
              </legend>
              <div class=\"alert alert-error\">{{error}}</div>
              <input type=\"hidden\" name=\"func\" value=\"login\" />
              <input type=\"hidden\" name=\"calling_system\" value=\"{{calling_system}}\" />
              <input type=\"hidden\" name=\"institute\" value=\"{{institute_key}}\" />
              <input type=\"hidden\" name=\"term1\" value=\"short\" />
              <input type=\"hidden\" name=\"selfreg\" value=\"{{self_url}}\" />
              <input type=\"hidden\" name=\"url\" value=\"{{target_url}}\" />
              <input type=\"hidden\" name=\"pds_handle\" value=\"{{session_id}}\" />
              <div class=\"control-group\">
                <label class=\"control-label\" for=\"bor_id\">Enter your ID Number</label>
                <div class=\"controls\">
                  <input id=\"bor_id\" type=\"text\" name=\"bor_id\" value=\"{{id}}\" placeholder=\"e.g. N12345678\" /><br />
                </div>
              </div>    
              <div class=\"control-group\">
                <label class=\"control-label\" for=\"bor_verification\">Password or first four letters of your last name</label>
                <div class=\"controls\">
                  <input id=\"bor_verification\" type=\"password\" name=\"bor_verification\" placeholder=\"e.g. SMIT\" /><br />
                </div>
              </div>    
              <input type=\"submit\" value=\"Login\" />
            </fieldset>
          </form>
            <div class=\"login_help\">
              <a href=\"https://library.nyu.edu/info/bobcat/no_netid.html\" target=\"_blank\">Login help without an NYU NetID</a>
            </div>
            <div id=\"nyu_pds_nonetid_note\" class=\"login_note\">
              <h3>Additional information:</h3>
              <ul>
                <li><a href=\"http://library.cooper.edu/\" target=\"_blank\">Cooper Union</a></li>
                <li><a href=\"http://library.newschool.edu/login/ns\" target=\"_blank\">New School</a></li>
                <li><a href=\"http://nysidlibrary.org/logging-into-bobcat\" target=\"_blank\">NYSID</a></li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
    <footer>NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo</footer>
  </body>
</html>
", "Unexpected login html");
