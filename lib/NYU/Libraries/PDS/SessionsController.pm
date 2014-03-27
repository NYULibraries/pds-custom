# Controller for managing the PDS session flow.
# 
# A SessionsController instance has the following methods
#   login:
#     Renders the appropriate login screen unless the user is single signed on.
#   ezproxy:
#     Renders the appropriate login screen unless the user is authorized for ezproxy.
#   ezborrow:
#     Renders the appropriate login screen unless the user is authorized for ezborrow.
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
use Data::Dumper;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# CGI module for dealing with redirects, etc.
use CGI qw/:standard/;
use CGI::Cookie;

# Time functions
use POSIX qw(strftime);

# Hash functions
use Digest::MD5 qw(md5_hex md5);

# URI module
use URI;
use URI::Escape;
use URI::QueryParam;

# PDS Logout module
use PDSLogout;

# NYU Libraries modules
use NYU::Libraries::Util qw(trim whitelist_institution save_permanent_eshelf_records handle_primo_target_url);
use NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use NYU::Libraries::PDS::IdentitiesControllers::NsLdapController;
use NYU::Libraries::PDS::IdentitiesControllers::AlephController;
use NYU::Libraries::PDS::Session;
use NYU::Libraries::PDS::Views::Login;
use NYU::Libraries::PDS::Views::Logout;
use NYU::Libraries::PDS::Views::Redirect;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(institute calling_system target_url current_url cleanup_url session_id error));

# Default constants
use constant UNAUTHORIZED_URL => "http://library.nyu.edu/errors/login-library-nyu-edu/unauthorized.html";
use constant EZPROXY_UNAUTHORIZED_URL => "http://library.nyu.edu/errors/ezproxy-library-nyu-edu/login.html";
use constant EZBORROW_UNAUTHORIZED_URL => "http://library.nyu.edu/errors/ezborrow-library-nyu-edu/login.html";
use constant ALUMNI_EZPROXY_URL => "http://library.nyu.edu/alumni/eresources.html";
use constant DEFAULT_INSTITUTE => "NYU";
use constant DEFAULT_CALLING_SYSTEM => "primo";
use constant DEFAULT_TARGET_URL => "http://bobcat.library.nyu.edu";
use constant DEFAULT_FUNCTION => "sso";
use constant GLOBAL_NYU_SHIBBOLETH_LOGOUT => "https://login.nyu.edu/sso/UI/Logout";
use constant EZBORROW_AUTHORIZED_STATUSES => qw(50 51 52 53 54 55 56 57 58 60 61 62 63 65 66 80 81 82);
use constant EZBORROW_URL_BASE => "https://e-zborrow.relaisd2d.com/service-proxy/";
# library dot nyu cookies to delete on logout
use constant LIBRARY_DOT_NYU_COOKIES => qw(_tsetse_session tsetse_credentials tsetse_handle nyulibrary_opensso_illiad
  _umlaut_session _getit_session _eshelf_session _umbra_session _privileges_guide_session
    _room_reservation_session _room_reservation_session _marli_session xerxessession_);
use constant COOKIE_EXPIRATION => 'Thu, 01-Jan-1970 00:00:01 GMT';

# Private method to encrypt the Aleph identity
# Usage:
#   $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity)
my $encrypt_aleph_identity = sub {
  my($self, $aleph_identity) = @_;
  # Encrypt the password
  $aleph_identity->encrypt(1);
  # And reset the attributes
  $aleph_identity->set_attributes(1);
  return $aleph_identity;
};

# Private method to find the current session
# Usage:
#   $self->$current_session()
my $current_session = sub {
  my $self = shift;
  unless ($self->{'current_session'}) {
    # Testing environment differs
    unless ($ENV{'CI'}) {
      $self->{'current_session'} = 
        NYU::Libraries::PDS::Session::find($self->session_id);
    }
  }
  return $self->{'current_session'};
};

