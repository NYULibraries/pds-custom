use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::SessionsController' );

# Get an instance of SessionController
my $controller = NYU::Libraries::PDS::SessionsController->new({}, "nyu");

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
  </head>
  <body>
    <div class=\"nyu-container\">
      <div class=\"container-fluid\">
        <div class=\"row-fluid\">
          Please login to access library services.
        </div>
      </div>
    </div>
  </body>
</html>
", "Unexpected login html");
