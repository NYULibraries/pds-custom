package NYU::Libraries::PDS::Views::Login;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(Template::Mustache);
$Template::Mustache::template_path = './lib';

# Private initialization method
# Usage:
#   $self->$initialize(configurations, institute, calling_system, target_url, session_id)
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url) = @_;
  # Set configurations
  $self->{'conf'} = $conf;
  # Set institute
  $self->{'institute'} = $institute;
  # Set calling_system
  $self->{'calling_system'} = $calling_system;
  # Set target_url
  $self->{'target_url'} = $target_url;
};

# Returns an new SessionsController
# Usage:
#   NYU::Libraries::PDS::Controllers::SessionsController->new(configurations, institute, calling_system, target_url, session_id)
sub new {
  my($proto, @initialization_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Template::Mustache->new(), $class);
  # Initialize
  $self->$initialize(@initialization_args);
  # Return self
  return $self;
}

sub test {
  return "TITLE";
}

1;
