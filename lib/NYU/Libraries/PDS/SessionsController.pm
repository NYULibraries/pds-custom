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

# Use the Net::OAuth2 client for logging in with oauth2 standard
use Net::OAuth2::Client;

# Use JSON to parse JSON response from oauth2 provider
use JSON;

# NYU Libraries modules
use NYU::Libraries::Util qw(trim whitelist_institution save_permanent_eshelf_records handle_primo_target_url
                                expire_target_url_cookie set_target_url_cookie target_url_cookie
                                  aleph_identity PDS_TARGET_COOKIE COOKIE_EXPIRATION);
use NYU::Libraries::PDS::Session;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(institute calling_system target_url current_url cleanup_url session_id error));

# Default constants
use constant UNAUTHORIZED_URL => "http://library.nyu.edu/errors/login-library-nyu-edu/unauthorized.html";
use constant EZPROXY_UNAUTHORIZED_URL => "http://library.nyu.edu/errors/ezproxy-library-nyu-edu/login.html";
use constant EZBORROW_UNAUTHORIZED_URL => "http://library.nyu.edu/errors/ezborrow-library-nyu-edu/login.html";
use constant ALUMNI_EZPROXY_URL => "http://library.nyu.edu/alumni/eresources.html";
use constant DEFAULT_INSTITUTE => "NYU";
use constant DEFAULT_CALLING_SYSTEM => "primo";
use constant DEFAULT_TARGET_URL => "http://bobcat.library.nyu.edu/primo_library/libweb/action/search.do?vid=NYU";
use constant DEFAULT_FUNCTION => "sso";
use constant EZBORROW_AUTHORIZED_STATUSES => qw(20 21 22 23 50 51 52 53 54 55 56 57 58 60 61 62 63 65 66 80 81 82);
use constant EZBORROW_URL_BASE => "https://e-zborrow.relaisd2d.com/service-proxy/";

# Private method to retrieve the OAuth2 server info
# Usage:
#   $oauth2_client = $self->$client
my $client = sub {
  my $self = shift;
  my $conf = $self->{'conf'};
  my $oauth2_client = Net::OAuth2::Client->new(
    $conf->{site_id},
    $conf->{site_secret},
    site => $conf->{site},
    authorize_path => $conf->{authorize_path},
    protected_resource_url => $conf->{protected_resource_url},
    access_token_path => $conf->{access_token_path},
    access_token_method => $conf->{access_token_method}
  )->web_server(redirect_uri => $conf->{oauth_callback_url});
  return $oauth2_client;
};

# Private method to retrieve whether or not there is an aleph identity
# Usage:
#   $aleph_identity = $self->$aleph_identity($user);
my $aleph_identity = sub {
  my ($self, $user) = @_;
  my @identities = $user->{'identities'};
  my $aleph_identity = aleph_identity(@identities);
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
  return 0 unless $session->entitlement;
  my $entitlement = $session->entitlement;
  # Poly students have partial access which actually means full access
  return 1 if ($entitlement =~ m/urn:mace:nyu.edu:entl:lib:partialeresources/);
  # Everyone else has full access which actually means full access
  return 1 if ($entitlement =~ m/urn:mace:nyu.edu:entl:lib:eresources/);
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
  return (grep { $_ eq $session->patron_status } EZBORROW_AUTHORIZED_STATUSES);
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
  return 0 unless $session->entitlement;
  my $entitlement = $session->entitlement;
  return ($entitlement =~ m/alum/);
};

# Private method to create a session
# Usage:
#   $self->$create_session($identity1, $identity2)
my $create_session = sub {
  my($self, $user) = @_;
  # Get a new session based on the given identities
  my $session = NYU::Libraries::PDS::Session->new($user, $self->{'conf'});
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
  } else {
    $session->{session_id} = "0123456789"
  }
  return $session;
};

# Private method to set the target URL
# Usage:
#   $self->$set_target_url($target_url);
my $set_target_url = sub {
  my($self, $target_url) = @_;
  # Everytime we create a new sessions controller,
  # redirect to the first target url we tried to login from
  if (defined($target_url) && $target_url =~ /oauth_callback/) {
    $target_url = target_url_cookie();
  }
  $target_url ||= $self->{'conf'}->{default_target_url} if $self->{'conf'};
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

# Private method to redirect
# Usage:
#   $self->$redirect($target_url, $session);
my $redirect = sub {
  my($self, $target_url) = @_;
  my $cgi = CGI->new();
  return $cgi->redirect($target_url);
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

# Redirects to the external Oauth2 login screen
# Usage:
#   my $login_screen = $self->_login_screen();
sub _login_screen {
  my $self = shift;
  # Present Login Screen
  return $self->$redirect($self->$client->authorize());
}

# Returns a redirect header to the unauthorized message URL
# Usage:
#   my $redirect_header = $self->_redirect_to_unauthorized();
sub _redirect_to_unauthorized {
  my $self = shift;
  return $self->$redirect(UNAUTHORIZED_URL);
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
    EZBORROW_URL_BASE."?command=mkauth&LS=NYU&PI=$barcode&query=".uri_escape($query);
  $ezborrow_url = uri_escape($ezborrow_url);
  return $self->$redirect($self->cleanup_url.$ezborrow_url);
};

# Display the login screen, unless already signed in
# Usage:
#   $controller->load_login();
sub load_login {
  my $self = shift;
  # Set the target url to be the last url before calling login
  set_target_url_cookie($self->target_url);
  # Print the login screen
  return $self->_login_screen();
}

# Single sign on if possible, otherwise return from whence you came
# Alias this method from OAuth2 callback, and do all passive login stuff from here
# Usage:
#   $controller->sso($auth_code);
sub sso {
  my($self, $auth_code) = @_;
  my $cgi = CGI->new();

  # Use the auth code to fetch the access token
  if (defined($auth_code)) {
    my $access_token = $self->$client->get_access_token($auth_code);

    if (defined($access_token)) {
      # Use the access token to fetch a protected resource
      my $response = $access_token->get($self->$client->protected_resource_url);

      # If we got the response and this user has an aleph identity, let's log 'em in
      if ($response->is_success) {
        my $user = decode_json($response->decoded_content);
        if ($self->$aleph_identity($user)) {
          # Create the session
          my $session = $self->$create_session($user);
          # Redirect to target
          return $self->_redirect_to_cleanup($session);
        } else {
          $self->set('error', "Unauthorized");
          return $self->_redirect_to_unauthorized();
        }
      }
      else {
        $self->set('error', "Unauthorized");
        return $self->_redirect_to_unauthorized();
      }
    }
  }
  return $self->_redirect_to_target();
}

# Redirect to the SSO logout
sub logout {
  my $self = shift;
  my $cgi = CGI->new();
  return $self->$redirect($self->{'conf'}->{'site'}.$self->{'conf'}->{'logout_path'});
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
  }
  # Print the login screen
  return $self->load_login();
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
  }
  # Print the login screen
  return $self->load_login();
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
