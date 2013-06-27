package NYU::Libraries::PDS::Identities::Aleph;

use strict;
use warnings;

# Hash encryption module for password
use Digest::MD5 qw(md5_hex md5);

# NYU Libraries modules
use NYU::Libraries::XService::Aleph::BorAuth;
use NYU::Libraries::XService::Aleph::BorInfo;

use constant LOADED_FROM_PLIF => "PLIF LOADED";
use constant FAMILY_MEMBER_BOR_STATUS => "65";

use base qw(NYU::Libraries::PDS::Identities::Base);
my @attributes = qw(barcode verification expiry_date birthplace bor_status
  bor_type bor_name mail ill_permission birthplace college_code college_name dept_code 
    dept_name major_code major);
__PACKAGE__->mk_ro_accessors(@attributes);
__PACKAGE__->mk_accessors(qw(encrypt));


# Private method returns an identity from the flat file for the given id
# Usage:
#   $self->$lookup_from_xserver(id)
my $lookup_from_flat_file = sub {
  my($self, $id) = @_;
  my $conf = $self->{'conf'};
  # Open the flat file.
  my $flat_file = open(FF, "<", $conf->{flat_file});
  # Stop if we don't have a flat file to look at
  return unless $flat_file;
  #Check each line of flat file for user and load into identity hash reference.
  my $identity;
  $identity->{"birthplace"} = "";
  while (my $line = <FF>) {
    # Next if empty line
    next if ($line =~/^\s*$/);
    # Case insensitive identity id matched in flat file
    if ($line =~ m/^$id\t/i) {
      # Remove new line character
      $line =~ s/\n$//;
      # Set identity hash reference from flat file.
      ($identity->{"id"}, $identity->{"barcode"}, $identity->{"verification"}, 
        $identity->{"expiry_date"}, $identity->{"bor_status"}, $identity->{"bor_type"}, 
          $identity->{"bor_name"}, $identity->{"mail"}, $identity->{"ill_permission"}, 
            $identity->{"birthplace"}, $identity->{"college_code"}, $identity->{"college_name"}, 
              $identity->{"dept_code"}, $identity->{"dept_name"}, $identity->{"major_code"}, 
                $identity->{"major"}) = split(/\t/, $line);
      last;
    }
  }
  close (FF);
  # Return identity if we found one
  return $identity if $identity->{"id"};
};

# Private method returns an identity from the bor-info xservice for the given id
# Usage:
#   $self->$lookup_from_xserver(id)
my $lookup_from_xserver = sub {
  my($self, $id) = @_;
  my $conf = $self->{'conf'};
  # Call bor-info xservice
  my $bor_info = NYU::Libraries::XService::Aleph::BorInfo->new(
    "Host" => $conf->{xserver_host}, "Port" => $conf->{xserver_port},
      "BorID" => $id, "Library" => $conf->{ adm },
        "Loans" => "N", "Cash" => "N", "Holds" => "N", "Translate" => "N",
          "UserName" => $conf->{ xserver_user }, 
            "UserPassword" => $conf->{ xserver_password });
  # Return empty if the xservice call was unsuccessful or if it returned errors
  return if (!($bor_info->success) || $bor_info->get_error);
  # Set identity hash reference from xservice.
  my $identity;
  $identity->{"id"} = $bor_info->get_z303_id();
  $identity->{"barcode"} =  "";
  $identity->{"expiry_date"} = $bor_info->get_z305_expiry_date();
  $identity->{"bor_status"} = $bor_info->get_z305_borstatus();
  $identity->{"bor_type"} = $bor_info->get_z305_bortype();
  $identity->{"bor_name"} = $bor_info->get_z303_name();
  $identity->{"mail"} = $bor_info->get_z304_email_address();
  $identity->{"ill_permission"} = $bor_info->get_z305_photo_permission();
  $identity->{"birthplace"} = $bor_info->get_z303_birthplace();
  # Return identity if we found one
  return $identity if $identity->{"id"};
};

# Private method returns an aleph identity
# Usage:
#   $self->$lookup_aleph_identity(id)
my $lookup_aleph_identity = sub {
  my($self, $id) = @_;
  # First look up from the flat file and failing that look up from the xserver
  return ($self->$lookup_from_flat_file($id) || $self->$lookup_from_xserver($id));
};

