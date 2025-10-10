#!/bin/bash

set -euo pipefail
trap 'echo "Error: $BASH_SOURCE:$LINENO $BASH_COMMAND" >&2' ERR

function show_usage(){
    echo "Usage: nmap-xml-to-json.sh [-h] [-s] [-g server] [-p port] [-u 'http://server/nmaps'] -i input.xml
Convert nmap xml report to json.
Reports can be sent to a json input on a graylog server.

-i : xml input file
-g : graylog server to send report to
-p : graylog port for json input
-u : URL prefix to access html reports from JSON
-s : print JSON to stdout
-h : this screen
"
}

XMLFILE=""
URLPREFIX=""

while getopts "hg:p:i:u:" flag; do
    case $flag in
        h)
            show_usage
            exit 0
            ;;
        g)
            GLSRV="$OPTARG"
            ;;
        p)
            GLPRT="$OPTARG"
            ;;
        i)
            XMLFILE="$OPTARG"
            ;;
        u)
            URLPREFIX="$OPTARG"
            ;;
        \?)
            # invalid option
            exit 1;
            ;;
    esac
done

if [ "$XMLFILE" == "" ] || [ ! -e "$XMLFILE" ]; then
    echo "Error, no xml input file".
    exit 1
fi

TMPFILE="/tmp/xmltojson-`date +%s`.json"
OUTFILE="/tmp/outfile-`date +%s`.json"

# xml to json
cat "$XMLFILE" | perl -MXML::Simple -MJSON -e 'print encode_json XMLin q{-}' > $TMPFILE

# get scan and target details
details=(`jq -r '.host.address.addr, .host.hostnames.hostname.name' $TMPFILE`)

# set html report url
URL="n/a"
if [ "$URLPREFIX" != "" ]; then
    HTMLFILE=`basename $XMLFILE|sed 's/xml/html/'`
    URL="$URLPREFIX/$HTMLFILE"
fi

# create json output file
cat $TMPFILE |jq '.host.ports.port' |jq --arg Address "${details[0]}" --arg Hostname "${details[1]}" --arg URL "$URL" 'map({Address:$Address, Hostname:$Hostname, URL:$URL, PortId:.portid, Service:.service.name, Protocol:.protocol, State:.state.state, Reason:.state.reason})' > $OUTFILE

# echo to stdout
cat $OUTFILE | jq -c '.[]'

# send to graylog
if [ "$GLSRV" != "" ] && [ "$GLPRT" != "" ]; then
    # send to graylog
    cat $OUTFILE | jq -c '.[]' | nc -q 1 $GLSRV $GLPRT
fi

rm -f $TMPFILE
rm -f $OUTFILE
