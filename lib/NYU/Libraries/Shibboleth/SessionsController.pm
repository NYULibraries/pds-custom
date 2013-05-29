package NYU::Libraries::Shibboleth::SessionsController;
use strict;
use warnings;

# Use PDS core libraries
use PDSUtil;
use PDSParamUtil;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(mode session idp_url target_url));

1;
