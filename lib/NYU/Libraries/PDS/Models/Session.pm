package NYU::Libraries::PDS::Models::Session;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

# Use PDS core libraries
use IOZ311_file;
use IOZ312_file;
use PDSSession;
use PDSSessionUserAttrs;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(pds_handle));

1;
