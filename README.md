# kea-dhcp-logformat-to-isc

The purpose of this simple script is to convert kea dhcp log output into the more familiar ISC DHCPD type formatting that makes it easier to see output.

Simply clone this repo, then parse your log through it like this:

tail -F /var/log/kea-dhcpd.log | dhcpd_logprocess.sh

Configuration for kea-dhcp is like this:

```
       "loggers": [
            {
                "name": "kea-dhcp4.packets",
                "severity": "DEBUG",
                "debuglevel": 99,
                "output_options": [
                    {
                        "output": "/kea/logs/dhcp4.log",
                        // This specifies the maximum size of the file before
                        // it is rotated.
                        "maxsize": 1048576,
                        // This specifies the maximum number of rotated files
                        // to keep.
                        "maxver": 8,
                        // We use pattern to specify custom log message layout.
                        "pattern": "%D{%Y-%m-%d %H:%M:%S.%q} %-5p [%c/%i.%t] %m\n"
                    }
                ]
            },
            {
                "name": "kea-dhcp4.leases",
                "severity": "DEBUG",
                "debuglevel": 50,
                "output_options": [
                    {
                        "output": "/kea/logs/dhcp4.log",
                        // This specifies the maximum size of the file before
                        // it is rotated.
                        "maxsize": 1048576,
                        // This specifies the maximum number of rotated files
                        // to keep.
                        "maxver": 8,
                        // We use pattern to specify custom log message layout.
                        "pattern": "%D{%Y-%m-%d %H:%M:%S.%q} %-5p [%c/%i.%t] %m\n"
                    }
                ]
            }
        ]
```

# Example of new output:

```
2026-04-20 16:04:13.870 DHCPREQUEST for 192.168.1.215 from 84:15:31:00:00:38 (unknown)
2026-04-20 16:04:13.870 DHCPACK on 192.168.1.215 to 84:15:31:00:00:38 (unknown) requested 192.168.1.215 lease 6000s
2026-04-20 16:04:41.487 DHCPREQUEST for 192.168.1.184 from b8:14:eb:08:55:55 (unknown)
2026-04-20 16:04:41.487 DHCPACK on 192.168.1.184 to b8:14:eb:08:55:55 (unknown) requested 192.168.1.184 lease 6000s
```