package NYU::Libraries::PDS::Views::ShibbolethRedirect;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(NYU::Libraries::PDS::Views::Redirect);

# Specify the name of the template file that we're looking for
sub template_file { return 'shibboleth_redirect.mustache'; }

1;
