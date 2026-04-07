#!/bin/bash

set -u

if command -v apt >/dev/null 2>&1; then
  PACKAGE_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
  PACKAGE_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
  PACKAGE_MANAGER="yum"
else
  echo "ERROR: no supported package manager found"
  exit 1
fi

echo "== Packages report =="
echo "package_manager=$PACKAGE_MANAGER"

if [ "$PACKAGE_MANAGER" = "apt" ]; then
  INSTALLED_COUNT=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)
  APT_CACHE_PRESENT="NO"

  if [ -d /var/lib/apt/lists ] && [ -n "$(find /var/lib/apt/lists -type f 2>/dev/null)" ]; then
    APT_CACHE_PRESENT="YES"
  fi

  echo "installed_packages=$INSTALLED_COUNT"
  echo "apt_metadata_present=$APT_CACHE_PRESENT"
  exit 0
fi

if [ "$PACKAGE_MANAGER" = "dnf" ]; then
  INSTALLED_COUNT=$(dnf list installed 2>/dev/null | tail -n +2 | wc -l)
  echo "installed_packages=$INSTALLED_COUNT"
  exit 0
fi

if [ "$PACKAGE_MANAGER" = "yum" ]; then
  INSTALLED_COUNT=$(yum list installed 2>/dev/null | tail -n +2 | wc -l)
  echo "installed_packages=$INSTALLED_COUNT"
  exit 0
fi
