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

# New CGI
my $cgi = new CGI;
# Get Session Id
my $session_id = $cgi->cookie('PDS_HANDLE');
# Institute from URL
my $institute = PDSParamUtil::getAndFilterParam('institute');
# Target URL is the current URL with the query
my $target_url = $cgi->url(-query => 1)
# Calling system is ezproxy
my $calling_system = "ezproxy";
# Get the configuration
my $pds_directory = getEnvironmentParams('pds_directory');
my $conf = parse_conf("$pds_directory/config/pds/nyu.conf");
my $session_controller = NYU::Libraries::PDS::controller($conf, $institute,
  $calling_system, $target_url, $session_id);
# Logout
print $session_controller->ezproxy();
# Get the hell out of dodge
exit;
