# Base controller for identities
package NYU::Libraries::PDS::IdentitiesControllers::BaseController;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(error));

# Private initialization method
# Usage:
#   $self->$initialize(configurations)
my $initialize = sub {
  my($self, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
};

# Returns an new Identity
# Usage:
#   NYU::Libraries::PDS::Identities::Base->new(configurations, id, password)
sub new {
  my($proto, $conf) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Class::Accessor->new(), $class);
  # Initialize
  $self->$initialize($conf);
  # Return self
  return $self;
}

1;
