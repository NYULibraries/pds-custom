# Controller for managing the PDS session flow.
# 
# A SessionsController instance has the following methods
#   login:
#     Renders the appropriate login screen unless the user is single signed on.
#   sso:
#     Redirects to the given url unless the user is single signed on
#   authenticate:
#     Attempts authentication for the given authentication method
#   bor_info:
#     Returns XML representation of an existing PDS session
# 
package NYU::Libraries::PDS::SessionsController;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# CGI module for dealing with redirects, etc.
use CGI qw/:standard/;

# URI encoding module
use URI::Escape;


# NYU Libraries modules
use NYU::Libraries::Util qw(trim whitelist_institution);
use NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use NYU::Libraries::PDS::IdentitiesControllers::NsLdapController;
use NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use NYU::Libraries::PDS::Session;
use NYU::Libraries::PDS::Views::Login;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(institute calling_system target_url current_url session_id error));

# Default constants
use constant UNAUTHORIZED_URL => "http://library.nyu.edu/unauthorized";
use constant DEFAULT_INSTITUTE => "NYU";
use constant DEFAULT_CALLING_SYSTEM => "primo";
use constant DEFAULT_TARGET_URL => "http://bobcat.library.nyu.edu";
use constant DEFAULT_FUNCTION => "sso";

# Private method to create a session
# Usage:
#   $self->$create_session($identity1, $identity2)
my $create_session = sub {
  my($self, @identities) = @_;
  # Get a new session based on the given identities
  my $session = NYU::Libraries::PDS::Session->new(@identities);
  # Add some attributes from the controller
  $session->target_url($self->target_url);
  $session->calling_system($self->calling_system);
  # Testing environment differs
  unless ($ENV{'CI'}) {
    # Save the session
    $session->save();
    # Set the session cookie
    my $pds_handle = CGI::Cookie->new(-name=>'PDS_HANDLE',
      -value=>$session->session_id,-domain=>'.library.nyu.edu');
    my $cgi = CGI->new();
    print $cgi->header(-cookie=>[$pds_handle]);
  }
  return $session;
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
    $nyu_shibboleth_controller->target_url($self->target_url);
    $nyu_shibboleth_controller->current_url($self->current_url);
    $self->{'nyu_shibboleth_controller'} = $nyu_shibboleth_controller;
  }
  return $self->{'nyu_shibboleth_controller'};
};

# Private method to set the target URL
# Usage:
#   $self->$set_target_url($target_url);
my $set_target_url = sub {
  my($self, $target_url) = @_;
  # Set target_url from either the given target URL, the shibboleth controller stored
  # "been there done that cookie" or the default
  $target_url ||= 
    NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController->been_there_done_that();
  $target_url ||= $self->conf{bobcat_url};
  $target_url ||= DEFAULT_TARGET_URL;
  $self->set('target_url', $target_url);
};

# Private method to set the current URL
# Usage:
#   $self->$set_current_url();
my $set_current_url = sub {
  my($self) = @_;
  my $cgi = CGI->new();
  my $base = $cgi->url(-base => 1);
  my $function = ($cgi->url_param('func') || DEFAULT_FUNCTION);
  my $institute = $self->institute;
  my $calling_system = $self->calling_system;
  my $target_url = uri_escape($self->target_url);
  my $current_url ||=
    uri_escape("$base/pds?func=$function&institute=$institute&calling_system=$calling_system&url=$target_url");
  $self->set('current_url', $current_url);
};

# Private method to get the target_url
# Private initialization method
# Usage:
#   $self->$initialize(configurations, institute, calling_system, target_url, session_id);
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url, $session_id) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set institute
  $self->set('institute', (whitelist_institution($institute) || DEFAULT_INSTITUTE));
  # Set calling_system
  $self->set('calling_system', ($calling_system || DEFAULT_CALLING_SYSTEM));
  # Set the target_url
  $self->$set_target_url($target_url);
  # Set current_url
  $self->$set_current_url();
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

# Returns a rendered HTML login screen for presentation.
# Usage:
#   my $login_screen = $self->$_login_screen();
sub _login_screen {
  my $self = shift;
  # Present Login Screen
  my $template = NYU::Libraries::PDS::Views::Login->new($self->{'conf'}, $self);
  return $template->render();
}

# Returns a redirect header to the unauthorized message URL.
# Usage:
#   my $redirect_header = $self->$_redirect_to_unauthorized();
sub _redirect_to_unauthorized {
  my $self = shift;
  my $cgi = CGI->new();
  return $cgi->redirect(UNAUTHORIZED_URL);
}

# Returns a redirect header to the target URL.
# Usage:
#   my $redirect_header = $self->$_redirect_to_target_url();
sub _redirect_to_target_url {
  my $self = shift;
  my $cgi = CGI->new();
  return $cgi->redirect($self->target_url);
}

