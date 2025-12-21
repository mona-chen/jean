# TMCP Protocol Changelog

All notable changes to the Tween Mini-App Communication Protocol (TMCP) will be documented in this file.

## [1.2.0] - 2025-12-19

### Added
- **Section 7.4: Multi-Factor Authentication for Payments**
  - Added MFA challenge-response mechanism for payment authorization
  - Defined standard MFA method types (transaction_pin, biometric, totp)
  - Added device registration protocol for biometric MFA
  - Updated payment state machine to include MFA_REQUIRED state
  - Added Wallet Service MFA interface requirements

- **Section 10.3: Mini-App Storage System**
  - Added key-value storage protocol for mini-apps
  - Defined storage quotas (10MB per user/app, 1MB per key, 1000 keys)
  - Added offline storage support with conflict resolution
  - Implemented batch operations for efficiency
  - Added storage scopes (storage:read, storage:write) with auto-approval

- **Section 8.1.4: App Lifecycle Events**
  - Added Matrix events for app installation, updates, and uninstallation
  - Defined event formats for lifecycle tracking

- **Section 16: Official and Preinstalled Mini-Apps**
  - Added mini-app classification system (official, verified, community, beta)
  - Defined preinstallation manifest format and loading process
  - Added internal URL scheme (tween-internal://) for official apps
  - Implemented mini-app store protocol with discovery and installation
  - Added app ranking algorithm and trending detection
  - Defined privileged scopes for official apps
  - Added update management protocol with verification requirements
  - Modified OAuth flow for official apps to use PKCE with pre-approved basic scopes

- **Section 11.4.1: Rate Limiting Implementation Guidance**
  - Added required rate limit headers (X-RateLimit-*)
  - Defined token bucket/sliding window algorithm recommendation
  - Added 429 status code with retry_after header

- **Section 12.2: Additional Error Codes**
  - Added MFA_REQUIRED, MFA_LOCKED, INVALID_MFA_CREDENTIALS
  - Added STORAGE_QUOTA_EXCEEDED, APP_NOT_REMOVABLE, APP_NOT_FOUND, DEVICE_NOT_REGISTERED

### Security Enhancements
- Biometric attestation for MFA using device-bound keys
- Enhanced token security for official apps
- Audit logging requirements for privileged operations

### Implementation Guidance
- Added Section 16.10: OAuth Server Implementation with Keycloak
  - Comprehensive Keycloak realm configuration
  - Client registration process for mini-apps
  - Token service configuration with JWT signing
  - MFA service integration details

### Documentation
- Added Appendix D: Protocol Change Log for tracking evolution
- Updated Table of Contents to reflect new section numbering

---

## [Unreleased] - Future

### Planned
- None currently

---

## Format

This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with modifications for the TMCP protocol's specific needs.

### Types of Changes
- `Added` for new features
- `Changed` for modifications to existing features
- `Deprecated` for removed features
- `Security` for security-related changes
- `Documentation` for documentation updates