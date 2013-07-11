package NYU::Libraries::PDS::IdentitiesControllers::NsLdapController;
use strict;
use warnings;

# New School LDAP Identity
use NYU::Libraries::PDS::Identities::NsLdap;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);

# Attempts to create the 
sub create {
  my($self, $id, $password) = @_;
  return NYU::Libraries::PDS::Identities::NsLdap->new($self->{'conf'}, $id, $password);
}


1;
