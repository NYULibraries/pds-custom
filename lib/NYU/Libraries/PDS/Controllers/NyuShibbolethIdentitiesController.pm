package NYU::Libraries::PDS::Controllers::NyuShibbolethIdentitiesController;
use strict;
use warnings;

use base qw(NYU::Libraries::PDS::Controllers::BaseIdentitiesController);

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(target_url));

# Checks for passive cookie
#   If exists, returns false
#   otherwise redirects to Idp
sub create {
  
}

1;
