#!/usr/bin/env bash

set -e

# Config variables.
# See e.g. https://nodejs.org/dist/v8.10.0/SHASUMS256.txt for checksum.
NODE_VERSION=v14.11.0
NODE_SHA256=615b78188b615cf19b7ecf4b9514035b112adaeef4b592e29e99a5bca40264f7

cd $(dirname $0)
cd ../..
  
check_node_needed () {
  if [ -x ext/node/bin/node ]
  then
    local CURRENT_NODE_VERSION=$(ext/node/bin/node --version 2>/dev/null)
    if [[ "$CURRENT_NODE_VERSION" == "v$NODE_VERSION" ]]
    then
      echo "Node v$NODE_VERSION is already installed, skipping" >&2
      exit 0
    fi
  fi
}

verify_checksum () {
  local FILE=$1
  local EXPECTED_CHECKSUM=$2

  local ACTUAL_CHECKSUM=$(sha256sum "$FILE")
  [[ "$EXPECTED_CHECKSUM  $FILE" != "$ACTUAL_CHECKSUM" ]]
}

download_node () {
  local NODE_FILENAME="node-${NODE_VERSION}-linux-x64.tar.xz"
  local NODE_URL="https://github.com/jcheng5/node-centos6/releases/download/${NODE_VERSION}/${NODE_FILENAME}"
  local NODE_ARCHIVE_DEST="/tmp/${NODE_FILENAME}"
  echo "Downloading Node v${NODE_VERSION} from ${NODE_URL}"

  wget -O "$NODE_ARCHIVE_DEST" "$NODE_URL"
  if verify_checksum "$NODE_ARCHIVE_DEST" "$NODE_SHA256"
  then
    echo "Checksum failed!" >&2
    exit 1
  fi

  mkdir -p ext/node
  echo "Extracting ${NODE_FILENAME}"
  tar xf "${NODE_ARCHIVE_DEST}" --strip-components=1 -C "ext/node"

  # Clean up temp file
  rm "${NODE_ARCHIVE_DEST}"
  # cp /usr/bin/node ext/node/bin/node
  # cp ext/node/bin/node ext/node/bin/shiny-server
  cp /opt/nodejs/node-${NODE_VERSION}-linux-s390x/bin/node ext/node/bin/node
  cp ext/node/bin/node ext/node/bin/shiny-server
  # cp /opt/nodejs/node-${NODE_VERSION}-linux-s390x/bin/node ext/node/bin/shiny-server
  
  rm ext/node/bin/npm
  (cd ext/node/lib/node_modules/npm && ./scripts/relocate.sh)
}
install_shiny(){
  cd shiny-server/tmp
  # mkdir tmp
  # cd tmp

# Add the bin directory to the path so we can reference node
DIR=`pwd`
PATH=$DIR/../bin:$PATH

# Use cmake to prepare the make step. Modify the "--DCMAKE_INSTALL_PREFIX"
# if you wish the install the software at a different location.
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../
# Get an error here? Check the "How do I set the cmake Python version?" question below

# Recompile the npm modules included in the project
make
mkdir ../build
(cd .. && npm install)
(cd .. && node ./ext/node/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js rebuild)

# Install the software at the predefined location
sudo make install
ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server
mkdir -p /var/log/shiny-server
mkdir -p /var/log/supervisord
mkdir -p /srv/shiny-server
mkdir -p /var/lib/shiny-server
mkdir -p /etc/shiny-server
cp ../config/default.config /etc/shiny-server/shiny-server.conf
rm -rf /tmp/*
} 
check_node_needed
download_node
install_shiny