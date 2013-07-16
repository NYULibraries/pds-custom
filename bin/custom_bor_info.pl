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

sub custom_bor_info {
  my ($session_id, $institute, $calling_system, $params) = @_;
  my $pds_directory = getEnvironmentParams('pds_directory');
  my $conf = parse_conf("$pds_directory/config/pds/nyu.conf");
  $calling_system ||= PDSParamUtil::getAndFilterParam('calling_system');
  my $target_url = PDSParamUtil::queryUrl();
  $target_url = '' if $target_url eq '?';
  my $session_controller = NYU::Libraries::PDS::controller($conf, $institute, 
    $calling_system, $target_url, $session_id);
  my $bor_info_xml = $session_controller->bor_info();
  return (defined($bor_info_xml)) ? ("00", $bor_info_xml) : ("11", undef);
}
