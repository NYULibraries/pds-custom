use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::Shibboleth::SessionsController') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::Shibboleth::SessionsController' );

# Get an instance of Shibboleth::SessionController
my $controller = NYU::Libraries::Shibboleth::SessionsController->new();

# Verify that this a Class::Accessor
isa_ok($controller, qw(Class::Accessor));

# Verify that this a Shibboleth::SessionController
isa_ok($controller, qw(NYU::Libraries::Shibboleth::SessionsController));

# Verify methods
can_ok($controller, (qw(mode session idp_url target_url)));
