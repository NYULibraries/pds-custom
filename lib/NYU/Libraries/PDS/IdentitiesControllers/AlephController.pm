# Controller for creating and getting Aleph identities
package NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use strict;
use warnings;

# Aleph Identity
use NYU::Libraries::PDS::Identities::Aleph;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);

# Method to create an Aleph identity based on the given ID and password
# Usage:
#   $controller->create($id, $password);
sub create {
  my($self, $id, $password) = @_;
  my $identity = 
    NYU::Libraries::PDS::Identities::Aleph->new($self->{'conf'}, $id, $password);
  return $identity;
}

# Method to get an Aleph identity based on the given ID
# Usage:
#   $controller->create($id);
sub get {
  my($self, $id) = @_;
  # Specify that this is only a lookup
  $self->{'conf'}->{lookup_only} = 1;
  my $identity = 
    NYU::Libraries::PDS::Identities::Aleph->new($self->{'conf'}, $id);
  return $identity;
}

1;
