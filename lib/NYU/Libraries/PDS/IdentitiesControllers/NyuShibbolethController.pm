# Controller for creating NYU Shibboleth identities
package NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use strict;
use warnings;

# CGI module for dealing with redirects and cookies
use CGI qw/:standard/;
use CGI::Cookie;

# URI encoding module
use URI::Escape;

# NYU Libraries modules
use NYU::Libraries::Util qw(handle_primo_target_url);
use NYU::Libraries::PDS::Identities::NyuShibboleth;
use NYU::Libraries::PDS::Views::Redirect;
use NYU::Libraries::PDS::Views::ShibbolethRedirect;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);
__PACKAGE__->mk_accessors(qw(target_url current_url cleanup_url institute));

# Been there done that cookie name
use constant PDS_TARGET_COOKIE => 'pds_btdt_target_url';

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
  my $self = shift;
  my $cgi = CGI->new();
  # Set the cookie to the current target URL
  # It expires in 5 minutes
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE, 
    -expires => '+5m', -value => $self->target_url);
  print $cgi->header(-cookie => [$pds_target]);
};

# Private method gets/sets the cookie that specifies that 
# we've been here done that
# Method name is a dumb reference to 
# "check yourself before you wreck yourself"
# Usage:
#   $self->$check();
my $check = sub {
  my $self = shift;
  my $cgi = CGI->new();
  if ($self->been_there_done_that()) {
    $self->$expire_been_there_done_that();
    return 1;
  } else {
    $self->$set_been_there_done_that();
    return 0;
  }
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

# Private method to redirect to Shibboleth via JavaScript (via a template)
# since Safari won't set our cookie if we send as
# a redirect (302)
# http://stackoverflow.com/questions/1144894/safari-doesnt-set-cookie-but-ie-ff-does
# Usage:
#   $self->$redirect_to_shibboleth($target_url, $session);
my $redirect_to_shibboleth = sub {
  my($self, $target_url, $session) = @_;
  # Present Redirect Screen
  my $template = NYU::Libraries::PDS::Views::ShibbolethRedirect->new($self->{'conf'}, $self);
  $template->{target_url} = $target_url;
  return $template->render();
};

# Private method exits the running program and immediately redirects
# to the Shibboleth IdP
# Method name is a dumb reference to 
# "check yourself before you wreck yourself"
# Usage:
#   $self->$wreck();
my $wreck = sub {
  my $self = shift;
  my $current_url = $self->current_url();
  # Redirect to the Shib IdP and exit
  print $self->$redirect_to_shibboleth($current_url);
  # Stop, collabortate and listen!
  exit;
};

# Method to create an NYU Shibboleth identity based on the current environment
# Usage:
#   $controller->create($id, $password);
sub create {
  my $self = shift;
  my $identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new($self->{'conf'});
  # If we have an identity, we've successfully created from the Shibboleth SP
  if ($identity->exists) {
    # Expire the been there done that cookie.
    $self->$expire_been_there_done_that();
    return $identity
  } else {
    # Check yourself before you wreck yourself
    # Checks for passive cookie
    #   If exists, returns undef
    #   otherwise redirects to Idp
    unless($self->$check()) {
      $self->$wreck();
    } else {
      return undef;
    }
  }
  return undef;
}

# Returns a redirect header to the target
# Usage:
#   my $redirect_header = $controller->redirect_to_target($session);
sub redirect_to_target {
  my ($self, $session) = @_;
  my $target_url = $self->get_target_url();
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  return $self->$redirect($target_url);
}

# Returns a redirect header to the Primo cleanup page
# Usage:
#   my $redirect_header = $controller->redirect_to_cleanup($session);
sub redirect_to_cleanup {
  my ($self, $session) = @_;
  return redirect_to_target unless $self->cleanup_url;
  my $target_url = $self->get_target_url();
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  $target_url = uri_escape($target_url);
  return $self->$redirect($self->cleanup_url.$target_url);
}

# Returns a redirect header to the eshelf
# Usage:
#   my $redirect_header = $controller->redirect_to_eshelf($session);
sub redirect_to_eshelf {
  my ($self, $session) = @_;
  my $eshelf_url = $self->{'conf'}->{eshelf_url};
  return redirect_to_cleanup unless $eshelf_url;
  my $target_url = $self->get_target_url();
  # Primo sucks!
  $target_url = handle_primo_target_url($self->{'conf'}, $target_url, $session);
  $target_url = uri_escape($target_url);
  my $cleanup_url = uri_escape($self->cleanup_url.$target_url);
  return $self->$redirect("$eshelf_url/validate?return_url=$cleanup_url");
}

# Method returns the target url
# Checks the "been there done that" cookie first.
# Usage:
#   $controller->get_target_url();
sub get_target_url {
  my $self = shift;
  return ($self->been_there_done_that() || $self->target_url);
};

# Method to get the "been there done that" cookie
# Usage:
#   $controller->been_there_done_that();
sub been_there_done_that {
  # Get the "been there done that" cookie that says 
  # we've tried this and failed.  Get the target URL.
  my $cgi = CGI->new();
  return $cgi->cookie(PDS_TARGET_COOKIE);
}

1;