my $aleph_authenticate = sub {
  my($self, $id, $password) = @_;
  my $conf = $self->{'conf'};
  my $bor_auth = NYU::Libraries::XService::Aleph::BorInfo->new(
    "Host" => $conf->{xserver_host}, "Port" => $conf->{xserver_port},
      "BorID" => $id, "Verification" => $password, "Library" => $conf->{ adm },
        "Translate" => "N", "UserName" => $conf->{ xserver_user }, 
            "UserPassword" => $conf->{ xserver_password });
  # Return empty if the xservice call was unsuccessful or if it returned errors
  return if (!($bor_auth->success) || $bor_auth->get_error);
  # Set identity hash reference from xservice.
  my $identity;
  $identity->{"id"} = $bor_auth->get_z303_id();
  $identity->{"barcode"} =  "";
  $identity->{"expiry_date"} = $bor_auth->get_z305_expiry_date();
  $identity->{"bor_status"} = $bor_auth->get_z305_borstatus();
  $identity->{"bor_type"} = $bor_auth->get_z305_bortype();
  $identity->{"bor_name"} = $bor_auth->get_z303_name();
  $identity->{"mail"} = $bor_auth->get_z304_email_address();
  $identity->{"ill_permission"} = $bor_auth->get_z305_photo_permission();
  $identity->{"birthplace"} = $bor_auth->get_z303_birthplace();
  # Return identity if we found one
  return $identity if $identity->{"id"};
};

# Private method returns a surnamed scrubbed of special chars
my $clean_surname = sub {
  my($self, $sn) = @_;
  $sn =~ s/\s//g;
  $sn =~ s/-//g;
  $sn =~ s/\.//g;
  $sn =~ s/,//g;
  return $sn;
};

# Private method returns whether this record was loaded from the PLIF
my $loaded_from_plif = sub {
  my $self = shift;
  return ($self->birthplace eq LOADED_FROM_PLIF);
};

# Private method returns a boolean indicating whether to encrypt the verification
# based on some business logic
# Usage:
#   $self->$is_encrypt_verification()
my $is_encrypt_verification = sub {
  my $self = shift;
  # If no NetID and the record wasn't loaded from plif, don't encrypt.
  return ($self->encrypt && ($self->$loaded_from_plif))
};

# Private method returns an encrypted verification based on a shared secret
# Usage:
#   $self->$encrypt_verification(unencrypted_verification)
my $encrypt_verification = sub {
  my($self, $unencrypted_verification) = @_;
  my $conf = $self->{'conf'};
  # Return unencrypted unless shared secret provided
  return $unencrypted_verification unless $conf->{shared_secret};
  my $encrypted_verification = 
    md5_hex($conf->{shared_secret}, $unencrypted_verification);
  return $encrypted_verification;
};

# Private method returns a boolean indicating whether this is an encryption exception
# Usage:
#   $self->$encryption_exception()
my $encryption_exception = sub {
  my $self = shift;
  return ($self->bor_status eq FAMILY_MEMBER_BOR_STATUS);
};

# Authentication method
# Usage:
#   $self->authenticate(id, password)
sub authenticate {
  my($self, $id, $password) = @_;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return unless $self->{'conf'};
  my $identity;
  if($password) {
    # If we have a password, we are actually authenticating
    $identity = $self->$aleph_authenticate($id, $password);
  } else {
    # If we don't have a password, we are actually doing a lookup after
    # an authentication via another identity.
    $identity = $self->$lookup_aleph_identity($id);
  }
  $self->set('identity', $identity) if $identity;
};

# Method that sets the attributes from the Aleph identity
# Usage:
#   $self->set_attributes()
sub set_attributes {
  my $self = shift;
  $self->SUPER::set_attributes();
  # Since verification isn't necessary for this call, add it based on info from Aleph
  my @name_array = split(/,/, $self->{"identity"}->{"bor_name"});
  my $surname = $name_array[0];
  # Set verification as first four characters of the cleaned last name 
  my $verification = uc(substr($self->$clean_surname($surname), 0, 4));
  # Don't encrypt if this is an exception.
  unless ($self->$encryption_exception()) {
    # Don't encrypt unless the patron meets the encryption business logic.
    $verification = $self->$encrypt_verification($verification) if $self->$is_encrypt_verification();
  };
  $self->set('verification', $verification);
}

1;
