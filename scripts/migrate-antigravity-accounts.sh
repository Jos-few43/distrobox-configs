#!/usr/bin/env bash
set -euo pipefail

echo "==> Migrating Google Antigravity accounts from OpenClaw to OpenCode"

OPENCLAW_AUTH="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
OPENCODE_ACCOUNTS="$HOME/.config/opencode/antigravity-accounts.json"

if [ ! -f "$OPENCLAW_AUTH" ]; then
  echo "ERROR: OpenClaw auth file not found at $OPENCLAW_AUTH"
  exit 1
fi

echo "Reading accounts from OpenClaw..."

accounts_json=$(jq -r '
  .profiles
  | to_entries
  | map(select(.value.provider == "google-antigravity"))
  | map({
      email: .value.email,
      refreshToken: .value.refresh,
      projectId: .value.projectId,
      addedAt: (now * 1000 | floor),
      lastUsed: 0,
      lastSwitchReason: "initial",
      isRateLimited: false
    })
' "$OPENCLAW_AUTH")

account_count=$(echo "$accounts_json" | jq 'length')

if [ "$account_count" -eq 0 ]; then
  echo "ERROR: No Google Antigravity accounts found in OpenClaw"
  exit 1
fi

echo "Found $account_count Google Antigravity account(s)"

mkdir -p "$(dirname "$OPENCODE_ACCOUNTS")"

cat > "$OPENCODE_ACCOUNTS" << EOF
{
  "version": 1,
  "accounts": $accounts_json,
  "activeIndex": 0
}
EOF

echo "✅ Successfully migrated $account_count account(s) to OpenCode"
echo "Accounts file: $OPENCODE_ACCOUNTS"
echo ""
echo "Account emails:"
jq -r '.accounts[].email' "$OPENCODE_ACCOUNTS"
