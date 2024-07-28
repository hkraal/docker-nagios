# Build nagios.
FROM debian:12

ENV NAGIOS_VERSION=4.5.3 \
    NAGIOS_PLUGINS_VERSION=2.4.10 \
    NAGIOS_NRPE_VERSION=4.1.0 \
    NAGIOS_NRDP_VERSION=2.0.5

RUN apt-get update && \
    apt-get install -y wget build-essential openssl libssl-dev unzip autoconf gcc libc6 libmcrypt-dev make bc gawk dc snmp libnet-snmp-perl gettext procps


# Build nagios.
WORKDIR /usr/src

RUN wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar zxf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagios-${NAGIOS_VERSION} && \
    ./configure && \
    make all && \
    useradd --system nagios && \
    make install install-init install-commandmode install-cgis install-config

# Build plugins.
WORKDIR /usr/src

RUN wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    tar zxf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} && \
    ./configure && \
    make && \
    make install

# Actual container.
FROM debian:12

ENV NAGIOS_USER=nagiosadmin \
    NAGIOS_PASSWORD=nagiosadmin

RUN apt-get update && \
    apt-get install -y vim apache2 php8.2 && \
    useradd --system nagios

COPY --from=0 /usr/src/nagios-*/sample-config/httpd.conf /etc/apache2/conf-available/nagios.conf

COPY --from=0 --chown=nagios:nagios /usr/local/nagios /usr/local/nagios

RUN a2enconf nagios && \
    a2enmod rewrite && \
    a2enmod cgi && \
    htpasswd -bc /usr/local/nagios/etc/htpasswd.users $NAGIOS_USER $NAGIOS_PASSWORD && \
    chgrp www-data /usr/local/nagios/var/rw/nagios.cmd

COPY bin/entrypoint.sh /

CMD ["/entrypoint.sh"]
