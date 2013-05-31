package NYU::Libraries::PDS::Controllers::NyuShibbolethPatronsController;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# Use PDS core libraries
use PDSUtil;
use PDSParamUtil;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(mode session idp_url target_url));

1;
