package NYU::Libraries::PDS::Controllers::SessionsController;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# Use PDS core libraries
use PDSUtil;
use PDSParamUtil;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(institute calling_system target_url session_id));

# Default constants
use constant DEFAULT_INSTITUTE => "NYU";
use constant DEFAULT_CALLING_SYSTEM => "primo";

# A SessionsController instance has the following methods
#   login:
#     Attempts single sign on
#     If not successful, renders the appropriate login screen
#   sso:
#     Attempt single sign on
#     If not successful, redirects to the calling system
#   authenticate:
#     Attemps single sign on
#     If not successful, attempts authentication with the given
#   bor_info:
#     Returns XML representation of an existing PDS session
# 

# Private initialization method
# Usage:
#   $self->$initialize(configurations)
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url, $session_id) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set institute
  $self->set('institute', ($institute || DEFAULT_INSTITUTE));
  # Set calling_system
  $self->set('calling_system', ($calling_system || DEFAULT_CALLING_SYSTEM));
  # Set target_url
  $self->set('target_url', $target_url) if $target_url;
  # Set session_id
  $self->set('target_url', $session_id) if $session_id;
};

# Returns an new Identity
# Usage:
#   NYU::Libraries::PDS::Identities::Base->new(configurations, id, password)
sub new {
  my($proto, @initialization_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Class::Accessor->new(), $class);
  # Initialize
  $self->$initialize(@initialization_args);
  # Return self
  return $self;
}

# If ShibIdentity
#   Create session
# Else
#   Unless ShibController->create
#     Show login screen
#     
sub login {
}

# If ShibIdentity
#   Create session
# Else
#   Unless ShibController->create
#     Redirect to target url
#     
sub sso {
}

# Depending on 
sub authenticate {
}

sub bor_info {
}

1;
