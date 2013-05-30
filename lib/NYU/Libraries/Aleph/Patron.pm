package NYU::Libraries::Aleph::Patron;

use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

use CGI;
use XML::Simple;
# use Net::SFTP;
# use Net::SSH::Perl;
use Digest::MD5 qw(md5_hex md5);
use NYU::Libraries::XService::Aleph::BorByKey;
use NYU::Libraries::XService::Aleph::BorInfo;

use constant LOADED_FROM_PLIF => "PLIF LOADED";
use constant FAMILY_MEMBER_BOR_STATUS => "65";

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(data exists ssh_host ssh_port ssh_user ssh_password save_cmd xserver_host xserver_port xserver_user xserver_password adm plif_file_path plif_file_name pds_root flat_file error error_msg patron_id patron_uid patron_verification patron_birthplace patron_bor_status shared_secret force_encryption __z303 __z304s __z305s __z308s));

sub init {
  my $self = shift;
  $self->data($self->__get());
  $self->exists($self->__exists());
  if($self->exists) {
    $self->patron_verification($self->__get_verification($self->data->{"sn"}));
  }
}

sub save {
  my $self = shift;
  return if $self->exists;
  my $patron;
  $patron->{'patron-record'}->{'z303'} = $self->{__z303} if defined $self->{__z303};
  $patron->{'patron-record'}->{'z304'} = $self->{__z304s} if defined $self->{__z304s};
  $patron->{'patron-record'}->{'z305'} = $self->{__z305s} if defined $self->{__z305s};
  $patron->{'patron-record'}->{'z308'} = $self->{__z308s} if defined $self->{__z308s};
  my $xs = XML::Simple->new('NoAttr' => 1, 'RootName' => 'p-file-20', 'XMLDecl' => '<?xml version="1.0" encoding="utf-8"?>', 'OutputFile' => $self->{pds_root}."/tmp/".$self->{plif_file_name} );
  $xs->XMLout($patron);
  #my %args = (user => $self->{ssh_user}, password => $self->{ssh_password}, ssh_args => [ port => $self->{ssh_port} ], debug => 1);
  #Hack fix for mod_perl environment.
  #$IO::Socket::SSL::VERSION = undef;
  #my $sftp = Net::SFTP->new($self->{ssh_host}, %args) or die "Cannot connect to $@";
  #my $local = $self->{pds_root}."/tmp/".$self->{plif_file_name};
  #my $remote = $self->{plif_file_path}."/".$self->{plif_file_name};
  #my $sftp_success = $sftp->put($local, $remote);
  #if ($sftp_success) {
  #  my $ssh = Net::SSH::Perl->new($self->{ssh_host});
  #  $ssh->login($self->{ssh_user}, $self->{ssh_password});
  #  my($stdout, $stderr, $exit) = $ssh->cmd($self->{save_cmd});
  #  $self->__log_error("003", "SSH Call Failed.", "NYU:Libraries::Aleph::Patron::get") if $exit;
  #  return undef if $exit;
  #  return 1;
  #} else {
  #  $self->__log_error("002", "SFTP Failed.", "NYU:Libraries::Aleph::Patron::save");
  #  return undef;
  #}
}

sub __get {
  my $self = shift;
  return $self->data if defined($self->data);
  $self->__log_error("001", "Patron ID not set.", "NYU:Libraries::Aleph::Patron::get") unless ($self->{patron_id});
  return undef unless ($self->{patron_id});
  # First try flat file.
  my $patron = $self->__get_from_flat_file;
  return $patron if $patron;
  # If not in flat file, try Aleph via X-Server
  $patron = $self->__get_from_xserver;
  return $patron if $patron;
  return undef;
}

sub __exists {
  my $self = shift;
  return 1 if defined($self->data);
  return 1 if $self->__exists_in_flat_file;
  return 1 if $self->__exists_in_aleph;
  return undef;
}

