package NYU::Libraries::PDS::Models::Session;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# Use PDS core libraries
use IOZ311_file;
use IOZ312_file;
use PDSSession;
use PDSSessionUserAttrs;
use PDSUtil qw(isUsingOracle);

use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(id institute barcode bor-status bor-type name uid email cn 
  givenname sn verification nyuidn opensso newschool_ldap edupersonentitlement objectclass 
    ill-permission college_code college_name dept_code dept_name major_code major));

# Returns an new PDS Session based on the given identities
# Usage:
#   NYU::Libraries::PDS::Models::Session->new(identities, configurations)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->_init(@args);
}

# Private initialization method
# Usage:
#   $self->_init(identities, configurations)
sub _init {
  my($self, $identities, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
  foreach my $identity (@$identities) {
    # Order matters
    if($identity.isa("NYU::Libraries::PDS::Models::NyuShibbolethIdentity")) {
      
    } elsif($identity.isa("NYU::Libraries::PDS::Models::NsLdapIdentity")) {
    } elsif($identity.isa("NYU::Libraries::PDS::Models::AlephIdentity")) {
    } else {
      # Assume we're creating the session from an existing Session hash
    }
  }
  # Return self
  return $self;
}

# Find a session based on the given session id
# Returns a ??????
# Usage:
#   NYU::Libraries::PDS::Models::Session->find('some_id');
sub find {
  my ($self, $id) = @_;
  # Check if the login is valid
  my ($xml_string, $error_code) = ('','');
  my %session = {};
  $session{'session_id'} = $id;
  if (isUsingOracle()) {
    $error_code = PDSSession::pds_session('READ', \%session);
    $error_code = PDSSession::pds_session('DISPLAY', \%session) if $error_code eq "00";
    PDSSessionUserAttrs::pds_session_ua("READ", \%session, $id) if $error_code eq "00";
  } else {
    $error_code = IOZ311_file::io_z311_file('READ', \%session);
    $error_code = IOZ311_file::io_z311_file('DISPLAY', \%session) if $error_code eq "00";
    IOZ312_file::io_z312_file("READ", \%session, $id) if $error_code eq "00";
  }
  return $self->new(\%session);
}

1;
