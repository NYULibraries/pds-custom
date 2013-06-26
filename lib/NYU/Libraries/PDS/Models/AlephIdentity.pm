package NYU::Libraries::PDS::Models::AlephIdentity;

use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

use XML::Simple;
# use Net::SFTP;
# use Net::SSH::Perl;
use Digest::MD5 qw(md5_hex md5);
use NYU::Libraries::XService::Aleph::BorByKey;
use NYU::Libraries::XService::Aleph::BorInfo;

use constant LOADED_FROM_PLIF => "PLIF LOADED";
use constant FAMILY_MEMBER_BOR_STATUS => "65";

use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(conf error id is_encrypt barcode verification expiry_date birthplace bor_status 
  bor_type bor_name mail ill_permission birthplace college_code college_name dept_code dept_name major_code major));

my $patron_from_flat_file = sub {
  my($self, $id, $conf) = @_;
  # Open the flat file.
  my $flat_file = open(FF, "<", $conf->{flat_file});
  # Stop if we don't have a flat file to look at
  return unless $flat_file;
  #Check each line of flat file for user and load into patron hash reference.
  my $patron;
  $patron->{"birthplace"} = "";
  while (my $p = <FF>) {
    # Next if empty line
    next if ($p =~/^\s*$/);
    if ($p =~ m/^$id\t/i) { # Case insensitive patron id matched in flat file - BUG FIX 2011/06/29
      # Remove new line character
      $p =~ s/\n$//;
      # Set patron hash reference from flat file.
      ($patron->{"id"}, $patron->{"barcode"}, $patron->{"verification"}, $patron->{"expiry_date"}, 
        $patron->{"bor_status"}, $patron->{"bor_type"}, $patron->{"bor_name"}, $patron->{"mail"}, 
          $patron->{"ill_permission"}, $patron->{"birthplace"}, $patron->{"college_code"}, $patron->{"college_name"}, 
            $patron->{"dept_code"}, $patron->{"dept_name"}, $patron->{"major_code"}, $patron->{"major"}) = split(/\t/, $p);
      last;
    }
  }
  close (FF);
  # Return patron if we found one
  return $patron if $patron->{"id"};
};

my $patron_from_xserver = sub {
  my($self, $id ,$conf) = @_;
  # Call bor-info xservice
  my $bor_info = NYU::Libraries::XService::Aleph::BorInfo->new(
    "Host" => $conf->{ xserver_host }, "Port" => $conf->{ xserver_port },
      "BorID" => $id, "Library" => $conf->{ adm },
      "Loans" => "N", "Cash" => "N", "Holds" => "N", "Translate" => "N",
        "UserName" => $conf->{xserver_user}, 
          "UserPassword" => $conf->{xserver_password});
  # Stop unless the xservice call was successful
  return unless ($bor_info->success);
  # Stop if any errors in the xservice call
  return if ($bor_info->get_error);
  # Set patron hash reference from xservice.
  my $patron;
  $patron->{"id"} = $bor_info->get_z303_id();
  $patron->{"barcode"} =  "";
  $patron->{"expiry_date"} = $bor_info->get_z305_expiry_date();
  $patron->{"bor_status"} = $bor_info->get_z305_borstatus();
  $patron->{"bor_type"} = $bor_info->get_z305_bortype();
  $patron->{"bor_name"} = $bor_info->get_z303_name();
  $patron->{"mail"} = $bor_info->get_z304_email_address();
  $patron->{"ill_permission"} = $bor_info->get_z305_photo_permission();
  $patron->{"birthplace"} = $bor_info->get_z303_birthplace();
  # Return patron if we found one
  return $patron if $patron->{"id"};
};

# Private sub makes a call to Aleph and sets the attributes
my $set_attributes_from_aleph = sub {
  my($self, $id) = @_;
  # Set error and return if we don't have a configuration
  $self->set('error', "No configuration set.") and return unless $self->conf;
  my($conf) = $self->conf;
  my $patron = ($patron_from_flat_file || $patron_from_xserver);
  $self->set('error', "Couldn't find identity in Aleph.") and return unless $patron;
  # Add the attributes from the patron call
  foreach my $key (keys %$patron) { set($key, $patron->{$key}); }
  # Add birthplace and bor_status to self for verification check
  $self->birthplace($patron->{"birthplace"});
  $self->bor_status($patron->{"bor_status"});
  # Since verification isn't necessary for this call, add it based on info from Aleph
  my @name_array = split(/,/, $patron->{"bor_name"});
  my $sn = $name_array[0];
  # Set verification as first four characters of the cleaned last name 
  my $verification = uc(substr($self->clean_surname($sn), 0, 4));
  # Don't encrypt if this is an exception.
  unless ($self->plif_exception()) {
    # Don't encrypt unless we it meets the encryption business logic.
    $verification = $self->encrypt_verification($verification) if $self->is_encrypt_verification();
  };
  $self->verification($verification);
};

my $loaded_from_plif = sub {
  my $self = shift;
  return ($self->patron_birthplace eq LOADED_FROM_PLIF);
};

# Returns an new AlephIdentity
# Usage:
#   NYU::Libraries::PDS::Models::AlephIdentity->new(id, configurations)
sub new {
  my($proto, @args) = @_;
  my($class) = ref $proto || $proto;
  my($self) = bless(Class::Accessor->new(), $class);
  return $self->_init(@args);
}

sub _init {
  my($self, $id, $conf) = @_;
  # Set configurations
  $self->set('conf', $conf);
  # Set the attributes from LDAP.
  $self->$set_attributes_from_aleph($id);
  # Return self
  return $self;
}

sub clean_surname {
  my($self, $sn) = @_;
  $sn =~ s/\s//g;
  $sn =~ s/-//g;
  $sn =~ s/\.//g;
  $sn =~ s/,//g;
  return $sn;
}

sub encrypt_verification {
  my($self, $unencrypted_verification) = @_;
  my $conf = $self->conf;
  # Return unencrypted unless shared secret provided
  return $unencrypted_verification unless $conf->{shared_secret};
  my $encrypted_verification = 
    md5_hex($conf->{shared_secret}, $unencrypted_verification);
  return $encrypted_verification;
}

sub is_encrypt_verification {
  my $self = shift;
  # If no NetID and the record wasn't loaded from plif, don't encrypt.
  return ($self->is_encrypt && ($self->$loaded_from_plif))
}

1;
