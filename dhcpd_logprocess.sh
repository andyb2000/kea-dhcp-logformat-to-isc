#!/bin/bash

## kea-DHCPD logprocessing by andyb2000
##  https://github.com/andyb2000/kea-dhcp-logformat-to-isc
##########################################################################



# Transaction tracking by identifier
declare -A transaction_hostname
declare -A transaction_fqdn
declare -A transaction_mac
declare -A transaction_ip
declare -A transaction_tid

# Accumulate multiline log entries and process them as a single logical line
buffer=""

process_log_entry() {
    local entry="$1"
    # Extract the transaction identifier (e.g., kea-dhcp4.packets/1.129234940282560)
    ident=$(echo "$entry" | grep -oP '\[([a-zA-Z0-9.-]+/[0-9.]+)\]' | head -1 | tr -d '[]')
    ts=$(echo "$entry" | awk '{print $1, $2}')
    if [[ -z "$ident" ]]; then
        return
    fi

    # Capture client data from DHCP4_QUERY_DATA
    if [[ "$entry" == *"DHCP4_QUERY_DATA"* ]]; then
        # MAC
        mac=$(echo "$entry" | grep -oP 'hwtype=1 \K([0-9a-f:]+)')
        transaction_mac["$ident"]="$mac"
        # Hostname (option 12)
        hostname=$(echo "$entry" | grep -oP 'type=012, len=[0-9]+: "\K[^"]+')
        if [[ -n "$hostname" ]]; then
            transaction_hostname["$ident"]="$hostname"
        fi
        # FQDN (option 81)
        fqdn=$(echo "$entry" | grep -oP 'type=081, len=[0-9]+: "\K[^"]+')
        if [[ -n "$fqdn" ]]; then
            transaction_fqdn["$ident"]="$fqdn"
        fi
        # Transaction ID
        tid=$(echo "$entry" | grep -oP 'trans_id=0x\K[0-9a-f]+')
        if [[ -n "$tid" ]]; then
            transaction_tid["$ident"]="$tid"
        fi
        # IP (remote_address)
        ip=$(echo "$entry" | grep -oP 'remote_address=\K([0-9.]+)')
        if [[ -n "$ip" ]]; then
            transaction_ip["$ident"]="$ip"
        fi
    fi

    # Output on DHCP4_RESPONSE_DATA (end of transaction)
    if [[ "$entry" == *"DHCP4_RESPONSE_DATA"* ]]; then
        mac=${transaction_mac[$ident]:-"unknown"}
        hostname=${transaction_hostname[$ident]:-"unknown"}
        fqdn=${transaction_fqdn[$ident]:-"unknown"}
        ip=${transaction_ip[$ident]:-"unknown"}
        tid=${transaction_tid[$ident]:-"unknown"}
        echo "$ts DHCP transaction $ident: MAC=$mac IP=$ip Hostname=$hostname FQDN=$fqdn TID=$tid"
        # Clean up
        unset transaction_mac[$ident]
        unset transaction_hostname[$ident]
        unset transaction_fqdn[$ident]
        unset transaction_ip[$ident]
        unset transaction_tid[$ident]
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
