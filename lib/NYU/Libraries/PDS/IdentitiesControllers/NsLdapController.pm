# Controller for creating New School LDAP identities
package NYU::Libraries::PDS::IdentitiesControllers::NsLdapController;
use strict;
use warnings;

# New School LDAP Identity
use NYU::Libraries::PDS::Identities::NsLdap;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);

# Method to create a New School LDAP identity based on the given ID and password
# Usage:
#   $controller->create($id, $password);
sub create {
  my($self, $id, $password) = @_;
  my $identity = 
    NYU::Libraries::PDS::Identities::NsLdap->new($self->{'conf'}, $id, $password);
  return $identity;
}

1;
