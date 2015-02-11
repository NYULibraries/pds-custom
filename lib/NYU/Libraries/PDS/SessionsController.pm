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
use NYU::Libraries::Util qw(trim whitelist_institution save_permanent_eshelf_records handle_primo_target_url PDS_TARGET_COOKIE);
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
use constant DEFAULT_TARGET_URL => "http://bobcat.library.nyu.edu";
use constant DEFAULT_FUNCTION => "sso";
use constant EZBORROW_AUTHORIZED_STATUSES => qw(20 21 22 23 50 51 52 53 54 55 56 57 58 60 61 62 63 65 66 80 81 82);
use constant EZBORROW_URL_BASE => "https://e-zborrow.relaisd2d.com/service-proxy/";
# library dot nyu cookies to delete on logout
use constant LIBRARY_DOT_NYU_COOKIES => qw(_tsetse_session tsetse_credentials tsetse_handle nyulibrary_opensso_illiad
  _umlaut_session _getit_session _eshelf_session _umbra_session _privileges_guide_session
    _room_reservation_session _room_reservation_session _marli_session xerxessession_);
use constant COOKIE_EXPIRATION => 'Thu, 01-Jan-1970 00:00:01 GMT';

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
    access_token_method => $conf->{accesss_token_method}
  )->web_server(redirect_uri => $conf->{oauth_callback_url});
  return $oauth2_client;
};

# Private method expires the cookie that specifies that
# we've been here done that
# Usage:
#   $self->$expire_been_there_done_that();
my $expire_been_there_done_that = sub {
  my $self = shift;
  my $cgi = CGI->new();
  # Unset the cookie!
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
    -expires => 'Thu, 01-Jan-1970 00:00:01 GMT');
  print $cgi->header(-cookie => [$pds_target]);
};

# Private method sets the cookie that specifies that
# we've been here done that
# Usage:
#   $self->$set_been_there_done_that();
my $set_been_there_done_that = sub {
  my ($self) = shift;
  my $cgi = CGI->new();
  # Set the cookie to the current target URL
  # It expires in 5 minutes
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
    -expires => '+5m', -value => $self->target_url);
  print $cgi->header(-cookie => [$pds_target]);
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
# my $is_ezproxy_authorized = sub {
#   my($self, $session) = @_;
#   # Not authorized if we're not signed on through NYU shibboleth
#   return 0 unless $session->nyu_shibboleth;
#   # Not authorized if we don't have an entitlements
#   return 0 unless $session->entitlements;
#   my $entitlements = $session->entitlements;
#   # Poly students have partial access which actually means full access
#   return 1 if ($entitlements =~ m/urn:mace:nyu.edu:entl:lib:partialeresources/);
#   # Everyone else has full access which actually means full access
#   return 1 if ($entitlements =~ m/urn:mace:nyu.edu:entl:lib:eresources/);
#   return 0;
# };

# Private method to determine if the given session is
# authorized for EZ Borrow
# Usage:
#   $self->$is_ezborrow_authorized($session)
# my $is_ezborrow_authorized = sub {
#   my($self, $session) = @_;
#   # Must have a barcode
#   return 0 unless $session->barcode;
#   # Must be an approved status
#   return (grep { $_ eq $session->bor_status } EZBORROW_AUTHORIZED_STATUSES);
# };

# Private method to determine if the given session is
# an alumnus
# Usage:
#   $self->$is_alumni($session)
# my $is_alumni = sub {
#   my($self, $session) = @_;
#   # Not alumni if we're not signed on through NYU shibboleth
#   return 0 unless $session->nyu_shibboleth;
#   # Not alumni if we don't have an entitlements
#   return 0 unless $session->entitlements;
#   my $entitlements = $session->entitlements;
#   return ($entitlements =~ m/alum/);
# };

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

