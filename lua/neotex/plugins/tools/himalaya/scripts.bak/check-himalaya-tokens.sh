#!/usr/bin/env bash
# Check himalaya token storage

echo "=== Checking Himalaya Token Storage ==="
echo

echo "1. Tokens with service='himalaya' (what himalaya uses):"
secret-tool search service himalaya 2>/dev/null | grep -E "(attribute.username|secret)" | while read -r line; do
  if [[ "$line" =~ attribute\.username.*=.*(.+) ]]; then
    username="${BASH_REMATCH[1]}"
    echo "  Token: $username"
  fi
done

echo
echo "2. Tokens with service='himalaya-cli' (what mbsync uses):"
secret-tool search service himalaya-cli 2>/dev/null | grep -E "attribute.username" | while read -r line; do
  if [[ "$line" =~ attribute\.username.*=.*(.+) ]]; then
    username="${BASH_REMATCH[1]}"
    echo "  Token: $username"
  fi
done

echo
echo "3. Checking if gmail-imap tokens exist:"
for service in himalaya himalaya-cli; do
  echo "  Service: $service"
  for token_type in access-token refresh-token client-secret; do
    # Check direct format (himalaya)
    if secret-tool lookup service "$service" username "gmail-imap-${token_type}" >/dev/null 2>&1; then
      echo "    ✓ gmail-imap-${token_type}"
    fi
    # Check mbsync format
    if secret-tool lookup service "$service" username "gmail-imap-imap-oauth2-${token_type}" >/dev/null 2>&1; then
      echo "    ✓ gmail-imap-imap-oauth2-${token_type}"
    fi
  done
done

echo
echo "4. Testing manual token refresh:"
if [[ -f ~/.config/nvim/lua/neotex/plugins/tools/himalaya/scripts/refresh-himalaya-oauth2-direct ]]; then
  echo "  Running direct refresh script..."
  ~/.config/nvim/lua/neotex/plugins/tools/himalaya/scripts/refresh-himalaya-oauth2-direct gmail-imap
else
  echo "  Direct refresh script not found"
fi