package NYU::Libraries::XService::Base;
use strict;
use warnings;

use XML::Simple;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Response;

use constant NO_VALUE => 0;
use constant NO_ERROR => 0;
use constant HAS_CHILDREN => "Has Children";
use constant MULTIPLE_VALUES => "Multiple Values";

BEGIN {
  require Exporter;
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT= qw();
}

my $set_xml = sub {
  my $self = shift;
  my $xs = new XML::Simple();
  my $ref = $xs->XMLin($self->{"Body"},ForceArray =>1);
  $self->{"XML"} = $ref;
};

sub new {
  my $class  = shift;
  my(%params) = @_;
  my $cgi = $params{"CGI"};

  #URI Elements for XService HTTP Response
  my $host = $params{"Host"};
  my $port = $params{"Port"};
  my $path = $params{"Path"};

  #X-Service Application (Metalib,Aleph)
  my $xapp = $params{"XApp"};

  #Handle Query String for XService HTTP Response
  my $op = $params{"OP"};
  my $xparams = $params{"XParams"};
  my $query_string = handle_query_string($op, $xparams);

  my $url = $host.":".$port."/".$path."?".$query_string;

  my $ua = LWP::UserAgent->new;
  my $request = HTTP::Request->new('GET' => $url);
  my $response = $ua->request($request);
  my $success = $response->is_success;

  my $header = $response->headers_as_string();
  my $body = $response->content();

  my $self = {
    "CGI" => $cgi,
    "Host" => $host,
    "Port" => $port,
    "Path" => $path,
    "QueryString" => $query_string,
    "Response" => $response,
    "URL" => $url,
    "Header" => $header,
    "Body" => $body,
    "OP" => $op,
    "Success" => $success
  };

  return bless($self, $class);
}

#convenience method for handling query string;
#not for public consumption!
sub handle_query_string {
  my $op = shift;
  my $xparams = shift;
  my $query_string = "op=".$op;
  while (my ($xparam_name, $xparam_value) = each (%$xparams)) {
    $query_string .= "&".$xparam_name."=".$xparam_value;
  }
  return $query_string;
}

sub get_url {
  my $self = shift;
  #get and return value
  return $self->{"URL"};
}

sub get_query_string {
  my $self = shift;
  #get and return value
  return $self->{"QueryString"};
}

sub get_xml {
  my $self = shift;
  return undef unless $self->{"Success"};
  #check if set
  if (!$self->{"XML"}) {
    #set XML if not already set
    $self->$set_xml();
  }
  #get and return XML
  return $self->{"XML"};
}

sub get_xml_string {
  my $self = shift;
  #get XML
  my $ref = $self->get_xml();
  #get and return XML String
  my $xs = new XML::Simple();
  my $xml = $xs->XMLout($ref);
  return $xml;
}

sub get_content {
  my $self = shift;
  return undef unless $self->{"Success"};
  my $input = shift;
  my $content = NO_VALUE;
  if ($input) {
    $content = $input;
  }
  return $input;
}

sub success {
  my $self = shift;
  return $self->{"Success"};
}

1;
