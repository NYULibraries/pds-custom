package NYU::Libraries::PDS::Models::NyuShibbolethIdentity;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# NYU Libraries modules
use NYU::Libraries::Util qw(trim);

# Data Dumper for error reporting
use Data::Dumper;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(conf id index authentication_instance authentication_method context_class identity_provider aleph_identifier uid givenname mail cn sn edupersonentitlement));

# Private sub that sets the attributes from Shibboleth
my $set_attributes_from_shibboleth = sub {
  my($self) = shift;
};

# Returns an new NyuShibbolethIdentity
# Usage:
#   NYU::Libraries::PDS::Models::NyuShibbolethIdentity->new(configurations)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->_init(@args);
}

# Private initialization method
# Usage:
#   $self->_init(configurations)
sub _init {
  my($self, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set the attributes from Shibboleth.
  $self->$set_attributes_from_shibboleth();
  # Return self
  return $self;
}

1;