# Private method to determine if the given session is 
# authorized for EZproxy
# Usage:
#   $self->$is_ezproxy_authorized($session)
my $is_ezproxy_authorized = sub {
  my($self, $session) = @_;
  # Not authorized if we're not signed on through NYU shibboleth
  return 0 unless $session->nyu_shibboleth;
  # Not authorized if we don't have an entitlements
  return 0 unless $session->entitlements;
  my $entitlements = $session->entitlements;
  # Poly students have partial access which actually means full access
  return 1 if ($entitlements =~ m/urn:mace:nyu.edu:entl:lib:partialeresources/);
  # Everyone else has full access which actually means full access
  return 1 if ($entitlements =~ m/urn:mace:nyu.edu:entl:lib:eresources/);
  return 0;
};

# Private method to determine if the given session is 
# authorized for EZ Borrow
# Usage:
#   $self->$is_ezborrow_authorized($session)
my $is_ezborrow_authorized = sub {
  my($self, $session) = @_;
  # Must have a barcode
  return 0 unless $session->barcode;
  # Must be an approved status
  return (grep { $_ eq $session->bor_status } EZBORROW_AUTHORIZED_STATUSES);
};

# Private method to determine if the given session is 
# an alumnus
# Usage:
#   $self->$is_alumni($session)
my $is_alumni = sub {
  my($self, $session) = @_;
  # Not alumni if we're not signed on through NYU shibboleth
  return 0 unless $session->nyu_shibboleth;
  # Not alumni if we don't have an entitlements
  return 0 unless $session->entitlements;
  my $entitlements = $session->entitlements;
  return ($entitlements =~ m/alum/);
};

# Private method to save eshelf records
# Usage:
#   $self->$tsetse($session_id)
my $tsetse = sub {
  my ($self, $session_id) = @_;
  my $conf = $self->{'conf'};
  my $cgi = CGI->new;
  my $tsetse_handle = $cgi->cookie('tsetse_handle');
  my $tsetse_credentials = $cgi->cookie('tsetse_credentials');
  my $eshelf_success = save_permanent_eshelf_records($conf, $session_id, 
    $tsetse_handle, $tsetse_credentials);
};

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
      -value=>$session->session_id, -domain=>'.library.nyu.edu');
    my $cgi = CGI->new();
    print $cgi->header(-cookie=>[$pds_handle]);
    # Save the eshelf records
    $self->$tsetse($session->session_id);
  } else {
    $session->{session_id} = "0123456789"
  }
  return $session;
};

# Private method to destroy the session
# Usage:
#   $self->$destroy_session()
my $destroy_session = sub {
  my $self = shift;
  # Get the current session
  my $session = $self->$current_session();
  # Destroy it
  $session->destroy();
  # Expire the session cookie
  my $pds_handle = CGI::Cookie->new(-name=>'PDS_HANDLE',
    -expires => COOKIE_EXPIRATION, -value=>'', -domain=>'.library.nyu.edu');
  my $cgi = CGI->new();
  print $cgi->header(-cookie=>[$pds_handle]);
  foreach my $library_cookie_name (LIBRARY_DOT_NYU_COOKIES) {
    if($cgi->cookie($library_cookie_name)) {
      my $library_cookie = CGI::Cookie->new(-name=>$library_cookie_name,
        -expires => COOKIE_EXPIRATION, -value=>'',
          -domain=>'.library.nyu.edu');
      print $cgi->header(-cookie=>[$library_cookie]);
    }
  }
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
    $nyu_shibboleth_controller->cleanup_url($self->cleanup_url);
    $nyu_shibboleth_controller->institute($self->institute);
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
  $target_url ||= $self->{'conf'}->{bobcat_url} if $self->{'conf'};
  $target_url ||= DEFAULT_TARGET_URL;
  $self->set('target_url', $target_url);
};

