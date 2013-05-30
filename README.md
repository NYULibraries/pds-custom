# NYU PDS Perl Modules

The NYU PDS Perl Modules are a set of libraries, written in Perl, that facilitate customized functionality for NYU's PDS implementation.

## Testing
NYU PDS Perl Modules uses the [Test Anything Protocol](http://testanything.org/) as the testing framework for its 
continuous integration implementation.

Since Ex Libris bundles its perl version with PDS, we use [perlbrew](http://perlbrew.pl/) to simulate the PDS environment.
We use `perl v5.8.9` because that's what PDS reports using.

    primo@primo1(p3_1):~/p3_1/primom$perl -v
    This is perl, v5.8.9 built for i686-linux

### Dependencies
Since most software is built on the shoulders of giants and all good programmers should leverage that which has come before, 
our libraries have many dependencies which cause the testing environment and the actual PDS environments to differ.

These dependencies, have dependencies of there own, which introduces yet more variation between the environments,
but that is a rabbit hole left to braver souls.

[This sucks](http://en.wikipedia.org/wiki/Dependency_hell), but we can't think of a cleaner way of doing it.
Maybe [vagrant](http://www.vagrantup.com/) and 
[the Jenkin's VirtualBox plugin](https://wiki.jenkins-ci.org/display/JENKINS/VirtualBox+Plugin) can help at some point.

#### Build Dependencies
There are two dependencies for building our testing environment:

1. `Module::Build (v0.4005)`
2. `YAML(v0.84)`

#### Library Bundled Dependencies
Since we use PDS' bundled perl and want to keep it in its original state,
we bundle `Class::Accessor` with this package in the `vendor/lib` directory.

#### Testing Modules
In order to run our tests, we use four testing modules

1. `Test::More (v0.98)`
2. `Devel::Cover (v1.03)`
3. `Test::Harness (v3.28)`
4. `TAP::Harness::Archive (v0.15)`


#### PDS Dependencies
PDS' Perl comes bundled with several perl module dependencies.
Some of these are out of date.
We use the latest version (as of the time of writing) and cross our fingers.

The direct dependencies, with their versions are listed below.
This list is **incomplete**.

| Dependency         | PDS Version | Testing Version |
|:------------------ | -----------:| ---------------:|
| `XML::Simple`      |        2.18 |            2.20 |
| `CGI::Session`     |        4.42 |            4.48 |
| `DBI`              |       1.609 |           1.627 |
| `Unicode::MapUTF8` |        1.11 |            1.11 |
| `HTML::TagFilter`  |        1.03 |            1.03 |
