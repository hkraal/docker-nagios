# Build nagios.
FROM debian:12

ENV NAGIOS_VERSION=4.4.14

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

# # Actual container.
# FROM httpd:2.4-bookworm

# RUN useradd --system nagios

# COPY --from=0 /usr/local/nagios /usr/local/nagios 