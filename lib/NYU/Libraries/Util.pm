package NYU::Libraries::Util;
use strict;
use warnings;

use URI::URL;
use LWP::UserAgent;

# Export these methods
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(trim xml_encode parse_conf save_permanent_eshelf_records);

# global lookup hash
my %ESCAPES = ('&' => '&amp;', '"' => '&quot;');

sub xml_encode {
  my ($string) = @_;
  $string =~ s/([&"])/$ESCAPES{$1}/ge;
  return $string;
}

sub parse_conf {
  my ($file_name, $defaults) = @_;
  return undef if (!(open(OPEN_FILE, $file_name)))
  $defaults = {} unless $defaults;
  my $conf = {};
  my $line;
  while ($line = <OPEN_FILE>) {
    # Next if empty line or 
    # comment(starts with # or !) or
    # section heading ([SECTION HEADING])
    next if ($line =~/^\s*$/) || 
      ($line =~ /^\s*(#|!)/) || 
        ($line =~/^\[[A-Z]/i);
    $line = $self->trim($line);
    if ($line =~ /=/) {
      my $key = $self->trim($`);
      my $value = $self->trim($');
      if (defined $conf->{"$key"}) {
        $conf->{"$key"} .= ";$value";
      } else {
        $conf->{"$key"} = $value;
      }
    }
  }
  close(OPEN_FILE);
  foreach my $key ($defaults) {
    $conf->{$key} = $defaults->{$key} unless defined $conf->{"$key"}
  }
  return $conf;
}

sub trim {
  my ($string) = @_;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub save_permanent_eshelf_records {
  my ($conf, $pds_handle, $tsetse_handle, $tsetse_credentials) = @_;
  return 0 if !defined $conf;
  if ($tsetse_handle && $pds_handle) {
    my $tsetse_url = $conf->{'tsetse_url'};
    return 0 unless defined $tsetse_url;
    my $tsetse_save_permanent_url = "$tsetse_url/records/save_permanent.json";
    # Pack cookies (semi colon delimited list of name value pairs)
    # Pack tsetse_handle, PDS_HANDLE, and tsetse_credentials (if logging in via tsetse[saves a call to PDS]).
    my $cookies = "tsetse_handle=$tsetse_handle; domain=.library.nyu.edu; path=/, ".
        "PDS_HANDLE=$pds_handle; domain=.library.nyu.edu; path=/, ";
    $cookies .= "tsetse_credentials=$tsetse_credentials; domain=.library.nyu.edu; path=/, " if $tsetse_credentials;
    # PUT the request to the eshelf and get the response.
    my $user_agent = LWP::UserAgent->new();
    my $url = URI::URL->new($tsetse_save_permanent_url);
      my $headers = HTTP::Headers->new(
      'Content-Type' => 'application/json',
      'Cache-Control' => 'no-cache',
      'Cookie' => $cookies);
    my $request = HTTP::Request->new("PUT", $url, $headers);
    my $response = $user_agent->request($request);
    return 0 unless ($response->is_success);
    return 1;
  }
}
1;
