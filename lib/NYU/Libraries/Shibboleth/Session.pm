package NYU::Libraries::Shibboleth::Session;
use strict;
use warnings;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(id index authentication_instance authentication_method context_class identity_provider nyuidn uid givenname mail cn sn edupersonentitlement));

1;
