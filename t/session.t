use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

# NYU Libraries modules
use NYU::Libraries::Util qw(parse_conf);

# JSON functions
use JSON qw(decode_json);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::PDS::Session') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::PDS::Session' );

# Get an instance of Session
my $session = NYU::Libraries::PDS::Session->new();

# Verify that this a Class::Accessor
isa_ok($session, qw(Class::Accessor));

# Verify that this a Session
isa_ok($session, qw(NYU::Libraries::PDS::Session));

# Verify methods
can_ok($session, (qw(id email institution_code institute barcode patron_status
  patron_type name first_name last_name uid nyuidn nyu_shibboleth ns_ldap verification
    entitlement ill_permission college_code college plif_status
      dept_code department major_code major ill_library session_id expiry_date remote_address)));

my $conf;
if($ENV{'CONFIG_BASEPATH'}) {
  $conf = parse_conf($ENV{'CONFIG_BASEPATH'}."config/pds/nyu.conf");
} else {
  $conf = parse_conf("config/pds/nyu.conf");
}

# Setup oauth2 JSON response mock
my $entitlement = 'urn:mace:nyu.edu:entl:its:wikispriv;urn:mace:nyu.edu:entl:its:classes;urn:mace:nyu.edu:entl:its:qualtrics;urn:mace:nyu.edu:entl:lib:eresources;urn:mace:nyu.edu:entl:its:wikispub;urn:mace:nyu.edu:entl:its:lynda;urn:mace:nyu.edu:entl:lib:ideaexchange;urn:mace:nyu.edu:entl:its:files;urn:mace:incommon:entitlement:common:1';
# my $json_response = '{"id":1,"username":"xx10","email":"dev@library.nyu.edu","admin":true,"created_at":"2014-02-24T22:13:00.529Z","updated_at":"2015-02-04T21:36:34.275Z","institution_code":"NYU","provider":"nyu_shibboleth","identities":[{"provider":"new_school_ldap"},{"id":17,"user_id":1,"provider":"aleph","uid":"1234567890","properties":{"verification":"12345","barcode":"67890","type":"","major":"Web Services","status":"51","college":"Division of Libraries","department":"IT Services \u0026 Media Services","identifier":"1234567890","ill_library":"","patron_type":"","plif_status":"PLIF LOADED","patron_status":"51","ill_permission":"Y","institution_code":"NYU"},"created_at":"2014-10-17T17:38:43.095Z","updated_at":"2015-02-03T17:23:15.150Z"},{"id":1,"user_id":1,"provider":"nyu_shibboleth","uid":"xx10","properties":{"uid":"xx10","name":"Dev Eloper","email":"dev@library.nyu.edu","extra":{"raw_info":{"nyuidn":"1234567890","entitlement":"'.$entitlement.'"}},"nyuidn":"1234567890","nickname":"Mickie","last_name":"Eloper","first_name":"Dev","entitlement":"'.$entitlement.'","institution_code":"NYU"},"created_at":"2014-02-24T22:13:00.565Z","updated_at":"2015-02-04T21:36:34.307Z"}]}';
my $json_response = '{"id":1,"username":"xx10","email":"dev@library.nyu.edu","admin":true,"created_at":"2014-02-24T22:13:00.529Z","updated_at":"2015-02-04T21:36:34.275Z","institution_code":"NYU","provider":"nyu_shibboleth","identities":[{"id":17,"user_id":1,"provider":"aleph","uid":"1234567890","properties":{"verification":"12345","barcode":"67890","type":"","major":"Web Services","status":"51","college":"Division of Libraries","department":"IT Services \u0026 Media Services","identifier":"1234567890","ill_library":"","patron_type":"","plif_status":"PLIF LOADED","patron_status":"51","ill_permission":"Y","institution_code":"NYU","expiry_date":"20141010"},"created_at":"2014-10-17T17:38:43.095Z","updated_at":"2015-02-03T17:23:15.150Z"},{"id":1,"user_id":1,"provider":"nyu_shibboleth","uid":"xx10","properties":{"uid":"xx10","name":"Dev Eloper","email":"dev@library.nyu.edu","extra":{"raw_info":{"nyuidn":"1234567890","entitlement":"'.$entitlement.'"}},"nyuidn":"1234567890","nickname":"Mickie","last_name":"Eloper","first_name":"Dev","entitlement":"'.$entitlement.'","institution_code":"NYU"},"created_at":"2014-02-24T22:13:00.565Z","updated_at":"2015-02-04T21:36:34.307Z"}]}';
my $decoded_json = decode_json($json_response);
# Create a new session based on JSON identities
my $new_session = NYU::Libraries::PDS::Session->new($decoded_json, $conf);

is($new_session->to_xml(),
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".
  "<session>".
    "<id>1234567890</id>".
    "<email>dev\@library.nyu.edu</email>".
    "<institution_code>NYU</institution_code>".
    "<institute>NYU</institute>".
    "<barcode>67890</barcode>".
    "<patron_status>51</patron_status>".
    "<name>Dev Eloper</name>".
    "<first_name>Dev</first_name>".
    "<last_name>Eloper</last_name>".
    "<uid>xx10</uid>".
    "<nyuidn>1234567890</nyuidn>".
    "<nyu_shibboleth>true</nyu_shibboleth>".
    "<verification>12345</verification>".
    "<entitlement>urn:mace:nyu.edu:entl:its:wikispriv;urn:mace:nyu.edu:entl:its:classes;urn:mace:nyu.edu:entl:its:qualtrics;urn:mace:nyu.edu:entl:lib:eresources;urn:mace:nyu.edu:entl:its:wikispub;urn:mace:nyu.edu:entl:its:lynda;urn:mace:nyu.edu:entl:lib:ideaexchange;urn:mace:nyu.edu:entl:its:files;urn:mace:incommon:entitlement:common:1</entitlement>".
    "<ill_permission>Y</ill_permission>".
    "<college>Division of Libraries</college>".
    "<plif_status>PLIF LOADED</plif_status>".
    "<department>IT Services &amp; Media Services</department>".
    "<major>Web Services</major>".
    "<expiry_date>20141010</expiry_date>".
    "<edupersonentitlement><value>urn:mace:nyu.edu:entl:its:wikispriv</value>".
      "<value>urn:mace:nyu.edu:entl:its:classes</value>".
      "<value>urn:mace:nyu.edu:entl:its:qualtrics</value>".
      "<value>urn:mace:nyu.edu:entl:lib:eresources</value>".
      "<value>urn:mace:nyu.edu:entl:its:wikispub</value>".
      "<value>urn:mace:nyu.edu:entl:its:lynda</value>".
      "<value>urn:mace:nyu.edu:entl:lib:ideaexchange</value>".
      "<value>urn:mace:nyu.edu:entl:its:files</value>".
      "<value>urn:mace:incommon:entitlement:common:1</value>".
    "</edupersonentitlement>".
  "</session>", "Unexpected session xml");
