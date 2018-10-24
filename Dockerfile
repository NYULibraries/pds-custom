FROM perl:5.16.3

ENV INSTALL_PATH /app
ENV CONFIG_BASEPATH $INSTALL_PATH/vendor/pds-core/
ENV PERL_MM_USE_DEFAULT 1
ENV PERL5LIB $INSTALL_PATH/local/lib/perl5:$INSTALL_PATH/vendor/pds-core/program:$PERL5LIB

WORKDIR $INSTALL_PATH

RUN apt-get update -qq && apt-get install -y \
      vim

RUN cpanm Carton

COPY cpanfile* .
RUN carton install

COPY . .

RUN rm -rf results && mkdir -p results

CMD prove -l
# -a results t
