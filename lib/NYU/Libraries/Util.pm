package NYU::Libraries::Util;
use strict;
use warnings;

# URI module
use URI;
use URI::URL;
use URI::Escape;
use URI::QueryParam;

use LWP::UserAgent;

# PDS Util module
use PDSUtil;

# Export these methods
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trim xml_encode parse_conf fix_target_url
  save_permanent_eshelf_records whitelist_institution handle_primo_target_url aleph_identity nyu_shibboleth_identity new_school_ldap_identity);

use constant ALEPH_IDENTITY_NAME => 'aleph';
use constant NYU_SHIBBOLETH_IDENTITY_NAME => 'nyu_shibboleth';
use constant NEW_SCHOOL_LDAP_IDENTITY_NAME => 'new_school_ldap';

# global lookup hash
my %ESCAPES = ('&' => '&amp;', '"' => '&quot;');

# Function to encode quotes and ampersands.
# Usage:
#   my $xml = xml_encode($unencoded_string);
sub xml_encode {
  my ($string) = @_;
  $string =~ s/([&"])/$ESCAPES{$1}/ge;
  return $string;
}

# Function to whitelist institutions.
# Returns institution if whitelisted, undef if not.
# Usage:
#   my $whitelisted_institution = whitelist_institution($wild_institution);
sub whitelist_institution {
  my ($institute) = @_;
  return undef unless $institute;
  my @institutes = qw(NYU NYUAD NYUSH HSL CU NS NYSID);
  ( grep { $_ eq $institute} @institutes ) ? $institute : undef;
}

# Function to parse the PDS configuration file
# Usage:
#   my $conf = parse_conf($conf_file);
sub parse_conf {
  my ($file_name, $defaults) = @_;
  return undef if (!(open(OPEN_FILE, $file_name)));
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
    $line = trim($line);
    if ($line =~ /=/) {
      my $key = trim($`);
      my $value = trim($');
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

# Function to trim a given string
# Usage:
#   my $trimmed_string = trim($extra_spaces_string);
sub trim {
  my ($string) = @_;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

# Function to fix a given target url
# Usage:
#   $target_url = fix_target_url($target_url);
sub fix_target_url {
  my ($target_url) = @_;
  $target_url =~ s/\&amp;/\&/g;
  $target_url = '' if $target_url eq '?';
  return $target_url;
}

# Private method to deal with Primo's stupidity
# Usage:
#   $primo_target_url = $self->$handle_primo_target_url($target_url)
sub handle_primo_target_url {
  my($conf, $target_url, $session) = @_;
  if($session) {
    my $session_id = $session->session_id;
    my $bobcat_url = $conf->{bobcat_url};
    if($target_url =~ /$bobcat_url(:[0-9]+)?\/primo_library\/libweb/) {
      if($target_url !~ /\/goto\/logon\//) {
        $target_url = $PDSUtil::server_httpsd."/goto/logon/$target_url&pds_handle=$session_id";
      }
    }
  }
  return $target_url;
};

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
    my $headers = HTTP::Headers->new('Content-Type' => 'application/json',
      'Cache-Control' => 'no-cache', 'Cookie' => $cookies);
    my $request = HTTP::Request->new("PUT", $url, $headers);
    my $response = $user_agent->request($request);
    return 0 unless ($response->is_success);
    return 1;
  }
}

# Private method to get identity from identities array based on provider
sub get_identity_from_provider {
  my($identities, $provider) = @_;
  for my $identity (@$identities) {
    if ($identity->{provider} eq $provider) {
      return $identity;
    }
  }
}

# Pull Aleph identity
sub aleph_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, ALEPH_IDENTITY_NAME);
}

# Pull NYU Shibboleth identity
sub nyu_shibboleth_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, NYU_SHIBBOLETH_IDENTITY_NAME);
}

# Pull New School LDAP identity
sub new_school_ldap_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, NEW_SCHOOL_LDAP_IDENTITY_NAME);
}

1;
