#!/bin/bash

TMPFILE=/tmp/.trivy.report.$USER.$RANDOM.json

function show_usage(){
    echo "Usage: trivy-scan.sh (-i <image> | -f path | -r path) [-t https://trivy.example.com -k abc123] [-g graylog.example.com -p port] [-w duration]

This script uses trivy, in client-server mode, to scan and report on HIGH & CRITICAL vulnerabilities.
If defined, the report will be sent to a graylog server, otherwise the report will be printed to the standard output.

-i : scan the given container image
-f : scan the given filesystem path
-r : scan the rootfs

-t : trivy server url
-k : trivy server token

-g : graylog server address
-p : graylog port

-w : trivy scan timeout (default 5m0s)

This script requires: jq, and netcat to send report to graylog.
"
}

# default timeout
TMOUT=5m0s

while getopts "hi:f:r:g:p:t:k:w:" flag; do
    case $flag in
        h)
            show_usage
            exit 0
            ;;
        i)
            MODE="image"
            TARGET="$OPTARG"
            ;;
        f)
            MODE="filesystem"
            TARGET="$OPTARG"
            ;;
        r)
            MODE="rootfs"
            TARGET="$OPTARG"
            ;;
        t)
            TVSRV="$OPTARG"
            ;;
        k)
            TVTKN="$OPTARG"
            ;;
        g)
            GLSRV="$OPTARG"
            ;;
        p)
            GLPRT="$OPTARG"
            ;;
        w)
            TMOUT="$OPTARG"
            ;;
        \?)
            # invalid option
            exit 1;
            ;;
    esac
done

if [ "$MODE" == "image" ] && [ "$TARGET" = "" ]; then
    echo "Error, container image undefined."
    exit 1;
elif [ "$MODE" == "filesystem" ] && [ "$TARGET" = "" ]; then
    echo "Error, filesystem path undefined."
    exit 1;
elif [ "$MODE" == "" ]; then
    echo "Error, missing parameters."
    show_usage
    exit 1;
fi

which jq > /dev/null
if [ $? -ne 0 ]; then
    echo "Error, can't find 'jq'."
    exit 1;
fi

which trivy > /dev/null
if [ $? -ne 0 ]; then
    echo "Error, can't find 'trivy'."
    exit 1;
fi

if [ "$GLSRV" != "" ]; then
    if [ "$GLPRT" == "" ]; then
        echo "Error, port undefined, required for graylog."
        exit 1;
    fi
    which nc > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error, can't find 'nc', required for graylog."
        exit 1;
    fi
fi


# scan
if [ "$TVSRV" == "" ]; then
    trivy --severity HIGH,CRITICAL -f json --scanners vuln --timeout $TMOUT $MODE $TARGET > $TMPFILE
else
    trivy --server $TVSRV --token $TVTKN --severity HIGH,CRITICAL -f json --scanners vuln --timeout $TMOUT $MODE $TARGET > $TMPFILE
fi

if [ $? == 0 ]; then
    if [ "$GLSRV" != "" ]; then
        # send to graylog
        # the last jq replaces the array of elements with several elements (one per line)
        cat $TMPFILE |jq -c '.Results'|jq -c '.[].Vulnerabilities' |jq -c --arg TG "$TARGET" --arg MD "$MODE" --arg HN "$HOSTNAME" 'map({Target:$TG, Type:$MD, Host:$HN, CVE:.VulnerabilityID, PkgName:.PkgName, PkgInstVer:.InstalledVersion, PkgFixVer:.FixedVersion, Status:.Status, URL:.PrimaryURL, Title:.Title, Severity:.Severity, PubDate:.PublishedDate, LastUpdate:.LastModifiedDate})' | jq -c '.[]' | nc -q 1 $GLSRV $GLPRT
    else
        # print to stdout
        cat $TMPFILE |jq '.Results'|jq '.[].Vulnerabilities' |jq --arg TG "$TARGET" --arg MD "$MODE" --arg HN "$HOSTNAME" 'map({Target:$TG, Type:$MD, Host:$HN, CVE:.VulnerabilityID, PkgName:.PkgName, PkgInstVer:.InstalledVersion, PkgFixVer:.FixedVersion, Status:.Status, URL:.PrimaryURL, Title:.Title, Severity:.Severity, PubDate:.PublishedDate, LastUpdate:.LastModifiedDate})'
    fi
fi

rm -f $TMPFILE
