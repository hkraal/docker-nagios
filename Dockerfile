# Setup build container.
FROM debian:12

ENV NAGIOS_VERSION=4.5.3 \
    NAGIOS_PLUGINS_VERSION=2.4.10 \
    NAGIOS_NRPE_VERSION=4.1.0 \
    NAGIOS_NRDP_VERSION=2.0.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget build-essential openssl libssl-dev unzip autoconf gcc libc6 libmcrypt-dev make bc gawk dc snmp libnet-snmp-perl gettext procps fping iputils-ping dnsutils

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

# Build nrpe.
RUN wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-${NAGIOS_NRPE_VERSION}/nrpe-${NAGIOS_NRPE_VERSION}.tar.gz && \
    tar zxf nrpe-${NAGIOS_NRPE_VERSION}.tar.gz && \
    cd nrpe-${NAGIOS_NRPE_VERSION}

RUN cd nrpe-${NAGIOS_NRPE_VERSION} && ./configure

RUN cd nrpe-${NAGIOS_NRPE_VERSION} && make nrpe

RUN cd nrpe-${NAGIOS_NRPE_VERSION} && make install-daemon

RUN cd nrpe-${NAGIOS_NRPE_VERSION} && make install-plugin

# Actual container.
FROM debian:12

ENV NAGIOS_USER=nagiosadmin \
    NAGIOS_PASSWORD=nagiosadmin

RUN apt-get update && \
    apt-get install -y --no-install-recommends vim apache2 php8.2 iputils-ping dnsutils python3 python3-pip python3-requests && \
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
