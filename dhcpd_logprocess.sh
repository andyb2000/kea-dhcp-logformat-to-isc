#!/bin/bash

## kea-DHCPD logprocessing by andyb2000
##  https://github.com/andyb2000/kea-dhcp-logformat-to-isc
##########################################################################


declare -A hostnames
declare -A last_request_ip

# Normalize carriage returns and ensure each log entry is on a single line
tr '\r' '\n' | while read -r line; do


    # ---- Extract timestamp ----
    ts=$(echo "$line" | awk '{print $1, $2}')


    # ---- Capture hostname (option 12) ----
    if [[ "$line" == *"option[12]"* ]]; then
        mac=$(echo "$line" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}')
        hostname=$(echo "$line" | grep -oP 'option\[12\]=\K([^ ]+)')

        if [[ -n "$mac" && -n "$hostname" ]]; then
            hostnames["$mac"]="$hostname"
        fi
    fi


    # ---- Capture FQDN (option 81) ----
    if [[ "$line" == *"option[81]"* ]]; then
        mac=$(echo "$line" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}')
        fqdn=$(echo "$line" | grep -oP 'option\[81\]=\K([^ ]+)')

        if [[ -n "$mac" && -n "$fqdn" ]]; then
            hostnames["$mac"]="$fqdn"
        fi
    fi


    # ---- DHCPREQUEST ----
    if [[ "$line" == *"DHCP4_REQUEST"* ]]; then
        mac=$(echo "$line" | grep -oP 'hwtype=1 \K([0-9a-f:]+)')
        ip=$(echo "$line" | grep -oP 'hint=\K([0-9.]+)')
        host=${hostnames[$mac]:-"unknown"}

        if [[ -n "$mac" && -n "$ip" ]]; then
            last_request_ip["$mac"]="$ip"
            echo "$ts DHCPREQUEST for $ip from $mac ($host)"
        fi
    fi


    # ---- DHCPACK (LEASE_ALLOC) ----
    if [[ "$line" == *"DHCP4_LEASE_ALLOC"* ]]; then
        mac=$(echo "$line" | grep -oP 'hwtype=1 \K([0-9a-f:]+)')
        ip=$(echo "$line" | grep -oP 'lease \K([0-9.]+)')
        lease=$(echo "$line" | grep -oP 'for \K([0-9]+)')
        host=${hostnames[$mac]:-"unknown"}
        requested=${last_request_ip[$mac]:-"unknown"}

        if [[ -n "$mac" && -n "$ip" ]]; then
            echo "$ts DHCPACK on $ip to $mac ($host) requested $requested lease ${lease}s"
        fi
    fi

done

## Version 0.01 - andyb2000 https://github.com/andyb2000
