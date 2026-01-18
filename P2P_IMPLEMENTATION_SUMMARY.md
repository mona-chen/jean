# TMCP v1.8.0 P2P Transfer Implementation Summary

## Implementation Overview

This document summarizes the implementation of TMCP Protocol v1.8.0 Section 7.2 (Flexible Authorization for P2P Transfers) in the jean (TMCP Server) project.

## Changes Made

### 1. WalletService Enhancements

**File: `app/services/wallet_service.rb`**

Added `confirm_p2p_transfer` method to support new flexible authorization flow:
```ruby
def self.confirm_p2p_transfer(transfer_id, auth_proof, user_id)
  # Confirms P2P transfer with biometric, PIN, or OTP auth
  # Calls tween-pay wallet service endpoint
end
```

### 2. WalletController Updates

**File: `app/controllers/api/v1/wallet_controller.rb`**

#### Updated `initiate_p2p` action (Section 7.2.3)
- Returns available auth methods from wallet service
- Includes `recipient_acceptance_required` status
- Supports `note` parameter
- Properly handles idempotency
- Publishes Matrix events on completion

#### Added `confirm_p2p` action (Section 7.2.4)
- New endpoint: `POST /api/v1/wallet/p2p/:transfer_id/confirm`
- Validates `auth_proof` parameter
- Supports three auth methods:
  - **Biometric**: Requires signature, device_id, timestamp
  - **PIN**: Requires hashed_pin, device_id, timestamp
  - **OTP**: Requires otp_code, timestamp
- Calls Wallet Service confirm endpoint
- Publishes Matrix status updates

#### Route Update
**File: `config/routes.rb`**
```ruby
post "wallet/p2p/:transfer_id/confirm", to: "wallet#confirm_p2p"
```

### 3. Matrix Event Service Updates

**File: `app/services/matrix_event_service.rb`**

#### Updated `publish_p2p_transfer` method
- Adds `recipient_acceptance_required` to event content
- Includes `expires_at` when acceptance is required
- Adds action buttons for acceptance/rejection when required:
  ```json
  {
    "type": "accept",
    "label": "Confirm Receipt",
    "endpoint": "/wallet/v1/p2p/{transfer_id}/accept"
  },
  {
    "type": "reject",
    "label": "Decline",
    "endpoint": "/wallet/v1/p2p/{transfer_id}/reject"
  }
  ```

#### Updated `publish_p2p_status_update` method
- Adds visual indicators for different statuses:
  - ✓ Completed (green)
  - ✕ Rejected (red)
  - ⏰ Expired (gray)
  - ⏳ Pending (yellow)
- Includes `status_text` for client rendering

### 4. Scheduled Job for Expired Transfers

**New File: `app/jobs/process_expired_p2p_transfers_job.rb`**

Background job to automatically expire pending acceptance transfers:
- Queries wallet service for expired transfers
- Initiates rejection for expired transfers
- Publishes Matrix status updates
- Logs processing results

Usage:
```ruby
ProcessExpiredP2PTransfersJob.perform_later
```

### 5. Test Suite Updates

**File: `test/controllers/api/v1/wallet_controller_test.rb`**

Added new test cases for flexible authorization:

1. **Biometric Auth Confirm** (`test_should_confirm_P2P_transfer_with_biometric_auth`)
   - Tests signature-based auth proof
   - Validates device_id and timestamp

2. **PIN Auth Confirm** (`test_should_confirm_P2P_transfer_with_PIN_auth`)
   - Tests hashed PIN auth proof
   - Validates device_id inclusion

3. **OTP Auth Confirm** (`test_should_confirm_P2P_transfer_with_OTP_auth`)
   - Tests OTP code auth proof
   - Validates timestamp

4. **Missing Auth Proof** (`test_should_require_auth_proof_for_confirm`)
   - Validates error handling when auth_proof is missing

**New File: `test/integration/p2p_transfer_integration_test.rb`**

End-to-end integration tests:
- Complete flow with biometric auth
- Complete flow with PIN auth
- Complete flow with OTP auth
- Rejection flow
- Matrix event publishing

## Protocol Compliance

### Section 7.2.1: Authorization Methods
✓ Biometric support (signature, device_id, timestamp)
✓ PIN support (hashed_pin, device_id, timestamp)
✓ OTP support (otp_code, timestamp)
✓ Fallback logic (client-side)
✓ Proof type validation

