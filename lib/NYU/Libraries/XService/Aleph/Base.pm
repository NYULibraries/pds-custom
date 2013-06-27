package NYU::Libraries::XService::Aleph::Base;
use strict;
use warnings;

use Data::Dumper;

use constant DEFAULT_HOST => "http://aleph.library.nyu.edu";
use constant DEFAULT_PORT => "80";
use constant DEFAULT_PATH => "X";

BEGIN {
  our @ISA = ("NYU::Libraries::XService::Base");
  require NYU::Libraries::XService::Base;
}

sub new {
  my($class) = shift;
  my(%params) = @_;
  my $host = (defined($params{"Host"})) ? $params{"Host"} : DEFAULT_HOST;
  my $port = (defined($params{"Port"})) ? $params{"Port"} : DEFAULT_PORT;
  my $path = (defined($params{"Path"})) ? $params{"Path"} : DEFAULT_PATH;
  my ($self) = NYU::Libraries::XService::Base->new(
    @_, "Host" => $host, "Port" => $port, "Path" => $path);
  return(bless($self, $class));
}

sub get_session_id {
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"session-id"}->[0]);
  return (ref $content) ? '' : $content;
}

sub get_error {
  my $self = shift;
  my $xml = $self->get_xml();
  my $content = $self->get_content($xml->{"error"}->[0]);
  return (ref $content) ? '' : $content;
}

1;
