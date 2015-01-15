# siteWideADprobe
Bash tool that reads AD DCs from SRV records in AD, then if it can ping the record, probes the DNS, LDAP, and DHCP ports using netcat. Tested on OS X.

# Usage
./siteWideADprobe [fqdn] to target a specific domain, or run without to attempt to read the domain from /etc/resolv.conf.
