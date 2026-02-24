#!/usr/bin/env bash
# Update the Auto-Drive API key without re-running full setup
# Usage: ./scripts/update-api-key.sh
# Env: AUTO_DRIVE_API_KEY may be set to skip the prompt (non-interactive use)

set -euo pipefail

# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

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

autodrive_verify_key "$API_KEY"
autodrive_save_key "$API_KEY"

echo ""
echo "API key updated. Restart the OpenClaw gateway to apply."