# Private method to set the target URL
# Usage:
#   $self->$set_target_url($target_url);
my $set_target_url = sub {
  my($self, $target_url) = @_;
  # Set target_url from either the given target URL, the shibboleth controller stored
  # "been there done that cookie" or the default
  $target_url ||= $self->_been_there_done_that();
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


# Method returns the target url
# Checks the "been there done that" cookie first.
# Usage:
#   $self->_get_target_url();
sub _get_target_url {
  my $self = shift;
  return ($self->_been_there_done_that() || $self->target_url);
};

# Method to get the "been there done that" cookie
# Usage:
#   $self->_been_there_done_that();
sub _been_there_done_that {
  # Get the "been there done that" cookie that says
  # we've tried this and failed.  Get the target URL.
  my $cgi = CGI->new();
  return $cgi->cookie(PDS_TARGET_COOKIE);
}

# Returns a rendered HTML login screen for presentation
# Usage:
#   my $login_screen = $self->_login_screen();
sub _login_screen {
  my $self = shift;
  # Present Login Screen
  return $self->$redirect($self->$client->authorize());
}

# Returns a rendered HTML logout screen for presentation
# Usage:
#   my $login_screen = $self->_logout_screen();
sub _logout_screen {
  my $self = shift;
  my $conf = $self->{'conf'};
  # Present Login Screen
  return $self->$redirect($conf->{site}.$conf->{logout_path});
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
  my $target_url = $self->_get_target_url();
  # Primo sucks!
  print STDERR Dumper($target_url);
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  print STDERR Dumper($target_url);
  return $self->$redirect($target_url);
}

# Returns a redirect header to the cleanup URL
# Usage:
#   my $redirect_header = $self->_redirect_to_cleanup($session);
# sub _redirect_to_cleanup {
#   my ($self, $session) = @_;
#   return _redirect_to_target unless $self->cleanup_url;
#   my $target_url = $self->target_url;
#   # Primo sucks!
#   $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
#   $target_url = uri_escape($target_url);
#   return $self->$redirect($self->cleanup_url.$target_url);
# }

# Returns a redirect header to the eshelf
# Usage:
#   my $redirect_header = $self->_redirect_to_eshelf($session);
# sub _redirect_to_eshelf {
#   my ($self, $session) = @_;
#   my $eshelf_url = $self->{'conf'}->{eshelf_url};
#   return _redirect_to_cleanup unless $eshelf_url;
#   my $target_url = $self->target_url;
#   # Primo sucks!
#   $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
#   $target_url = uri_escape($target_url);
#   my $cleanup_url = uri_escape($self->cleanup_url.$target_url);
#   return $self->$redirect("$eshelf_url/validate?return_url=$cleanup_url");
# }

# Returns a redirect header to the EZProxy URL for the given target url
# Usage:
#   my $redirect_header = $self->_redirect_to_ezproxy($target_url);
# TODO: Set the EZProxy redirect!
# sub _redirect_to_ezproxy {
#   my($self, $user, $target_url, $session) = @_;
#   my $uri = URI->new($target_url);
#   my $resource_url = uri_escape($uri->query_param('url'));
#   my $ezproxy_url = $self->{'conf'}->{ezproxy_url};
#   my $ezproxy_ticket = $self->$ezproxy_ticket($user);
#   $ezproxy_url .= "/login?ticket=$ezproxy_ticket&user=$user&qurl=$resource_url";
#   # Go through the cleanup if we have a session.
#    if ($session) {
#      $ezproxy_url = uri_escape($ezproxy_url);
#      # my $eshelf_url = $self->{'conf'}->{eshelf_url};
#      # return $self->$redirect("$eshelf_url/validate?return_url=$ezproxy_url");
#      return $self->$redirect($self->cleanup_url.$ezproxy_url);
#    } else {
#      return $self->$redirect($ezproxy_url);
#    }
# }
#
# # Returns a redirect header to the EZProxy URL
# sub _redirect_to_alumni_ezproxy {
#   my $self = shift;
#   return $self->$redirect(ALUMNI_EZPROXY_URL);
# }
#
# # Returns a redirect header to the EZBorrow URL for the given session and query
# sub _redirect_to_ezborrow {
#   my($self, $session, $current_url) = @_;
#   my $uri = URI->new($current_url);
#   my $query =  $uri->query_param('query');
#   my $barcode = $session->barcode;
#   my $ezborrow_url =
#     EZBORROW_URL_BASE."?command=mkauth&LS=NYU&PI=$barcode&query=".uri_escape($query);
#   $ezborrow_url = uri_escape($ezborrow_url);
#   # my $eshelf_url = $self->{'conf'}->{eshelf_url};
#   # return $self->$redirect("$eshelf_url/validate?return_url=$ezborrow_url");
#   return $self->$redirect($self->cleanup_url.$ezborrow_url);
# };

# Display the login screen, unless already signed in
# Usage:
#   $controller->load_login();
sub load_login {
  my $self = shift;
  # Print the login screen
  return $self->_login_screen();
}

# Alias this method from OAuth2 callback
# Single sign on if possible, otherwise return from whence you came
# Usage:
#   $controller->sso($auth_code);
sub sso {
  my($self, $auth_code) = @_;
  my $cgi = CGI->new();

  unless ($self->_been_there_done_that()) {
    # Use the auth code to fetch the access token
    if (defined($auth_code)) {
      my $access_token = $self->$client->get_access_token($auth_code);

      if (defined($access_token)) {
        # Use the access token to fetch a protected resource
        my $response = $access_token->get($self->$client->protected_resource_url);

        # If we got the response and this user has an aleph identity, let's log 'em in
        if ($response->is_success) {# && $self->aleph_identity()->exists) {
          my $user = decode_json($response->decoded_content);
          # Now we've been there, done that
          $self->$set_been_there_done_that();
          # Create the session
          my $session = $self->$create_session($user);
          # Redirecet to target
          return $self->_redirect_to_target($session);
        }
        else {
          $self->set('error', "Unauthorized");
          return $self->_redirect_to_unauthorized();
        }
      }
    }
  }
  return $self->_redirect_to_target();
}

# Destroy the session, handle cookie maintenance and
# redirect to the Shibboleth local logout
sub logout {
  # my $self = shift;
  # my $cgi = CGI->new();
  # print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  # my $session = $self->$current_session;
  # my $nyu_shibboleth;
  # if($session) {
  #   # Logout of ExLibris applications with hack for logging out of Primo due to load balancer issues.
  #   my @remote_address = split (/,/,$session->remote_address);
  #   my $bobcat_logout_url = $self->{'conf'}->{'bobcat_logout_url'};
  #   $nyu_shibboleth = $session->nyu_shibboleth;
  #   my $session_id = $session->session_id;
  #   for (my $i=0; $remote_address[$i]; $i++) {
  #     my @remote_one = split (/;/,$remote_address[$i]);
  #     # Hack for dealing with the fact that we can't call primo logout from the
  #     # pds server since they are the same box and the load balancer doesn't like it.
  #     if ($remote_one[2] eq "primo") {
  #       my $url = uri_escape($remote_one[0]);
  #       CallHttpd::call_httpd('GET',"$bobcat_logout_url?bobcat_url=$url&pds_handle=$session_id");
  #     } else {
  #       PDSLogout::logout_application($remote_one[0], $session_id, $session->institute, $remote_one[2], , "");
  #     }
  #   }
  #   # Logout
  #   $self->$destroy_session();
  # }
  # my $target_url = ($nyu_shibboleth) ? GLOBAL_NYU_SHIBBOLETH_LOGOUT : $self->target_url;
  # $target_url = uri_escape($target_url) if $target_url;
  # my $return = ($self->target_url) ? "return=$target_url" : "";
  # return $self->$redirect("/Shibboleth.sso/Logout?$return");
}

# Redirect to ezproxy if authenticated and authorized
# Otherwise, present unauthorized screen if unauthorized
# or login screen in not logged in
# Usage:
#   $controller->ezproxy();
sub ezproxy {
  my $self = shift;
  # my $cgi = CGI->new();
  # print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  # # First check the current session
  # if(defined($self->$current_session)) {
  #   if ($self->$is_ezproxy_authorized($self->$current_session)) {
  #     # Get the session's user id
  #     my $uid = $self->$current_session->uid;
  #     # Redirect to ezproxy
  #     return $self->_redirect_to_ezproxy($uid, $self->target_url);
  #   } elsif($self->$is_alumni($self->$current_session)) {
  #     # Redirect to alumnni EZ proxy
  #     return $self->_redirect_to_alumni_ezproxy();
  #   } else {
  #     # Exit with Unauthorized Error
  #     $self->set('error', "EZProxy Unauthorized");
  #     return $self->_redirect_to_ezproxy_unauthorized();
  #   }
  # } else {
  #   my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  #   # The Shibboleth controller can go "nuclear" and just exit at this point.
  #   # It will redirect to the Shibboleth IdP for passive authentication.
  #   my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  #   # Do we have an Shibboleth identity? If so, let's check if it can ezproxy
  #   if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
  #     # Try to create a PDS session, since we have the opportunity.
  #     my $aleph_controller = $self->$aleph_controller();
  #     my $aleph_identity =
  #       $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
  #     my $session;
  #     # Check if the Aleph identity exists
  #     if ($aleph_identity->exists) {
  #       # Encrypt the Aleph identity's password
  #       $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
  #       $session =
  #         $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
  #     }
  #     # Check if the Shibboleth user is authorized
  #     # Were duck typing here, having an NYU shibboleth identity
  #     # quacking like a session
  #     if ($self->$is_ezproxy_authorized($nyu_shibboleth_identity)) {
  #       # Get the NYU Shibboleth identity's user id
  #       my $uid = $nyu_shibboleth_identity->uid;
  #       # Get the target URL from Shibboleth controller,
  #       # since it captured it on the previous pass,
  #       # or just got it from me.
  #       my $target_url = $nyu_shibboleth_controller->get_target_url();
  #       # Redirect to EZ proxy
  #       return $self->_redirect_to_ezproxy($uid, $self->target_url, $session);
  #     } elsif ($self->$is_alumni($nyu_shibboleth_identity)) {
  #       # Redirect to alumnni EZ proxy
  #       return $self->_redirect_to_alumni_ezproxy();
  #     } else {
  #       # Exit with Unauthorized Error
  #       $self->set('error', "EZProxy Unauthorized");
  #       return $self->_redirect_to_ezproxy_unauthorized();
  #     }
  #   }
  # }
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
  # my $cgi = CGI->new();
  # print $cgi->header(-type=>'text/html', -charset =>'UTF-8');
  # # First check the current session
  # if(defined($self->$current_session)) {
  #   if($self->$is_ezborrow_authorized($self->$current_session)) {
  #     # Redirect to EZ borrow
  #     return $self->_redirect_to_ezborrow($self->$current_session, uri_unescape($self->current_url));
  #   } else {
  #     # Exit with Unauthorized Error
  #     $self->set('error', "EZBorrow Unauthorized");
  #     return $self->_redirect_to_ezborrow_unauthorized();
  #   }
  # } else {
  #   my $nyu_shibboleth_controller = $self->$nyu_shibboleth_controller();
  #   # The Shibboleth controller can go "nuclear" and just exit at this point.
  #   # It will redirect to the Shibboleth IdP for passive authentication.
  #   my $nyu_shibboleth_identity = $nyu_shibboleth_controller->create();
  #   # Do we have an identity? If so, let's get the associated Aleph identity
  #   if (defined($nyu_shibboleth_identity) && $nyu_shibboleth_identity->exists) {
  #     my $aleph_controller = $self->$aleph_controller();
  #     my $aleph_identity =
  #       $aleph_controller->get($nyu_shibboleth_identity->aleph_identifier);
  #     # Check if the Aleph identity exists
  #     if ($aleph_identity->exists) {
  #       # Encrypt the Aleph identity's password
  #       $aleph_identity = $self->$encrypt_aleph_identity($aleph_identity);
  #       my $session =
  #         $self->$create_session($nyu_shibboleth_identity, $aleph_identity);
  #       if ($self->$is_ezborrow_authorized($session)) {
  #         # Redirect to EZ proxy
  #         return $self->_redirect_to_ezborrow($session, uri_unescape($self->current_url));
  #       } else {
  #         # Exit with Unauthorized Error
  #         $self->set('error', "EZBorrow Unauthorized");
  #         return $self->_redirect_to_ezborrow_unauthorized();
  #       }
  #     } else {
  #       # Exit with Unauthorized Error
  #       $self->set('error', "EZBorrow Unauthorized");
  #       return $self->_redirect_to_ezborrow_unauthorized();
  #     }
  #   }
  # }
  # Print the login screen
  # return $self->_login_screen();
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
