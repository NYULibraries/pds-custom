package NYU::Libraries::PDS::Views::Login;
use strict;
use warnings;

# Use our bundled Perl modules, e.g. Template::Mustache
use lib "vendor/lib";

use base qw(Template::Mustache);

# Specify the name of the template file that we're looking for
sub template_file { return 'login.mustache'; }

# Override Template::Mustache methods with our configurations
sub template_path {
  my $self = shift;
  my $institute = $self->institute_key;
  my $template_path = "templates/$institute";
  # Testing environment differs
  return ($ENV{'CI'}) ? "./$template_path" : 
    "/exlibris/primo/p3_1/pds/custom/$template_path";
}

sub template_namespace { 'NYU::Libraries::PDS::Views'; };

use constant DEFAULT_FORM_TITLE => 'Consortium & NYU Users without a NetID';
use constant DEFAULT_FORM_ACTION => '/pds';
use constant EZPROXY_FORM_ACTION => '/ezproxy';
use constant EZBORROW_FORM_ACTION => '/ezborrow';
use constant DEFAULT_USERNAME_LABEL => "Enter your ID Number";
use constant DEFAULT_USERNAME_PLACEHOLDER => "e.g. N12345678";
use constant DEFAULT_PASSWORD_LABEL => "Password or first four letters of your last name";
use constant DEFAULT_PASSWORD_PLACEHOLDER => "e.g. SMIT";
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
  'nyush' => {
    'footer' => 'NYU Division of Libraries.  BobCat.  Powered by Ex Libris Primo',
    'breadcrumbs' => {
      'parent' => {
        'display' => "NYU Libraries",
        'url' => "http://library.nyu.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/nyush" }}},
  'nyuad' => {
    'footer' => 'NYU Division of Libraries.  Powered by Ex Libris Primo',
    'breadcrumbs' => {
      'parent' => {
        'display' => "NYU Libraries",
        'url' => "http://library.nyu.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/nyuad" }}},
  'hsl' => {
    'breadcrumbs' => {
      'parent' => {
        'display' => "NYU Health Sciences Libraries",
        'url' => "http://hsl.med.nyu.edu/" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/hsl" }}},
  'cu' => {
    'breadcrumbs' => {
      'parent' => {
        'display' => "Cooper Union Library",
        'url' => "http://library.cooper.edu" },
      'bobcat' => {
        'display' => "BobCat",
        'url' => "http://bobcat.library.nyu.edu/cooper" }}},
  'ns' => {
    'form' => {
      'title' => 'Consortium or New School Patrons',
      'username' => {
        'label' => "Enter your NetID Username",
        'placeholder' => "e.g. ParsJ123"
      },
      'password' => {
        'label' => "Enter your NetID Password"
      }
    },
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
#   $self->$initialize($configurations, $controller)
my $initialize = sub {
  my($self, $conf, $controller) = @_;
  # Set configurations
  $self->{'conf'} = $conf;
  # Set controller
  $self->{'controller'} = $controller;
};

# Returns an new Login template
# Usage:
#   NYU::Libraries::PDS::Views::Login->new($configurations, $controller)
sub new {
  my($proto, @initialization_args) = @_;
  my $class = ref $proto || $proto;
  my $self = bless(Template::Mustache->new(), $class);
  # Initialize
  $self->$initialize(@initialization_args);
  # Return self
  return $self;
}

sub controller {
  my $self = shift;
  return $self->{'controller'};
}

sub institute_key {
  my $self = shift;
  return lc($self->controller->institute);
}

sub institute_key_uc {
  my $self = shift;
  return uc($self->institute_key);
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
  return $self->controller->calling_system;
}

sub self_url {
  my $self = shift;
  return ($self->controller->self_url || "");
}

sub target_url {
  my $self = shift;
  return ($self->controller->target_url || "");
}

sub session_id {
  my $self = shift;
  return ($self->controller->session_id || "");
}

sub current_url {
  my $self = shift;
  return $self->controller->current_url;
}

sub error {
  my $self = shift;
  return $self->controller->error;
}

sub is_ezproxy {
  my $self = shift;
  return ($self->calling_system eq "ezproxy");
}

sub is_ezborrow {
  my $self = shift;
  return ($self->calling_system eq "ezborrow");
}

sub is_form {
  my $self = shift;
  return (!$self->is_ezproxy);
}

sub is_shib {
  my $self = shift;
  return 1;
}

sub institutional_stylesheet {
  my $self = shift;
  my $institute_key = $self->institute_key;
  return "/assets/css/$institute_key.css";
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

sub form {
  my $self = shift;
  return ($self->institute->{'form'});
}

sub form_title {
  my $self = shift;
  return (defined($self->form) && $self->form->{'title'}) ? 
    ($self->form->{'title'}) : DEFAULT_FORM_TITLE;
}

sub form_action {
  my $self = shift;
  return DEFAULT_FORM_ACTION;
}

sub username {
  my $self = shift;
  return ($self->form->{'username'}) if defined($self->form);
}

sub username_label {
  my $self = shift;
  return ($self->username) ? 
    ($self->username->{'label'}) : DEFAULT_USERNAME_LABEL;
}

sub username_placeholder {
  my $self = shift;
  return ($self->username) ? 
    ($self->username->{'placeholder'}) : DEFAULT_USERNAME_PLACEHOLDER;
}

sub password {
  my $self = shift;
  return ($self->form->{'password'}) if defined($self->form);
}

sub password_label {
  my $self = shift;
  return ($self->password) ? 
    ($self->password->{'label'}) : DEFAULT_PASSWORD_LABEL;
}

sub password_placeholder {
  my $self = shift;
  return ($self->password) ? 
    ($self->password->{'placeholder'}) : DEFAULT_PASSWORD_PLACEHOLDER;
}

sub footer {
  my $self = shift;
  return ($self->institute->{'footer'} || DEFAULT_FOOTER);
}

1;
