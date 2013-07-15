# Controller for creating NYU Shibboleth identities
package NYU::Libraries::PDS::IdentitiesControllers::NyuShibbolethController;
use strict;
use warnings;

# CGI module for dealing with redirects and cookies
use CGI qw/:standard/;
use CGI::Cookie;

# NYU Libraries Shibboleth Identity
use NYU::Libraries::PDS::Identities::NyuShibboleth;

use base qw(NYU::Libraries::PDS::IdentitiesControllers::BaseController);
__PACKAGE__->mk_accessors(qw(target_url));

use constant PDS_TARGET_COOKIE => 'pds_target';
use constant PDS_TARGET_COOKIE_DOMAIN => '.logindev.library.nyu.edu';

# Private method to get the "been_here_done_that" cookie
my $been_here_done_that = sub {
  # Get the "been_here_done_that" cookie that says 
  # we've tried this and failed.  Get the target URL.
  my %cookies = CGI::Cookie->fetch;
  return $cookies{PDS_TARGET_COOKIE};
};

# Private method to return the target url
my $target_url = sub {
  my $self = shift;
  return ($self->$been_here_done_that() || $self->target_url);
};

# Private method gets/sets the cookie that specifies that 
# we've been here done that
my $check = sub {
  my $self = shift;
  my $cgi = CGI->new();
  my $pds_target;
  if ($self->$been_here_done_that()) {
    # Unset the cookie!
    # TODO: Unset the cookie!
    $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE, -expires => '-5Y',
      -value => $self->target_url, -domain => PDS_TARGET_COOKIE_DOMAIN);
    print $cgi->header(-cookie=>[$pds_target]);
    return 0;
  } else {
    # Set the cookie to the current target URL
    # TODO: Set the cookie to the current target URL
    # Set the session cookie
    $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
      -value => $self->target_url, -domain => PDS_TARGET_COOKIE_DOMAIN);
    print $cgi->header(-cookie=>[$pds_target]);
    return 1;
  }
};

# Private method redirects to the NYU Shibboleth IdP
my $wreck = sub {
  my $self = shift;
  my $cgi = CGI->new();
  # Redirect to the Shib IdP
  return $cgi->redirect("/Shibboleth.sso/pds/Login?isPassive=true&target=https://logindev.library.nyu.edu/pds?func=load-login&institute=NYU");
};

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
    if($self->$check()) {
      print $self->$wreck();
      # Stop, collabortate and listen!
      exit;
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

1;
