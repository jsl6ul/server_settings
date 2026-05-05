#!/bin/bash

TMPFILE=/tmp/.trivy.report.$USER.$RANDOM.json

function show_usage(){
    echo "Usage: trivy-scan.sh (-i <image> | -f path | -r path) [-s '/dir1 /dir2'] [-t https://trivy.example.com -k abc123] [-g graylog.example.com -p port] [-w duration] [-c /path/cache] [-u (os|library)]

This script uses trivy in client-server mode, to scan and report on
HIGH & CRITICAL vulnerabilities.  If defined, the report will be sent
to a graylog server, otherwise the report will be printed to the
standard output.

-i : scan the given container image
-f : scan the given filesystem path
-r : scan the rootfs

-u : subset of package types
     os: scan packages managed by the OS package manager like dpkg, yum, apk.
     library: scan language-specific packages installed by pip, npm, or gem.

-s : exclude specific directories when scanning a root filesystem

-t : trivy server url
-k : trivy server token

-g : graylog server address
-p : graylog port

-w : trivy scan timeout (default 5m0s)

-c : cache directory (default ~/.cache/trivy)

This script requires: jq, and netcat to send report to graylog.
"
}

# default timeout
TMOUT=5m0s
SKIPDIRS=""
CACHE_DIR=""
FULLPKGTYPES=""
PKGTYPES=""

while getopts "hi:f:r:g:p:t:k:w:s:c:u:" flag; do
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
        s)
            for p in $OPTARG; do
                SKIPDIRS="$SKIPDIRS --skip-dirs \"$p\""
            done
            ;;
        w)
            TMOUT="$OPTARG"
            ;;
        c)
            CACHE_DIR="$OPTARG"
            ;;
        u)
            FULLPKGTYPES="--pkg-types $OPTARG"
            PKGTYPES="$OPTARG"
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

CACHE_ARGS=""
if [ "$CACHE_DIR" != "" ]; then
    if [ ! -d "$CACHE_DIR" ]; then
        echo "No such directory $CACHE_DIR"
        exit 1
    fi
    CACHE_ARGS="--cache-dir $CACHE_DIR"
fi

# scan
if [ "$TVSRV" == "" ]; then
    trivy $CACHE_ARGS --severity HIGH,CRITICAL -f json --scanners vuln --timeout $TMOUT $SKIPDIRS $FULLPKGTYPES $MODE $TARGET > $TMPFILE
else
    trivy $CACHE_ARGS --server $TVSRV --token $TVTKN --severity HIGH,CRITICAL -f json --scanners vuln --timeout $TMOUT $SKIPDIRS $FULLPKGTYPES $MODE $TARGET > $TMPFILE
fi

if [ $? == 0 ]; then
    json_results=`cat $TMPFILE|jq '.Results'`
    echo "$json_results"|grep -q Vulnerabilities
    if [ $? == 0 ]; then
        if [ "$GLSRV" != "" ]; then
            # send to graylog
            # the last jq replaces the array of elements with several elements (one per line)
            echo "$json_results"|jq -c '.[].Vulnerabilities' |jq -c --arg TG "$TARGET" --arg MD "$MODE" --arg HN "$HOSTNAME" --arg PKGTYPES "$PKGTYPES" 'map({Target:$TG, Type:$MD, Host:$HN, PkgType:$PKGTYPES, CVE:.VulnerabilityID, PkgName:.PkgName, PkgInstVer:.InstalledVersion, PkgFixVer:.FixedVersion, Status:.Status, URL:.PrimaryURL, Title:.Title, Severity:.Severity, PubDate:.PublishedDate, LastUpdate:.LastModifiedDate})' | jq -c '.[]' | nc -q 1 $GLSRV $GLPRT
        else
            # print to stdout
            echo "$json_results"|jq '.[].Vulnerabilities' |jq --arg TG "$TARGET" --arg MD "$MODE" --arg HN "$HOSTNAME" --arg PKGTYPES "$PKGTYPES" 'map({Target:$TG, Type:$MD, Host:$HN, PkgType:$PKGTYPES, CVE:.VulnerabilityID, PkgName:.PkgName, PkgInstVer:.InstalledVersion, PkgFixVer:.FixedVersion, Status:.Status, URL:.PrimaryURL, Title:.Title, Severity:.Severity, PubDate:.PublishedDate, LastUpdate:.LastModifiedDate})'
        fi
    fi
fi

rm -f $TMPFILE
