use strict;
use warnings;
use Test::More qw(no_plan);

# Verify module can be included via "use" pragma
BEGIN { use_ok('NYU::Libraries::Aleph::Patron') };

# Verify module can be included via "require" pragma
require_ok( 'NYU::Libraries::Aleph::Patron' );

# Get an instance of Aleph::Patron
my $patron = NYU::Libraries::Aleph::Patron->new();

# Verify that this a Class::Accessor
isa_ok($patron, qw(Class::Accessor));

# Verify that this a Aleph::Patron
isa_ok($patron, qw(NYU::Libraries::Aleph::Patron));

# Verify methods
can_ok($patron, (qw(data exists ssh_host ssh_port ssh_user ssh_password save_cmd xserver_host xserver_port xserver_user xserver_password adm plif_file_path plif_file_name pds_root flat_file error error_msg patron_id patron_uid patron_verification patron_birthplace patron_bor_status shared_secret force_encryption __z303 __z304s __z305s __z308s)));
