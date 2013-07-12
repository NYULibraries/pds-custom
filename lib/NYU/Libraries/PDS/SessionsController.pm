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
use constant UNAUTHORIZED_URL => "http://library.nyu.edu/unauthorized";
use constant DEFAULT_INSTITUTE => "NYU";
use constant DEFAULT_CALLING_SYSTEM => "primo";
use constant DEFAULT_TARGET_URL => "http://bobcat.library.nyu.edu";

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
    $pds_handle = CGI::Cookie->new(-name=>'PDS_HANDLE',
      -value=>$session->session_id,-domain=>'.library.nyu.edu');
    print header(-cookie=>[$pds_handle]);
  }
  return $session if $session->save();
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
  $self->set('target_url', ($target_url || DEFAULT_TARGET_URL));
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

sub _login_screen {
  my $self = shift;
  # Present Login Screen
  my $template = NYU::Libraries::PDS::Views::Login->new($self->{'conf'}, $self);
  return $template->render();
}

sub _redirect_to_unauthorized {
  my $self = shift;
  my $cgi = CGI->new();
  print $cgi->redirect(UNAUTHORIZED_URL);
}

sub _redirect_to_target_url {
  my $self = shift;
  my $cgi = CGI->new();
  return $cgi->redirect($self->target_url);
}

# Authenticate against Aleph.
# Returns a newly created session.
# Usage:
#   my $session = $self->$authenticate_aleph($id, $password);
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
    $self->set('error', "There seems to have been a problem logging in. $error");
    return undef;
  }
  # If we successfully authenticated return identity
  return [$aleph_identity];
}

# Authenticate against New School's LDAP.
# Returns a newly created session.
# Usage:
#   my $session = $self->$authenticate_ns_ldap($id, $password);
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
#   $controller->login();
# 
# Logic:
#   If NYU Shibboleth Identity and Aleph Identity
#     Create session and return from whence you came
#   Else
#     Unless ShibController->create
#       Show login screen
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
      print $nyu_shibboleth_controller->redirect_to_target();
      return;
    } else {
      # Exit with Unauthorized Error
      $self->set('error', "Unauthorized");
      print $self->_redirect_to_unauthorized();
      return;
    }
  }
  # Print the login screen
  print $self->_login_screen();
  return;
}

# Single sign on if possible, otherwise return from whence you came
# Usage:
#   $controller->sso();
# 
# Logic:
#   If NYU Shibboleth Identity and Aleph Identity
#     Create session and return from whence you came
#   Else
#     Return from whence you came
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
      my $session = 
        $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
    }
  }
  # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
  # or just got it from me.
  print $nyu_shibboleth_controller->redirect_to_target();
  return;
}

sub _authenticate {
  my($self, $id, $password) = @_;
  my $identities;
  unless($self->institute eq "NS") {
    $identities = $self->_authenticate_aleph($id, $password);
    $identities = $self->_authenticate_ns_ldap($id, $password) unless defined($identities);
  } else {
    $identities = $self->_authenticate_ns_ldap($id, $password);
    $identities = $self->_authenticate_aleph($id, $password) unless defined($identities);
  }
  # If we got some identities, create a session and redirect to the target URL
  # Otherwise, present the login screen
  if (defined($identities)) {
    my $session = $self->$create_session(@$identities);
    return $self->_redirect_to_target_url();
  } else {
    $self->set('error', "There seems to have been a problem logging in. Please check your credentials.");
    # Return Login Screen
    return $self->_login_screen();
  }
}

sub authenticate {
  my($self, $id, $password) = @_;
  print $self->_authenticate($id, $password);
}

# Return the bor_info as an XML string
sub bor_info {
  my($self) = @_;
  if ($self->session_id) {
    my $session = NYU::Libraries::PDS::Session::find($self->session_id);
    if ($session) {
      print $session->to_xml("bor-info");
    } else {
      print "<!--?xml version=\"1.0\" encoding=\"UTF-8\" ?-->".
        "<error>Error User does not exist</error>";
    }
  }
  return;
}

1;
