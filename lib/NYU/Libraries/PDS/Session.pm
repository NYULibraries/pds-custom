# Model for creating, finding and storing data for a PDS session
package NYU::Libraries::PDS::Session;
use strict;
use warnings;
use Data::Dumper;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# Use PDS core libraries
use IOZ311_file;
use IOZ312_file;
use PDSSession;
use PDSSessionUserAttrs;
use PDSUtil qw(isUsingOracle);
use PDSParamUtil;

# Hash encryption module for password
use Digest::MD5 qw(md5_hex md5);

# NYU Libraries modules
use NYU::Libraries::Util qw(trim xml_encode);

use base qw(Class::Accessor);
# Assumes the same names as the identities
# Duplicate entries are there for legacy apps which expect old values:
# => patron_status = bor_status
# => `institute` is expected by PDS
# => `expiry_date` is expected by PDS
my @attributes = qw(id email institution_code institute barcode bor_status patron_status
  patron_type name first_name last_name uid nyuidn nyu_shibboleth ns_ldap verification
    entitlement objectclass ill_permission college_code college plif_status
      dept_code department major_code major ill_library session_id expiry_date remote_address);
__PACKAGE__->mk_ro_accessors(@attributes);
__PACKAGE__->mk_accessors(qw(calling_system target_url));

use constant LOADED_FROM_PLIF => "PLIF LOADED";
use constant FAMILY_MEMBER_BOR_STATUS => "65";
use constant ALEPH_IDENTITY_NAME => 'aleph';
use constant NYU_SHIBBOLETH_IDENTITY_NAME => 'nyu_shibboleth';
use constant NEW_SCHOOL_LDAP_IDENTITY_NAME => 'new_school_ldap';

# Private method returns whether this record was loaded from the PLIF
my $loaded_from_plif = sub {
  my $self = shift;
  return ($self->plif_status eq LOADED_FROM_PLIF);
};

# Private method returns a boolean indicating whether to encrypt the verification
# based on some business logic
# Usage:
#   $self->$is_encrypt_verification()
my $is_encrypt_verification = sub {
  my $self = shift;
  # If no NetID and the record wasn't loaded from plif, don't encrypt.
  return ($self->nyu_shibboleth && ($self->$loaded_from_plif))
  # ????????????
};

# Private method returns a boolean indicating whether this is an encryption exception
# Usage:
#   $self->$encryption_exception()
my $encryption_exception = sub {
  my $self = shift;
  return ($self->patron_status eq FAMILY_MEMBER_BOR_STATUS);
};

# Private method returns an encrypted verification based on a shared secret
# Usage:
#   $self->$encrypt_verification(unencrypted_verification)
my $encrypt_verification = sub {
  my($self, $unencrypted_verification) = @_;
  my $conf = $self->{'conf'};
  # Don't encrypt if no shared secret provided
  return $unencrypted_verification unless $conf->{shared_secret};
  # Don't encrypt if this is an exception.
  return $unencrypted_verification if $self->$encryption_exception();
  # Don't encrypt unless the patron meets the encryption business logic.
  return $unencrypted_verification unless $self->$is_encrypt_verification();
  my $encrypted_verification =
    md5_hex($conf->{shared_secret}, $unencrypted_verification);
  return $encrypted_verification;
};

# Pull Aleph identity
my $aleph_identity = sub {
  my ($self, $identities) = @_;
  for my $identity (@$identities) {
    if ($identity->{provider} eq ALEPH_IDENTITY_NAME) {
      return $identity;
    }
  }
};

# Pull NYU Shibboleth identity
my $nyu_shibboleth_identity = sub {
  my ($self, $identities) = @_;
  for my $identity (@$identities) {
    if ($identity->{provider} eq NYU_SHIBBOLETH_IDENTITY_NAME) {
      return $identity;
    }
  }
};

# Pull New School LDAP identity
my $new_school_ldap_identity = sub {
  my ($self, $identities) = @_;
  for my $identity (@$identities) {
    if ($identity->{provider} eq NEW_SCHOOL_LDAP_IDENTITY_NAME) {
      return $identity;
    }
  }
};

