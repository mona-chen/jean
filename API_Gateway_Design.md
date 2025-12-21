# TMCP API Gateway and Request Routing Design

## 1. Overview

The TMCP API Gateway serves as the single entry point for all client requests to the TMCP ecosystem. It handles request routing, authentication, rate limiting, protocol translation, and provides a unified interface to the various microservices.

## 2. System Architecture

```mermaid
graph TB
    Client[Client Applications] --> LB[Load Balancer]
    LB --> AG1[API Gateway 1]
    LB --> AG2[API Gateway 2]
    LB --> AGN[API Gateway N]
    
    AG1 --> Auth[Authentication Service]
    AG1 --> Rate[Rate Limiter]
    AG1 --> Router[Request Router]
    AG1 --> Validator[Request Validator]
    AG1 --> Monitor[Gateway Monitor]
    
    Router --> AuthSvc[Authentication Service]
    Router --> StoreSvc[App Store Service]
    Router --> PaySvc[Payment Service]
    Router --> StorSvc[Storage Service]
    Router --> ALSvc[App Lifecycle Service]
    
    Rate --> Redis[(Redis Cluster)]
    Auth --> TokenStore[(Token Store)]
    
    subgraph "Service Mesh"
        AuthSvc
        StoreSvc
        PaySvc
        StorSvc
        ALSvc
    end
    
    subgraph "External Services"
        OAuth[OAuth Provider]
        PaymentProc[Payment Processors]
        CDN[Content Delivery Network]
    end
    
    AuthSvc --> OAuth
    PaySvc --> PaymentProc
    StoreSvc --> CDN
```

## 3. Request Flow

### 3.1 Request Processing Pipeline

```mermaid
sequenceDiagram
    participant C as Client
    participant LB as Load Balancer
    participant AG as API Gateway
    participant Auth as Auth Service
    participant Rate as Rate Limiter
    participant Router as Request Router
    participant Svc as Backend Service
    
    C->>LB: HTTP Request
    LB->>AG: Forward request
    AG->>Auth: Validate authentication
    Auth->>AG: Authentication result
    AG->>Rate: Check rate limits
    Rate->>AG: Rate limit result
    AG->>AG: Validate request
    AG->>Router: Route to service
    Router->>Svc: Forward request
    Svc->>Router: Service response
    Router->>AG: Process response
    AG->>C: HTTP Response
```

### 3.2 Request Routing Decision Tree

```mermaid
graph TD
    A[Incoming Request] --> B{Authentication Required?}
    B -->|Yes| C[Validate Token]
    B -->|No| D[Public Endpoint]
    C --> E{Valid Token?}
    E -->|Yes| F[Check Scopes]
    E -->|No| G[Return 401]
    F --> H{Sufficient Scopes?}
    H -->|Yes| I[Check Rate Limits]
    H -->|No| J[Return 403]
    D --> I
    I --> K{Within Limits?}
    K -->|Yes| L[Route to Service]
    K -->|No| M[Return 429]
    L --> N[Service Response]
    N --> O[Format Response]
    O --> P[Return Response]
    G --> P
    J --> P
    M --> P
```

## 4. API Gateway Components

### 4.1 Authentication Handler

**Responsibilities:**
- Token validation and extraction
- JWT signature verification
- Token expiration checking
- User context extraction

**Implementation:**
```javascript
class AuthenticationHandler {
  async validateToken(request) {
    const token = this.extractToken(request);
    if (!token) return null;
    
    const payload = await this.verifyJWT(token);
    if (!payload || this.isExpired(payload)) return null;
    
    return {
      userId: payload.sub,
      appId: payload.app_id,
      scopes: payload.scp,
      expiresAt: payload.exp
    };
  }
}
```

### 4.2 Rate Limiter

**Responsibilities:**
- Rate limit enforcement
- Distributed rate limiting
- Multiple limit types (user, IP, endpoint)
- Configurable limit policies

**Rate Limiting Algorithms:**
1. **Token Bucket** - Smooth rate limiting
2. **Sliding Window** - Precise rate control
3. **Fixed Window** - Simple implementation

