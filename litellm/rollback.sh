#!/bin/bash
# Immediately promote whichever instance is NOT currently active
CFG=~/litellm-router/haproxy.cfg
ACTIVE_PORT=$(grep 'server active' "$CFG" | grep -oP ':\K[0-9]+' | head -1)

case "$ACTIVE_PORT" in
  4001)
    echo "Rolling back: blue → green"
    bash "$(dirname "$0")/promote.sh" green
    ;;
  4002)
    echo "Rolling back: green → blue"
    bash "$(dirname "$0")/promote.sh" blue
    ;;
  *)
    echo "Unknown active port ${ACTIVE_PORT:-?} — cannot determine rollback target"
    exit 1
    ;;
esac
