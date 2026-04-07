#!/bin/bash

set -u

if command -v apt >/dev/null 2>&1; then
  PACKAGE_MANAGER="apt"
else
  echo "ERROR: only apt-based systems are supported by this script for now"
  exit 1
fi

echo "== Package updates check =="
echo "package_manager=$PACKAGE_MANAGER"

UPGRADABLE_OUTPUT=$(apt list --upgradable 2>/dev/null)

UPGRADABLE_COUNT=$(echo "$UPGRADABLE_OUTPUT" | tail -n +2 | sed '/^\s*$/d' | wc -l)

echo "upgradable_packages=$UPGRADABLE_COUNT"

if [ "$UPGRADABLE_COUNT" -eq 0 ]; then
  echo "status=OK"
  echo "message=No package updates available"
  exit 0
fi

echo "status=WARNING"
echo "message=Package updates are available"
exit 1
