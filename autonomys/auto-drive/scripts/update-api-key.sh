#!/usr/bin/env bash
# Update the Auto-Drive API key without re-running full setup
# Usage: ./scripts/update-api-key.sh
# Env: AUTO_DRIVE_API_KEY may be set to skip the prompt (non-interactive use)

set -euo pipefail

API_BASE="https://mainnet.auto-drive.autonomys.xyz/api"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
ENV_FILE="$OPENCLAW_DIR/.env"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Accept key from argument, env var, or interactive prompt
if [[ -n "${1:-}" ]]; then
  API_KEY="$1"
elif [[ -n "${AUTO_DRIVE_API_KEY:-}" ]]; then
  API_KEY="$AUTO_DRIVE_API_KEY"
else
  read -rp "New Auto-Drive API key: " API_KEY
fi
API_KEY="${API_KEY//[[:space:]]/}"

if [[ -z "$API_KEY" ]]; then
  echo -e "${RED}Error: No API key provided.${NC}" >&2
  exit 1
fi

# Verify before writing
echo "Verifying API key..."
RESPONSE=$(curl -sS -w "\n%{http_code}" "$API_BASE/accounts/@me" \
  -H "Authorization: Bearer $API_KEY" \
  -H "X-Auth-Provider: apikey")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo -e "${RED}Error: Key verification failed (HTTP $HTTP_CODE).${NC}" >&2
  echo "$BODY" >&2
  exit 1
fi
echo -e "${GREEN}✓ Key verified${NC}"

mkdir -p "$OPENCLAW_DIR"

# Update openclaw.json
if [[ ! -f "$CONFIG_FILE" ]]; then
  jq -n --arg key "$API_KEY" \
    '{"skills": {"entries": {"auto-drive": {"enabled": true, "env": {"AUTO_DRIVE_API_KEY": $key}}}}}' \
    > "$CONFIG_FILE"
else
  JSONTMP=$(mktemp)
  jq --arg key "$API_KEY" \
    '.skills.entries["auto-drive"].env.AUTO_DRIVE_API_KEY = $key' \
    "$CONFIG_FILE" > "$JSONTMP" && mv "$JSONTMP" "$CONFIG_FILE"
fi
echo -e "${GREEN}✓ Updated $CONFIG_FILE${NC}"

# Update .env
if [[ -f "$ENV_FILE" ]] && grep -q "^AUTO_DRIVE_API_KEY=" "$ENV_FILE" 2>/dev/null; then
  SEDTMP=$(mktemp)
  sed "s|^AUTO_DRIVE_API_KEY=.*|AUTO_DRIVE_API_KEY=$API_KEY|" "$ENV_FILE" > "$SEDTMP" && mv "$SEDTMP" "$ENV_FILE"
else
  echo "AUTO_DRIVE_API_KEY=$API_KEY" >> "$ENV_FILE"
fi
echo -e "${GREEN}✓ Updated $ENV_FILE${NC}"

echo ""
echo "API key updated. Restart the OpenClaw gateway to apply."
