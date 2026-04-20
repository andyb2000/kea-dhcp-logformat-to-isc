# kea-dhcp-logformat-to-isc

The purpose of this simple script is to convert kea dhcp log output into the more familiar ISC DHCPD type formatting that makes it easier to see output.

Simply clone this repo, then parse your log through it like this:

tail -F /var/log/kea-dhcpd.log | dhcpd_logprocess.sh
