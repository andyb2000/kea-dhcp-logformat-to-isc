#!/bin/bash

## kea-DHCPD logprocessing by andyb2000
##  https://github.com/andyb2000/kea-dhcp-logformat-to-isc
##########################################################################


declare -A hostnames
declare -A last_request_ip

# Accumulate multiline log entries and process them as a single logical line
buffer=""
process_log_entry() {
    local entry="$1"
    # ---- Extract timestamp ----
    ts=$(echo "$entry" | awk '{print $1, $2}')

    # ---- Capture hostname (option 12) ----
    if [[ "$entry" == *"type=012"* ]]; then
        hostname=$(echo "$entry" | grep -oP 'type=012, len=[0-9]+: "\K[^"]+')
        if [[ -n "$hostname" ]]; then
            mac=$(echo "$entry" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}')
            hostnames["$mac"]="$hostname"
        fi
    fi

    # ---- Capture FQDN (option 81) ----
    if [[ "$entry" == *"type=081"* ]]; then
        fqdn=$(echo "$entry" | grep -oP 'type=081, len=[0-9]+: "\K[^"]+')
        if [[ -n "$fqdn" ]]; then
            mac=$(echo "$entry" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}')
            hostnames["$mac"]="$fqdn"
        fi
    fi

    # ---- DHCPREQUEST ----
    if [[ "$entry" == *"DHCP4_REQUEST"* ]]; then
        mac=$(echo "$entry" | grep -oP 'hwtype=1 \K([0-9a-f:]+)')
        ip=$(echo "$entry" | grep -oP 'hint=\K([0-9.]+)')
        host=${hostnames[$mac]:-"unknown"}
        if [[ -n "$mac" && -n "$ip" ]]; then
            last_request_ip["$mac"]="$ip"
            echo "$ts DHCPREQUEST for $ip from $mac ($host)"
        fi
    fi

    # ---- DHCPACK (LEASE_ALLOC) ----
    if [[ "$entry" == *"DHCP4_LEASE_ALLOC"* ]]; then
        mac=$(echo "$entry" | grep -oP 'hwtype=1 \K([0-9a-f:]+)')
        ip=$(echo "$entry" | grep -oP 'lease \K([0-9.]+)')
        lease=$(echo "$entry" | grep -oP 'for \K([0-9]+)')
        host=${hostnames[$mac]:-"unknown"}
        requested=${last_request_ip[$mac]:-"unknown"}
        if [[ -n "$mac" && -n "$ip" ]]; then
            echo "$ts DHCPACK on $ip to $mac ($host) requested $requested lease ${lease}s"
        fi
    fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect start of a new log entry (timestamp at start of line)
    if [[ "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} ]]; then
        if [[ -n "$buffer" ]]; then
            process_log_entry "$buffer"
        fi
        buffer="$line"
    else
        # Append to buffer (multiline log entry)
        buffer+=$'\n'$line
    fi
done
# Process any remaining buffer
if [[ -n "$buffer" ]]; then
    process_log_entry "$buffer"
fi

## Version 0.01 - andyb2000 https://github.com/andyb2000
