package NYU::Libraries::PDS::Views::Login;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(Template::Mustache);
$Template::Mustache::template_path = './templates';
sub template_namespace { 'NYU::Libraries::PDS::Views'; };

use constant DEFAULT_FOOTER => "BobCat.  Powered by Ex Libris Primo";

my $INSTITUTES = {
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
};

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

sub institute {
  my $self = shift;
  return $self->{'institute'};
}

sub calling_system {
  my $self = shift;
  return $self->{'calling_system'};
}

sub target_url {
  my $self = shift;
  return $self->{'target_url'};
}

sub session_id {
  my $self = shift;
  return $self->{'session_id'};
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
  my $institute = $self->{'institute'};
  return $INSTITUTES->{$institute}->{'breadcrumbs'};
}

sub application_title {
  return "Login";
}

sub bobcat_title {
  my $self = shift;
  return $self->bobcat;
}

sub institutional_stylesheet {
  my $self = shift;
  my $institute = $self->{'institute'};
  return "/assets/stylesheets/$institute.css";
}

sub footer {
  my $self = shift;
  my $institute = $self->{'institute'};
  return ($INSTITUTES->{$institute}->{'footer'} || DEFAULT_FOOTER);
  
}

1;