# Private method to set the current URL
# Usage:
#   $self->$set_current_url();
my $set_current_url = sub {
  my($self, $current_url) = @_;
  unless ($current_url) {
    my $cgi = CGI->new();
    my $base = $cgi->url(-base => 1);
    my $function = ($cgi->url_param('func') || DEFAULT_FUNCTION);
    my $institute = $self->institute;
    my $calling_system = $self->calling_system;
    my $target_url = uri_escape($self->target_url);
    $current_url ||=
      "$base/pds?func=$function&institute=$institute&calling_system=$calling_system&url=$target_url";
  }
  $self->set('current_url', uri_escape($current_url));
};

# Private method to set the cleanup URL
# Usage:
#   $self->$set_cleanup_url();
my $set_cleanup_url = sub {
  my $self = shift;
  my $conf = $self->{'conf'};
  my $base = $conf->{bobcat_url};
  if($base) {
    my $cleanup_url ||= "$base/primo_library/libweb/custom/cleanup.jsp?url=";
    $self->set('cleanup_url', $cleanup_url);
  }
};

# Private method to get the EZProxy ticket
# Usage:
#   $self->$ezproxy_ticket($user, $groups);
my $ezproxy_ticket = sub {
  my ($self, $user, $groups) = @_;
  $groups ||= "Default";
  my $ezproxy_secret = $self->{'conf'}->{ezproxy_secret};
  return undef unless $user && $groups && $ezproxy_secret;
  my $packet = '$u'.time();
  $packet .= '$g'.$groups;
  my $ezproxy_ticket = md5_hex($ezproxy_secret.$user.$packet).$packet;
  return ($ezproxy_ticket) ? CGI::escape($ezproxy_ticket) : undef;
};

# Private method to redirect via JavaScript (via a template)
# since Safari won't set our cookie if we send as
# a redirect (302)
# http://stackoverflow.com/questions/1144894/safari-doesnt-set-cookie-but-ie-ff-does
# Usage:
#   $self->$redirect($target_url, $session);
my $redirect = sub {
  my($self, $target_url) = @_;
  # Present Redirect Screen
  my $template = NYU::Libraries::PDS::Views::Redirect->new($self->{'conf'}, $self);
  $template->{target_url} = $target_url;
  return $template->render();
};

# Private method to get the target_url
# Private initialization method
# Usage:
#   $self->$initialize($configurations, $institute, $calling_system, $target_url, $session_id, $current_url);
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url, $session_id, $current_url) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set institute
  $self->set('institute', (whitelist_institution($institute) || DEFAULT_INSTITUTE));
  # Set calling_system
  $self->set('calling_system', ($calling_system || DEFAULT_CALLING_SYSTEM));
  # Set the target_url
  $self->$set_target_url($target_url);
  # Set current_url
  $self->$set_current_url($current_url);
  # Set cleanup_url
  $self->$set_cleanup_url();
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

# Returns a rendered HTML login screen for presentation
# Usage:
#   my $login_screen = $self->_login_screen();
sub _login_screen {
  my $self = shift;
  # Present Login Screen
  my $template = NYU::Libraries::PDS::Views::Login->new($self->{'conf'}, $self);
  return $template->render();
}

# Returns a rendered HTML logout screen for presentation
# Usage:
#   my $login_screen = $self->_logout_screen();
sub _logout_screen {
  my $self = shift;
  # Present Login Screen
  my $template = NYU::Libraries::PDS::Views::Logout->new($self->{'conf'}, $self);
  return $template->render();
}

# Returns a redirect header to the unauthorized message URL
# Usage:
#   my $redirect_header = $self->_redirect_to_unauthorized();
sub _redirect_to_unauthorized {
  my $self = shift;
  my $cgi = CGI->new();
  return $cgi->redirect(UNAUTHORIZED_URL);
}

# Returns a redirect header to the EZProxy unauthorized message URL
# Usage:
#   my $redirect_header = $self->_redirect_to_ezproxy_unauthorized();
sub _redirect_to_ezproxy_unauthorized {
  my $self = shift;
  return $self->$redirect(EZPROXY_UNAUTHORIZED_URL);
}