# Authenticate against Aleph.
# Returns an 1 element array of newly created identities.
# The first element is the Aleph identity.
# Usage:
#   my @identities = $self->$authenticate_aleph($id, $password);
sub _authenticate_aleph {
  my($self, $id, $password) = @_;
  # We need an Aleph identity to successfully create a session for this
  # authentication mechanism
  # Try to create the Aleph identity
  # based on the given ID and password
  my $aleph_identity = 
    $self->$aleph_controller()->create($id, $password);
  # Check if the Aleph identity exists
  unless($aleph_identity->exists) {
    # The Aleph identity doesn't exist
    # so we exit and set a Login Error
    my $error = $aleph_identity->error;
    # Don't overwrite the existing error.
    unless ($self->error) {
      $self->set('error', "There seems to have been a problem logging in. $error");
    }
    return undef;
  }
  # If we successfully authenticated return identity
  return [$aleph_identity];
}

# Authenticate against New School's LDAP.
# Returns an 2 element array of newly created identities.
# The first element is the New School LDAP identity,
# the second is the Aleph identity.
# Usage:
#   my @identities = $self->$authenticate_ns_ldap($id, $password);
sub _authenticate_ns_ldap {
  my($self, $id, $password) = @_;
  # We need a New School LDAP identity AND an Aleph identity
  # to successfully create a session for this authentication
  # mechanism
  my ($ns_ldap_identity, $aleph_identity);
  # Try to create the New School identity
  # based on the given ID and password
  $ns_ldap_identity = 
    $self->$ns_ldap_controller()->create($id, $password);
  # Check if the New School LDAP identity exists
  if($ns_ldap_identity->exists) {
    # Try to create the Aleph identity
    # based on the Aleph identifier that we got from
    # the New School LDAP identity
    $aleph_identity =
      $self->$aleph_controller()->get($ns_ldap_identity->aleph_identifier);
    # Check if the Aleph identity exists
    unless($aleph_identity->exists) {
      # The Aleph identity doesn't exist
      # so we exit and set a Unauthorized Error
      $self->set('error', "Unauthorized");
      return undef;
    }
  } else {
    # The New School LDAP identity doesn't exist
    # so we exit and set a Login Error
    my $error = $ns_ldap_identity->error;
    $self->set('error', "There seems to have been a problem logging in. $error");
    return undef;
  }
  # If we successfully authenticated return identities
  return [$ns_ldap_identity, $aleph_identity];
};

# Display the login screen, unless already signed in
# Usage:
#   $controller->load_login();
sub load_login {
  my $self = shift;
  my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  # The Shibboleth controller can go "nuclear" and just exit at this point.
  # It will redirect to the Shibboleth IdP for passive authentication.
  my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  # Do we have an identity? If so, let's get the associated Aleph identity
  if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
    my $aleph_controller = $self->$aleph_controller();
    my $aleph_identity = $aleph_controller->create($nyu_shibboleth_identity->aleph_identifier);
    # Check if the Aleph identity exists
    if ($aleph_identity->exists) {
      $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
      # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
      # or just got it from me.
      return $nyu_shibboleth_controller->redirect_to_target();
    } else {
      # Exit with Unauthorized Error
      $self->set('error', "Unauthorized");
      return $self->_redirect_to_unauthorized();
    }
  }
  # Print the login screen
  return $self->_login_screen();
}

# Single sign on if possible, otherwise return from whence you came
# Usage:
#   $controller->sso();
sub sso {
  my $self = shift;
  my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
    my $aleph_controller = $self->$aleph_controller();
    my $aleph_identity = 
      $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
    # Check if the Aleph identity exists
    if ($aleph_identity->exists) {
      my $session = 
        $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
    }
  }
  # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
  # or just got it from me.
  return $nyu_shibboleth_controller->redirect_to_target();
}

# Authenticate based on the given id and password
# Usage:
#   $controller->authenticate();
sub authenticate {
  my($self, $id, $password) = @_;
  my $identities;
  # If we're New School, do New School LDAP first.
  # Otherwise, do Aleph first
  if($self->institute eq "NS") {
    $identities = $self->_authenticate_ns_ldap($id, $password);
    $identities = $self->_authenticate_aleph($id, $password) unless defined($identities);
  } else {
    $identities = $self->_authenticate_aleph($id, $password);
    $identities = $self->_authenticate_ns_ldap($id, $password) unless defined($identities);
  }
  # If we got some identities, create a session and redirect to the target URL
  # Otherwise, present the login screen or redirect to unauthorized
  if (defined($identities)) {
    my $session = $self->$create_session(@$identities);
    return $self->_redirect_to_target_url();
  } else {
    # Redirect to unauthorized page
    return $self->_redirect_to_unauthorized() if ($self->error eq "Unauthorized");
    $self->set('error', "There seems to have been a problem logging in. Please check your credentials.");
    # Return Login Screen
    return $self->_login_screen();
  }
}

# Return the bor_info as an XML string
# Usage:
#   $controller->bor_info();
sub bor_info {
  my($self) = @_;
  my $cgi = CGI->new();
  print $cgi->header(-type=>'text/xml', -charset =>'UTF-8');
  if ($self->session_id) {
    my $session = NYU::Libraries::PDS::Session::find($self->session_id);
    if ($session) {
      return $session->to_xml("bor-info");
    # } else {
    #   return "<!--?xml version=\"1.0\" encoding=\"UTF-8\" ?-->".
    #     "<error>Error User does not exist</error>";
    }
  }
  return undef;
}

1;
