# Matrix Session Delegation Authentication Flow

## Overview

Matrix Session Delegation allows users who are already logged into their Matrix client (Element) to seamlessly access TMCP mini-apps without additional authentication. This is the primary authentication method for TMCP.

## How It Works

### Step 1: User Opens Mini-App
```
User in Element Matrix client
    ↓
Clicks on mini-app in chat or room
    ↓
Element detects TMCP mini-app
    ↓
Element prepares Matrix access token
```

### Step 2: Token Exchange Request
```
Element → TMCP Server OAuth endpoint

POST /api/v1/oauth/token
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  grant_type=urn:ietf:params:oauth:grant-type:token-exchange
  subject_token=<MATRIX_ACCESS_TOKEN>
  subject_token_type=urn:ietf:params:oauth:token-type:access_token
  client_id=ma_tweenpay
  scope=user:read wallet:balance
  requested_token_type=urn:tmcp:params:oauth:token-type:tep
```

### Step 3: TMCP Server Validation
```
TMCP Server receives request
    ↓
Validates mini-app exists (client_id)
    ↓
Introspects Matrix token with MAS
POST /oauth2/introspect
  token=<MATRIX_ACCESS_TOKEN>
    ↓
Receives: { "active": true, "sub": "@alice:tween.example" }
    ↓
Validates user permissions and scopes
    ↓
Generates TEP token with claims
```

### Step 4: Dual Token Response
```
TMCP Server → Element

HTTP 200 OK
{
  "access_token": "tep.eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "refresh_token": "rt_abc123",
  "matrix_access_token": "syt_new_matrix_token",
  "matrix_expires_in": 300,
  "user_id": "@alice:tween.example",
  "wallet_id": "tw_alice_123",
  "delegated_session": true
}
```

### Step 5: Mini-App Launch
```
Element receives tokens
    ↓
TEP token stored securely (Keychain/EncryptedSharedPrefs)
    ↓
Matrix token stored in memory only
    ↓
Mini-app loads with TEP authentication
    ↓
User can now use wallet, payments, etc.
```

## Technical Details

### TEP Token Claims
```json
{
  "iss": "https://tmcp.tween.example",
  "sub": "@alice:tween.example",
  "aud": "ma_tweenpay",
  "exp": 1735689600,
  "iat": 1735603200,
  "jti": "unique-token-id-abc123",
  "token_type": "tep_access_token",
  "client_id": "ma_tweenpay",
  "scope": "user:read wallet:balance",
  "wallet_id": "tw_alice_123",
  "session_id": "session_xyz789",
  "mas_session": {
    "active": true,
    "refresh_token_id": "rt_abc123"
  },
  "delegated_session": "matrix_session"
}
```

### Security Features

1. **Matrix Token Introspection**: Validates user identity via MAS
2. **Scope Authorization**: Checks user permissions for requested scopes
3. **TEP Token Signing**: Cryptographically signed JWT with RS256
4. **Short-lived Matrix Tokens**: New Matrix token issued for TMCP operations
5. **Secure Token Storage**: TEP tokens encrypted, Matrix tokens in memory

### Error Handling

#### Consent Required
```json
HTTP 403 Forbidden
{
  "error": "consent_required",
  "error_description": "User must approve sensitive scopes",
  "consent_required_scopes": ["wallet:pay"],
  "pre_approved_scopes": ["user:read"],
  "consent_ui_endpoint": "/oauth2/consent?session=xyz123"
}
```

#### Invalid Token
```json
HTTP 401 Unauthorized
{
  "error": "invalid_token",
  "error_description": "Matrix token is invalid or expired"
}
```

### User Experience

1. **Zero Additional Steps**: User taps mini-app, it just works
2. **Transparent Authentication**: No username/password prompts
3. **Seamless Integration**: Uses existing Matrix session
4. **Progressive Consent**: Sensitive permissions require explicit approval

### Implementation in TMCP Server

```ruby
# app/controllers/api/v1/oauth_controller.rb
def token
  # 1. Parse token exchange request
  grant_type = params[:grant_type]
  matrix_token = params[:subject_token]
  mini_app_id = params[:client_id]

  # 2. Validate mini-app exists
  mini_app = MiniApp.find_by(app_id: mini_app_id)

  # 3. Introspect Matrix token with MAS
  user_info = MasClient.introspect_token(matrix_token)

  # 4. Generate TEP token
  tep_token = TepTokenService.encode(
    user_id: user_info["sub"],
    miniapp_id: mini_app_id,
    scopes: requested_scopes
  )

  # 5. Exchange for fresh Matrix token
  new_matrix_token = MasClient.token_exchange(matrix_token)

  # 6. Return dual tokens
  render json: {
    access_token: tep_token,
    matrix_access_token: new_matrix_token,
    user_id: user_info["sub"],
    delegated_session: true
  }
end
```

## Summary

Matrix Session Delegation provides:
- ✅ **Seamless UX**: No additional login required
- ✅ **Strong Security**: MAS-backed token validation
- ✅ **Dual Tokens**: Separate TEP + Matrix tokens
- ✅ **Scope Control**: Granular permission management
- ✅ **Consent Flow**: Progressive permission granting

This flow enables the core TMCP value proposition: integrated mini-apps within the Matrix ecosystem without compromising security or user experience.