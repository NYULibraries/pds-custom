package NYU::Libraries::PDS::Models::ShibbolethSession;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Class::Accessor
use lib "vendor/lib";

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement));

1;
