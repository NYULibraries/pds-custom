# Base class for identities
package NYU::Libraries::PDS::Identities::Base;

use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# NYU Libraries modules
use NYU::Libraries::Util qw(trim);

# Data Dumper for error reporting
use Data::Dumper;

use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(error exists id email givenname cn sn));
my @attributes;


# Private method to snake case the class name
# Usage:
#   $self->$snake_case_class_name()
my $snake_case_class_name = sub {
  my $self = shift;
  my $ref = ref $self;
  my @ref = split(':', $ref);
  my $last = pop(@ref);
  $last =~ s/([a-z])([A-Z])/$1\_$2/;
  return lc($last);
};

# Private initialization method
# Usage:
#   $self->$initialize(configurations)
my $initialize = sub {
  my($self, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
};

# Returns an new Identity
# Usage:
#   NYU::Libraries::PDS::Identities::Base->new(configurations, id, password)
sub new {
  my($proto, $conf, @authentication_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Class::Accessor->new(), $class);
  # Initialize
  $self->$initialize($conf);
  # Authenticate
  $self->authenticate(@authentication_args);
  # Return self
  return $self;
}

# Authentication method
# Should be overridden by sub classes
sub authenticate { 
}

# Method to set attributes
# Must be overridden by sub classes
sub get_attributes {
  return @attributes;
}

# Method to set attributes
# Can be overridden by sub classes
sub set_attributes {
  my $self = shift;
  # Set error and return if there is no identity
  $self->set('error', 'No identity set.') and return undef unless $self->{'identity'};
  my $identity = $self->{'identity'};
  # Add the attributes from the patron call
  foreach my $key (keys %$identity) {
    $self->set($key, trim($identity->{$key})) if $identity->{$key}; 
  }
}

# Returns a hash respresentatino of this identity
# Usage:
#   $identity->to_h()
sub to_h {
  my $self = shift;
  # Return nothing set if we have an error
  return undef if $self->error;
  # Set error and return if there is no identity
  $self->set('error', 'No identity set.') and return undef unless $self->{'identity'};
  # Set the attributes if it hasn't been done yet
  $self->set_attributes() unless $self->id();
  # Loop through the attributes and return them in a hash
  my $h;
  foreach my $attribute ($self->get_attributes()) {
    $h->{$attribute} = $self->{$attribute} if $self->{$attribute};
  }
  return $h;
}

# Returns an XML respresentatino of this identity
# Usage:
#   $identity->to_xml()
sub to_xml {
  my $self = shift;
  # Return nothing set if we have an error
  return undef if $self->error;
  # Set error and return if there is no identity
  $self->set('error', 'No identity set.') and return undef unless $self->{'identity'};
  # Set the attributes if it hasn't been done yet
  $self->set_attributes() unless $self->id();
  my $root = $self->$snake_case_class_name();
  # Loop through the attributes and return them in a hash
  my $xml = "<$root>";
  foreach my $attribute ($self->get_attributes()) {
    my $attribute_value = $self->{$attribute} if $self->{$attribute};
    $xml .= "<$attribute>$attribute_value</$attribute>" if $attribute_value;
  }
  $xml .= "</$root>";
  return $xml;
}
