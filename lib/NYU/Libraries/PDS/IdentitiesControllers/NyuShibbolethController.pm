# Controller for creating NYU Shibboleth identities
package NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use strict;
use warnings;

# CGI module for dealing with redirects and cookies
use CGI qw/:standard/;
use CGI::Cookie;

# URI encoding module
use URI::Escape;

# NYU Libraries Shibboleth Identity
use NYU::Libraries::PDS::Identities::NyuShibboleth;
use NYU::Libraries::PDS::Views::Redirect;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);
__PACKAGE__->mk_accessors(qw(target_url current_url cleanup_url institute));

# Been there done that cookie name
use constant PDS_TARGET_COOKIE => 'pds_btdt_target_url';

my $expire_been_there_done_that = sub {
  my $self = shift;
  my $cgi = CGI->new();
  # Unset the cookie!
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
    -expires => '-10Y', -value => '');
  print $cgi->header(-cookie => [$pds_target]);
};

my $set_been_there_done_that = sub {
  my $self = shift;
  my $cgi = CGI->new();
  # Set the cookie to the current target URL
  # Set the session cookie
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE, 
    -value => $self->target_url);
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

my $redirect = sub {
  my($self, $target_url) = @_;
  # Present Redirect Screen
  my $template = NYU::Libraries::PDS::Views::Redirect->new($self->{'conf'}, $self);
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
  print $self->$redirect("/Shibboleth.sso/Login?isPassive=true&target=$current_url");
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

sub redirect_to_target {
  my $self = shift;
  return $self->$redirect($self->get_target_url());
}

sub redirect_to_cleanup {
  my $self = shift;
  return redirect_to_target unless $self->cleanup_url;
  my $target_url = uri_escape($self->get_target_url());
  return $self->$redirect($self->cleanup_url.$target_url);
}

# Returns a redirect header to the eshelf
# Usage:
#   my $redirect_header = $controller->redirect_to_eshelf();
sub redirect_to_eshelf {
  my $self = shift;
  my $eshelf_url = $self->{'conf'}->{eshelf_url};
  return redirect_to_cleanup unless $eshelf_url;
  my $target_url = uri_escape($self->target_url);
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
