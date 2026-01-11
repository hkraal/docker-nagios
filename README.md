# Nagios

Builds a docker image with Nagios, default plugins and NRPE.

# Kubernetes caveats

### Force FQDN lookups

If DNS lookups fail, make sure your `check_dns` has a trailing dot for the hostname to prevent local lookups.

```
/usr/bin/nslookup example.com 1.2.3.4
Server:		1.2.3.4
Address:	1.2.3.4#53

** server can't find example.com.nagios.svc.cluster.local: REFUSED
```
