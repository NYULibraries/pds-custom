package NYU::Libraries::PDS;
use strict;
use warnings;

use NYU::Libraries::PDS::SessionsController;

our $VERSION = '0.1'; # VERSION

# Convenience method to call from the PDS handler script
sub controller {
  # Set up controller params
  my %params = ('pds_handle' => $_[0], 'institute' => $_[1], 
    'calling_system' => $_[2], 'conf_file' => $_[3], 'target_url' => $_[4]);
  # Return an instance of the controller based on the given params
  return NYU::Libraries::PDS::SessionsController->new(\%params);
}

1;
