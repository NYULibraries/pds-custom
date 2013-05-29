package NYU::Libraries::PDS::SessionsController;
use strict;
use warnings;

# Use PDS core libraries
use PDSUtil;
use PDSParamUtil;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(pds_handle institute calling_system target_url));

1;
