package JSON::Parse;
require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw/parse_json
		json_to_perl
		valid_json
		assert_valid_json
		validate_json
		json_file_to_perl/;

%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.31';
require XSLoader;
XSLoader::load (__PACKAGE__, $VERSION);

# Experimental, return a string of JSON as the error.

our $json_diagnostics;

# JSON literals all point to these. They're set to read-only within
# the XS.

our $true;
our $false;
our $null;

# Old names of subroutines.

sub json_to_perl
{
    goto &parse_json;
}

sub validate_json
{
    goto &assert_valid_json;
}

sub valid_json
{
    my ($json) = @_;
    if (! $json) {
	return 0;
    }
    eval {
	assert_valid_json (@_);
    };
    if ($@) {
	return 0;
    }
    return 1;
}

sub json_file_to_perl
{
    my ($file_name) = @_;
    my $json = '';
    open my $in, "<:encoding(utf8)", $file_name or croak $!;
    while (<$in>) {
	$json .= $_;
    }
    close $in or croak $!;
    return parse_json ($json);
}

1;
