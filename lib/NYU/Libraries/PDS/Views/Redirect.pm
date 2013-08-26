package NYU::Libraries::PDS::Views::Redirect;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(NYU::Libraries::PDS::Views::Login);

# Specify the name of the template file that we're looking for
sub template_file { return 'redirect.mustache'; }

# Override Template::Mustache methods with our configurations
sub template_path {
  my $self = shift;
  my $institute = $self->institute_key;
  my $template_path = "templates/";
  # Testing environment differs
  return ($ENV{'CI'}) ? "./$template_path" : 
    "/exlibris/primo/p3_1/pds/custom/$template_path";
}

sub target_url {
  my $self = shift;
  return $self->{target_url};
}

1;
