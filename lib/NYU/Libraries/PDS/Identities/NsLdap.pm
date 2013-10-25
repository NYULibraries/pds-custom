# The New School LDAP Identity stores data from the New
# School LDAP for current user given an ID and password
package NYU::Libraries::PDS::Identities::NsLdap;

use strict;
use warnings;

# LDAP modules
use Net::LDAPS;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text ldap_error_name ldap_error_desc);
use Net::LDAP::Constant;

# NYU Libraries modules
use NYU::Libraries::Util qw(trim);

use base qw(NYU::Libraries::PDS::Identities::Base);
my @attributes = qw(uid role aleph_identifier);
__PACKAGE__->mk_ro_accessors(@attributes);

# Private method returns a new LDAP object based on the objects configuration
# Usage:
#   $self->$ldap_object()
my $ldap_object = sub {
  my $self = shift;
  my $conf = $self->{'conf'};
  return Net::LDAPS->new($conf->{ldap_host}, port => $conf->{ldap_port},
    timeout => $conf->{ldap_timeout}, version => $conf->{ldap_version}, 
      capath => $conf->{ssl_cert_path});
};

# Private method returns a user given an ID
# Usage:
#   $self->$ldap_user_search(id)
my $ldap_user_search = sub {
  my($self, $id) = @_;
  my $conf = $self->{'conf'};
  # Set up the LDAP object for admin binding
  my $admin_ldap_object = $self->$ldap_object();
  $self->set('error', "Could not create new admin LDAP object.") and return undef unless defined($admin_ldap_object);
  # Bind as admin user
  my $admin_bind_message = $admin_ldap_object->bind($conf->{ldap_admin_dn}, password => $conf->{ldap_admin_password});
  # Set error and return if the user bind failed
  $self->set('error', "Admin bind failed. ".$admin_bind_message->error) and return undef if $admin_bind_message->is_error();
  # Search for user based on the given id
  my $user_search = 
    $admin_ldap_object->search(base => "ou=people,o=newschool.edu,o=cp",
      filter => "(|(pdsLoginId=$id))", attr => ['*', 'pdsExternalSystemID']);
  # Close the admin connection
  $admin_ldap_object->disconnect();
  # Set error and return if more than one record exists for the user
  $self->set('error', "Non unique records for given id exist.") and return undef if $user_search->count > 1;
  # Set error and return if less than one record exists for the user
  $self->set('error', "No record returned for given id.") and return undef if $user_search->count < 1;
  # Return the user from the search
  return $user_search->entry(0);
};

# Private method authenticates a user
# (via an LDAP bind) given a uid and password
# Returns true if successfully authenticated
# Usage:
#   $self->$ldap_user_authenticate(uid, password)
my $ldap_user_authenticate = sub {
  my($self, $uid, $password) = @_;
  # Get the LDAP object for user binding
  my $user_ldap_object = $self->$ldap_object();
  $self->set('error', "Could not create new user LDAP object.") and return undef unless defined($user_ldap_object);
  # Set the user dn for binding
  my $user_dn = "uid=$uid,ou=people,o=newschool.edu,o=cp";
  # Bind to user dn with password to authenticate
  my $user_bind_message = $user_ldap_object->bind($user_dn, password=>$password);
  # Set error and return if the user bind failed
  $self->set('error', "User bind failed. ".$user_bind_message->error) and return undef if $user_bind_message->is_error();
  # Close the user connection.
  $user_ldap_object->disconnect();
  # Return true
  return 1;
};

# Authentication method
# Usage:
#   $self->authenticate(id, password)
sub authenticate {
  my($self, $id, $password) = @_;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return undef unless $self->{'conf'};
  # Get the identity
  my $identity = $self->$ldap_user_search($id);
  # Get uid from the identity
  my $uid = $identity->get_value("uid") if defined($identity);
  if ($uid) {
    # Set the identity instance variable if we've authenticated
    if ($self->$ldap_user_authenticate($uid, $password)) {
      $self->set('exists', 1);
      $self->set('identity', $identity);
    }
  }
};

# Method that gets the attributes from the NS LDAP identity
# Usage:
#   $self->get_attributes()
sub get_attributes {
  my $self = shift;
  my @all_attributes = $self->SUPER::get_attributes();
  push(@all_attributes, @attributes);
  return @all_attributes;
}

# Method sets the attributes from the NS LDAP identity
# Usage:
#   $self->set_attributes()
sub set_attributes {
  my $self = shift;
  # Set error and return if there is no user
  $self->set('error', 'No user set.') and return undef unless $self->{'identity'};
  my $identity = $self->{'identity'};
  # Set the attributes
  # Set the id
  $self->set('id', trim($identity->get_value("pdsLoginId")));
  # Set the common name
  $self->set('cn', trim($identity->get_value("cn")));
  # Set the given name
  $self->set('givenname', trim($identity->get_value("givenname")));
  # Set the surname
  $self->set('sn', trim($identity->get_value("sn")));
  # Set the role
  $self->set('role', trim($identity->get_value("pdsRole")));
  # Set the Aleph identifier
  my $aleph_identifier;
  foreach ($identity->get_value("pdsExternalSystemID")) {
    if ($_ =~ m/(N[0-9]+)::sct/) {
      $_ =~ s/(N[0-9]+)::sct/$1/;
      $aleph_identifier = $_;
    }
  }
  $self->set('aleph_identifier', $aleph_identifier);
};

1;
