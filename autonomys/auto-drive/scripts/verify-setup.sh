#!/usr/bin/env bash
# Verify Auto-Drive setup — checks API key, account info, and remaining credits
# Usage: ./scripts/verify-setup.sh

set -euo pipefail

API_BASE="https://mainnet.auto-drive.autonomys.xyz/api"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=== Auto-Drive Setup Verification ==="
echo ""

# Check for API key
if [[ -z "${AUTO_DRIVE_API_KEY:-}" ]]; then
  echo -e "${RED}✗ AUTO_DRIVE_API_KEY is not set${NC}" >&2
  echo "  Run: scripts/setup-auto-drive.sh" >&2
  exit 1
fi
echo -e "${GREEN}✓ AUTO_DRIVE_API_KEY is set${NC}"

# Verify key and fetch account info
RESPONSE=$(curl -sS -w "\n%{http_code}" "$API_BASE/accounts/@me" \
  -H "Authorization: Bearer $AUTO_DRIVE_API_KEY" \
  -H "X-Auth-Provider: apikey")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
  echo -e "${RED}✗ API key verification failed (HTTP $HTTP_CODE)${NC}" >&2
  echo "$BODY" >&2
  echo "  The key may be invalid or expired. Run: scripts/update-api-key.sh" >&2
  exit 1
fi
echo -e "${GREEN}✓ API key is valid${NC}"

# Display account details
LIMIT=$(echo "$BODY" | jq -r '.uploadLimit // .limits.uploadLimit // empty' 2>/dev/null || true)
USED=$(echo "$BODY" | jq -r '.uploadedBytes // .limits.uploadedBytes // empty' 2>/dev/null || true)

if [[ -n "$LIMIT" && -n "$USED" ]]; then
  REMAINING=$((LIMIT - USED))
  LIMIT_MB=$(echo "scale=1; $LIMIT / 1048576" | bc 2>/dev/null || echo "$LIMIT bytes")
  USED_MB=$(echo "scale=1; $USED / 1048576" | bc 2>/dev/null || echo "$USED bytes")
  REMAINING_MB=$(echo "scale=1; $REMAINING / 1048576" | bc 2>/dev/null || echo "$REMAINING bytes")
  echo "  Upload limit:    ${LIMIT_MB} MB / month"
  echo "  Used this month: ${USED_MB} MB"
  if [[ "$REMAINING" -lt 1048576 ]]; then
    echo -e "  Remaining:       ${YELLOW}${REMAINING_MB} MB (low)${NC}"
  else
    echo -e "  Remaining:       ${GREEN}${REMAINING_MB} MB${NC}"
  fi
fi

# Check prerequisites
echo ""
MISSING=()
for bin in curl jq file; do
  if command -v "$bin" &>/dev/null; then
    echo -e "  ${GREEN}✓ $bin${NC}"
  else
    echo -e "  ${RED}✗ $bin not found${NC}"
    MISSING+=("$bin")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo -e "${RED}✗ Missing prerequisites: ${MISSING[*]}${NC}" >&2
  exit 1
fi

echo ""
echo -e "${GREEN}All checks passed. Auto-Drive is ready.${NC}"
echo ""
echo "Try: scripts/autodrive-upload.sh /path/to/any/file"
echo ""
