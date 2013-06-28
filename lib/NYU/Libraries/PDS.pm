package NYU::Libraries::PDS;
use strict;
use warnings;

use NYU::Libraries::PDS::SessionsController;

our $VERSION = '0.1'; # VERSION

# Convenience method to call from the PDS handler script
sub controller {
  # Return an instance of the controller based on the given params
  return NYU::Libraries::PDS::SessionsController->new(@_);
}

1;
