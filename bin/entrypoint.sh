#!/bin/bash

set -e

apachectl start

chgrp www-data /usr/local/nagios/var/rw

htpasswd -bc /usr/local/nagios/etc/htpasswd.users $NAGIOS_USER $NAGIOS_PASSWORD

/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
