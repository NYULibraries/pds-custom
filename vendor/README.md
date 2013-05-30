# `vendor`
Directory for including bundled Perl modules

    vendor/lib

and for cloning testing instance of PDS core libraries

    vendor/pds-core

To test with prove

    $ prove -l -Ivendor/pds-core/program t

To test with Build.PL

    $ perl -Ivendor/pds-core/program Build.pl