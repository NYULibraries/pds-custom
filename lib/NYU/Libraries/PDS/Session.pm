package NYU::Libraries::PDS::Session;
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
__PACKAGE__->mk_ro_accessors(qw(id institute barcode bor_status bor_type name uid email cn 
  givenname sn verification nyuidn nyu_shibboleth ns_ldap edupersonentitlement objectclass 
    ill_permission college_code college_name dept_code dept_name major_code major));

# Returns an new PDS Session based on the given identities
# Usage:
#   NYU::Libraries::PDS::Session->new(identities)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->_init(@args);
}

# Private initialization method
# Usage:
#   $self->_init(identities)
sub _init {
  my($self, @identities) = @_;
  print STDERR @identities[0]."ABLE MISER\n\n\n";
  foreach my $identity (@identities) {
    print STDERR ref($identity)."MISERY\n\n\n";
    # Order matters
    if($identity->isa("NYU::Libraries::PDS::Identities::NyuShibboleth")) {
      $self->set('nyu_shibboleth', 'true')
    } elsif($identity->isa("NYU::Libraries::PDS::Identities::NsLdap")) {
      $self->set('ns_ldap', 'true')
    } elsif($identity->isa("NYU::Libraries::PDS::Identities::Aleph")) {
    } else {
      # Assume we're creating the Session object from an existing PDS session hash
    }
  }
  # Return self
  return $self;
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
  return NYU::Libraries::PDS::Session->new(\%session);
}

# Returns this session as XML
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
#     <edupersonentitlement>
#       <value>urn:mace:nyu.edu:entl:its:wikispriv</value>
#       <value>urn:mace:nyu.edu:entl:its:classes</value>
#       <value>urn:mace:nyu.edu:entl:its:qualtrics</value>
#       <value>urn:mace:nyu.edu:entl:lib:eresources</value>
#       <value>urn:mace:nyu.edu:entl:its:wikispub</value>
#       <value>urn:mace:nyu.edu:entl:its:webspace</value>
#       <value>urn:mace:nyu.edu:entl:lib:ideaexchange</value>
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
#         <edupersonentitlement>
#           <value>urn:mace:nyu.edu:entl:its:wikispriv</value>
#           <value>urn:mace:nyu.edu:entl:its:classes</value>
#           <value>urn:mace:nyu.edu:entl:its:qualtrics</value>
#           <value>urn:mace:nyu.edu:entl:lib:eresources</value>
#           <value>urn:mace:nyu.edu:entl:its:wikispub</value>
#           <value>urn:mace:nyu.edu:entl:its:webspace</value>
#           <value>urn:mace:nyu.edu:entl:lib:ideaexchange</value>
#           <value>urn:mace:nyu.edu:entl:its:projmgmt</value>
#           <value>urn:mace:nyu.edu:entl:its:files</value>
#           <value>urn:mace:incommon:entitlement:common:1</value>
#         </edupersonentitlement>
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
}

1;
