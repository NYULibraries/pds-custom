#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use NYU::Libraries::Util qw(parse_conf);
use NYU::Libraries::PDS::Identities::Aleph;
my $conf = parse_conf("../vendor/pds-core/config/pds/nyu.conf");
# Specify that this is only a lookup
$conf->{lookup_only} = 1;
my $identity = NYU::Libraries::PDS::Identities::Aleph->new($conf, 'N13386520');
$identity->set_attributes(1);
print $identity->encrypt("RUSS");
exit;
