use strict;
use warning;

use lib "/exlibris/primo/p3_1/pds/custom";
use lib "/exlibris/primo/p3_1/pds/program";

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);
use NYU::Libraries::PDS;

# PDS Core modules
use PDSUtil qw(getEnvironmentParams);
use PDSParamUtil qw(getAndFilterParam queryUrl);

sub custom_bor_info {
  my ($session_id, $id, $password, $institute, $user_ip, $params) = @_;
  my $pds_directory = getEnvironmentParams('pds_directory');
  my $conf = parse_conf("$pds_directory/config/nyu.conf");
  my $calling_system = getAndFilterParam('calling_system');
  my $target_url = queryUrl();
  my $session_controller = NYU::Libraries::PDS->controller($conf, $institute, 
    $calling_system, $target_url, $session_id);
  print $session_controller->bor_info();
}
