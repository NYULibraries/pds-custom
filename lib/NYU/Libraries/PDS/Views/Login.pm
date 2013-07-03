package NYU::Libraries::PDS::Views::Login;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(Template::Mustache);

# Specify the name of the template file that we're looking for
$Template::Mustache::template_file = 'login.mustache';

# Override Template::Mustache methods with our configurations
sub template_path {
  my $self = shift;
  my $institute = $self->institute_key;
  my $template_path = "templates/$institute";
  return ($ENV{'CI'}) ? "./$template_path" : 
    "/exlibris/primo/p3_1/pds/custom/$template_path";
}

sub template_namespace { 'NYU::Libraries::PDS::Views'; };

use constant DEFAULT_FOOTER => "BobCat.  Powered by Ex Libris Primo";

my %INSTITUTES = (
  'nyu' => {
    'footer' => 'NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo',
    'breadcrumbs' => {
      'parent' => {
        'display' => "NYU Libraries",
        'url' => "http://library.nyu.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu" }}},
  'nyuad' => {
    'footer' => 'NYU Division of Libraries.  Powered by Ex Libris Primo',
    'breadcrumbs' => {
      'parent' => {
        'display' => "NYU Libraries",
        'url' => "http://library.nyu.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/nyuad" }}},
  'cu' => {
    'breadcrumbs' => {
      'parent' => {
        'display' => "Cooper Union Library",
        'url' => "http://library.cooper.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/cooper" }}},
  'ns' => {
    'breadcrumbs' => {
      'parent' => {
        'display' => "New School University Libraries",
        'url' => "http://library.newschool.edu/" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/newschool" }}},
  'nysid' => {
    'breadcrumbs' => {
      'parent' => {
        'display' => "New York School of Interior Design Library",
        'url' => "http://nysidlibrary.org/" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/nysid" }}}
);

# Private initialization method
# Usage:
#   $self->$initialize(configurations, institute, calling_system, target_url, session_id)
my $initialize = sub {
  my($self, $conf, $institute, $calling_system, $target_url, $session_id) = @_;
  # Set configurations
  $self->{'conf'} = $conf;
  # Set institute
  $self->{'institute'} = $institute;
  # Set calling_system
  $self->{'calling_system'} = $calling_system;
  # Set target_url
  $self->{'target_url'} = $target_url;
  # Set session_id
  $self->{'session_id'} = $session_id;
};

# Returns an new SessionsController
# Usage:
#   NYU::Libraries::PDS::Controllers::SessionsController->new(configurations, institute, calling_system, target_url, session_id)
sub new {
  my($proto, @initialization_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Template::Mustache->new(), $class);
  # Initialize
  $self->$initialize(@initialization_args);
  # Return self
  return $self;
}

sub institute_key {
  my $self = shift;
  return lc($self->{'institute'});
}

sub institutes {
  return \%INSTITUTES;
}

sub institute {
  my $self = shift;
  return $self->institutes->{$self->institute_key};
}

sub calling_system {
  my $self = shift;
  return $self->{'calling_system'};
}

sub self_url {
  my $self = shift;
  return ($self->{'self_url'} || "");
}

sub target_url {
  my $self = shift;
  return ($self->{'target_url'} || "");
}

sub session_id {
  my $self = shift;
  return ($self->{'session_id'} || "");
}

sub institutional_stylesheet {
  my $self = shift;
  my $institute_key = $self->institute_key;
  return "/assets/stylesheets/$institute_key.css";
}

sub parent {
  my $self = shift;
  return $self->breadcrumbs->{'parent'}->{'display'};
}

sub parent_url {
  my $self = shift;
  return $self->breadcrumbs->{'parent'}->{'url'};
}

sub bobcat {
  my $self = shift;
  return $self->breadcrumbs->{'bobcat'}->{'display'};
}

sub bobcat_url {
  my $self = shift;
  return $self->breadcrumbs->{'bobcat'}->{'url'};
}

sub breadcrumbs {
  my $self = shift;
  return $self->institute->{'breadcrumbs'};
}

sub application_title {
  return "Login";
}

sub bobcat_title {
  my $self = shift;
  return $self->bobcat;
}

sub footer {
  my $self = shift;
  return ($self->institute->{'footer'} || DEFAULT_FOOTER);
}

1;
