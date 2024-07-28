#!/bin/bash

set -e

apachectl start

mkdir -p /usr/local/nagios/var/rw /usr/local/nagios/var/spool

chgrp www-data /usr/local/nagios/var/rw

/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
