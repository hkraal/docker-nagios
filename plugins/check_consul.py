#!/usr/bin/env python3
import requests
import sys

def check_services(hostname):
    exit_code = 0
    total_count = 0
    passing_count = 0
    critical = []
    warning = []

    try:
        services = requests.get(f'https://{hostname}/v1/internal/ui/services').json()
    except:
        print('Failed to connect to Consul')
        sys.exit(2)

    for s in services:
#        if not s['Tags'] or 'live' not in s['Tags'] or 'canary' in s['Tags']:
#            continue

        health = requests.get(f'https://{hostname}/v1/health/service/%s' % s['Name']).json()
        total_count += s['ChecksCritical'] + s['ChecksPassing'] + s['ChecksWarning']
        passing_count += s['ChecksPassing']

        service_passing = False

        for alloc in health:
            if 'Checks' not in alloc:
                continue
            alloc_passing = True
            for check in alloc['Checks']:
                if check['Status'] != 'passing':
                    alloc_passing = False

            if alloc_passing:
                service_passing = True

        if not service_passing:
            critical.append(s['Name'])
        elif s['ChecksCritical'] > 0 or s['ChecksWarning'] > 0:
            warning.append(s['Name'])

    msg = '%s/%s passing' % (passing_count, total_count)

    if len(warning) > 0:
        msg = 'WARNING: %s, %s' % (','.join(warning), msg)
        exit_code = 1

    if len(critical) > 0:
        msg = 'CRITICAL: %s, %s' % (','.join(critical), msg)
        exit_code = 2

    if exit_code == 0:
        msg = 'OK: %s' % (msg)

    print(msg)
    sys.exit(exit_code)


if __name__ == '__main__':
    check_services(hostname=sys.argv[1])
