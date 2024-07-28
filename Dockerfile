# Build nagios.
FROM debian:12

ENV NAGIOS_VERSION=4.5.3

RUN apt-get update && \
    apt-get install -y wget build-essential openssl libssl-dev unzip

WORKDIR /usr/src

RUN wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar zxf nagios-${NAGIOS_VERSION}.tar.gz

WORKDIR /usr/src/nagios-${NAGIOS_VERSION}

RUN ./configure

RUN make all

RUN useradd --system nagios

RUN make install install-init install-commandmode install-cgis install-config

# Actual container.
FROM debian:12

RUN apt-get update && \
    apt-get install -y vim apache2 php8.2 

COPY --from=0 /usr/src/nagios-*/sample-config/httpd.conf /etc/apache2/conf-available/nagios.conf

RUN useradd --system nagios && \
    a2enconf nagios


COPY --from=0 --chown=nagios:nagios /usr/local/nagios /usr/local/nagios
