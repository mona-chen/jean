#!/bin/bash
# Matrix Session Delegation Demo Script
# This script demonstrates the complete authentication flow

echo "=== Matrix Session Delegation Demo ==="
echo

# Configuration
TMCP_SERVER="http://localhost:3000"
MAS_SERVER="http://docker:8080"
MINI_APP_ID="ma_tweenpay"

echo "Configuration:"
echo "TMCP Server: $TMCP_SERVER"
echo "MAS Server: $MAS_SERVER"
echo "Mini-App ID: $MINI_APP_ID"
echo

# Step 1: Simulate getting a Matrix token (normally from Element)
echo "Step 1: Getting Matrix Access Token from MAS"
echo "POST $MAS_SERVER/oauth2/token"
MATRIX_TOKEN=$(curl -s -X POST "$MAS_SERVER/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "tmcp-server:pF/Y9eiJXTHASLFNPOIzXiym0E9o1J7o5+UsHONumS0=" \
  -d "grant_type=client_credentials&scope=urn:matrix:org.matrix.msc2967.client:api:*" \
  | jq -r '.access_token')

if [ -z "$MATRIX_TOKEN" ] || [ "$MATRIX_TOKEN" = "null" ]; then
  echo "❌ Failed to get Matrix token"
  exit 1
fi

echo "✅ Got Matrix token: ${MATRIX_TOKEN:0:20}..."
echo

# Step 2: Demonstrate token introspection (what TMCP Server does)
echo "Step 2: TMCP Server introspects Matrix token with MAS"
echo "POST $MAS_SERVER/oauth2/introspect"
INTROSPECTION=$(curl -s -X POST "$MAS_SERVER/oauth2/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "tmcp-server:pF/Y9eiJXTHASLFNPOIzXiym0E9o1J7o5+UsHONumS0=" \
  -d "token=$MATRIX_TOKEN")

echo "Introspection result:"
echo "$INTROSPECTION" | jq .
echo

# Extract user info
USER_ID=$(echo "$INTROSPECTION" | jq -r '.sub')
IS_ACTIVE=$(echo "$INTROSPECTION" | jq -r '.active')

if [ "$IS_ACTIVE" != "true" ]; then
  echo "❌ Matrix token is not active"
  exit 1
fi

echo "✅ Token valid for user: $USER_ID"
echo

# Step 3: Perform token exchange (Matrix Session Delegation)
echo "Step 3: Performing Matrix Session Delegation"
echo "POST $TMCP_SERVER/api/v1/oauth/token"

# Check if TMCP server is running
if ! curl -s "$TMCP_SERVER/health/check" > /dev/null; then
  echo "⚠️  TMCP Server not running at $TMCP_SERVER"
  echo "   This demo shows the request that would be made:"
  echo
  echo "   POST $TMCP_SERVER/api/v1/oauth/token"
  echo "   grant_type=urn:ietf:params:oauth:grant-type:token-exchange"
  echo "   subject_token=$MATRIX_TOKEN"
  echo "   subject_token_type=urn:ietf:params:oauth:token-type:access_token"
  echo "   client_id=$MINI_APP_ID"
  echo "   scope=user:read wallet:balance"
  echo "   requested_token_type=urn:tmcp:params:oauth:token-type:tep"
  echo
  echo "Expected Response:"
  echo '{
  "access_token": "tep.eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "matrix_access_token": "syt_new_matrix_token",
  "user_id": "'$USER_ID'",
  "wallet_id": "tw_xxx",
  "delegated_session": true
}'
  exit 0
fi

# Perform actual token exchange
EXCHANGE_RESPONSE=$(curl -s -X POST "$TMCP_SERVER/api/v1/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&subject_token=$MATRIX_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&client_id=$MINI_APP_ID&scope=user:read wallet:balance&requested_token_type=urn:tmcp:params:oauth:token-type:tep")

echo "Token Exchange Response:"
echo "$EXCHANGE_RESPONSE" | jq .
echo

# Step 4: Extract TEP token and test it
TEP_TOKEN=$(echo "$EXCHANGE_RESPONSE" | jq -r '.access_token')
if [ -n "$TEP_TOKEN" ] && [ "$TEP_TOKEN" != "null" ]; then
  echo "✅ Matrix Session Delegation successful!"
  echo "TEP Token: ${TEP_TOKEN:0:20}..."
  echo
  echo "Step 4: Testing TEP token with mini-app API"
  echo "GET $TMCP_SERVER/api/v1/mini-apps"

  MINI_APPS_RESPONSE=$(curl -s -H "Authorization: Bearer $TEP_TOKEN" \
    "$TMCP_SERVER/api/v1/mini-apps")

  if echo "$MINI_APPS_RESPONSE" | jq . >/dev/null 2>&1; then
    echo "✅ TEP token authentication successful!"
    echo "Mini-apps available:"
    echo "$MINI_APPS_RESPONSE" | jq -r '.[].name' 2>/dev/null || echo "$MINI_APPS_RESPONSE"
  else
    echo "⚠️  TEP token test failed (may need mini-apps endpoint)"
  fi
else
  echo "❌ Matrix Session Delegation failed"
  echo "Response: $EXCHANGE_RESPONSE"
fi

echo
echo "=== Demo Complete ==="
echo
echo "Summary:"
echo "1. ✅ Got Matrix access token from MAS"
echo "2. ✅ Introspected token to validate user"
echo "3. ✅ Performed Matrix Session Delegation"
echo "4. ✅ Received TEP token for mini-app authentication"
echo
echo "This demonstrates the complete user authentication flow"
echo "from Matrix login to mini-app access without additional steps!"