# Returns a redirect header to the EZ Borrow unauthorized message URL
# Usage:
#   my $redirect_header = $self->_redirect_to_ezborrow_unauthorized();
sub _redirect_to_ezborrow_unauthorized {
  my $self = shift;
  return $self->$redirect(EZBORROW_UNAUTHORIZED_URL);
}

# Returns a redirect header to the target URL
# Usage:
#   my $redirect_header = $self->_redirect_to_target($session);
sub _redirect_to_target {
  my ($self, $session) = @_;
  my $target_url = $self->target_url;
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  return $self->$redirect($target_url);
}

# Returns a redirect header to the cleanup URL
# Usage:
#   my $redirect_header = $self->_redirect_to_cleanup($session);
sub _redirect_to_cleanup {
  my ($self, $session) = @_;
  return _redirect_to_target unless $self->cleanup_url;
  my $target_url = $self->target_url;
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  $target_url = uri_escape($target_url);
  return $self->$redirect($self->cleanup_url.$target_url);
}

# Returns a redirect header to the eshelf
# Usage:
#   my $redirect_header = $self->_redirect_to_eshelf($session);
sub _redirect_to_eshelf {
  my ($self, $session) = @_;
  my $eshelf_url = $self->{'conf'}->{eshelf_url};
  return _redirect_to_cleanup unless $eshelf_url;
  my $target_url = $self->target_url;
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  $target_url = uri_escape($target_url);
  my $cleanup_url = uri_escape($self->cleanup_url.$target_url);
  return $self->$redirect("$eshelf_url/validate?return_url=$cleanup_url");
}

# Returns a redirect header to the EZProxy URL for the given target url
# Usage:
#   my $redirect_header = $self->_redirect_to_ezproxy($target_url);
# TODO: Set the EZProxy redirect!
sub _redirect_to_ezproxy {
  my($self, $user, $target_url, $session) = @_;
  my $uri = URI->new($target_url);
  my $resource_url = uri_escape($uri->query_param('url'));
  my $ezproxy_url = $self->{'conf'}->{ezproxy_url};
  my $ezproxy_ticket = $self->$ezproxy_ticket($user);
  $ezproxy_url .= "/login?ticket=$ezproxy_ticket&user=$user&qurl=$resource_url";
  # Go through the cleanup if we have a session.
   if ($session) {
     $ezproxy_url = uri_escape($ezproxy_url);
     # my $eshelf_url = $self->{'conf'}->{eshelf_url};
     # return $self->$redirect("$eshelf_url/validate?return_url=$ezproxy_url");
     return $self->$redirect($self->cleanup_url.$ezproxy_url);
   } else {
     return $self->$redirect($ezproxy_url);
   }
}

# Returns a redirect header to the EZProxy URL
sub _redirect_to_alumni_ezproxy {
  my $self = shift;
  return $self->$redirect(ALUMNI_EZPROXY_URL);
}

