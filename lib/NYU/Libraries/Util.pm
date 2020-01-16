package NYU::Libraries::Util;
use strict;
use warnings;
use Data::Dumper;

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
  save_permanent_eshelf_records whitelist_institution handle_primo_target_url handle_aleph_target_url
    expire_target_url_cookie set_target_url_cookie target_url_cookie
      aleph_identity nyu_shibboleth_identity new_school_ldap_identity PDS_TARGET_COOKIE COOKIE_EXPIRATION);

# global lookup hash
my %ESCAPES = ('&' => '&amp;', '"' => '&quot;');

# Been there done that cookie name
use constant PDS_TARGET_COOKIE => 'pds_target_url';
use constant COOKIE_EXPIRATION => 'Thu, 01-Jan-1970 00:00:01 GMT';
use constant ALEPH_IDENTITY_NAME => 'aleph';
use constant NYU_SHIBBOLETH_IDENTITY_NAME => 'nyu_shibboleth';
use constant NEW_SCHOOL_LDAP_IDENTITY_NAME => 'new_school_ldap';

# Function gets the identity from an array of identites
# for the given provider
# Usage:
#   get_identity_from_provider($identities, $provider);
sub get_identity_from_provider {
  my ($identities, $provider) = @_;
  for my $identity (@$identities) {
    if ($identity->{provider} eq $provider) {
      return $identity;
    }
  }
}

# Function pulls Aleph identity from array of identities
sub aleph_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, ALEPH_IDENTITY_NAME);
}

# Function pulls NYU Shibboleth identity from array of identities
sub nyu_shibboleth_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, NYU_SHIBBOLETH_IDENTITY_NAME);
}

# Function pulls New School LDAP identity from array of identities
sub new_school_ldap_identity {
  my ($identities) = @_;
  return get_identity_from_provider($identities, NEW_SCHOOL_LDAP_IDENTITY_NAME);
}

# Function expires the cookie that specifies that
# we've gone to SSO
# Usage:
#   expire_target_url_cookie();
sub expire_target_url_cookie {
  my $cgi = CGI->new();
  # Unset the cookie!
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
    -expires => 'Thu, 01-Jan-1970 00:00:01 GMT');
  print $cgi->header(-cookie => [$pds_target]);
}

# Function sets the cookie that specifies that
# we're coming back from SSO
# Usage:
#   set_target_url_cookie($target_url);
sub set_target_url_cookie {
  my ($target_url) = @_;
  my $cgi = CGI->new();
  # Force this URL to be HTTPS
  $target_url =~ s/^http/https/;
  $target_url =~ s/:80//;
  $test_target = "https://library.nyu.edu?url=".$target_url;
  # Set the cookie to the current target URL
  # It expires in 5 minutes
  my $pds_target = CGI::Cookie->new(-name => PDS_TARGET_COOKIE,
    -expires => '+5m', -value => $test_target);
  print $cgi->header(-cookie => [$pds_target]);
}

# Method to get the "target url" cookie
# Usage:
#   target_url_cookie();
sub target_url_cookie {
  # Get the "target url" cookie
  my $cgi = CGI->new();
  return $cgi->cookie(PDS_TARGET_COOKIE);
}

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
    $bobcat_url =~ s/http(s)?:\/\///;
    if($target_url =~ /$bobcat_url/) {
      if($target_url !~ /\/goto\/logon\//) {
        $target_url = $PDSUtil::server_httpsd."/goto/logon/$target_url&pds_handle=$session_id";
      }
    }
  }
  return $target_url;
};

# Private method to deal with Aleph needing pds_handle appended to the return url
# Usage:
#   $aleph_target_url = $self->handle_aleph_target_url($target_url)
sub handle_aleph_target_url {
  my($conf, $target_url, $session) = @_;
  if($session) {
    my $session_id = $session->session_id;
    my $aleph_url = $conf->{aleph_url};
    $aleph_url =~ s/http(s)?:\/\///;
    if($target_url =~ /$aleph_url/) {
      $target_url = $target_url."&pds_handle=".$session_id;
    }
  }
  return $target_url;
}

1;
