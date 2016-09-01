#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Exit codes
EX_USAGE=64
EX_OSFILE=72

# Magento build vars
MAGE_REPO="https://repo.magento.com"
MAJOR_VERSION=2
MINOR_VERSION=2.1
FULL_VERSION=2.1.0
EDITION="$1"

if [[ ! -f "$SCRIPT_DIR/auth.json" ]]; then
  AUTH_FILE="$HOME/.composer/auth.json"

  if [[ -f "$AUTH_FILE" ]]; then
    cp "$AUTH_FILE" "$SCRIPT_DIR/auth.json"
  else
    echo "Could not locate Composer auth.json file"
    exit $EX_OSFILE
  fi
fi

case "$EDITION" in
  community )
    EDITION_CODE=ce
    ;;
  enterprise )
    EDITION_CODE=ee
    ;;
  * )
    cat <<EOF

Usage: `basename ${BASH_SOURCE[0]}` EDITION

EDITION must be one of:

    * community
    * enterprise

EOF
    exit $EX_USAGE
    ;;
esac

docker build \
  --force-rm \
  -t dnunez24/magento2-$EDITION_CODE:build \
  --build-arg MAGE_REPO=$MAGE_REPO \
  --build-arg MAGE_VERSION=$FULL_VERSION \
  --build-arg MAGE_EDITION=$EDITION \
  -f $SCRIPT_DIR/Dockerfile.build $SCRIPT_DIR \
&& docker run --rm dnunez24/magento2-$EDITION_CODE:build > $SCRIPT_DIR/$EDITION-build.tar.gz \
&& docker rmi dnunez24/magento2-$EDITION_CODE:build \
&& docker build \
  --force-rm \
  -t dnunez24/magento2-$EDITION_CODE:$MAJOR_VERSION \
  -t dnunez24/magento2-$EDITION_CODE:$MINOR_VERSION \
  -t dnunez24/magento2-$EDITION_CODE:$FULL_VERSION \
  -t dnunez24/magento2-$EDITION_CODE:latest \
  -t dnunez24/magento2-$EDITION_CODE \
  --build-arg MAGE_EDITION=$EDITION \
  -f $SCRIPT_DIR/Dockerfile.dist $SCRIPT_DIR \
&& rm $SCRIPT_DIR/$EDITION-build.tar.gz