sub add_z303 {
  my $self = shift;
  my ($name, $field1, $field2, $field3, $note1, $note2, $home_library, $export_consent, $send_all_letters, $plain_html) = @_;
  my $z303 = {
    'match-id-type' => "00", 
    'match-id' => $self->{patron_id},
    'record-action' => "A",
    'z303-id' => $self->{patron_id},
    'z303-name' => $name,
    'z303-field-1' => $field1,
    'z303-field-2' => $field2,
    'z303-field-3' => $field3,
    'z303-note-1' => $note1,
    'z303-note-2' => $note2,
    'z303-home-library' => $home_library,
    'z303-export-consent' => $export_consent,
    'z303-send-all-letters' => $send_all_letters,
    'z303-plain-html' => $plain_html
  };
  $self->__z303([$z303]);
}

sub add_z304 {
  my $self = shift;
  my ($sequence, $type, $a0, $a1, $a2, $a3, $email, $date_from, $date_to, $telephone) = @_;
  my $z304 = {
    'record-action' => "A",
    'z304-id' => $self->{patron_id},
    'z304-sequence' => $sequence,
    'z304-address-type' => $type,
    'z304-address-0' => $a0,
    'z304-address-1' => $a1,
    'z304-address-2' => $a2,
    'z304-address-3' => $a3,
    'z304-email-address' => $email,
    'z304-date-from' => $date_from,
    'z304-date-to' => $date_to,
    'z304-telephone' => $telephone
  };
  my $addresses = (defined $self->{__z304s}) ? $self->{__z304s}:[];
  push(@$addresses, $z304);
  $self->__z304s($addresses);
}

sub add_z305 {
  my $self = shift;
  my ($sub_library, $bor_status, $expiry_date) = @_;
  my $z305 = {
    'record-action' => "A",
    'z305-sub-library' => $sub_library,
    'z305-bor-status' => $bor_status,
    'z305-expiry-date' => $expiry_date
  };
  my $locals = ($self->{__z305s}) ? $self->{__z305s}:[];
  push(@$locals, $z305);
  $self->__z305s($locals);
}

sub add_z308 {
  my $self = shift;
  my ($key_type, $key_data, $verification, $verification_type, $status, $encryption) = @_;
  my $z308 = {
    'record-action' => "A",
    'z308-key-type' => $key_type,
    'z308-key-data' => $key_data,
    'z308-verification' => $verification,
    'z308-verification-type' => $verification_type,
    'z308-status' => $status,
    'z308-encryption' => $encryption
  };
  my $ids = ($self->{__z308s}) ? $self->{__z308s}:[];
  push(@$ids, $z308);
  $self->__z308s($ids);
}

