# NmapScanner

Simple scripts for scanning networks and generating results in various file formats.

# Graylog

The report script use `jq` and can use `netcat` to send the json report to a [graylog](https://graylog.org/) server.

Add a raw input to graylog with a json extractor. [how to set them up](https://graylog.org/videos/json-extractor/)

# Usage

- Scan: `/usr/local/bin/nmap-scan.sh -t 192.168.1.0/24 -o /opt/nmaps -w /var/www/html/nmaps`
- Report: `find /opt/nmaps/ -name '*.xml' -mtime 0 -exec /usr/local/bin/nmap-xml-to-json.sh -g graylog -p 5556 -u 'http://ipaddr/nmaps' -i {} \;`
