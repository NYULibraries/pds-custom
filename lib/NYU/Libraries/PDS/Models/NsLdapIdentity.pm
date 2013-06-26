package NYU::Libraries::PDS::Models::NsLdapIdentity;

use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(id));

1;
