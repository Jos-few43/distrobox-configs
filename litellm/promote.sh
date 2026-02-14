#!/bin/bash
# Usage: promote.sh blue|green
# Zero-downtime promotion via haproxy graceful reload (SIGUSR2)
set -euo pipefail

TARGET=${1:-}
CFG=~/litellm-router/haproxy.cfg
PID_FILE=~/litellm-router/haproxy.pid
LOG=~/litellm-router/promotions.log

case "$TARGET" in
  blue)  PORT=4001 ;;
  green) PORT=4002 ;;
  *)
    echo "Usage: promote.sh blue|green"
    echo "  blue  → port 4001 (primary)"
    echo "  green → port 4002 (staging)"
    exit 1
    ;;
esac

# Update haproxy config — swap the active backend port
sed -i "s|server active 127.0.0.1:[0-9]*|server active 127.0.0.1:$PORT|" "$CFG"

# Graceful reload — SIGUSR2 forks new worker, drains old connections, exits old worker
if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
  kill -USR2 "$(cat $PID_FILE)"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Promoted $TARGET (port $PORT)" | tee -a "$LOG"
  echo "✅ Promoted to $TARGET — haproxy reloaded gracefully"
else
  echo "⚠️  haproxy not running — config updated but not reloaded"
  echo "   Start with: distrobox enter litellm-router -- haproxy -D -f ~/litellm-router/haproxy.cfg -p ~/litellm-router/haproxy.pid"
fi
