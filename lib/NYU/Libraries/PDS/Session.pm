package NYU::Libraries::PDS::Session;
use strict;
use warnings;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(pds_handle));

1;
