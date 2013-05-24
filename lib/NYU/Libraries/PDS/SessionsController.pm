package NYU::Libraries::PDS::SessionsController;
use strict;
use warnings;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(pds_handle institute));

1;