sub __get_from_flat_file {
  my $self = shift;
  # Open the flat file.
  my $flat_file_open = open(FF, "<", $self->{flat_file});
  # Log warning and return undef if flat file doesn't exist.
  $self->__log_warning(sprintf('File does not exist:  %s', $self->{flat_file}), "NYU:Libraries::Aleph::Patron::__get_from_flat_file") unless ($flat_file_open);
  return undef unless ($flat_file_open);
  my $patron_id = $self->{patron_id};
  # Log error and return undef if patron ID not set.
  $self->__log_error("001", "Patron ID not set.", "NYU:Libraries::Aleph::Patron::__get_from_flat_file") unless ($patron_id);
  return undef unless ($patron_id);
  #Check each line of flat file for user and load into patron hash reference.
  my $patron;
  $patron->{"birthplace"} = "";
  while (my $p = <FF>) {
    # Next if empty line
    next if ($p =~/^\s*$/);
    if ($p =~ m/^$patron_id\t/i) { # Case insensitive patron id matched in flat file - BUG FIX 2011/06/29
      # Remove new line character
      $p =~ s/\n$//;
      # Set patron hash reference from flat file.
      ($patron->{"id"}, $patron->{"barcode"}, $patron->{"verification"}, $patron->{"expiry_date"}, $patron->{"bor-status"}, $patron->{"bor-type"}, $patron->{"bor-name"}, $patron->{"mail"}, $patron->{"ill-permission"}, $patron->{"birthplace"}, $patron->{"college_code"}, $patron->{"college_name"}, $patron->{"dept_code"}, $patron->{"dept_name"}, $patron->{"major_code"}, $patron->{"major"}) =  split(/\t/, $p);
      last;
    }
  }
  close (FF);
  return undef unless $patron->{"id"};
  # Add birthplace and bor_status to self for verification check
  $self->patron_birthplace($patron->{"birthplace"});
  $self->patron_bor_status($patron->{"bor-status"});
  #Add additional attributes for mapping purposes
  $patron->{"z305-bor-status"} = $patron->{"bor-status"};
  my @name_array = split(/,/, $patron->{"bor-name"});
  $patron->{"cn"} = $patron->{"bor-name"};
  $patron->{"givenname"} = (defined($name_array[1])) ? $name_array[1]:$patron->{"bor-name"};
  #$patron->{"uid"} = $patron->{"bor-name"};
  # Set last name
  my $sn = $name_array[0];
  $patron->{"sn"} = $sn;
  # Since verification isn't used for this call, add it based on info from Aleph
  $self->patron_verification($self->__get_verification($sn));
  $patron->{"verification"} = $self->{patron_verification};
  return $patron;
}

sub __get_from_xserver {
  my $self = shift;
  # Call bor-info xservice
  my $bor_info = NYU::Libraries::XService::Aleph::BorInfo->new(
    "Host" => $self->{xserver_host},
    "Port" => $self->{xserver_port},
    "BorID" => $self->{patron_id},
    "Library" => $self->{adm},
    "Loans" => "N",
    "Cash" => "N",
    "Holds" => "N",
    "Translate" => "N",
    "UserName" => $self->{xserver_user},
    "UserPassword" => $self->{xserver_password}  
  );
  # Check if call was successful.
  $self->__log_warning("XService call failed.", "NYU:Libraries::Aleph::Patron::__get_from_xserver") unless ($bor_info->success);
  return undef unless ($bor_info->success);
  # Checking if any errors in xservice.
  $self->__log_warning(sprintf('XService error:  %s', $bor_info->get_error), "NYU:Libraries::Aleph::Patron::__get_from_xserver") if ($bor_info->get_error);
  return undef if ($bor_info->get_error);
  # Set patron hash reference from xservice.
  my $patron;
  $patron->{"id"} = $bor_info->get_z303_id();
  $patron->{"barcode"} =  "";
  $patron->{"expiry_date"} = $bor_info->get_z305_expiry_date();
  $patron->{"bor-status"} = $bor_info->get_z305_borstatus();
  $patron->{"bor-type"} = $bor_info->get_z305_bortype();
  $patron->{"bor-name"} = $bor_info->get_z303_name();
  $patron->{"mail"} = $bor_info->get_z304_email_address();
  $patron->{"ill-permission"} = $bor_info->get_z305_photo_permission();
  $patron->{"birthplace"} = $bor_info->get_z303_birthplace();
  # Add birthplace and bor_status to self for verification check
  $self->patron_birthplace($patron->{"birthplace"});
  $self->patron_bor_status($patron->{"bor-status"});
  #Add additional attributes for mapping purposes
  $patron->{"z305-bor-status"} = $patron->{"bor-status"};
  my @name_array = split(/,/, $patron->{"bor-name"});
  $patron->{"cn"} = $patron->{"bor-name"};
  $patron->{"givenname"} = (defined($name_array[1])) ? $name_array[1]:$patron->{"bor-name"};
  #$patron->{"uid"} = $patron->{"bor-name"};
  # Set last name
  my $sn = $name_array[0];
  $patron->{"sn"} = $sn;
  # Since verification isn't necessary for this call, add it based on info from Aleph
  $self->patron_verification($self->__get_verification($sn));
  $patron->{"verification"} = $self->{patron_verification};
  return $patron;
}