# Private initialization method
# Usage:
#   $self->$initialize(identities)
my $initialize = sub {
  my($self, $user, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);

  # Extra identities from OAuth2 API
  my $identities = $user->{'identities'};
  my $aleph_identity = $self->$aleph_identity($identities);
  my $new_school_ldap_identity = $self->$new_school_ldap_identity($identities);
  my $nyu_shibboleth_identity = $self->$nyu_shibboleth_identity($identities);

  # Create session based on OAuth2 response if we have an aleph identity
  if ($aleph_identity) {
    # Look for the top-level email first,
    # if it's not set here we'll set it from one of the identities
    $self->set('email', $user->{'email'});

    if ($nyu_shibboleth_identity) {
      # Yes this is an nyu_shibboleth session
      $self->set('nyu_shibboleth', 'true');
      # Set NYU Shibboleth properties to the session variables
      foreach my $key (keys(%{$nyu_shibboleth_identity->{properties}})) {
        $self->set($key, %{$nyu_shibboleth_identity->{properties}}->{$key});
      }
    }
    # Set New School LDAP properties to the session variables
    # Unless they're already set
    if ($new_school_ldap_identity) {
      # Yes this is an new school LDAP session
      $self->set('ns_ldap', 'true');
      foreach my $key (keys(%{$new_school_ldap_identity->{properties}})) {
        next if $self->{$key};
        $self->set($key, %{$new_school_ldap_identity->{properties}}->{$key});
      }
    }
    # Set Aleph properties to the session variables
    # Unless they're already set
    foreach my $key (keys(%{$aleph_identity->{properties}})) {
      next if $self->{$key};
      $self->set($key, %{$aleph_identity->{properties}}->{$key});
    }
    # Set ID from Aleph Identity
    $self->set('id', $aleph_identity->{uid});
    # Set institute from institution_code, required by Aleph
    $self->set('institute', $user->{'institution_code'}) if $user->{'institution_code'};

    # Encrypt verification and set as attribute
    my $encrypted_verification = $self->$encrypt_verification($self->verification);
    $self->set('verification', $encrypted_verification);
  }
  # Assume we're creating the Session object from an existing PDS session hash
  else {
    foreach my $attribute (keys %$user) {
      $self->set("$attribute", $user->{$attribute});
    }
  }
  # Return self
  return $self;
};

# Returns an new PDS Session based on the given identities
# Usage:
#   NYU::Libraries::PDS::Session->new(user, conf)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->$initialize(@args);
}

# Find a session based on the given session id
# Returns a ??????
# Usage:
#   NYU::Libraries::PDS::Session::find('some_id');
sub find {
  my $id = shift;
  # Check if the login is valid
  my ($xml_string, $error_code) = ('','');
  my %session = ();
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
  return ($error_code eq "00") ? NYU::Libraries::PDS::Session->new(\%session) : undef;
}

