# Trivy

A role to install [Trivy](https://aquasecurity.github.io/trivy/) comprehensive and versatile security scanner.

Support for Debian and RedHat families.

# Trivy & Graylog

The report script use `jq` and can use `netcat` to send the json report to a [graylog](https://graylog.org/) server.

Add a raw input to graylog and a json extractor to this input. [how to set them up](https://graylog.org/videos/json-extractor/)

# Usage

`/usr/local/bin/trivy-scan.sh -r / -t https://trivy.example.com -k abc123 -g graylog.example.com -p 5555`

```
for img in `docker ps|tail -n +2|awk '{print $2}'`; do 
  /usr/local/bin/trivy-scan.sh -t https://trivy.example.com -k abc123 -i $img
done
```