# Returns a redirect header to the EZBorrow URL for the given session and query
sub _redirect_to_ezborrow {
  my($self, $session, $current_url) = @_;
  my $uri = URI->new($current_url);
  my $query =  $uri->query_param('query');
  my $barcode = $session->barcode;
  my $ezborrow_url =
    EZBORROW_URL_BASE."?command=mkauth&LS=NYU&PI=$barcode&query=$query";
  $ezborrow_url = uri_escape($ezborrow_url);
  # my $eshelf_url = $self->{'conf'}->{eshelf_url};
  # return $self->$redirect("$eshelf_url/validate?return_url=$ezborrow_url");
  return $self->$redirect($self->cleanup_url.$ezborrow_url);
};

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
      $self->set('error', $error);
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
    # Don't overwrite the existing error.
    unless ($self->error) {
      my $error = $ns_ldap_identity->error;
      $self->set('error', $error);
    }
    return undef;
  }
  # Encrypt the Aleph identity's password
  $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
  # If we successfully authenticated return identities
  return [$ns_ldap_identity, $aleph_identity];
}

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
    my $aleph_identity = $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
    # Check if the Aleph identity exists
    if ($aleph_identity->exists) {
      # Encrypt the Aleph identity's password
      $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
      my $session = 
        $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
      # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
      # or just got it from me.
      # return $nyu_shibboleth_controller->redirect_to_eshelf();
      return $nyu_shibboleth_controller->redirect_to_cleanup($session);
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
      # Encrypt the Aleph identity's password
      $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
      my $session = 
        $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
      # Delegate redirect to Shibboleth controller, since it captured it on the previous pass,
      # or just got it from me.
      # return $nyu_shibboleth_controller->redirect_to_eshelf();
      return $nyu_shibboleth_controller->redirect_to_cleanup($session);
    }
  }
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
    # Redirect to whence we came (with some processing)
    # return $self->_redirect_to_eshelf();
    return $self->_redirect_to_cleanup($session);
  } else {
    # Redirect to unauthorized page
    return $self->_redirect_to_unauthorized() if ($self->error eq "Unauthorized");
    # Let people know that BobCat is down.
    if ($self->error eq "Authentication error: Couldn't get a session id") {
      $self->set('error', "We're sorry for the inconvenience, but BobCat login services are down at the moment.");
    } else {
      $self->set('error', "There seems to have been a problem logging in. Please check your credentials.");
    }
    # Return Login Screen
    return $self->_login_screen();
  }
}

# Destroy the session, handle cookie maintenance and
# redirect to the Shibboleth local logout
sub logout {
  my $self = shift;
  my $cgi = CGI->new();
  print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  my $session = $self->$current_session;
  my $nyu_shibboleth;
  if($session) {
    # Logout of ExLibris applications with hack for logging out of Primo due to load balancer issues.
    my @remote_address = split (/,/,$session->remote_address);
    my $bobcat_logout_url = $self->{'conf'}->{'bobcat_logout_url'};
    $nyu_shibboleth = $session->nyu_shibboleth;
    my $session_id = $session->session_id;
    for (my $i=0; $remote_address[$i]; $i++) {
      my @remote_one = split (/;/,$remote_address[$i]);
      # Hack for dealing with the fact that we can't call primo logout from the 
      # pds server since they are the same box and the load balancer doesn't like it.
      if ($remote_one[2] eq "primo") {
        my $url = uri_escape($remote_one[0]);
        CallHttpd::call_httpd('GET',"$bobcat_logout_url?bobcat_url=$url&pds_handle=$session_id");
      } else {
        PDSLogout::logout_application($remote_one[0], $session_id, $session->institute, $remote_one[2], , "");
      }
    }
    # Logout
    $self->$destroy_session();
  }
  my $target_url = ($nyu_shibboleth) ? GLOBAL_NYU_SHIBBOLETH_LOGOUT : $self->target_url;
  $target_url = uri_escape($target_url) if $target_url;
  my $return = ($self->target_url) ? "return=$target_url" : "";
  return $self->$redirect("/Shibboleth.sso/Logout?$return");
}