# Save the session to either the DB or file system
# Returns self
# Usage:
#   $session->save();
sub save {
  my $self = shift;
  my (%Z311, %Z312) = ((), ());
  # Store PDS info in Z311 hash.
  %Z311 = ();
  $Z311{'exl_id'} = $self->id;
  $Z311{'institute'} = $self->institute;
  $Z311{'id'} = $self->id;
  $Z311{'verification'} = $self->verification;
  my ($http, $temp, $host, $cgi_name) = map split(/\//), split(/\?/,$self->target_url);
  my $user_ip = PDSUtil::getIpAddress();
  my $calling_system = $self->calling_system;
  $Z311{'remote_address'} = "$host/$cgi_name;$user_ip;$calling_system";
  $Z311{'calling_system'} = $calling_system;
  my $term = PDSParamUtil::getAndFilterParam('term');
  $Z311{'term'} = PDSUtil::reset_term_cookie($term);
  # Persist Z311
  if(isUsingOracle()) {
    PDSSession::pds_session('WRITE', \%Z311);
  } else {
    IOZ311_file::io_z311_file('WRITE', \%Z311);
  }
  $self->set('session_id', $Z311{'session_id'});
  # Store additional information in Z312 hash.
  %Z312 = ();
  $Z312{'verification'} = $self->verification;
  foreach my $attribute (@attributes) {
    # Skip ID attribute
    next if $attribute eq "id";
    # Only put in the hash if we have a value
    next unless $self->{$attribute};
    $Z312{$attribute} = $self->{$attribute};
  }
  # Persist Z312
  if (isUsingOracle()) {
    PDSSessionUserAttrs::pds_session_ua('WRITE', \%Z312, $self->session_id);
  } else {
    IOZ312_file::io_z312_file('WRITE', \%Z312, $self->session_id);
  }
  return $self;
}

# Save the session in either the DB or file system
# Returns self
# Usage:
#   $session->destroy();
sub destroy {
  my $self = shift;
  my %Z311 = ();
  my $error_code;
  # Set PDS Handle for session file
  $Z311{'session_id'} = $self->session_id;
  # Delete the session
  if (isUsingOracle()) {
    PDSSession::pds_session('DELETE', \%Z311);
  } else {
    IOZ311_file::io_z311_file('DELETE', \%Z311);
  }
}

# Returns the session as XML
# Usage:
#   $session->to_xml()
# Output:
#   <session>
#     <id>ALEPH_ID</id>
#     <expiry-date>20131031</expiry-date>
#     <institute>NYU|NYUAD|NYUSH|NS|CU|NYSID</institute>
#     <barcode>BARCODE</barcode>
#     <bor-status>BOR_STATUS</bor-status>
#     <bor-type>BOR_TYPE</bor-type>
#     <name>Given Name</name>
#     <uid>NetID</uid>
#     <email>email@nyu.edu</email>
#     <cn>Common Name</cn>
#     <givenname>Given Name</givenname>
#     <sn>Surname</sn>
#     <verification>VERIFICATION</verification>
#     <nyuidn>ALEPH_ID</nyuidn>
#     <nyu_shibboleth>true|false</nyu_shibboleth>
#     <ns_ldap>true|false</ns_ldap>
#     <entitlements>
#       urn:mace:nyu.edu:entl:its:wikispriv;urn:mace:nyu.edu:entl:its:classes;urn:mace:nyu.edu:entl:its:qualtrics;urn:mace:nyu.edu:entl:lib:eresources;urn:mace:nyu.edu:entl:its:projmgmt;urn:mace:nyu.edu:entl:its:files;urn:mace:incommon:entitlement:common:1
#     </entitlements>
#     <edupersonentitlement>
#       <value>urn:mace:nyu.edu:entl:its:wikispriv</value>
#       <value>urn:mace:nyu.edu:entl:its:classes</value>
#       <value>urn:mace:nyu.edu:entl:its:qualtrics</value>
#       <value>urn:mace:nyu.edu:entl:lib:eresources</value>
#       <value>urn:mace:nyu.edu:entl:its:projmgmt</value>
#       <value>urn:mace:nyu.edu:entl:its:files</value>
#       <value>urn:mace:incommon:entitlement:common:1</value>
#     </edupersonentitlement>
#     <ill-permission>Y|N</ill-permission>
#     <college_code>COLLEGE_CODE</college_code>
#     <college_name>College Name</college_name>
#     <dept_code>DEPARTMENT_CODE</dept_code>
#     <dept_name>Department Name</dept_name>
#     <major_code>MAJOR_CODE</major_code>
#     <major>Major</major>
#   </session>
#
# In the future, this should specify identities
#   <session>
#     <!-- PDS Session Information -->
#     <id>ALEPH_ID</id>
#     <verification>VERIFICATION</verification>
#     <expiry-date>20131031</expiry-date>
#     <institute>NYU|NYUAD|NYUSH|NS|CU|NYSID</institute>
#     <barcode>BARCODE</barcode>
#     <bor-status>BOR_STATUS</bor-status>
#     <bor-type>BOR_TYPE</bor-type>
#     <name>Given Name</name>
#     <email>email@nyu.edu</email>
#     <identities>
#       <!-- Aleph Identity Information -->
#       <aleph>
#         <id>ALEPH_ID</id>
#         <email>aleph_email@nyu.edu</email>
#         <bor_name>BORROWER NAME</bor_name>
#         <verification>VERIFICATION</verification>
#         <barcode>BARCODE</barcode>
#         <expiry_date>20131031</expiry_date>
#         <bor_status>BOR_STATUS</bor_status>
#         <bor_type>BOR_TYPE</bor_type>
#         <ill_permission>Y|N</ill_permission>
#         <college_code>COLLEGE_CODE</college_code>
#         <college_name>College Name</college_name>
#         <dept_code>DEPARTMENT_CODE</dept_code>
#         <dept_name>Department Name</dept_name>
#         <major_code>MAJOR_CODE</major_code>
#         <major>Major</major>
#         <plif_status>PLIF LOADED|''</plif_status>
#       </aleph>
#       <!-- NYU Shibboleth Identity Information (Optional) -->
#       <nyu_shibboleth>
#         <id>NetID</id>
#         <cn>Common Name</cn>
#         <givenname>Given Name</givenname>
#         <sn>Surname</sn>
#         <email>nyu_shibboleth_email@nyu.edu</email>
#         <aleph_identifier>ALEPH_ID</aleph_identifier>
#         <entitlements>urn:mace:nyu.edu:entl:its:wikispriv;urn:mace:nyu.edu:entl:its:classes;urn:mace:nyu.edu:entl:its:qualtrics;urn:mace:nyu.edu:entl:lib:eresources;urn:mace:nyu.edu:entl:its:projmgmt;urn:mace:nyu.edu:entl:its:files;urn:mace:incommon:entitlement:common:1</entitlements>
#       </nyu_shibboleth>
#       <!-- NS LDAP Identity Information (Optional) -->
#       <ns_ldap>
#         <id>NetID</id>
#         <cn>Common Name</cn>
#         <givenname>Given Name</givenname>
#         <sn>Surname</sn>
#         <email>ns_ldap_email@newschool.edu</email>
#         <aleph_identifier>ALEPH_ID</aleph_identifier>
#         <role>Role</role>
#       </ns_ldap>
#     </identities>
#   </session>
sub to_xml {
  my($self, $root) = @_;
  $root = ($root || "session");
  my $xml  = '<?xml version="1.0" encoding="UTF-8"?>';
  $xml .= "<$root>";
  foreach my $attribute (@attributes) {
    $xml .= "<$attribute>".xml_encode(trim($self->{$attribute}))."</$attribute>" if $self->{$attribute};
  }
  if($self->{'entitlement'}) {
    my $entitlement = $self->{'entitlement'};
    $entitlement =~ s/;/<\/value><value>/g;
    my $edupersonentitlements = "<value>$entitlement</value>";
    $xml .= "<edupersonentitlement>$edupersonentitlements</edupersonentitlement>";
  }
  $xml .= "</$root>";
  return $xml;
}

1;
