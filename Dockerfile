# Setup build container.
FROM debian:12

ENV NAGIOS_VERSION=4.5.3 \
    NAGIOS_PLUGINS_VERSION=2.4.10 \
    NAGIOS_NRPE_VERSION=4.1.0 \
    NAGIOS_NRDP_VERSION=2.0.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget build-essential openssl libssl-dev unzip autoconf gcc libc6 libmcrypt-dev make bc gawk dc snmp libnet-snmp-perl gettext procps fping

WORKDIR /usr/src

# Build nagios.
RUN wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar zxf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagios-${NAGIOS_VERSION} && \
    ./configure && \
    make all && \
    useradd --system nagios && \
    make install install-init install-commandmode install-cgis install-config

# Build plugins.
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

COPY --from=0 /usr/src/nagios-*/sample-config/httpd.conf /etc/apache2/conf-available/nagios.conf

COPY --from=0 --chown=nagios:nagios /usr/local/nagios /usr/local/nagios

RUN apt-get update && \
    apt-get install -y --no-install-recommends vim apache2 php8.2 && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache /usr/share/doc/ && \
    useradd --system nagios && \
    a2enconf nagios && \
    a2enmod rewrite && \
    a2enmod cgi && \
    htpasswd -bc /usr/local/nagios/etc/htpasswd.users $NAGIOS_USER $NAGIOS_PASSWORD && \
    chgrp www-data /usr/local/nagios/var/rw

VOLUME ["/usr/local/nagios/var", "/usr/local/nagios/etc"]

COPY bin/entrypoint.sh /

CMD ["/entrypoint.sh"]
