#!/bin/bash

set -e

apachectl start

/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
