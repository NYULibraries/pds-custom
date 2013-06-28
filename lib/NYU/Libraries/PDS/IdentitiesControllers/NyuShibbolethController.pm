package NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use strict;
use warnings;

# NYU Libraries Shibboleth Identity
use NYU::Libraries::PDS::Identities::NyuShibboleth;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);
__PACKAGE__->mk_accessors(qw(target_url));

# Checks for passive cookie
#   If exists, returns false
#   otherwise redirects to Idp
sub create {
  my $self = shift;
  my $identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new();
  # If we have an identity, we've successfully created from the Shibboleth SP
  if ($identity->id) {
    return
  }
}

1;
