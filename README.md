# TMCP Server - Tween Mini-App Communication Protocol

The TMCP Server is a Rails-based Application Service that implements the Tween Mini-App Communication Protocol for secure communication between instant messaging applications and third-party mini-applications.

## Architecture

This server implements the TMCP protocol as defined in [PROTO.md](docs/PROTO.md), providing:

- **OAuth 2.0 + PKCE Authentication** with Matrix Authentication Service (MAS) integration
- **Matrix Session Delegation** for authenticated users (RFC 8693)
- **Device Authorization Grant** (RFC 8628) for new users
- **Authorization Code Flow with PKCE** (RFC 7636) for web mini-apps
- **TEP Token Management** for mini-app sessions
- **Wallet Integration** with P2P transfers and payments
- **Mini-App Storage** with quotas and TTL
- **Matrix Application Service** for event routing
- **Group Gift Distribution** and payment processing

## Key Components

- **Matrix Synapse**: `core.tween.im` (Homeserver)
- **Matrix Authentication Service (MAS)**: `mas.tween.example` (OAuth Identity Provider)
- **TMCP Server**: Current repository (Application Service)

## Quick Start

### Prerequisites

- Ruby 3.4.4
- PostgreSQL (production) or SQLite (development)
- Matrix Synapse homeserver
- Matrix Authentication Service (MAS) for OAuth 2.0

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd tmcp-server

# Install dependencies
bundle install

# Set up environment variables
cp .env.example .env
# Edit .env with your MAS and Matrix configurations

# Set up database
rails db:setup

# Run tests
rails test

# Start the server
rails server
```

### Configuration

Key environment variables:

```bash
# Matrix Authentication Service (MAS)
MAS_URL=https://mas.tween.example
MAS_CLIENT_ID=tmcp-server
MAS_CLIENT_SECRET=your-client-secret
MAS_TOKEN_URL=https://mas.tween.example/oauth2/token
MAS_INTROSPECTION_URL=https://mas.tween.example/oauth2/introspect
MAS_REVOCATION_URL=https://mas.tween.example/oauth2/revoke

# Matrix Integration
MATRIX_API_URL=https://core.tween.im
MATRIX_HS_TOKEN=your-homeserver-token

# Database
DATABASE_URL=postgresql://user:pass@localhost/tmcp_production
```

## API Endpoints

### OAuth 2.0 + PKCE
- `GET /api/v1/oauth/authorize` - Authorization request (web mini-apps)
- `POST /api/v1/oauth/token` - Token exchange (Matrix Session Delegation)
- `POST /api/v1/oauth2/device/authorization` - Device authorization (RFC 8628)
- `POST /api/v1/oauth2/device/token` - Device token polling
- `POST /api/v1/oauth/consent` - Scope consent approval

### Wallet Operations
- `GET /api/v1/wallet/balance` - Get wallet balance
- `GET /api/v1/wallet/transactions` - Transaction history
- `POST /api/v1/wallet/p2p/initiate` - P2P transfer
- `GET /api/v1/wallet/resolve/:user_id` - User resolution

### Payment Processing
- `POST /api/v1/payments/request` - Payment request
- `POST /api/v1/payments/:id/authorize` - Payment authorization
- `POST /api/v1/payments/:id/mfa/verify` - MFA verification

### Mini-App Storage
- `GET /api/v1/storage` - List storage entries
- `POST /api/v1/storage` - Create storage entry
- `GET /api/v1/storage/:key` - Get storage value
- `PUT /api/v1/storage/:key` - Update storage value
- `DELETE /api/v1/storage/:key` - Delete storage entry

### Matrix AS Endpoints
- `POST /_matrix/app/v1/transactions/:txn_id` - Event processing
- `GET /_matrix/app/v1/users/:user_id` - User queries
- `GET /_matrix/app/v1/rooms/:room_alias` - Room queries
- `GET /_matrix/app/v1/ping` - Health check

## Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run with coverage
rails test --verbose
```

## Documentation

All architectural documentation is available in the `docs/` directory:

- [PROTO.md](docs/PROTO.md) - Complete protocol specification
- [TMCP_Architecture_Plan.md](docs/TMCP_Architecture_Plan.md) - System architecture
- [Deployment_Architecture_Design.md](docs/Deployment_Architecture_Design.md) - Deployment guide

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

Copyright (c) 2025 Tween IM. All rights reserved.