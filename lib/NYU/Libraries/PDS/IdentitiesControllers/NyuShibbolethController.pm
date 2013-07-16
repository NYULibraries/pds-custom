# Controller for creating NYU Shibboleth identities
package NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use strict;
use warnings;

# CGI module for dealing with redirects and cookies
use CGI qw/:standard/;

# NYU Libraries Shibboleth Identity
use NYU::Libraries::PDS::Identities::NyuShibboleth;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);
__PACKAGE__->mk_accessors(qw(target_url current_url));

# Been there done that cookie name
use constant PDS_TARGET_COOKIE => 'pds_btdt_target_url';

# Private method returns the target url
# Checks the "been there done that" cookie first.
# Usage:
#   $self->$target_url();
my $target_url = sub {
  my $self = shift;
  return ($self->been_there_done_that() || $self->target_url);
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
  my $pds_target;
  if ($self->been_there_done_that()) {
    # Unset the cookie!
    $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
      -expires => '-5Y', -value => '');
    print $cgi->header(-cookie => [$pds_target]);
    return 1;
  } else {
    # Set the cookie to the current target URL
    # Set the session cookie
    $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE, 
      -value => $self->target_url);
    print $cgi->header(-cookie => [$pds_target]);
    return 0;
  }
};

# Private method exits the running program and immediately redirects
# to the Shibboleth IdP
# Method name is a dumb reference to 
# "check yourself before you wreck yourself"
# Usage:
#   $self->$wreck();
my $wreck = sub {
  my $self = shift;
  my $cgi = CGI->new();
  my $current_url = $self->current_url();
  # Redirect to the Shib IdP and exit
  print $cgi->redirect("/Shibboleth.sso/Login?isPassive=true&target=$current_url");
  # Stop, collabortate and listen!
  exit;
};

# Method to create an NYU Shibboleth identity based on the current environment
# Usage:
#   $controller->create($id, $password);
sub create {
  my $self = shift;
  my $identity = NYU::Libraries::PDS::Identities::NyuShibboleth->new();
  # If we have an identity, we've successfully created from the Shibboleth SP
  if ($identity->exists) {
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
}

sub redirect_to_target {
  my $self = shift;
  my $cgi = CGI->new();
  return $cgi->redirect($self->$target_url());
}

# Method to get the "been there done that" cookie
sub been_there_done_that {
  # Get the "been there done that" cookie that says 
  # we've tried this and failed.  Get the target URL.
  my $cgi = CGI->new();
  return $cgi->cookie(PDS_TARGET_COOKIE);
}

1;
