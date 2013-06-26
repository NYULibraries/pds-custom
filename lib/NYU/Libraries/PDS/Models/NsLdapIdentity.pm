package NYU::Libraries::PDS::Models::NsLdapIdentity;

use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# LDAP modules
use Net::LDAPS;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text ldap_error_name ldap_error_desc);
use Net::LDAP::Constant;

# NYU Libraries modules
use NYU::Libraries::Util qw(trim);

# Data Dumper for error reporting
use Data::Dumper;

use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(id cn givenname sn mail role aleph_identifer error conf));

# Private sub returns a new LDAP object based on the objects configuration
my $ldap_object = sub {
  my($self) = shift;
  my($conf) = $self->conf;
  return Net::LDAPS->new($conf->{'ldap_host'}, port => $conf->{'ldap_port'},
    timeout => $conf->{'ldap_timeout'}, version => $conf->{'ldap_version'}, 
      capath => $conf->{'ssl_cert_path'});
};

# Private sub makes a call to LDAP and sets the attributes
my $set_attributes_from_ldap = sub {
  my($self, $id, $password) = @_;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return unless $self->conf;
  my($conf) = $self->conf;
  # Set up the admin LDAP object
  my($admin_ldap_object) = $self->ldap_object();
  $self->set('error', "Could not create new admin LDAP object.") and return unless defined($admin_ldap_object);
  # Bind as admin user
  my $admin_bind_message = $admin_ldap_object->bind($conf->{'ldap_admin_dn'}, password => $conf->{'ldap_admin_password'});
  # Set error and return if the user bind failed
  $self->set('error', "Admin bind failed. ".Dumper($admin_bind_message)) and return if $admin_bind_message->is_error();
  # Search for user based on the given id
  my $user_search = 
    $admin_ldap_object->search(base => $conf->{'ldap_base_dn'}, 
      filter => "(|(".$conf->{'ldap_user_id_attribute'}."=$id))",
        attr => ['*', 'pdsExternalSystemID']);
  # Close the admin connection
  $admin_ldap_object->disconnect();
  # Set error and return if more than one record exists for the user
  $self->set('error', "Non unique records for given id exist.") and return if $user_search->count > 1;
  # Set error and return if less than one record exists for the user
  # Also fail if less than one record exists for the user.
  $self->set('error', "No record returned for given id.") and return if $user_search->count < 1;
  # Get the user object from the search
  my $user = $user_search->entry(0);
  # Get uid from the user
  my $uid = $user->get_value("uid");
  # Set the user dn for binding again
  my $user_dn = "uid=$uid,".$conf->{'ldap_base_dn'};
  # Bind to user dn with password to authenticate
  my $user_ldap_object = $self->ldap_object();
  $self->set('error', "Could not create new user LDAP object.") and return unless defined($user_ldap_object);
  my $user_bind_message = $user_ldap_object->bind($user_dn, password=>$password);
  # Set error and return if the user bind failed
  $self->set('error', "User bind failed. ".Dumper($user_bind_message)) and return if $user_bind_message->is_error();
  # Close the user connection.
  $user_ldap_object->disconnect();
  # Set the attributes
  # Set the id
  $self->set('id', $id);
  # Set the common name
  $self->set('cn', trim($user->get_value("cn")));
  # Set the given name
  $self->set('givenname', trim($user->get_value("givenname")));
  # Set the surname
  $self->set('sn', trim($user->get_value("sn")));
  # Set the role
  $self->set('role', trim($user->get_value("pdsRole")));
  # Set the Aleph identifier
  my $aleph_identifier;
  foreach ($user->get_value("pdsExternalSystemID")) {
    if ($_ =~ m/(N[0-9]+)::sct/) {
      $_ =~ s/(N[0-9]+)::sct/$1/;
      $aleph_identifier = $_;
    }
  }
  $self->set('aleph_identifier', $aleph_identifier);
};

# Returns an new NsLdapIdentity
# Usage:
#   NYU::Libraries::PDS::Models::NsLdapIdentity->new(id, password, configurations)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->_init(@args);
}

# Private initialization method
# Usage:
#   $self->_init(id, password, configurations)
sub _init {
  my($self, $id, $password, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set the attributes from LDAP.
  $self->$set_attributes_from_ldap($id, $password);
  # Return self
  return $self;
}

1;
