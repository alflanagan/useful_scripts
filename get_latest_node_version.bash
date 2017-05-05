#!/usr/bin/env bash

# retrieve most recent node package from http://nodejs.org/dist/latest/
if [[ -d latest ]]; then
  rm -r latest
fi
mkdir latest
cd latest || exit 1

# first get http://nodejs.org/dist/latest/SHASUMS256.txt.asc
wget http://nodejs.org/dist/latest/SHASUMS256.txt.asc > wget.log 2>&1
NEW_VERSION=$(grep -o 'node-v.\..\..'  SHASUMS256.txt.asc | head -n1 | sed -e 's/node-v//')
echo Latest node version found is "${NEW_VERSION}".

echo '================================================================================' >> wget.log
SRC_FILE_NAME="node-v${NEW_VERSION}-linux-x64.tar.xz"
if [[ -f ../${SRC_FILE_NAME} ]]; then
  echo "That version has already been downloaded."
else
  echo "Downloading ${SRC_FILE_NAME}."
  wget "http://nodejs.org/dist/latest/${SRC_FILE_NAME}" > wget.log 2>&1
  # TODO: Verify checksum of ${SRC_FILENAME} against SHASUM256.txt.asc
  mv "${SRC_FILE_NAME}" ..
fi
cd ..
rm -rf latest
