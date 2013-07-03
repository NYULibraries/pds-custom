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

sub custom_authenticate_ns_ldap {
  my ($session_id, $id, $password, $institute, $user_ip, $params) = @_;
  my $pds_directory = getEnvironmentParams('pds_directory');
  my $conf = parse_conf("$pds_directory/config/nyu.conf");
  my $calling_system = PDSParamUtil::getAndFilterParam('calling_system');
  my $target_url = PDSParamUtil::queryUrl();
  my $session_controller = NYU::Libraries::PDS->controller($conf, $institute, 
    $calling_system, $target_url, $session_id);
  $session_controller->authenticate_ns_ldap($id, $password);
}
