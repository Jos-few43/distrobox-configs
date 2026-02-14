#!/bin/bash
# Start all LiteLLM services: blue, green, and haproxy router
# Run this after login to bring up the full proxy stack
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting litellm-blue (port 4001)..."
distrobox enter litellm-dev -- bash -c "
  set -a
  source ~/litellm/blue/.env
  set +a
  nohup litellm --config ~/litellm/blue/config.yaml --port 4001 \
    > ~/litellm/blue/litellm.log 2>&1 &
  echo \$! > ~/litellm/blue/litellm.pid
  echo 'litellm-blue started (PID '\$!')'
"

echo "Starting litellm-green (port 4002)..."
distrobox enter litellm-green -- bash -c "
  set -a
  source ~/litellm/green/.env
  set +a
  nohup litellm --config ~/litellm/green/config.yaml --port 4002 \
    > ~/litellm/green/litellm.log 2>&1 &
  echo \$! > ~/litellm/green/litellm.pid
  echo 'litellm-green started (PID '\$!')'
"

echo "Waiting 10 seconds for LiteLLM instances to initialize..."
sleep 10

echo "Starting litellm-router (haproxy on port 4000)..."
distrobox enter litellm-router -- haproxy -D \
  -f ~/litellm-router/haproxy.cfg \
  -p ~/litellm-router/haproxy.pid

sleep 2
echo ""
bash "$SCRIPT_DIR/status.sh"
