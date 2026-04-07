#!/bin/bash

set -u

if ! command -v ip >/dev/null 2>&1; then
  echo "ERROR: 'ip' command is not available"
  exit 1
fi

if ! command -v hostname >/dev/null 2>&1; then
  echo "ERROR: 'hostname' command is not available"
  exit 1
fi

echo "== Network report =="

HOSTNAME_VALUE=$(hostname)
IP_ADDRESSES=$(hostname -I 2>/dev/null || true)
DEFAULT_GATEWAY=$(ip route | awk '/default/ {print $3; exit}')
ACTIVE_INTERFACES=$(ip -br link | awk '$2 == "UP" {print $1}')

echo "hostname=$HOSTNAME_VALUE"

if [ -n "${IP_ADDRESSES:-}" ]; then
  echo "ip_addresses=$IP_ADDRESSES"
else
  echo "ip_addresses=UNKNOWN"
fi

if [ -n "${DEFAULT_GATEWAY:-}" ]; then
  echo "default_gateway=$DEFAULT_GATEWAY"
else
  echo "default_gateway=UNKNOWN"
fi

if [ -n "${ACTIVE_INTERFACES:-}" ]; then
  echo "active_interfaces=$(echo "$ACTIVE_INTERFACES" | xargs)"
else
  echo "active_interfaces=NONE"
fi

if command -v ping >/dev/null 2>&1; then
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "internet_connectivity=OK"
  else
    echo "internet_connectivity=FAILED"
  fi
else
  echo "internet_connectivity=PING_COMMAND_NOT_FOUND"
fi
