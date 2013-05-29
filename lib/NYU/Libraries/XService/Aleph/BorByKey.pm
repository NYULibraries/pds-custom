package NYU::Libraries::XService::Aleph::BorByKey;

use warnings;
use strict;
use Data::Dumper;

use constant OP => "bor-by-key";
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
  my $borid = $params{"BorID"};
  my $verification = $params{"Verification"};
  my $user_name = $params{"UserName"};
  my $user_password = $params{"UserPassword"};
  my $xparams = {
    "library" => $library,
    "sub_library" => $sublibrary,
    "bor_id" => $borid,
    "verification" => $verification,
    "user_name" => $user_name,
    "user_password" => $user_password
  };
  my $self = NYU::Libraries::XService::Aleph::Base->new(
    @_,
    "OP" => $op,
    "Library" => $library,
    "SubLibrary" => $sublibrary,
    "BorID" => $borid,
    "Verification" => $verification,
    "UserName" => $user_name,
    "UserPassword" => $user_password,
    "XParams" => $xparams
  );
  return(bless($self, $class));
}

#All Get Methods
sub get_internal_id {
  #InternalID
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"internal-id"}->[0]);
  return $content;
}

1;