### Section 7.2.3: Initiate Transfer
✓ Available auth methods in response
✓ Recipient acceptance requirement indicator
✓ Idempotency key support
✓ Pre-authorization check integration (ready for tween-pay internal API)

### Section 7.2.4: Confirm Transfer
✓ auth_proof validation
✓ Method-specific proof validation
✓ Transfer status updates
✓ Matrix event publishing

### Section 7.2.7: Recipient Acceptance Protocol
✓ Conditional acceptance flow
✓ Accept/reject endpoints
✓ Auto-expiry handling
✓ Status update events

### Matrix Events (Section 8.1)
✓ `m.tween.wallet.p2p` with acceptance status
✓ `m.tween.wallet.p2p.status` with visual indicators
✓ Action buttons for acceptance/rejection
✓ Expiry timestamp inclusion

## P2P State Machine

```
INITIATED → PENDING_AUTHORIZATION → AUTHORIZED
                                        ↓
                              PENDING_RECIPIENT_ACCEPTANCE → COMPLETED
                                        ↓                        ↓
                                   ACCEPTED             EXPIRED (24h)
                                        ↓                        ↓
                                    COMPLETED            REJECTED
```

## Configuration

### Required Environment Variables

```bash
WALLET_API_BASE_URL=http://localhost:3300  # Tween-pay wallet service URL
WALLET_INTERNAL_API_KEY=<internal_key>   # For internal API calls
```

### Database

No schema changes required for TMCP Server.
All P2P transfer state is managed by tween-pay wallet service.

## Testing

### Unit Tests
```bash
rails test test/controllers/api/v1/wallet_controller_test.rb
```

### Integration Tests
```bash
rails test test/integration/p2p_transfer_integration_test.rb
```

### Manual Testing

#### 1. Initiate P2P Transfer
```bash
curl -X POST http://localhost:3001/api/v1/wallet/p2p/initiate \
  -H "Authorization: Bearer <TEP_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "recipient": "@bob:tween.example",
    "amount": 5000.00,
    "currency": "USD",
    "idempotency_key": "unique-uuid"
  }'
```

#### 2. Confirm with Biometric Auth
```bash
curl -X POST http://localhost:3001/api/v1/wallet/p2p/p2p_abc123/confirm \
  -H "Authorization: Bearer <TEP_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "auth_proof": {
      "method": "biometric",
      "proof": {
        "signature": "<base64_signature>",
        "device_id": "device_xyz789",
        "timestamp": "2025-01-18T14:30:15Z"
      }
    }
  }'
```

#### 3. Confirm with PIN Auth
```bash
curl -X POST http://localhost:3001/api/v1/wallet/p2p/p2p_abc123/confirm \
  -H "Authorization: Bearer <TEP_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "auth_proof": {
      "method": "pin",
      "proof": {
        "hashed_pin": "<sha256_hash>",
        "device_id": "device_xyz789",
        "timestamp": "2025-01-18T14:30:15Z"
      }
    }
  }'
```

#### 4. Confirm with OTP Auth
```bash
curl -X POST http://localhost:3001/api/v1/wallet/p2p/p2p_abc123/confirm \
  -H "Authorization: Bearer <TEP_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "auth_proof": {
      "method": "otp",
      "proof": {
        "otp_code": "123456",
        "timestamp": "2025-01-18T14:30:15Z"
      }
    }
  }'
```

## Known Limitations

1. **TEP Token Validation**: tween-pay requires valid TEP tokens for TMCP endpoints. Internal TMCP Server to Wallet Service communication needs TEP token generation or middleware bypass.

2. **Internal API Integration**: Pre-authorization check endpoint (`/api/v1/internal/user/{user_id}/auth-policy`) exists in tween-pay but TEP validation blocks internal calls.

3. **Circuit Breaker**: Wallet Service calls are wrapped in circuit breakers which may block requests after failures.

## Next Steps

1. Resolve TEP token validation for internal TMCP Server ↔ Wallet Service communication
2. Enable scheduled job in production (cron/sidekiq configuration)
3. Add rate limiting for P2P endpoints
4. Implement webhook delivery for hybrid mini-apps (Section 9.1.2)
5. Add metrics and monitoring for P2P transfer flows

## References

- TMCP Protocol v1.8.0 - Section 7.2: Peer-to-Peer Transfer
- PROTO.md: `/config/workspace/jean/docs/PROTO.md`
- Tween-Pay API: `http://localhost:3300/docs`
