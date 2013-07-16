use strict;
# use warning;

# Custom modules
use lib "/exlibris/primo/p3_1/pds/custom/lib";
use lib "/exlibris/primo/p3_1/pds/custom/vendor/lib";
# PDS program modules
use lib "/exlibris/primo/p3_1/pds/program";

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);
use NYU::Libraries::PDS;

# PDS Core modules
use PDSUtil qw(getEnvironmentParams);
use PDSParamUtil;

sub custom_load_sso {
  my ($session_id, $institute, $calling_system, $params, $target_url) = @_;
  my $pds_directory = getEnvironmentParams('pds_directory');
  my $conf = parse_conf("$pds_directory/config/pds/nyu.conf");
  $calling_system ||= PDSParamUtil::getAndFilterParam('calling_system');
  my $session_controller = NYU::Libraries::PDS::controller($conf, $institute, 
    $calling_system, $target_url, $session_id);
  print $session_controller->sso();
  # We're overriding the PDS chain, so we should just exit.
  exit;
}
