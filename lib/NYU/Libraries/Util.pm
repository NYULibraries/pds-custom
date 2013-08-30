package NYU::Libraries::Util;
use strict;
use warnings;

use URI::URL;
use LWP::UserAgent;

# Export these methods
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trim xml_encode parse_conf save_permanent_eshelf_records whitelist_institution);

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

1;