**Configuration:**
```yaml
rate_limits:
  default:
    requests_per_minute: 100
    burst: 20
  
  authentication:
    requests_per_minute: 10
    burst: 5
  
  payments:
    requests_per_minute: 30
    burst: 10
    
  storage:
    requests_per_minute: 200
    burst: 50
```

### 4.3 Request Router

**Responsibilities:**
- Path-based routing
- Service discovery integration
- Load balancing
- Circuit breaker pattern

**Routing Configuration:**
```yaml
routes:
  - path: "/auth/v1/*"
    service: "authentication-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    auth_required: false
    
  - path: "/store/v1/*"
    service: "app-store-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    auth_required: true
    scopes: ["profile"]
    
  - path: "/payments/v1/*"
    service: "payment-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    auth_required: true
    scopes: ["payment:read", "payment:write"]
    
  - path: "/storage/v1/*"
    service: "storage-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    auth_required: true
    scopes: ["storage:read", "storage:write"]
```

### 4.4 Request Validator

**Responsibilities:**
- Request schema validation
- Input sanitization
- Size limits enforcement
- Content type validation

**Validation Rules:**
```json
{
  "validation_rules": {
    "max_request_size": "10MB",
    "max_header_size": "8KB",
    "allowed_content_types": [
      "application/json",
      "application/x-www-form-urlencoded",
      "multipart/form-data"
    ],
    "sanitization": {
      "remove_html": true,
      "trim_strings": true,
      "normalize_unicode": true
    }
  }
}
```

## 5. API Versioning Strategy

### 5.1 Versioning Approaches

```mermaid
graph LR
    A[Versioning Strategies] --> B[URL Path Versioning]
    A --> C[Header Versioning]
    A --> D[Query Parameter Versioning]
    
    B --> B1[/v1/resource]
    B --> B2[/v2/resource]
    
    C --> C1[Accept: application/vnd.tmcp.v1+json]
    C --> C2[API-Version: v1]
    
    D --> D1[?version=v1]
    D --> D2[?api_version=v2]
```

**Chosen Strategy: URL Path Versioning**
- Clear and explicit versioning
- Easy to implement and understand
- Supports multiple versions simultaneously
- Simple for client developers

### 5.2 Version Compatibility

```mermaid
stateDiagram-v2
    [*] --> v1
    v1 --> v2: New features
    v1 --> v1_maintenance: Bug fixes only
    v2 --> v3: Breaking changes
    v2 --> v2_maintenance: Bug fixes only
    v1_maintenance --> Deprecated: EOL announced
    v2_maintenance --> Deprecated: EOL announced
    Deprecated --> [*]: Version removed
    
    note right of v1
        Current stable version
        Full support
        New features
    end note
    
    note right of v2
        Next version
        Backward compatible
        Gradual migration
    end note
```

## 6. Security Implementation

### 6.1 Security Headers

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### 6.2 CORS Configuration

```yaml
cors:
  default:
    allowed_origins: ["https://tween.com", "https://*.tween.com"]
    allowed_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allowed_headers: ["Authorization", "Content-Type", "X-API-Version"]
    max_age: 86400
    credentials: true
  
  public_endpoints:
    allowed_origins: ["*"]
    allowed_methods: ["GET", "OPTIONS"]
    allowed_headers: ["Content-Type"]
    max_age: 3600
    credentials: false
```

### 6.3 Request/Response Filtering

**Input Filtering:**
- SQL injection prevention
- XSS attack prevention
- Path traversal prevention
- Command injection prevention

**Output Filtering:**
- Sensitive data redaction
- PII filtering
- Error message sanitization
- Response size limits

## 7. Performance Optimization

### 7.1 Caching Strategy

```mermaid
graph TB
    Request[Client Request] --> AG[API Gateway]
    AG --> Cache[Cache Layer]
    Cache --> Hit{Cache Hit?}
    Hit -->|Yes| Response[Cached Response]
    Hit -->|No| Backend[Backend Service]
    Backend --> Cache[Update Cache]
    Cache --> Response
    
    subgraph "Cache Types"
        L1[Response Cache]
        L2[Authentication Cache]
        L3[Rate Limit Cache]
    end
    
    Cache --> L1
    Cache --> L2
    Cache --> L3
```

