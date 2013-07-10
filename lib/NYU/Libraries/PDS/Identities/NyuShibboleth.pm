package NYU::Libraries::PDS::Identities::NyuShibboleth;
use strict;
use warnings;

use base qw(NYU::Libraries::PDS::Identities::Base);
my @attributes = qw(givenname cn sn aleph_identifier edupersonentitlement index
  authentication_instance authentication_method context_class identity_provider);
__PACKAGE__->mk_ro_accessors(@attributes);

my $shibboleth_attribute_mappings = {
  'id' => 'uid',
  'email' => 'mail',
  'givenname' => 'givenName',
  'cn' => 'displayName',
  'sn' => 'sn',
  'aleph_identifier' => 'NYUIdn',
  'edupersonentitlement' => 'eduPersonEntitlement',
  'index' => '',
  'authentication_instance' => '',
  'authentication_method' => '',
  'context_class' => '',
  'identity_provider' => ''
};

# Private sub that gets the identity from the ShibbolethSP
my $shibboleth_identity = sub {
  my $identity;
  foreach my $attribute (keys %$shibboleth_attribute_mappings) {
    my $shibboleth_env_var = $shibboleth_attribute_mappings->{$attribute};
    $identity->{$attribute} = $ENV{$shibboleth_env_var} if defined($ENV{$shibboleth_env_var});
  }
  # Return identity if we found one
  return $identity if $identity->{"id"};
};

# Authentication method
# Usage:
#   $self->authenticate()
sub authenticate {
  my($self) = @_;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return undef unless $self->{'conf'};
  # Get the identity
  my $identity = $self->$shibboleth_identity();
  # Set the identity if we've found one
  if ($identity) {
    $self->set('exists', 1);
    $self->set('identity', $identity);
  }
};

# Method that gets the attributes from the NYU Shibboleth identity
# Usage:
#   $self->get_attributes()
sub get_attributes {
  return @attributes;
}

1;