sub __exists_in_flat_file {
  my $self = shift;
  my $exists = ($self->__get_from_flat_file) ? 1:undef;
  return $exists;
}

sub __exists_in_aleph {
  my $self = shift;
  # Call bor-by-key xservice since it is a lighter weight call
  my $bor_by_key = NYU::Libraries::XService::Aleph::BorByKey->new(
    "Host" => $self->{xserver_host},
    "Port" => $self->{xserver_port},
    "BorID" => $self->{patron_id},
    "Library" => $self->{adm},
    "UserName" => $self->{xserver_user},
    "UserPassword" => $self->{xserver_password}
  );
  # Check if call was successful.
  $self->__log_warning("XService call failed.", "NYU:Libraries::Aleph::Patron::__exists_in_aleph") unless ($bor_by_key->success);
  return undef unless ($bor_by_key->success);
  # Check if any errors in xservice.
  $self->__log_warning(sprintf('XService error:  %s', $bor_by_key->get_error), "NYU:Libraries::Aleph::Patron::__exists_in_aleph") if ($bor_by_key->get_error);
  return undef if ($bor_by_key->get_error);
  # If internal id exist, patron exists.
  my $exists = ($bor_by_key->get_internal_id) ? 1:undef;
  return $exists;
}

sub __log_warning {
  my $self = shift;
  my ($warning_msg, $sub) = @_;
  my $cgi = CGI->new;
  warn sprintf('[%s] [%s] Warning: %s', $sub, $cgi->remote_addr, $warning_msg);
}

sub __log_error {
  my $self = shift;
  my ($error, $error_msg, $sub) = @_;
  my $cgi = CGI->new;
  $self->error($error);
  $self->error_msg($error_msg);
  warn sprintf('[%s] [%s] Error %s: %s', $sub, $cgi->remote_addr, $self->{error}, $self->{error_msg});
}

sub __get_verification {
  my $self = shift;
  my $sn = shift;
  # Strip spaces and other characters
  my $naked_sn = $self->__strip_sn($sn);
  # Set verification as first four characters of last name 
  my $verification = uc(substr( $naked_sn, 0, 4 ));
  # Don't encrypt if this is an exception.
  return $verification if $self->__plif_exception;
  # Don't encrypt unless we it meets the encryption business logic.
  return $verification unless $self->__is_encrypt_verification;
  # And then encrypt the verification 
  my $encrypted_verification = $self->__encrypt_verification($verification);
  return $encrypted_verification;
}

sub __strip_sn {
  my $self = shift;
  my $sn = shift;
  $sn =~ s/\s//g;
  $sn =~ s/-//g;
  $sn =~ s/\.//g;
  $sn =~ s/,//g;
  return $sn;
}

sub __encrypt_verification {
  my $self = shift;
  my $unencrypted_verification = shift;
  return undef unless $unencrypted_verification;
  # Return unencrypted unless shared secret provided
  return $unencrypted_verification unless $self->{shared_secret};
  my $shared_secret = $self->{shared_secret};
  my $encrypted_verification = md5_hex($shared_secret, $unencrypted_verification);
  return $encrypted_verification;
}

sub __loaded_from_plif {
  my $self = shift;
  my $birthplace = $self->{patron_birthplace};
  my $birthplace_constant = LOADED_FROM_PLIF;
  return ($birthplace eq $birthplace_constant);
}

sub __is_encrypt_verification {
  my $self = shift;
  # If no NetID and either 'force encryption' is not set or the record wasn't loaded from plif, don't encrypt.
  return ($self->{patron_uid} && ($self->__loaded_from_plif || $self->{force_encryption}))
}

sub __plif_exception {
  my $self = shift;
  my $bor_status = $self->{patron_bor_status};
  my $bor_status_constant = FAMILY_MEMBER_BOR_STATUS;
  return ($bor_status eq $bor_status_constant);
}

1;
