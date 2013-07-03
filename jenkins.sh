#!/usr/bin/env bash

# Add PDS core libraries.
# Remove pds-core if it's there
if [ -d "vendor/pds-core" ]; then
  rm -r vendor/pds-core;
fi
# Clone it (again)
cd vendor && git clone git@github.com:NYULibraries/pds.git pds-core;
# Use the dev branch
cd pds-core && git checkout sp-3.1.4-120726-development;
# Get out of there
cd ../../;

# Use perlbrew version of perl-5.8.9
source ~/perl5/perlbrew/etc/bashrc && perlbrew use perl-5.8.9;
# Make sure dependencies are installed
perl -Ivendor/pds-core/program Build.pl && ./Build installdeps
# TAP results to results directory
mkdir -p results && prove -l -Ivendor/pds-core/program -a results t;
# Devel::Cover coverage report
./Build testcover && cover;
