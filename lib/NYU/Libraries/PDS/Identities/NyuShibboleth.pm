package NYU::Libraries::PDS::Identities::NyuShibboleth;
use strict;
use warnings;

# Data Dumper for error reporting
use Data::Dumper;

use base qw(NYU::Libraries::PDS::Identities::Base);
my @attributes = qw(index authentication_instance authentication_method
  context_class identity_provider aleph_identifier uid givenname mail cn sn
    edupersonentitlement);
__PACKAGE__->mk_ro_accessors(@attributes);

my $shibboleth_attribute_mappings = {
  'id' => 'Shib_Application_ID',
  'index' => '',
  'authentication_instance' => '',
  'authentication_method' => '',
  'context_class' => '',
  'identity_provider' => '',
  'aleph_identifier' => '',
  'uid' => '',
  'givenname' => '',
  'mail' => '',
  'cn' => '',
  'sn' => '',
  'edupersonentitlement' => ''
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
  $self->set('error', "No configuration set.") and return unless $self->{'conf'};
  # Get the identity
  my $identity = $self->$shibboleth_identity();
  # Set the identity instance variable if we have one
  $self->set('identity', $identity) if $identity;
};

1;