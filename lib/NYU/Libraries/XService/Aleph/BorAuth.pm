package NYU::Libraries::XService::Aleph::BorAuth;

use warnings;
use strict;

use Data::Dumper;

use constant OP => "bor-auth";
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
  my $translate = $params{"Translate"};
  my $borid = $params{"BorID"};
  my $verification = $params{"Verification"};
  my $user_name = $params{"UserName"};
  my $user_password = $params{"UserPassword"};
  my $xparams = {
    "library" => $library, "sub_library" => $sublibrary,
    "translate" => $translate, "bor_id" => $borid,
    "verification" => $verification, "user_name" => $user_name,
    "user_password" => $user_password };
  my $self = NYU::Libraries::XService::Aleph::Base->new(
    @_, "OP" => $op, "Library" => $library, "SubLibrary" => $sublibrary,
    "Translate" => $translate, "BorID" => $borid,
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
  return "$content";
}

sub get_z303_birthplace {
  #Z303Name
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z303"}->[0]->{"z303-birthplace"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z303_proxy_for_id {
  #Z303ProxyForID
}

sub get_z303_primary_id {
  #Z303PrimaryID
}

sub get_z303_name_key {
  #Z303NameKey
}

sub get_z303_user_type {
  #Z303UserType
}

sub get_z303_user_library {
  #Z303UserLibrary
}

sub get_z303_open_date {
  #Z303OpenDate
}

sub get_z303_update_date {
  #Z303UpdateDate
}

sub get_z303_con_lng {
  #Z303ConLng
}

sub get_z303_alpha {
  #Z303Alpha
}

sub get_z303_title {
  #Z303Title
}

sub get_z303_delinq_1 {
  #Z303Delinq1
}

sub get_z303_delinq_n_1 {
  #Z303DelinqN1
}

sub get_z303_delinq_1_update_date {
  #Z303Delinq1UpdateDate
}

sub get_z303_delinq_1_cat_name {
  #Z303Delinq1CatName
}

sub get_z303_delinq_2 {
  #Z303Delinq2
}

sub get_z303_delinq_n_2 {
  #Z303DelinqN2
}

sub get_z303_delinq_2_update_date {
  #Z303Delinq2UpdateDate
}

sub get_z303_delinq_2_cat_name {
  #Z303Delinq2CatName
}

sub get_z303_delinq_3 {
  #Z303Delinq3
}

sub get_z303_delinq_n_3 {
  #Z303DelinqN3
}

sub get_z303_delinq_3_update_date {
  #Z303Delinq3UpdateDate
}

sub get_z303_delinq_3_cat_name {
  #Z303Delinq3CatName
}

sub get_z303_profile_id {
  #Z303ProfileId
}

sub get_z303_export_consent {
  #Z303ExportConsent
}

sub get_z303_proxy_id_type {
  #Z303ProxyIdType
}

sub get_z303_send_all_letters {
  #Z303SendAllLetters
}

sub get_z303_plain_html {
  #Z303PlainHtml
}

sub get_z303_want_sms {
  #Z303WantSms
}

#Z304 Get Methods
sub get_z304_id {
  #Z304ID
}

sub get_z304_address0 {
  #Z304Address0
}

sub get_z304_address1 {
  #Z304Address1
}

sub get_z304_address2 {
  #Z304Address2
}

sub get_z304_address3 {
  #Z304Address3
}

sub get_z304_address4 {
  #Z304Address4
}

sub get_z304_zip {
  #Z304Zip
}

sub get_z304_email_address {
  #Z304EmailAddress
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z304"}->[0]->{"z304-email-address"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z304_telephone {
  #Z304Telephone
}

sub get_z304_telephone2 {
  #Z304Telephone2
}

sub get_z304_telephone3 {
  #Z304Telephone3
}

sub get_z304_telephone4 {
  #Z304Telephone4
}

sub get_z304_date_from {
  #Z304DateFrom
}

sub get_z304_date_to {
  #Z304DateTo
}

sub get_z304_address_type {
  #Z304AddressType
}

sub get_z304_sms_number {
  #Z304SmsNumber
}

sub get_z304_cat_name {
  #Z304CatNumber
}

#Z305 Get Methods
sub get_z305_id {
  #Z305ID
}

sub get_z305_sublibrary {
  #Z305SubLibrary
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

sub get_z305_loan_permission {
  #Z305LoanPermission
}

sub get_z305_photo_permission {
  #Z305PhotoPermission
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"z305"}->[0]->{"z305-photo-permission"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_z305_over_permission {
  #Z305OverPermission
}

sub get_z305_multi_hold {
  #Z305MultiHold
}

sub get_z305_loan_check {
  #Z305LoanCheck
}

sub get_z305_hold_permission {
  #Z305HoldPermission
}

sub get_z305_renew_permission {
  #Z305RenewPermission
}

sub get_z305_rr_permission {
  #Z305RrPermission
}

sub get_z305_ignore_late_return {
  #Z305IgnoreLateReturn
}

sub get_z305_hold_on_shelf {
  #Z305HoldOnShelf
}

sub get_z305_booking_permission {
  #Z305BookingPermission
}

sub get_z305_booking_ignore_hours {
  #Z305BookingIgnoreHours
}

1;
