#!/bin/bash

set -u

HOST="${1:-google.com}"

if [ -z "$HOST" ]; then
  echo "ERROR: host must not be empty"
  exit 1
fi

echo "== DNS check =="
echo "host=$HOST"

RESOLVED_IP=""

if command -v getent >/dev/null 2>&1; then
  RESOLVED_IP=$(getent hosts "$HOST" | awk '{print $1}' | head -n 1)
elif command -v nslookup >/dev/null 2>&1; then
  RESOLVED_IP=$(nslookup "$HOST" 2>/dev/null | awk '/^Address: / {print $2}' | tail -n 1)
else
  echo "status=CRITICAL"
  echo "message=No DNS tools available (getent/nslookup)"
  exit 2
fi

if [ -z "$RESOLVED_IP" ]; then
  echo "status=CRITICAL"
  echo "message=DNS resolution failed"
  exit 2
fi

echo "resolved_ip=$RESOLVED_IP"
echo "status=OK"
echo "message=DNS resolution successful"
exit 0