# Redirect to ezproxy if authenticated and authorized
# Otherwise, present unauthorized screen if unauthorized
# or login screen in not logged in
# Usage:
#   $controller->ezproxy();
sub ezproxy {
  my $self = shift;
  my $cgi = CGI->new();
  print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  # First check the current session
  if(defined($self->$current_session)) {
    if ($self->$is_ezproxy_authorized($self->$current_session)) {
      # Get the session's user id
      my $uid = $self->$current_session->uid;
      # Redirect to ezproxy
      return $self->_redirect_to_ezproxy($uid, $self->target_url);
    } elsif($self->$is_alumni($self->$current_session)) {
      # Redirect to alumnni EZ proxy
      return $self->_redirect_to_alumni_ezproxy();
    } else {
      # Exit with Unauthorized Error
      $self->set('error', "EZProxy Unauthorized");
      return $self->_redirect_to_ezproxy_unauthorized();
    }
  } else {
    my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
    # The Shibboleth controller can go "nuclear" and just exit at this point.
    # It will redirect to the Shibboleth IdP for passive authentication.
    my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
    # Do we have an Shibboleth identity? If so, let's check if it can ezproxy
    if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
      # Try to create a PDS session, since we have the opportunity.
      my $aleph_controller = $self->$aleph_controller();
      my $aleph_identity = 
        $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
      my $session;
      # Check if the Aleph identity exists
      if ($aleph_identity->exists) {
        # Encrypt the Aleph identity's password
        $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
        $session = 
          $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
      }
      # Check if the Shibboleth user is authorized
      # Were duck typing here, having an NYU shibboleth identity
      # quacking like a session
      if ($self->$is_ezproxy_authorized($nyu_shibboleth_identity)) {
        # Get the NYU Shibboleth identity's user id
        my $uid = $nyu_shibboleth_identity->uid;
        # Get the target URL from Shibboleth controller, 
        # since it captured it on the previous pass,
        # or just got it from me.
        my $target_url = $nyu_shibboleth_controller->get_target_url();
        # Redirect to EZ proxy
        return $self->_redirect_to_ezproxy($uid, $self->target_url, $session);
      } elsif ($self->$is_alumni($nyu_shibboleth_identity)) {
        # Redirect to alumnni EZ proxy
        return $self->_redirect_to_alumni_ezproxy();
      } else {
        # Exit with Unauthorized Error
        $self->set('error', "EZProxy Unauthorized");
        return $self->_redirect_to_ezproxy_unauthorized();
      }
    }
  }
  # Print the login screen
  return $self->_login_screen();
}

# Redirect to ezborrow if authenticated and authorized
# Otherwise, present unauthorized screen if unauthorized
# or login screen in not logged in
# Usage:
#   $controller->ezborrow();
sub ezborrow {
  my $self = shift;
  my $cgi = CGI->new();
  print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  # First check the current session
  if(defined($self->$current_session)) {
    if($self->$is_ezborrow_authorized($self->$current_session)) {
      # Redirect to EZ borrow
      return $self->_redirect_to_ezborrow($self->$current_session, uri_unescape($self->current_url));
    } else {
      # Exit with Unauthorized Error
      $self->set('error', "EZBorrow Unauthorized");
      return $self->_redirect_to_ezborrow_unauthorized();
    }
  } else {
    my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
    # The Shibboleth controller can go "nuclear" and just exit at this point.
    # It will redirect to the Shibboleth IdP for passive authentication.
    my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
    # Do we have an identity? If so, let's get the associated Aleph identity
    if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
      my $aleph_controller = $self->$aleph_controller();
      my $aleph_identity = 
        $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
      # Check if the Aleph identity exists
      if ($aleph_identity->exists) {
        # Encrypt the Aleph identity's password
        $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
        my $session = 
          $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
        if ($self->$is_ezborrow_authorized($session)) {
          # Redirect to EZ proxy
          return $self->_redirect_to_ezborrow($session, uri_unescape($self->current_url));
        } else {
          print "Aleph Id: ".Dumper($aleph_identity);
          #print "Barcode: ".$session->barcode;
          #print "Bor Status: ".$session->bor_status;
          #print "Auth Statuses: ".Dumper(EZBORROW_AUTHORIZED_STATUSES);
          # Exit with Unauthorized Error
          $self->set('error', "EZBorrow Unauthorized");
          return $self->_redirect_to_ezborrow_unauthorized();
        }
      } else {
        # Exit with Unauthorized Error
        $self->set('error', "EZBorrow Unauthorized");
        return $self->_redirect_to_ezborrow_unauthorized();
      }
    }
  }
  # Print the login screen
  return $self->_login_screen();
}

# Return the bor_info as an XML string
# Usage:
#   $controller->bor_info();
sub bor_info {
  my $self = shift;
  my $cgi = CGI->new();
  print $cgi->header(-type=>'text/xml', -charset =>'UTF-8');
  if ($self->session_id) {
    my $session = $self->$current_session();
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
