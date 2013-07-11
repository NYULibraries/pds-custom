package NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use strict;
use warnings;

# Aleph Identity
use NYU::Libraries::PDS::Identities::Aleph;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);

sub create {
  my($self, $id, $password) = @_;
  return NYU::Libraries::PDS::Identities::Aleph->new($self->{'conf'}, $id, $password);
}

# Returns an Aleph identity
sub get {
  my($self, $id) = @_;
  # Specify that this is only a lookup
  $self->{'conf'}->{lookup_only} = 1;
  return NYU::Libraries::PDS::Identities::Aleph->new($self->{'conf'}, $id);
}

1;
