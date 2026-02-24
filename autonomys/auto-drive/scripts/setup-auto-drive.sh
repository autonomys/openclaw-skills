#!/usr/bin/env bash
# Setup Autonomys Auto-Drive — interactive API key configuration
# Usage: ./scripts/setup-auto-drive.sh
# Opens explorer.ai3.storage in your browser, prompts for the API key,
# writes it to ~/.openclaw/openclaw.json (skills.entries.auto-drive.env)
# and ~/.openclaw/.env, then verifies the connection.

set -euo pipefail

API_BASE="https://mainnet.auto-drive.autonomys.xyz/api"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
ENV_FILE="$OPENCLAW_DIR/.env"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Autonomys Auto-Drive — Setup            ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Check prerequisites
MISSING=()
for bin in curl jq; do
  command -v "$bin" &>/dev/null || MISSING+=("$bin")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo -e "${RED}Error: Missing required tools: ${MISSING[*]}${NC}" >&2
  echo "Install them and re-run this script." >&2
  exit 1
fi
echo -e "${GREEN}✓ Prerequisites OK (curl, jq)${NC}"
echo ""

# Open browser to API key creation page
DASHBOARD_URL="https://explorer.ai3.storage/mainnet/drive/developers"
echo "Opening $DASHBOARD_URL in your browser..."
echo ""
echo "  → If prompted, sign in with Google, GitHub, or Discord"
echo "     (AI agents: you cannot complete OAuth yourself —"
echo "      ask the user to sign in, then take over)"
echo "  → Click 'Create API Key' and paste the key below"
echo ""
if command -v xdg-open &>/dev/null; then
  xdg-open "$DASHBOARD_URL" 2>/dev/null &
elif command -v open &>/dev/null; then
  open "$DASHBOARD_URL" 2>/dev/null &
elif [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
  cmd.exe /c start "$DASHBOARD_URL" 2>/dev/null &
else
  echo -e "${YELLOW}Could not open browser automatically — visit: $DASHBOARD_URL${NC}"
fi

read -rp "Paste your API key here: " API_KEY
API_KEY="${API_KEY//[[:space:]]/}"

if [[ -z "$API_KEY" ]]; then
  echo -e "${RED}Error: No API key provided.${NC}" >&2
  exit 1
fi

# Verify the key against the accounts endpoint
echo ""
echo "Verifying API key..."
RESPONSE=$(curl -sS -w "\n%{http_code}" "$API_BASE/accounts/@me" \
  -H "Authorization: Bearer $API_KEY" \
  -H "X-Auth-Provider: apikey")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo -e "${RED}Error: API key verification failed (HTTP $HTTP_CODE).${NC}" >&2
  echo "$BODY" >&2
  echo "Double-check the key at https://explorer.ai3.storage/mainnet/drive/developers and try again." >&2
  exit 1
fi

echo -e "${GREEN}✓ API key verified${NC}"

mkdir -p "$OPENCLAW_DIR"

# Write to ~/.openclaw/openclaw.json (OpenClaw-native: skills.entries.auto-drive.env)
if [[ ! -f "$CONFIG_FILE" ]]; then
  jq -n --arg key "$API_KEY" \
    '{"skills": {"entries": {"auto-drive": {"enabled": true, "env": {"AUTO_DRIVE_API_KEY": $key}}}}}' \
    > "$CONFIG_FILE"
else
  JSONTMP=$(mktemp)
  jq --arg key "$API_KEY" \
    '.skills //= {} | .skills.entries //= {} | .skills.entries["auto-drive"] //= {} | .skills.entries["auto-drive"].env //= {} | .skills.entries["auto-drive"].env.AUTO_DRIVE_API_KEY = $key | .skills.entries["auto-drive"].enabled = true' \
    "$CONFIG_FILE" > "$JSONTMP" && mv "$JSONTMP" "$CONFIG_FILE"
fi
echo -e "${GREEN}✓ Saved to $CONFIG_FILE (skills.entries.auto-drive.env.AUTO_DRIVE_API_KEY)${NC}"

# Also write to ~/.openclaw/.env as a fallback for shell-based invocations
if [[ -f "$ENV_FILE" ]] && grep -q "^AUTO_DRIVE_API_KEY=" "$ENV_FILE" 2>/dev/null; then
  SEDTMP=$(mktemp)
  sed "s|^AUTO_DRIVE_API_KEY=.*|AUTO_DRIVE_API_KEY=$API_KEY|" "$ENV_FILE" > "$SEDTMP" && mv "$SEDTMP" "$ENV_FILE"
else
  echo "AUTO_DRIVE_API_KEY=$API_KEY" >> "$ENV_FILE"
fi
echo -e "${GREEN}✓ Saved to $ENV_FILE (shell fallback)${NC}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Setup complete!                         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Restart OpenClaw gateway to pick up the new config"
echo "  2. Try: scripts/autodrive-upload.sh /path/to/any/file"
echo "  3. Or run: scripts/verify-setup.sh"
echo ""
echo "Or ask your agent: 'Save a memory that Auto-Drive is now configured'"
echo ""
