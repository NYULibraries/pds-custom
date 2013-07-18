# The NYU Shibboleth Identity stores data from the Apache
# environment for current user's Shibboleth session
package NYU::Libraries::PDS::Identities::NyuShibboleth;
use strict;
use warnings;

use base qw(NYU::Libraries::PDS::Identities::Base);
my @attributes = qw(aleph_identifier edupersonentitlement);
__PACKAGE__->mk_ro_accessors(@attributes);

my %SHIBBOLETH_ATTRIBUTE_MAPPINGS = (
  'id' => 'uid',
  'email' => 'mail',
  'givenname' => 'givenName',
  'cn' => 'displayName',
  'sn' => 'sn',
  'aleph_identifier' => 'nyuidn',
  'edupersonentitlement' => 'eduPersonEntitlement'
);

# Private sub that gets the identity from the ShibbolethSP
my $shibboleth_identity = sub {
  my $identity;
  foreach my $attribute (keys %SHIBBOLETH_ATTRIBUTE_MAPPINGS) {
    my $shibboleth_env_var = $SHIBBOLETH_ATTRIBUTE_MAPPINGS{$attribute};
    $identity->{$attribute} = $ENV{$shibboleth_env_var} if defined($ENV{$shibboleth_env_var});
  }
  # Return identity if we found one
  return $identity if $identity->{"id"};
};

# Authentication method
# Usage:
#   $self->authenticate()
sub authenticate {
  my $self = shift;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return undef unless $self->{'conf'};
  # Get the identity
  my $identity = $self->$shibboleth_identity();
  # Set the identity if we've found one
  if ($identity) {
    $self->set('exists', 1);
    $self->set('identity', $identity);
    return 1;
  }
  return undef;
};

# Method that gets the attributes from the NYU Shibboleth identity
# Usage:
#   $self->get_attributes()
sub get_attributes {
  my $self = shift;
  my @all_attributes = $self->SUPER::get_attributes();
  push(@all_attributes, @attributes);
  return @all_attributes;
}

1;
