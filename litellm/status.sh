#!/bin/bash
CFG=~/litellm-router/haproxy.cfg

ACTIVE_PORT=$(grep 'server active' "$CFG" | grep -oP ':\K[0-9]+' | head -1)
case "$ACTIVE_PORT" in
  4001) ACTIVE="blue (port 4001)" ;;
  4002) ACTIVE="green (port 4002)" ;;
  *)    ACTIVE="unknown (port ${ACTIVE_PORT:-?})" ;;
esac

echo "=== LiteLLM Router Status ==="
echo "Active backend: $ACTIVE"
echo ""

for name in blue green; do
  port=$([ "$name" = "blue" ] && echo 4001 || echo 4002)
  label=$([ "$port" = "$ACTIVE_PORT" ] && echo "[ACTIVE] " || echo "[standby]")
  health=$(curl -sf --max-time 3 "http://localhost:$port/health" 2>/dev/null && echo "✅ healthy" || echo "❌ unreachable")
  echo "  $name $label $health"
done

echo ""
ROUTER=$(curl -sf --max-time 3 http://localhost:4000/health 2>/dev/null && echo "✅ up" || echo "❌ down")
echo "Router (port 4000): $ROUTER"

PID_FILE=~/litellm-router/haproxy.pid
if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
  echo "haproxy PID: $(cat $PID_FILE) (running)"
else
  echo "haproxy: not running"
fi
