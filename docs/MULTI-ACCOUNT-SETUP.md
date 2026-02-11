# Multi-Account Setup for OpenCode/OpenClaw

## Overview

This setup provides automatic account rotation across multiple Google accounts to work around rate limits and maximize available quotas.

## Account Inventory

### Authentication Profiles (8 total)

**Antigravity OAuth (3 accounts)**
- skittlezguy1111@gmail.com (projectId: plexiform-antenna-3t6w3)
- bob.usa.kfc@gmail.com (projectId: deft-reason-2dtw2)
- joshfewx@gmail.com (projectId: prismatic-affinity-0zsgc)

**Gemini CLI OAuth (3 accounts)**
- skittlezguy1111@gmail.com
- bob.usa.kfc@gmail.com
- joshfewx@gmail.com

**Qwen Portal (2 accounts)**
- default
- qwen-cli

## Components

### 1. OpenCode Multi-Auth Plugin

**Location**: `/opt/opencode/plugins/opencode-antigravity-multi-auth`

**Features**:
- Automatic rotation between Google accounts on rate limits
- Tracks account usage and cooldown periods
- Persists state in `~/.config/opencode/antigravity-accounts.json`

**Configuration**:
- Plugin config: `~/.config/opencode/opencode.json`
- Account storage: `~/.config/opencode/antigravity-accounts.json`
- Auth tokens: `~/.config/opencode/auth.json`

### 2. OpenClaw Configuration

**Location**: `~/.openclaw/openclaw.json`

**Model Fallback Chain**:
1. `google-gemini-cli/gemini-3-pro-preview` (primary)
2. `google-antigravity/claude-opus-4-6-thinking`
3. `google-antigravity/gemini-3-flash`
4. `opencode/kimi-k2.5-free`
5. `qwen-portal/coder-model`
6. `groq/llama-3.3-70b-versatile`

**Auth Profiles**: Stored in `~/.openclaw/agents/main/agent/auth-profiles.json`

### 3. Migration Tools

**Migrate Accounts Script**: `scripts/migrate-antigravity-accounts.sh`
- Syncs accounts from OpenClaw to OpenCode
- Automatically called after adding new accounts
- Preserves existing accounts

**Add Account Helper**: `scripts/add-google-account.sh`
- Interactive script for adding new Google accounts
- Runs OpenClaw configuration wizard
- Automatically migrates new accounts

## Usage

### Adding New Accounts

```bash
# Quick method - interactive wizard
bash scripts/add-google-account.sh

# Manual method
distrobox enter openclaw-dev
openclaw configure --section model
# Add accounts via OAuth
bash scripts/migrate-antigravity-accounts.sh
```

### Checking Account Status

```bash
# OpenCode accounts
distrobox enter openclaw-dev
cat ~/.config/opencode/antigravity-accounts.json | jq

# OpenClaw accounts
cat ~/.openclaw/agents/main/agent/auth-profiles.json | jq
```

### Testing Multi-Account Rotation

```bash
# Enable debug logging
export OPENCODE_ANTIGRAVITY_DEBUG=1

# Test with OpenClaw
distrobox enter openclaw-dev
openclaw agent --local --agent main --message "test"

# Watch logs for account rotation
tail -f ~/.openclaw/logs/*.log
```

## Quota Pools

Each authentication profile has independent rate limits:

| Provider | Accounts | Quota Type |
|----------|----------|------------|
| Antigravity | 3 | Project-level quotas (separate per project) |
| Gemini CLI | 3 | AI Studio quotas (per account) |
| Qwen Portal | 2 | Portal quotas (per token) |

**Total**: 8 independent quota pools

## Rate Limit Behavior

### Antigravity Plugin
- Uses sticky account selection (same account until error)
- Switches on 429 (rate limit) or 500 (server error)
- Tracks cooldown periods per account
- Logs rotation events

### OpenClaw Failover
- Cascades through fallback chain on errors
- Tracks usage stats per auth profile
- Implements cooldown periods
- Automatically retries with next provider

## Troubleshooting

### All Accounts Rate Limited

**Check cooldown status**:
```bash
cat ~/.config/opencode/antigravity-accounts.json | jq '.accounts[] | {email, isRateLimited, rateLimitResetTime}'
```

**Check OpenClaw usage stats**:
```bash
cat ~/.openclaw/agents/main/agent/auth-profiles.json | jq '.usageStats'
```

### Account Not Being Used

**Verify account is in rotation**:
```bash
# OpenCode
cat ~/.config/opencode/antigravity-accounts.json | jq '.accounts[].email'

# OpenClaw
cat ~/.openclaw/agents/main/agent/auth-profiles.json | jq '.profiles | keys'
```

### Migration Not Working

**Re-run migration manually**:
```bash
distrobox enter openclaw-dev
bash /tmp/migrate-antigravity-accounts.sh
```

## Expansion Plan

### Additional Providers to Add

1. **More Qwen accounts** - Easy to create, good free tier
2. **OpenCode free models** - Multiple accounts possible
3. **OpenRouter** - Mix of free and paid models
4. **Local models** - Ollama as final fallback

### Best Practices

- Use different Google accounts from different households if possible
- Each Google account should have its own Cloud project for independent quotas
- Aim for 4-5 accounts per provider for optimal coverage
- Monitor quota usage to identify bottlenecks

## Files Reference

```
distrobox-configs/
├── scripts/
│   ├── migrate-antigravity-accounts.sh  # Sync OpenClaw → OpenCode
│   └── add-google-account.sh            # Interactive account addition
└── docs/
    └── MULTI-ACCOUNT-SETUP.md           # This file

~/.config/opencode/
├── opencode.json                        # Plugin configuration
├── antigravity-accounts.json            # Account rotation state
└── auth.json                            # Active account credentials

~/.openclaw/
├── openclaw.json                        # Model configuration
└── agents/main/agent/
    └── auth-profiles.json               # All auth profiles
```

## References

- [OpenCode Antigravity Multi-Auth Plugin](https://github.com/YiSHuA/opencode-antigravity-multi-auth)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Google Cloud Quotas](https://console.cloud.google.com/quotas)