**Cache Configuration:**
```yaml
cache:
  response_cache:
    ttl: 300  # 5 minutes
    max_size: 100MB
    vary_by: ["Authorization", "Accept-Language"]
  
  auth_cache:
    ttl: 60   # 1 minute
    max_size: 50MB
    
  rate_limit_cache:
    ttl: 3600  # 1 hour
    max_size: 200MB
```

### 7.2 Connection Pooling

**Backend Connection Pools:**
- HTTP/2 connection multiplexing
- Keep-alive connections
- Connection timeout configuration
- Circuit breaker implementation

**Database Connection Pools:**
- Read/write splitting
- Connection health checks
- Automatic failover
- Connection retry logic

## 8. Monitoring and Observability

### 8.1 Metrics Collection

**Gateway Metrics:**
- Request count and rate
- Response time percentiles
- Error rates by endpoint
- Authentication success/failure rates
- Rate limit violations

**Service Metrics:**
- Service response times
- Service health status
- Circuit breaker state
- Connection pool utilization

### 8.2 Distributed Tracing

```mermaid
sequenceDiagram
    participant Client
    participant Gateway
    participant Auth
    participant Service
    
    Client->>Gateway: Request with trace-id
    Gateway->>Gateway: Generate span-id
    Gateway->>Auth: Forward with trace context
    Auth->>Service: Forward with trace context
    Service->>Auth: Response with trace context
    Auth->>Gateway: Response with trace context
    Gateway->>Client: Response with trace headers
```

**Trace Headers:**
```
X-Trace-Id: unique-trace-identifier
X-Parent-Span-Id: parent-span-identifier
X-Span-Id: current-span-identifier
X-Sampled: true/false
```

## 9. Error Handling

### 9.1 Error Response Format

```json
{
  "error": {
    "code": "PAYMENT_REQUIRED",
    "message": "Payment method required for this operation",
    "details": {
      "field": "payment_method_id",
      "reason": "missing_required_field"
    },
    "request_id": "req_123456789",
    "timestamp": "2025-12-20T01:15:00Z"
  }
}
```

### 9.2 Error Classification

| Error Type | HTTP Status | Description |
|------------|-------------|-------------|
| Client Error | 4xx | Invalid request, authentication, authorization |
| Server Error | 5xx | Internal service failures |
| Rate Limit | 429 | Too many requests |
| Service Unavailable | 503 | Service temporarily unavailable |

## 10. Configuration Management

### 10.1 Dynamic Configuration

```yaml
gateway:
  port: 8080
  tls_port: 8443
  max_connections: 10000
  request_timeout: 30s
  
services:
  authentication:
    url: "http://auth-service:8080"
    timeout: 5s
    retries: 3
  
  app_store:
    url: "http://app-store-service:8080"
    timeout: 10s
    retries: 2
```

### 10.2 Environment-Specific Configs

**Development:**
- Debug logging enabled
- Relaxed security headers
- Mock services for testing
- Local database connections

**Production:**
- Strict security configuration
- Comprehensive monitoring
- High availability setup
- Production service endpoints

## 11. Deployment Architecture

### 11.1 High Availability Setup

```mermaid
graph TB
    Internet --> CDN[Content Delivery Network]
    CDN --> LB[Load Balancer]
    LB --> AG1[API Gateway Primary]
    LB --> AG2[API Gateway Secondary]
    LB --> AG3[API Gateway Tertiary]
    
    AG1 --> ServiceMesh[Service Mesh]
    AG2 --> ServiceMesh
    AG3 --> ServiceMesh
    
    ServiceMesh --> Services[Backend Services]
    
    subgraph "Monitoring"
        Monitor[Monitoring Stack]
        Alert[Alerting System]
    end
    
    AG1 --> Monitor
    AG2 --> Monitor
    AG3 --> Monitor
    Monitor --> Alert
```

### 11.2 Scaling Strategy

**Horizontal Scaling:**
- Auto-scaling based on CPU/memory
- Request-based scaling triggers
- Geographic distribution
- Blue-green deployments

**Vertical Scaling:**
- Resource allocation optimization
- Performance tuning
- Connection limit adjustments
- Cache size optimization

This API Gateway design provides a robust, secure, and scalable entry point for the TMCP ecosystem, ensuring proper request routing, authentication, rate limiting, and monitoring for all client interactions.