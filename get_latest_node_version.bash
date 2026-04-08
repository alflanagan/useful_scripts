#!/usr/bin/env bash
# bash "strict mode"
# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# retrieve most recent node package from http://nodejs.org/dist/latest/
TMPDIR=$(mktemp -d)
chmod a+x "${TMPDIR}"
cd "${TMPDIR}" || exit 1

# first get http://nodejs.org/dist/latest/SHASUMS256.txt.asc
wget http://nodejs.org/dist/latest/SHASUMS256.txt.asc >/dev/null 2>&1
NEW_VERSION=$(grep -o 'node-v..\.\d\+\.\d\+' SHASUMS256.txt.asc | head -n1 | sed -e 's/node-v//')
echo "Checked nodejs.org web distribution list."
echo Latest node version found is "${NEW_VERSION}".

cd
rm -rf "${TMPDIR}"
