#!/bin/bash

set -e

apachectl start

chgrp www-data /usr/local/nagios/var/rw

setpriv --reuid=nagios --regid=nagios --init-groups /usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
