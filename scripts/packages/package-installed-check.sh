#!/bin/bash

set -u

PACKAGE_NAME="${1:-curl}"

if [ -z "$PACKAGE_NAME" ]; then
  echo "ERROR: package name must not be empty"
  exit 1
fi

if command -v dpkg >/dev/null 2>&1; then
  PACKAGE_MANAGER="dpkg"
elif command -v rpm >/dev/null 2>&1; then
  PACKAGE_MANAGER="rpm"
else
  echo "ERROR: no supported package manager found"
  exit 1
fi

echo "== Package installed check =="
echo "package_name=$PACKAGE_NAME"

if [ "$PACKAGE_MANAGER" = "dpkg" ]; then
  if dpkg -s "$PACKAGE_NAME" >/dev/null 2>&1; then
    VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null)
    echo "package_manager=dpkg"
    echo "installed=true"
    echo "version=${VERSION:-UNKNOWN}"
    echo "status=OK"
    echo "message=Package is installed"
    exit 0
  fi

  echo "package_manager=dpkg"
  echo "installed=false"
  echo "status=CRITICAL"
  echo "message=Package is not installed"
  exit 2
fi

if [ "$PACKAGE_MANAGER" = "rpm" ]; then
  if rpm -q "$PACKAGE_NAME" >/dev/null 2>&1; then
    VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' "$PACKAGE_NAME" 2>/dev/null)
    echo "package_manager=rpm"
    echo "installed=true"
    echo "version=${VERSION:-UNKNOWN}"
    echo "status=OK"
    echo "message=Package is installed"
    exit 0
  fi

  echo "package_manager=rpm"
  echo "installed=false"
  echo "status=CRITICAL"
  echo "message=Package is not installed"
  exit 2
fi
