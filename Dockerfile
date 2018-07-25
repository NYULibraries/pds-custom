FROM perl:5.8.9

ENV INSTALL_PATH /app
ENV CONFIG_BASEPATH $INSTALL_PATH/vendor/pds-core/
ENV PERL_MM_USE_DEFAULT 1

WORKDIR $INSTALL_PATH

RUN apt-get update -qq && apt-get install -y \
      vim

RUN cpan Module::Build

COPY ./vendor/pds-core/program ./vendor/pds-core/program
COPY Build.pl Build.pl
#COPY ./lib ./lib

RUN perl -Ivendor/pds-core/program Build.pl && ./Build installdeps

COPY . .

RUN rm -rf results && mkdir -p results

CMD prove -l -Ivendor/pds-core/program -a results t && \
    ./Build testcover && cover

    RUN cpanm Carton \
        && mkdir -p /usr/src/app
    WORKDIR /usr/src/app

    ONBUILD COPY cpanfile* /usr/src/myapp
    ONBUILD RUN carton install

    ONBUILD COPY . /usr/src/app
