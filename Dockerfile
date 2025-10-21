# Setup build container.
FROM debian:12@sha256:26f2a7cab45014541c65f9d140ccfa6aaefbb49686c6759bea9c6f7f5bb3d72f

# renovate: datasource=github-tags packageName=NagiosEnterprises/nagioscore
ENV NAGIOS_VERSION=4.5.9
# renovate: datasource=github-tags packageName=nagios-plugins/nagios-plugins
ENV NAGIOS_PLUGINS_VERSION=2.4.12
# renovate: datasource=github-tags packageName=NagiosEnterprises/nrpe
ENV NAGIOS_NRPE_VERSION=4.1.3

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget build-essential openssl libssl-dev unzip autoconf gcc libc6 libmcrypt-dev make bc gawk dc snmp libnet-snmp-perl gettext procps fping iputils-ping dnsutils

WORKDIR /usr/src

# Build nagios.
RUN wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar zxf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagios-${NAGIOS_VERSION} && \
    ./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/*-linux-gnu/ && \
    make all && \
    useradd --system nagios && \
    make install install-init install-commandmode install-cgis install-config

# Build plugins.
RUN wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    tar zxf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} && \
    ./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/*-linux-gnu/ && \
    make && \
    make install

# Build nrpe.
RUN wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-${NAGIOS_NRPE_VERSION}/nrpe-${NAGIOS_NRPE_VERSION}.tar.gz && \
    tar zxf nrpe-${NAGIOS_NRPE_VERSION}.tar.gz && \
    cd nrpe-${NAGIOS_NRPE_VERSION} && \
    ./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/*-linux-gnu/ && \
    make nrpe && \
    make install-daemon && \
    make install-plugin

# Actual container.
FROM debian:12@sha256:26f2a7cab45014541c65f9d140ccfa6aaefbb49686c6759bea9c6f7f5bb3d72f

ENV NAGIOS_USER=nagiosadmin \
    NAGIOS_PASSWORD=nagiosadmin

RUN apt-get update && \
    apt-get install -y --no-install-recommends vim apache2 php8.2 iputils-ping dnsutils python3 python3-pip python3-requests mailutils curl && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache /usr/share/doc/ && \
    useradd --system nagios

COPY --from=0 /usr/src/nagios-*/sample-config/httpd.conf /etc/apache2/conf-available/nagios.conf

COPY --from=0 --chown=nagios:nagios /usr/local/nagios /usr/local/nagios

RUN a2enconf nagios && \
    a2enmod rewrite && \
    a2enmod cgi

VOLUME ["/usr/local/nagios/var", "/usr/local/nagios/etc"]

COPY plugins/* /usr/local/nagios/libexec/

COPY bin/entrypoint.sh /

CMD ["/entrypoint.sh"]
