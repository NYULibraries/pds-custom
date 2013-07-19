package NYU::Libraries::XService::Aleph::BorInfo;

use warnings;
use strict;

use Data::Dumper;

use constant OP => "bor-info";
use constant DEFAULT_LIBRARY => "NYU50";

BEGIN {
  our @ISA = ("NYU::Libraries::XService::Aleph::Base");
  require NYU::Libraries::XService::Aleph::Base;
}

sub new {
  my($class) = shift;
  my(%params) = @_;

  my $op = OP;

  #XParams
  my $library = (length($params{"Library"})) ? $params{"Library"} : DEFAULT_LIBRARY;
  my $sublibrary = $params{"SubLibrary"};
  my $loans = $params{"Loans"};
  my $cash = $params{"Cash"};
  my $filter_cash = $params{"FilterCash"};
  my $hold = $params{"Hold"};
  my $translate = $params{"Translate"};
  my $borid = $params{"BorID"};
  my $verification = $params{"Verification"};
  my $user_name = $params{"UserName"};
  my $user_password = $params{"UserPassword"};
  my $xparams = {
    "library" => $library, "sub_library" => $sublibrary, "loans" => $loans, 
    "cash" => $cash, "filter_cash" => $filter_cash, "hold" => $hold,
    "translate" => $translate, "bor_id" => $borid,
    "verification" => $verification, "user_name" => $user_name,
    "user_password" => $user_password };
  my $self = NYU::Libraries::XService::Aleph::Base->new(
    @_, "OP" => $op, "Library" => $library, "SubLibrary" => $sublibrary,
    "Loans" => $loans, "Cash" => $cash, "FilterCash" => $filter_cash,
    "Hold" => $hold, "Translate" => $translate, "BorID" => $borid,
    "Verification" => $verification, "UserName" => $user_name,
    "UserPassword" => $user_password, "XParams" => $xparams);
  return(bless($self, $class));
}

#All Get Methods
#Z303 Get Methods
sub get_z303_id {
  #Z303ID
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z303"}->[0]->{"z303-id"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z303_name {
  #Z303Name
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z303"}->[0]->{"z303-name"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z303_birthplace {
  #Z303Name
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z303"}->[0]->{"z303-birthplace"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z303_ill_library {
  #Z303IllLibrary
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z303"}->[0]->{"z303-ill-library"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z304_email_address {
  #Z304EmailAddress
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z304"}->[0]->{"z304-email-address"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z305_bortype {
  #Z305BorType
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z305"}->[0]->{"z305-bor-type"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z305_borstatus {
  #Z305BorStatus
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z305"}->[0]->{"z305-bor-status"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z305_expiry_date {
  #Z305ExpirtyDate
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z305"}->[0]->{"z305-expiry-date"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z305_photo_permission {
  #Z305PhotoPermission
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z305"}->[0]->{"z305-photo-permission"}->[0]);
  return (ref $content) ? '' : $content;
}

1;
