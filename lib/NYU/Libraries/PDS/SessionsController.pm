package NYU::Libraries::PDS::SessionsController;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# CGI module for dealing with redirects
use CGI qw/:standard/;

# NYU Libraries modules
use NYU::Libraries::Util qw(trim whitelist_institution);
use NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use NYU::Libraries::PDS::IdentitiesControllers::NsLdapController;
use NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use NYU::Libraries::PDS::Session;
use NYU::Libraries::PDS::Views::Login;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(institute calling_system target_url session_id error));

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

# Private method to create a session
# Usage:
#   $self->$create_session($identity1, $identity2)
my $create_session = sub {
  my($self, @identities) = @_;
  return NYU::Libraries::PDS::Session->new(@identities);
};

# Private method to get a new Aleph Controller
# Usage:
#   $self->$aleph_controller()
my $aleph_controller = sub {
  my $self = shift;
  unless ($self->{'aleph_controller'}) {
    $self->{'aleph_controller'} = 
      NYU::Libraries::PDS::IdentitiesControllers::AlephController->new($self->{'conf'});
  }
  return $self->{'aleph_controller'};
};

# Private method to get a new NsLdap Controller
# Usage:
#   $self->$ns_ldap_controller()
my $ns_ldap_controller = sub {
  my $self = shift;
  unless ($self->{'ns_ldap_controller'}) {
    $self->{'ns_ldap_controller'} = 
      NYU::Libraries::PDS::IdentitiesControllers::NsLdapController->new($self->{'conf'});
  }
  return $self->{'ns_ldap_controller'};
};

# Private method to get a new NyuShibboleth Controller
# Usage:
#   $self->$nyu_shibboleth_controller()
my $nyu_shibboleth_controller = sub {
  my $self = shift;
  unless ($self->{'nyu_shibboleth_controller'}) {
    my $nyu_shibboleth_controller = 
      NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController->new($self->{'conf'});
    $nyu_shibboleth_controller->target_url($self->{'target_url'});
    $self->{'nyu_shibboleth_controller'} = $nyu_shibboleth_controller;
  }
  return $self->{'nyu_shibboleth_controller'};
};

# Private initialization method
# Usage:
#   $self->$initialize(configurations, institute, calling_system, target_url, session_id)
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url, $session_id) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set institute
  $self->set('institute', (whitelist_institution($institute) || DEFAULT_INSTITUTE));
  # Set calling_system
  $self->set('calling_system', ($calling_system || DEFAULT_CALLING_SYSTEM));
  # Set target_url
  $self->set('target_url', $target_url) if $target_url;
  # Set session_id
  $self->set('session_id', $session_id) if $session_id;
};

# Returns an new SessionsController
# Usage:
#   NYU::Libraries::PDS::Controllers::SessionsController->new(configurations, institute, calling_system, target_url, session_id)
sub new {
  my($proto, @initialization_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Class::Accessor->new(), $class);
  # Initialize
  $self->$initialize(@initialization_args);
  # Return self
  return $self;
}

# If ShibIdentity and Aleph
#   Create session
# Else
#   Unless ShibController->create
#     Show login screen
#     
sub login {
  my $self = shift;
  my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
    my $aleph_controller = $self->$aleph_controller();
    my $aleph_identity = $aleph_controller->create($nyu_shibboleth_identity->aleph_identifier);
    # Check if the Aleph identity exists
    if ($aleph_identity->exists) {
      $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
      # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
      # or just got it from me.
      $nyu_shibboleth_controller->redirect_to_target();
    } else {
      # Exit with Unauthorized Error
      $self->set('error', "Unauthorized");
      return undef;
    }
  } else {
    # Present Login Screen
    my $template = 
      NYU::Libraries::PDS::Views::Login->new(
        $self->{'conf'}, $self->institute, $self->calling_system, 
          $self->target_url, $self->session_id);
    return $template->render();
  }
}

# If ShibIdentity
#   Create session
# Else
#   Unless ShibController->create
#     Redirect to target url
#     
sub sso {
  my $self = shift;
  my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  if ($nyu_shibboleth_identity->exists) {
    my $aleph_controller = $self->$aleph_controller();
    my $aleph_identity = 
      $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
    # Check if the Aleph identity exists
    if ($aleph_identity->exists) {
      $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
    }
  }
  # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
  # or just got it from me.
  $nyu_shibboleth_controller->redirect_to_target();
}

# Depending on 
sub authenticate_aleph {
  my($self, $id, $password) = @_;
  my $aleph_identity = 
    $self->$aleph_controller()->create($id, $password);
  # Unless the Aleph identity exists exit with Login Error
  unless($aleph_identity->exists) {
    # Exit with Login Error
    my $error = $self->$aleph_controller()->error;
    $self->set('error', "There seems to have been a problem logging in. $error");
    return undef;
  }
  # If all went well, we authenticate
  $self->$create_session($aleph_identity);
}

# Depending on 
sub authenticate_ns_ldap {
  my($self, $id, $password) = @_;
  my $ns_ldap_identity = 
    $self->$ns_ldap_controller()->create($id, $password);
  my $aleph_identity;
  # Check if the identity exists
  if($ns_ldap_identity->exists) {
    $aleph_identity =
      $self->$aleph_controller()->get($ns_ldap_identity->aleph_identifier);
    # Unless the Aleph identity exists, exit with Unauthorized Error
    unless($aleph_identity->exists) {
      # Exit with Unauthorized Error
      $self->set('error', "Unauthorized");
      return undef;
    }
  } else {
    # Exit with Login Error
    my $error = $self->$ns_ldap_controller()->error;
    $self->set('error', "There seems to have been a problem logging in. $error");
    return undef;
  }
  # If all went well, we authenticate
  $self->$create_session($ns_ldap_identity, $aleph_identity);
}

sub bor_info {
  my($self) = @_;
  return undef unless $self->session_id;
  return NYU::Libraries::PDS::Models::Session->find($self->session_id, "bor-info")->to_xml();
}

1;
