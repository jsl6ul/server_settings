#!/bin/bash

set -euo pipefail
trap 'echo "Error: $BASH_SOURCE:$LINENO $BASH_COMMAND" >&2' ERR

function show_usage(){
    echo "nmap-scan.sh -t target [-m mode] [-p ports] [-e 'extra switches'] [-o directory] [-w directory] [-h]
Nmap network scan.

  -t  Target (Can pass hostnames, IP addresses, networks)
  -m  Mode
      std    - scans the most common 1,000 ports (default)
      fast   - top 100 ports
      full   - all TCP ports (1-65535)
      custom - user-defined list
  -p  Custom ports (-p 22,80,443)
  -e  Extra Nmap switches (-e '-sV -O -A --script=vulners --min-rate=500')
  -o  Output directory (default to ./nmaps)
  -w  Directory for html report (required xsltproc)
  -h  This screen

Some extra Nmap switches:
  -sV               # service/version detection
  -O                # OS detection (requires root)
  -A                # enable NSE scripts, traceroute, etc.
  --script=vulners  # pull CVE info (needs vulners script)
  --script=default  # scan using the default set of scripts. (be careful, intrusive scripts)
  --min-rate=500    # speed-up host discovery (adjust for network)
  -T4 or -T5        # Faster scans (be careful on congested networks).
  -sU -p U:53,161   # UDP coverage for custom ports
  -sU -p-           # UDP coverage for all UDP ports - very slow.
  --max-rate=200    # Rate-limit to avoid IDS alarms instead of --min-rate.
  see the man page for more options and examples

Save only open ports
  After the run, grep the .gnmap files: grep '/open/' *.gnmap > open-ports-summary.txt.
"
}

__target=""
__scan_mode="std"
__custom_ports=""
__extra_opts=""
__output_dir="./nmaps"
__html_dir=""

while getopts "e:hm:o:p:t:w:" flag; do
    case $flag in
        e)
            __extra_opts="$OPTARG"
            ;;
        h)
            show_usage
            exit 1
            ;;
        m)
            __scan_mode="$OPTARG"
            ;;
        o)
            __output_dir="$OPTARG"
            ;;
        p)
            __custom_ports="$OPTARG"
            ;;
        t)
            __target="$OPTARG"
            ;;
        w)
            __html_dir="$OPTARG"
            ;;
        \?)
            show_usage
            exit 1;
            ;;
    esac
done

if [ "$__scan_mode" == "custom" ] && [ "$__custom_ports" == "" ]; then
    echo "Error, custom mode required custom port(s)."
    exit 1
fi

if [ "$__target" == "" ]; then
    echo "Error, target must be defined."
    exit 1
fi

if [ "$__html_dir" != "" ]; then
    if [ ! -d "$__html_dir" ]; then
        echo "Error, no directory named $__html_dir"
        exit 1
    elif [ ! -w "$__html_dir" ]; then
        echo "Error, no write access to $__html_dir"
        exit 1
    fi
    which xsltproc >/dev/null
fi

# ------------------------------------------------------------------
# INTERNAL VARIABLES - you normally don’t touch these
# ------------------------------------------------------------------
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
HOSTLIST="${__output_dir}/live-hosts-${TIMESTAMP}.txt"
SCAN_LOG="${__output_dir}/scan-${TIMESTAMP}.log"

# ------------------------------------------------------------------
# Helper: build the port argument string based on SCAN_MODE
# ------------------------------------------------------------------
build_port_arg() {
    case "$__scan_mode" in
        std)    echo "" ;;                       # the most common 1,000 ports
        fast)   echo "-F" ;;                     # top 100 ports (fast)
        full)   echo "-p-" ;;                    # all TCP ports (1-65535)
        custom) echo "-p${__custom_ports}" ;;    # user-defined list
        *)      echo "" ;;                       # fallback to std
    esac
}

PORT_ARG=$(build_port_arg)

# ------------------------------------------------------------------
# Step 0 - prepare output folder
# ------------------------------------------------------------------
mkdir -p "${__output_dir}"
echo "[+] Results will be stored in ${__output_dir}"
echo "[+] Starting at $(date)" | tee -a "${SCAN_LOG}"

# ------------------------------------------------------------------
# Step 1 - discover live hosts (ping sweep)
# ------------------------------------------------------------------
echo "[*] Discovering live hosts in ${__target} ..."
# -sn = ping-scan only (no port scan)
# -PE = ICMP echo request, -PP = timestamp request, -PM = netmask request
#   (these increase reliability on odd networks)
# -oG = greppable output (easy to parse)
nmap -sn -PE -PP -PM "${__target}" -oG - | awk '/Up$/{print $2}' > "${HOSTLIST}"

LIVE_COUNT=$(wc -l < "${HOSTLIST}")
echo "[+] Found ${LIVE_COUNT} live host(s)." | tee -a "${SCAN_LOG}"

if [[ ${LIVE_COUNT} -eq 0 ]]; then
    echo "[!] No hosts responded - exiting."
    exit 0
fi

# ------------------------------------------------------------------
# Step 2 - comprehensive scan of each host
# ------------------------------------------------------------------
echo "[*] Beginning detailed scan of each host ..."
while IFS= read -r HOST; do
    echo "=== Scanning ${HOST} ===" | tee -a "${SCAN_LOG}"
    BASE_OUT="${__output_dir}/${HOST}-${TIMESTAMP}"

    # Full scan command:
    #   -Pn   : treat host as up (we already know it’s alive)
    #   ${PORT_ARG} : ports to scan (see helper above)
    #   ${EXTRA_OPTS} : extra switches defined earlier
    #   -oA   : write three output files (txt, xml, gnmap) with same base name
    nmap -Pn ${PORT_ARG} ${__extra_opts} -oA "${BASE_OUT}" "${HOST}" 2>>"${SCAN_LOG}"

    echo "[+] Finished ${HOST} - outputs:"
    echo "    ${BASE_OUT}.nmap   (human-readable)"
    echo "    ${BASE_OUT}.xml    (machine-readable, good for tools)"
    echo "    ${BASE_OUT}.gnmap  (greppable list of open ports)"

    if [ "$__html_dir" != "" ]; then
        xsltproc -o $__html_dir/${HOST}-${TIMESTAMP}.html ${BASE_OUT}.xml
        echo "    $__html_dir/${HOST}-${TIMESTAMP}.html  (html report)"
    fi
done < "${HOSTLIST}"

echo "[+] All scans completed at $(date)." | tee -a "${SCAN_LOG}"
echo "[+] Summary of live hosts: $(cat "${HOSTLIST}")"
