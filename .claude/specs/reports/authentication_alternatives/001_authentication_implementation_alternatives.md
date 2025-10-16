# Authentication Implementation Alternatives - Comprehensive Research Report

**Report ID:** 001
**Category:** Authentication Alternatives
**Date:** 2025-10-13
**Research Focus:** Modern authentication patterns, security best practices, and implementation options for 2025

---

## Executive Summary

This report provides a comprehensive analysis of alternative authentication implementation patterns available in 2025, ranging from traditional session-based approaches to modern passwordless authentication. The research covers security best practices, implementation patterns, popular frameworks, and emerging technologies.

**Key Findings:**
- Passwordless authentication (WebAuthn/FIDO2) is rapidly becoming the industry standard
- JWT-based stateless authentication dominates for microservices and APIs
- Hybrid approaches combining session and token-based auth are gaining traction
- API key management remains critical but requires proper security controls
- Authentication-as-a-Service platforms significantly reduce implementation complexity

---

## Table of Contents

1. [Authentication Patterns Overview](#authentication-patterns-overview)
2. [Session-Based Authentication](#session-based-authentication)
3. [Token-Based Authentication (JWT)](#token-based-authentication-jwt)
4. [OAuth 2.0 and OpenID Connect](#oauth-20-and-openid-connect)
5. [Passwordless Authentication](#passwordless-authentication)
6. [API Key Management](#api-key-management)
7. [Mutual TLS (mTLS)](#mutual-tls-mtls)
8. [Authentication Frameworks and Services](#authentication-frameworks-and-services)
9. [Security Best Practices](#security-best-practices)
10. [Implementation Recommendations](#implementation-recommendations)

---

## Authentication Patterns Overview

### Pattern Comparison Matrix

| Pattern | Use Case | Security Level | Scalability | Implementation Complexity | Best For |
|---------|----------|----------------|-------------|--------------------------|----------|
| Session-Based | Web applications | Medium-High | Medium | Low-Medium | Traditional web apps |
| JWT | APIs, microservices | Medium-High | High | Medium | Distributed systems |
| OAuth 2.0 | Third-party access | High | High | High | Social login, API delegation |
| WebAuthn/FIDO2 | Modern apps | Very High | High | Medium-High | Passwordless experiences |
| API Keys | Service-to-service | Medium | High | Low | Developer APIs, integrations |
| mTLS | B2B, microservices | Very High | Medium | High | Zero-trust environments |

### Current Codebase Context

Based on analysis of the Neovim configuration codebase at `/home/benjamin/.config/nvim/`, the current implementation uses:

- **Session-based state management** for Claude AI integration (`session.lua`, `session-manager.lua`)
- **API key authentication** for external services (Avante AI, Claude API)
- **Environment variable storage** for credentials (`gmail-oauth2.env`)
- **File-based session persistence** (JSONL format for session history)

**Current Pattern:**
```lua
-- Session state stored in local files
local state_dir = vim.fn.stdpath("data") .. "/claude"
local state_file = state_dir .. "/last_session.json"

-- API keys loaded from environment variables
api_key = os.getenv("OPENAI_API_KEY")
```

---

## Session-Based Authentication

### Overview

Traditional server-side session management stores authentication state on the server and provides a session ID to the client via cookies.

### Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Client    │◄───────►│  Web Server │◄───────►│   Session   │
│   Browser   │         │             │         │   Store     │
└─────────────┘         └─────────────┘         └─────────────┘
     Cookie                  Session ID              Redis/DB
```

### Implementation with Redis

**Advantages:**
- High performance with in-memory storage
- Built-in expiration mechanisms
- Supports distributed deployments
- Simple implementation pattern

**Architecture:**
```
User Login
    ↓
Generate Session ID
    ↓
Store in Redis (key: session_id, value: user_data, ttl: 30min)
    ↓
Set Cookie (HttpOnly, Secure, SameSite=Strict)
    ↓
Client stores session cookie
    ↓
Subsequent requests include cookie
    ↓
Server validates session in Redis
```

**Example Implementation Pattern:**
```lua
-- Session creation
local session_id = generate_uuid()
redis:setex("session:" .. session_id, 1800, json_encode(user_data))
set_cookie("session_id", session_id, {
  httponly = true,
  secure = true,
  samesite = "strict"
})

-- Session validation
local session_data = redis:get("session:" .. cookie.session_id)
if session_data then
  -- Valid session, refresh TTL
  redis:expire("session:" .. cookie.session_id, 1800)
  return json_decode(session_data)
end
```

### Security Considerations

**Cookie Security Flags:**
- `HttpOnly` - Prevents JavaScript access (XSS protection)
- `Secure` - HTTPS only transmission
- `SameSite=Strict` - CSRF protection

**Session Management:**
- Implement absolute timeout (e.g., 24 hours)
- Implement idle timeout (e.g., 30 minutes)
- Regenerate session ID on privilege escalation
- Secure session storage with encryption at rest

### Redis Alternatives

- **Memcached** - Simpler, but no built-in persistence
- **PostgreSQL** - Persistent storage, lower performance
- **DynamoDB** - Serverless option for AWS environments
- **MongoDB** - Document-based session storage

---

## Token-Based Authentication (JWT)

### Overview

JSON Web Tokens (JWT) provide stateless authentication where all necessary information is encoded in the token itself.

### JWT Structure

```
Header.Payload.Signature

{                          {                          HMACSHA256(
  "alg": "HS256",           "sub": "user123",          base64(header) + "." +
  "typ": "JWT"              "name": "John",            base64(payload),
}                           "exp": 1735906800          secret
                          }
```

### Implementation Pattern

**Token Generation:**
```lua
local jwt = require("jwt")

local payload = {
  sub = user_id,
  name = username,
  iat = os.time(),
  exp = os.time() + 3600, -- 1 hour
  scope = {"read", "write"}
}

local token = jwt.encode(payload, secret_key, "HS256")
```

**Token Validation:**
```lua
local success, decoded = pcall(jwt.decode, token, secret_key)
if success and decoded.exp > os.time() then
  -- Valid token
  return decoded
end
```

### JWT Security Best Practices (2025)

1. **Short Expiration Times**
   - Access tokens: 5-15 minutes
   - Refresh tokens: 7-30 days
   - Never issue long-lived access tokens

2. **Secure Storage**
   - Backend: Environment variables or secrets manager
   - Frontend: HttpOnly cookies (not localStorage)
   - Mobile: Secure platform keychain

3. **Token Signing**
   - Use RS256 (asymmetric) for production
   - Avoid HS256 in distributed systems
   - Rotate signing keys regularly

4. **Data Privacy**
   - Never store sensitive data in JWT payload
   - JWT payloads are base64-encoded, not encrypted
   - Use JWE (JSON Web Encryption) for sensitive data

5. **Token Revocation Strategy**
   - Maintain token blacklist in Redis
   - Short expiration times reduce revocation needs
   - Implement token versioning per user

### Phantom Token Pattern

For enhanced security with sensitive data:

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│ Client  │────────►│ Gateway │────────►│   API   │
│         │ Opaque  │         │  JWT    │         │
│         │ Token   │         │ Token   │         │
└─────────┘         └─────────┘         └─────────┘
                         │
                         ▼
                    Token Exchange
                    Service (Redis)
```

Client receives opaque token, gateway exchanges for JWT when calling backend APIs.

### Refresh Token Pattern

```
┌─────────────────────────────────────────────────┐
│ Authentication Flow with Refresh Tokens         │
└─────────────────────────────────────────────────┘

1. Initial Login
   ├─ POST /auth/login
   └─ Response: { access_token (15min), refresh_token (7d) }

2. API Request
   ├─ Authorization: Bearer {access_token}
   └─ Response: 200 OK or 401 Unauthorized

3. Token Refresh (when access_token expires)
   ├─ POST /auth/refresh
   ├─ Body: { refresh_token }
   └─ Response: { new_access_token (15min) }

4. Logout
   ├─ POST /auth/logout
   └─ Invalidate refresh_token in database
```

---

## OAuth 2.0 and OpenID Connect

### OAuth 2.0 Overview

OAuth 2.0 is an authorization framework that enables third-party applications to obtain limited access to user accounts.

### OAuth 2.0 Grant Types

1. **Authorization Code Flow** (Most secure, for web apps)
2. **PKCE** (Proof Key for Code Exchange, for mobile/SPA)
3. **Client Credentials** (Service-to-service)
4. **Implicit Flow** (Deprecated, not recommended)

### Authorization Code Flow with PKCE

```
┌─────────┐                                         ┌─────────────┐
│         │─1. Authorization Request────────────────►│             │
│         │   + code_challenge                       │             │
│  Client │                                          │   OAuth     │
│         │◄─2. Authorization Code──────────────────┤   Provider  │
│         │                                          │             │
│         │─3. Token Request─────────────────────────►│             │
│         │   + authorization_code                   │             │
│         │   + code_verifier                        │             │
│         │                                          │             │
│         │◄─4. Access Token + ID Token──────────────┤             │
└─────────┘                                         └─────────────┘
```

### OpenID Connect (OIDC)

OpenID Connect is an authentication layer built on top of OAuth 2.0.

**Key Additions:**
- `id_token` - JWT containing user identity information
- `/userinfo` endpoint - Retrieve user profile data
- Standardized claims - `sub`, `name`, `email`, `picture`, etc.

### Implementation Example

```lua
-- 1. Generate PKCE challenge
local code_verifier = generate_random_string(128)
local code_challenge = base64_url_encode(sha256(code_verifier))

-- 2. Redirect to authorization endpoint
local auth_url = "https://oauth.provider.com/authorize?" ..
  "client_id=" .. client_id ..
  "&redirect_uri=" .. redirect_uri ..
  "&response_type=code" ..
  "&scope=openid profile email" ..
  "&code_challenge=" .. code_challenge ..
  "&code_challenge_method=S256"

-- 3. Exchange code for token
local token_response = http.post("https://oauth.provider.com/token", {
  grant_type = "authorization_code",
  code = authorization_code,
  redirect_uri = redirect_uri,
  client_id = client_id,
  code_verifier = code_verifier
})

-- 4. Validate and decode ID token
local id_token = jwt.decode(token_response.id_token)
local user = {
  id = id_token.sub,
  email = id_token.email,
  name = id_token.name
}
```

### Popular OAuth Providers (2025)

- **Google** - Widely used, reliable, good documentation
- **GitHub** - Popular for developer tools
- **Microsoft** - Enterprise environments, Azure integration
- **Auth0** - Full-featured identity platform
- **Okta** - Enterprise focus, comprehensive features

---

## Passwordless Authentication

### Overview

Passwordless authentication eliminates the need for passwords using biometrics, hardware tokens, or magic links.

### WebAuthn/FIDO2 Architecture

```
┌────────────────────────────────────────────────────────┐
│                 FIDO2 Architecture                     │
└────────────────────────────────────────────────────────┘

┌───────────────┐         ┌───────────────┐
│   Relying     │         │  Authenticator│
│   Party       │◄───────►│  (Device)     │
│   (Server)    │ WebAuthn│               │
└───────┬───────┘  API    └───────────────┘
        │                   │
        │                   │ CTAP2
        │                   ▼
        │            ┌───────────────┐
        │            │   Security    │
        │            │   Key         │
        └────────────┤   (USB/NFC/   │
                     │   Bluetooth)  │
                     └───────────────┘
```

### FIDO2 Components

1. **WebAuthn** - Browser/platform API for authentication
2. **CTAP2** - Protocol for external authenticators
3. **Platform Authenticators** - TouchID, FaceID, Windows Hello
4. **Roaming Authenticators** - YubiKey, security keys

### Registration Flow

```
User Registration
    ↓
1. Server generates challenge (random bytes)
    ↓
2. Client calls navigator.credentials.create()
    ├─ challenge: server_challenge
    ├─ rp: { name: "Example", id: "example.com" }
    ├─ user: { id: user_id, name: email, displayName: full_name }
    └─ pubKeyCredParams: [{ alg: -7, type: "public-key" }]
    ↓
3. Authenticator generates key pair
    ├─ Private key: stored on device (never leaves)
    └─ Public key: returned to client
    ↓
4. Client sends public key + credential ID to server
    ↓
5. Server stores public key for user
```

### Authentication Flow

```
User Login
    ↓
1. Server generates challenge
    ↓
2. Client calls navigator.credentials.get()
    ├─ challenge: server_challenge
    ├─ rpId: "example.com"
    └─ allowCredentials: [{ type: "public-key", id: credential_id }]
    ↓
3. Authenticator signs challenge with private key
    ↓
4. Client sends signed challenge to server
    ↓
5. Server verifies signature with public key
    ↓
6. Authentication successful
```

### Implementation Example (JavaScript)

```javascript
// Registration
const publicKeyCredentialCreationOptions = {
  challenge: Uint8Array.from(serverChallenge, c => c.charCodeAt(0)),
  rp: { name: "Example Corp", id: "example.com" },
  user: {
    id: Uint8Array.from(userId, c => c.charCodeAt(0)),
    name: "user@example.com",
    displayName: "John Doe"
  },
  pubKeyCredParams: [
    { alg: -7, type: "public-key" },  // ES256
    { alg: -257, type: "public-key" } // RS256
  ],
  authenticatorSelection: {
    authenticatorAttachment: "platform",
    requireResidentKey: false,
    userVerification: "preferred"
  },
  timeout: 60000,
  attestation: "direct"
};

const credential = await navigator.credentials.create({
  publicKey: publicKeyCredentialCreationOptions
});

// Send credential to server
await fetch('/auth/register', {
  method: 'POST',
  body: JSON.stringify({
    id: credential.id,
    rawId: arrayBufferToBase64(credential.rawId),
    response: {
      clientDataJSON: arrayBufferToBase64(credential.response.clientDataJSON),
      attestationObject: arrayBufferToBase64(credential.response.attestationObject)
    }
  })
});
```

### Passwordless Alternatives

1. **Magic Links**
   - Email-based one-time login links
   - Simple implementation
   - Requires email verification

2. **SMS/Authenticator OTP**
   - Time-based one-time passwords
   - Works without WebAuthn support
   - SMS less secure than authenticator apps

3. **Passkeys (2025 Standard)**
   - Cross-device WebAuthn credentials
   - Synced via platform (Apple/Google/Microsoft)
   - Best user experience

### Security Benefits

- **Phishing Resistant** - Credentials tied to origin domain
- **No Shared Secrets** - Private keys never leave device
- **Strong Authentication** - Biometric or PIN required
- **No Password Database** - No credentials to steal
- **MiTM Protection** - Challenge-response with cryptographic proof

### Platform Support (2025)

- **Browsers**: Chrome, Safari, Firefox, Edge (100% support)
- **Mobile**: iOS 16+, Android 9+
- **Desktop**: Windows 10+, macOS 13+, Linux (Chrome/Firefox)

---

## API Key Management

### Overview

API keys are simple authentication tokens used for service-to-service communication and developer APIs.

### Current Codebase Implementation

```lua
-- From avante.lua (lines 299, 362)
api_key = os.getenv("OPENAI_API_KEY")
api_key = os.getenv("ANTHROPIC_API_KEY")
```

### Security Best Practices (2025)

#### 1. Storage Methods (By Security Level)

**Production (Highest Security):**
```
Secrets Management System
├─ HashiCorp Vault
├─ AWS Secrets Manager
├─ Azure Key Vault
├─ Google Cloud Secret Manager
└─ 1Password Secrets Automation
```

**Development/CI:**
```
Environment Variables
├─ .env files (gitignored)
├─ CI/CD secret stores (GitHub Secrets, GitLab CI Variables)
└─ Container orchestration secrets (Kubernetes Secrets)
```

**Not Recommended:**
```
❌ Hardcoded in source code
❌ Committed to version control
❌ Stored in client-side code
❌ Shared via insecure channels (email, Slack)
```

#### 2. Access Restrictions

```
API Key Configuration
├─ IP Allowlist - Restrict to specific IPs/CIDR ranges
├─ Referrer Restrictions - Domain allowlist for web apps
├─ Rate Limits - Requests per minute/hour/day
├─ Scope Restrictions - Limit available operations
└─ Environment Separation - Different keys for dev/staging/prod
```

#### 3. Key Rotation Strategy

```
Regular Rotation Schedule
├─ High-Risk Keys (production, broad access): 30-90 days
├─ Medium-Risk Keys (limited scope): 90-180 days
├─ Low-Risk Keys (development): 180-365 days
└─ Immediate Rotation: On suspected compromise
```

**Zero-Downtime Rotation:**
```
1. Generate new API key (key_v2)
2. Update configuration to accept both keys
3. Deploy updated configuration
4. Update clients to use key_v2
5. Monitor for key_v1 usage (grace period: 7-30 days)
6. Revoke key_v1 when no longer used
```

#### 4. API Key Format Best Practices

```
Recommended Format:
[prefix]_[environment]_[random]_[checksum]

Examples:
sk_prod_j7ks92hd8s9d8f7s6d_9a8b
pk_test_s8d7f6g5h4j3k2l1_4c5d
api_dev_x9y8z7w6v5u4t3s2_1a2b

Benefits:
- Prefix identifies key type/service
- Environment prevents accidental misuse
- Checksum enables validation
- Random portion provides security
```

#### 5. Monitoring and Alerting

```
API Key Security Monitoring
├─ Usage Analytics
│   ├─ Requests per hour/day
│   ├─ Geographic distribution
│   └─ Endpoint access patterns
├─ Anomaly Detection
│   ├─ Unusual request volume
│   ├─ New IP addresses
│   ├─ Failed authentication attempts
│   └─ Access to restricted resources
└─ Compliance Tracking
    ├─ Key age and rotation status
    ├─ Access audit logs
    └─ Scope usage validation
```

#### 6. Secret Scanning

**Pre-Commit Protection:**
```bash
# Using gitleaks
gitleaks protect --verbose --redact --staged

# Using truffleHog
trufflehog git file://. --only-verified
```

**CI/CD Integration:**
```yaml
# GitHub Actions example
- name: Scan for secrets
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
```

### Implementation Example

```lua
-- config/secrets.lua
local M = {}

-- Load API keys from environment with validation
function M.load_api_key(service_name)
  local env_var = string.upper(service_name) .. "_API_KEY"
  local api_key = os.getenv(env_var)

  if not api_key or api_key == "" then
    error(string.format("API key for %s not found in environment", service_name))
  end

  -- Validate format (example)
  if not string.match(api_key, "^[a-z]+_[a-z]+_[a-zA-Z0-9]+_[a-zA-Z0-9]+$") then
    vim.notify(
      string.format("Warning: API key for %s has unexpected format", service_name),
      vim.log.levels.WARN
    )
  end

  return api_key
end

-- Mask API key for logging
function M.mask_api_key(api_key)
  if not api_key or #api_key < 12 then
    return "***"
  end
  return string.sub(api_key, 1, 8) .. "..." .. string.sub(api_key, -4)
end

return M
```

### API Key vs. OAuth Decision Matrix

| Factor | API Keys | OAuth 2.0 |
|--------|----------|-----------|
| Use Case | Service-to-service | User-delegated access |
| Complexity | Low | High |
| User Consent | No | Yes |
| Scope Control | Limited | Granular |
| Token Lifecycle | Manual rotation | Automatic refresh |
| Revocation | Manual | Built-in |
| Best For | Internal APIs | Third-party integrations |

---

## Mutual TLS (mTLS)

### Overview

Mutual TLS (mTLS) extends standard TLS by requiring both client and server to present certificates, providing bidirectional authentication.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│            mTLS Handshake Process                       │
└─────────────────────────────────────────────────────────┘

Client                              Server
  │                                   │
  ├─1. ClientHello──────────────────►│
  │                                   │
  │◄─2. ServerHello──────────────────┤
  │   + Server Certificate            │
  │   + Request Client Certificate    │
  │                                   │
  ├─3. Client Certificate────────────►│
  │   + Certificate Verify            │
  │   (signed with client private key)│
  │                                   │
  │                                   ├─4. Verify Client Cert
  │                                   │    - Check CA signature
  │                                   │    - Verify not revoked
  │                                   │    - Check expiration
  │                                   │
  │◄─5. Connection Established────────┤
  │                                   │
  ├─6. Encrypted Application Data────►│
  │                                   │
```

### Use Cases

1. **Zero-Trust Architecture**
   - Service-to-service authentication
   - Microsegmentation within networks
   - Defense in depth strategy

2. **B2B API Security**
   - Partner integrations
   - High-value transactions
   - Regulated industries

3. **IoT Device Authentication**
   - Device identity verification
   - Secure firmware updates
   - Command and control

4. **Kubernetes/Service Mesh**
   - Istio, Linkerd automatic mTLS
   - Pod-to-pod authentication
   - East-west traffic security

### Certificate Management

```
Certificate Lifecycle
├─ Generation
│   ├─ Certificate Authority (CA) setup
│   ├─ Private key generation (RSA 2048+ or ECDSA P-256)
│   └─ Certificate Signing Request (CSR)
├─ Distribution
│   ├─ Secure delivery to clients
│   ├─ Certificate pinning (optional)
│   └─ Trust store configuration
├─ Validation
│   ├─ CA signature verification
│   ├─ Expiration checking
│   ├─ Revocation status (CRL/OCSP)
│   └─ Subject/SAN validation
└─ Rotation
    ├─ Automated renewal (30 days before expiry)
    ├─ Zero-downtime certificate updates
    └─ Certificate revocation on compromise
```

### Implementation Example (Nginx)

```nginx
server {
    listen 443 ssl;
    server_name api.example.com;

    # Server certificate
    ssl_certificate /etc/nginx/certs/server.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    # Client certificate verification
    ssl_client_certificate /etc/nginx/certs/ca.crt;
    ssl_verify_client on;
    ssl_verify_depth 2;

    # TLS configuration
    ssl_protocols TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location /api {
        # Extract client certificate info
        proxy_set_header X-Client-Cert $ssl_client_cert;
        proxy_set_header X-Client-Subject-DN $ssl_client_s_dn;
        proxy_set_header X-Client-Issuer-DN $ssl_client_i_dn;

        proxy_pass http://backend;
    }
}
```

### Automated Certificate Management

**cert-manager (Kubernetes):**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: client-cert
spec:
  secretName: client-cert-tls
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days
  subject:
    organizations:
      - example-org
  commonName: client.example.com
  isCA: false
  privateKey:
    algorithm: ECDSA
    size: 256
  usages:
    - client auth
  issuerRef:
    name: ca-issuer
    kind: Issuer
```

### mTLS vs. API Key Comparison

| Factor | mTLS | API Keys |
|--------|------|----------|
| Security Level | Very High | Medium |
| Setup Complexity | High | Low |
| Performance Impact | Medium (TLS overhead) | Low |
| Certificate Management | Required | Not needed |
| Revocation | CRL/OCSP | Simple deletion |
| Mutual Authentication | Yes | No (server only) |
| Best For | Zero-trust, high-security | Developer APIs |

### Challenges and Solutions

**Challenge: Certificate Rotation at Scale**
- Solution: Automated certificate management (cert-manager, Vault PKI)
- Solution: Short-lived certificates (1-7 days) with automated renewal

**Challenge: Performance Overhead**
- Solution: TLS session resumption
- Solution: Hardware acceleration (TLS offloading)

**Challenge: Debugging Complexity**
- Solution: Certificate validation logs
- Solution: Testing tools (openssl s_client, curl --cert)

---

## Authentication Frameworks and Services

### Authentication-as-a-Service Platforms

#### 1. Auth0

**Overview:**
Enterprise-grade authentication platform with comprehensive features and excellent documentation.

**Key Features:**
- Universal login (social, enterprise, passwordless)
- Multi-factor authentication
- Attack protection (brute force, breached passwords)
- Extensive SDK support
- Custom login pages and flows

**Pricing (2025):**
- Free: Up to 7,500 MAU
- Essentials: $35/month (up to 1,000 MAU, $0.035/additional)
- Professional: $240/month (up to 1,000 MAU, $0.24/additional)
- Enterprise: Custom pricing (10k+ MAU, volume discounts)

**Pros:**
- Best-in-class documentation
- Mature ecosystem and integrations
- Enterprise features (SAML, custom domains)
- High reliability and uptime

**Cons:**
- Expensive at scale (costs increase with MAU)
- Vendor lock-in concerns
- Complex pricing structure
- Acquired by Okta (future uncertain)

#### 2. Keycloak

**Overview:**
Open-source identity and access management solution developed by Red Hat.

**Key Features:**
- SSO (Single Sign-On) across applications
- Identity brokering (external IdP integration)
- Social login
- User federation (LDAP, Active Directory)
- Fine-grained authorization
- Admin UI and REST API

**Deployment:**
- Self-hosted only
- Docker/Kubernetes support
- Clustered deployment for HA

**Pros:**
- No licensing costs
- Full control over data and infrastructure
- Feature parity with commercial solutions
- Strong SAML and OpenID Connect support
- Active community and Red Hat backing

**Cons:**
- Complex configuration and setup
- Requires infrastructure management
- Learning curve for administrators
- Self-managed updates and security patches

**Best For:**
- Organizations with existing infrastructure
- Compliance requirements (data sovereignty)
- Budget-conscious projects
- On-premise deployments

#### 3. Supabase Auth

**Overview:**
Open-source Firebase alternative with built-in authentication and PostgreSQL backend.

**Key Features:**
- Email/password authentication
- Magic links
- Social providers (OAuth)
- Phone authentication (SMS)
- Row-level security (RLS) integration
- JWT-based authentication

**Pricing (2025):**
- Free: 50,000 MAU
- Pro: $25/month (100,000 MAU included)
- Additional: $0.00325 per MAU above limit

**Pros:**
- Exceptional value for money
- Simple, developer-friendly API
- PostgreSQL-based (familiar SQL)
- Integrated with Supabase ecosystem
- Open source (can self-host)

**Cons:**
- Less mature than Auth0/Keycloak
- Limited enterprise features
- Fewer advanced authentication options
- Smaller ecosystem

**Best For:**
- Startups and small-to-medium projects
- Rapid prototyping
- Cost-sensitive applications
- PostgreSQL-based stacks

#### 4. Firebase Authentication

**Overview:**
Google's BaaS platform with comprehensive authentication services.

**Key Features:**
- Email/password and phone authentication
- Social providers (Google, Facebook, Twitter, GitHub)
- Anonymous authentication
- Custom token authentication
- Firebase Admin SDK for backend

**Pricing (2025):**
- Free: Generous limits (50K verifications/month)
- Pay-as-you-go: $0.055 per verification above free tier
- No MAU charges

**Pros:**
- Strong Google ecosystem integration
- Real-time database integration
- Excellent mobile SDK support
- Reliable infrastructure
- Simple pricing model

**Cons:**
- Vendor lock-in to Google ecosystem
- Limited customization options
- Not open source
- Less suitable for complex authentication flows

**Best For:**
- Mobile applications
- Google Cloud Platform users
- Rapid development
- Real-time applications

#### 5. Clerk

**Overview:**
Modern authentication platform focused on developer experience and beautiful UIs.

**Key Features:**
- Pre-built UI components
- Organization management
- User profiles and settings
- Social and passwordless auth
- Session management
- WebAuthn support

**Pricing (2025):**
- Free: 10,000 MAU
- Pro: $25/month (up to 10,000 MAU)
- Enterprise: Custom pricing

**Pros:**
- Exceptional developer experience
- Beautiful pre-built UI components
- Modern tech stack (React-focused)
- Organization/team management built-in
- Great documentation

**Cons:**
- Relatively new (less mature)
- Focused on JavaScript ecosystem
- Limited customization of UI components
- Smaller feature set than Auth0

**Best For:**
- React/Next.js applications
- SaaS products with organizations
- Developer-focused products
- Rapid frontend development

### Open-Source Libraries

#### Passport.js (Node.js)

**Overview:**
Flexible authentication middleware for Node.js with 500+ strategies.

```javascript
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;

passport.use(new LocalStrategy(
  async (username, password, done) => {
    try {
      const user = await User.findOne({ username });
      if (!user) return done(null, false);

      const isValid = await bcrypt.compare(password, user.password);
      if (!isValid) return done(null, false);

      return done(null, user);
    } catch (err) {
      return done(err);
    }
  }
));

app.post('/login', passport.authenticate('local'), (req, res) => {
  res.json({ user: req.user });
});
```

#### NextAuth.js (Next.js)

**Overview:**
Authentication solution specifically designed for Next.js applications.

```javascript
import NextAuth from "next-auth"
import GithubProvider from "next-auth/providers/github"
import CredentialsProvider from "next-auth/providers/credentials"

export default NextAuth({
  providers: [
    GithubProvider({
      clientId: process.env.GITHUB_ID,
      clientSecret: process.env.GITHUB_SECRET,
    }),
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        const user = await verifyCredentials(credentials)
        return user || null
      }
    })
  ],
  session: {
    strategy: "jwt",
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) token.id = user.id
      return token
    },
    async session({ session, token }) {
      session.user.id = token.id
      return session
    }
  }
})
```

### Framework Comparison Matrix

| Platform | Type | Hosting | Pricing | Complexity | Best For |
|----------|------|---------|---------|------------|----------|
| Auth0 | SaaS | Managed | $$$ | Low | Enterprise |
| Keycloak | OSS | Self-hosted | Free* | High | On-premise |
| Supabase | SaaS/OSS | Managed/Self | $ | Low | Startups |
| Firebase | SaaS | Managed | $$ | Low | Mobile apps |
| Clerk | SaaS | Managed | $$ | Low | SaaS products |
| Passport.js | Library | Self-hosted | Free | Medium | Node.js apps |
| NextAuth.js | Library | Self-hosted | Free | Low | Next.js apps |

*Free software but requires infrastructure costs

---

## Security Best Practices

### 1. Password Security (When Used)

**Password Hashing:**
```lua
-- Use Argon2id (recommended in 2025)
local argon2 = require("argon2")

-- Hash password
local hash = argon2.hash_encoded(
  password,
  argon2.ARGON2_ID,
  {
    t_cost = 4,      -- Time cost (iterations)
    m_cost = 2^16,   -- Memory cost (64 MB)
    parallelism = 2  -- Parallel threads
  }
)

-- Verify password
local valid = argon2.verify(hash, password)
```

**Password Policies (2025 NIST Guidelines):**
- Minimum 8 characters (12+ recommended)
- No composition rules (letters, numbers, symbols) required
- Check against breached password databases (Have I Been Pwned)
- No forced periodic password changes
- Allow all printable ASCII and Unicode characters
- Implement rate limiting on login attempts

**Password Strength Estimation:**
```javascript
import zxcvbn from 'zxcvbn';

const result = zxcvbn(password);
// result.score: 0-4 (0 = weak, 4 = strong)
// result.feedback: suggestions for improvement
```

### 2. Multi-Factor Authentication (MFA)

**MFA Factor Types:**
1. **Something you know** - Password, PIN
2. **Something you have** - Phone, security key, authenticator app
3. **Something you are** - Biometrics (fingerprint, face, voice)

**TOTP (Time-based One-Time Password):**
```lua
local totp = require("otp")

-- Generate secret for user
local secret = totp.generate_secret()

-- Generate QR code for authenticator app
local otpauth_url = string.format(
  "otpauth://totp/%s:%s?secret=%s&issuer=%s",
  issuer, username, secret, issuer
)

-- Verify TOTP code
local valid = totp.verify(code, secret, {
  window = 1,  -- Accept codes from previous/next 30s window
  time = os.time()
})
```

**SMS OTP (Less Secure):**
- Vulnerable to SIM swapping attacks
- Use as backup, not primary MFA method
- Consider authenticator apps or WebAuthn instead

**Backup Codes:**
```lua
-- Generate 10 single-use backup codes
local backup_codes = {}
for i = 1, 10 do
  local code = generate_random_alphanumeric(10)
  backup_codes[i] = code
  -- Store hashed version
  db:store_backup_code(user_id, hash(code))
end
```

### 3. Rate Limiting and Brute Force Protection

**Implementation Pattern:**
```lua
local redis = require("redis")

function check_rate_limit(user_or_ip, max_attempts, window)
  local key = "ratelimit:" .. user_or_ip
  local attempts = redis:incr(key)

  if attempts == 1 then
    redis:expire(key, window)
  end

  if attempts > max_attempts then
    local ttl = redis:ttl(key)
    return false, "Too many attempts. Try again in " .. ttl .. " seconds"
  end

  return true
end

-- Usage
local allowed, error = check_rate_limit(
  request.ip,
  5,    -- 5 attempts
  300   -- per 5 minutes
)

if not allowed then
  return { status = 429, error = error }
end
```

**Progressive Delays:**
```
Attempt   Delay
1         0s
2         1s
3         2s
4         4s
5         8s
6+        Account locked (require email verification)
```

### 4. Session Security

**Session Configuration:**
```lua
local session_config = {
  -- Cookie settings
  cookie = {
    name = "session",
    httponly = true,
    secure = true,  -- HTTPS only
    samesite = "strict",
    domain = ".example.com",
    path = "/"
  },

  -- Timeouts
  absolute_timeout = 86400,  -- 24 hours
  idle_timeout = 1800,       -- 30 minutes

  -- Security
  regenerate_id_on_privilege = true,
  single_session_per_user = false,

  -- Storage
  storage = "redis",
  storage_config = {
    host = "localhost",
    port = 6379,
    db = 0
  }
}
```

**Session Fixation Prevention:**
```lua
-- Regenerate session ID on login
function on_successful_login(user_id)
  local old_session_id = get_current_session_id()
  local new_session_id = generate_session_id()

  -- Transfer session data
  local session_data = redis:get("session:" .. old_session_id)
  redis:setex("session:" .. new_session_id, 1800, session_data)

  -- Delete old session
  redis:del("session:" .. old_session_id)

  -- Update cookie
  set_session_cookie(new_session_id)
end
```

### 5. CSRF Protection

**Synchronizer Token Pattern:**
```lua
-- Generate CSRF token
function generate_csrf_token(session_id)
  local token = generate_random_token(32)
  redis:setex("csrf:" .. session_id, 3600, token)
  return token
end

-- Verify CSRF token
function verify_csrf_token(session_id, token)
  local expected = redis:get("csrf:" .. session_id)
  return expected == token
end
```

**Double Submit Cookie Pattern:**
```lua
-- Set CSRF cookie
local csrf_token = generate_random_token(32)
set_cookie("csrf_token", csrf_token, {
  httponly = false,  -- JavaScript needs to read this
  secure = true,
  samesite = "strict"
})

-- Verify on form submission
local cookie_token = get_cookie("csrf_token")
local header_token = request.headers["X-CSRF-Token"]

if cookie_token ~= header_token then
  return { status = 403, error = "CSRF token mismatch" }
end
```

### 6. XSS Protection

**Content Security Policy (CSP):**
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}' https://trusted-cdn.com;
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```

**Input Sanitization:**
```lua
local html_entities = {
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ["&"] = "&amp;",
  ['"'] = "&quot;",
  ["'"] = "&#39;"
}

function escape_html(text)
  return (text:gsub("[<>&\"']", html_entities))
end

-- Use in templates
local safe_username = escape_html(user_input)
```

### 7. Secure Password Reset

**Best Practices:**
1. Generate cryptographically random token (32+ bytes)
2. Store hashed token in database
3. Include expiration time (15-60 minutes)
4. Invalidate token after use
5. Don't reveal whether email exists
6. Require current password for sensitive account changes

**Implementation:**
```lua
function initiate_password_reset(email)
  local user = db:find_user_by_email(email)

  -- Always return success (timing-safe)
  if not user then
    return { success = true, message = "If email exists, reset link sent" }
  end

  -- Generate reset token
  local token = generate_secure_random(32)
  local expires = os.time() + 3600  -- 1 hour

  -- Store hashed token
  db:store_reset_token(user.id, hash(token), expires)

  -- Send email
  send_email(email, {
    subject = "Password Reset Request",
    link = "https://example.com/reset?token=" .. token
  })

  return { success = true, message = "If email exists, reset link sent" }
end

function reset_password(token, new_password)
  -- Find token in database
  local reset_record = db:find_reset_token(hash(token))

  if not reset_record or reset_record.expires < os.time() then
    return { error = "Invalid or expired token" }
  end

  -- Update password
  db:update_password(reset_record.user_id, hash_password(new_password))

  -- Invalidate token
  db:delete_reset_token(reset_record.id)

  -- Invalidate all sessions for user
  db:invalidate_user_sessions(reset_record.user_id)

  return { success = true }
end
```

### 8. Secure Account Enumeration Prevention

**Problem:** Attackers can determine which accounts exist by observing different responses.

**Solutions:**
```lua
-- Bad: Reveals account existence
if not user then
  return { error = "User not found" }
end
if not verify_password(password, user.password_hash) then
  return { error = "Incorrect password" }
end

-- Good: Same response for both cases
local user = db:find_user_by_email(email)
local password_valid = false

if user then
  password_valid = verify_password(password, user.password_hash)
end

if not password_valid then
  -- Add constant-time delay to prevent timing attacks
  sleep_ms(100 + random(50))
  return { error = "Invalid credentials" }
end
```

### 9. Logging and Monitoring

**Security Events to Log:**
```
Authentication Events
├─ Successful logins
├─ Failed login attempts
├─ Password resets
├─ MFA enrollments/verifications
├─ Account lockouts
├─ Session creations/terminations
└─ Privilege escalations

Anomalies to Monitor
├─ Login from new location/device
├─ Unusual time-of-day access
├─ Multiple failed attempts
├─ Rapid session creation
├─ Token abuse patterns
└─ Concurrent sessions from different IPs
```

**Log Format (JSON):**
```json
{
  "timestamp": "2025-10-13T17:30:00Z",
  "event_type": "authentication",
  "action": "login_success",
  "user_id": "user_123",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "location": {
    "country": "US",
    "city": "San Francisco"
  },
  "session_id": "sess_abc123",
  "mfa_used": true,
  "device_fingerprint": "fp_xyz789"
}
```

### 10. Compliance Considerations

**GDPR (Europe):**
- Right to access (export user data)
- Right to deletion (account deletion)
- Data minimization (collect only necessary data)
- Consent for data processing
- Breach notification (72 hours)

**CCPA (California):**
- Right to know what data is collected
- Right to delete personal information
- Right to opt-out of data sale
- Non-discrimination for exercising rights

**SOC 2:**
- Access controls and authentication
- Encryption in transit and at rest
- Security monitoring and logging
- Incident response procedures
- Regular security assessments

---

## Implementation Recommendations

### Decision Framework

#### 1. Choose Authentication Pattern

```
Question Flow:
│
├─ Is this a public-facing web application?
│  ├─ Yes
│  │  ├─ Need social login (Google, GitHub, etc.)?
│  │  │  ├─ Yes → Use OAuth 2.0 / OpenID Connect
│  │  │  └─ No
│  │  │     ├─ Want passwordless experience?
│  │  │     │  ├─ Yes → Use WebAuthn/FIDO2 or Magic Links
│  │  │     │  └─ No → Use traditional email/password + MFA
│  │  └─ Use Session-based or JWT?
│  │     ├─ Monolithic app → Session-based (Redis)
│  │     └─ Microservices/SPA → JWT with refresh tokens
│  │
├─ Is this an API for developers?
│  ├─ Yes
│  │  ├─ Public API?
│  │  │  ├─ Yes → API Keys with usage limits
│  │  │  └─ No → OAuth 2.0 Client Credentials
│  │  └─ High security requirements?
│  │     └─ Yes → mTLS
│  │
└─ Is this service-to-service communication?
   ├─ Within same infrastructure?
   │  └─ Use mTLS or API Keys with network isolation
   └─ Cross-organization?
      └─ Use mTLS or OAuth 2.0 Client Credentials
```

#### 2. Choose Authentication Service

```
Decision Factors:

Budget
├─ Unlimited budget → Auth0 or Okta
├─ Medium budget → Clerk or Firebase
├─ Tight budget → Supabase or self-hosted Keycloak
└─ No budget → Open-source libraries (Passport, NextAuth)

Scale
├─ < 10k users → Any platform (free tiers)
├─ 10k-100k users → Supabase, Firebase, Clerk
├─ 100k-1M users → Auth0, Firebase, AWS Cognito
└─ > 1M users → Auth0 Enterprise, custom solution

Compliance
├─ Data sovereignty required → Keycloak (self-hosted)
├─ HIPAA/SOC 2 → Auth0, Okta, AWS Cognito
└─ GDPR → Any (with proper configuration)

Complexity
├─ Simple (email/password) → Supabase, Firebase
├─ Moderate (social + MFA) → Clerk, Auth0
└─ Complex (enterprise SSO, SAML) → Auth0, Keycloak

Technology Stack
├─ React/Next.js → Clerk, NextAuth.js, Supabase
├─ Node.js → Passport.js, Auth0
├─ Mobile-first → Firebase, Auth0
└─ Multi-platform → Auth0, Supabase
```

### Implementation Roadmap

#### Phase 1: Foundation (Week 1-2)

**Tasks:**
1. Define authentication requirements
   - User types (end-users, admins, API consumers)
   - Authentication methods needed
   - Security requirements
   - Compliance needs

2. Select authentication pattern
   - Use decision framework above
   - Document rationale

3. Choose authentication service/library
   - Evaluate 2-3 options
   - Create proof of concept
   - Consider total cost of ownership

4. Set up development environment
   - Install SDKs and dependencies
   - Configure local development
   - Create test accounts

#### Phase 2: Core Implementation (Week 3-4)

**Tasks:**
1. Implement basic authentication flow
   - Registration
   - Login
   - Logout
   - Session management

2. Add error handling
   - Invalid credentials
   - Network errors
   - Rate limiting
   - Timeout handling

3. Implement password management
   - Password hashing (Argon2id)
   - Password reset flow
   - Password strength validation

4. Basic security measures
   - HTTPS enforcement
   - CSRF protection
   - XSS prevention (CSP, input sanitization)
   - Secure cookie configuration

#### Phase 3: Enhanced Security (Week 5-6)

**Tasks:**
1. Add Multi-Factor Authentication
   - TOTP (authenticator apps)
   - Backup codes
   - SMS as backup option (optional)

2. Implement rate limiting
   - Login attempts
   - Password reset requests
   - API endpoints

3. Add logging and monitoring
   - Authentication events
   - Failed login attempts
   - Anomaly detection setup

4. Security testing
   - Penetration testing
   - Vulnerability scanning
   - Code review

#### Phase 4: Advanced Features (Week 7-8)

**Tasks:**
1. Social login (if needed)
   - Google OAuth
   - GitHub OAuth
   - Additional providers

2. Passwordless authentication (if needed)
   - WebAuthn/FIDO2 setup
   - Magic link implementation

3. Session management
   - Multiple device support
   - Session viewer/manager
   - Force logout functionality

4. Account management
   - Profile updates
   - Email verification
   - Account deletion (GDPR compliance)

#### Phase 5: Production Readiness (Week 9-10)

**Tasks:**
1. Performance optimization
   - Connection pooling
   - Caching strategies
   - Database indexing

2. Scalability testing
   - Load testing
   - Stress testing
   - Identify bottlenecks

3. Documentation
   - API documentation
   - User guides
   - Runbooks for operations

4. Monitoring and alerting
   - Uptime monitoring
   - Error rate alerts
   - Security event alerts

5. Compliance audit
   - GDPR checklist
   - Security controls review
   - Privacy policy update

### Code Examples for Current Codebase

Based on the current Neovim configuration implementation, here are recommended improvements:

#### 1. Enhanced Session Manager

```lua
-- neotex/plugins/ai/claude/core/session-manager-v2.lua
local M = {}
local Path = require("plenary.path")
local notify = require("neotex.util.notifications")

-- Use secrets manager for API keys
local secrets = require("neotex.util.secrets")

-- Session configuration
local config = {
  state_dir = vim.fn.stdpath("data") .. "/claude",
  state_file = "last_session.json",
  session_timeout = 1800,  -- 30 minutes
  absolute_timeout = 86400, -- 24 hours
  encryption_enabled = true
}

-- Encryption utilities
local crypto = require("neotex.util.crypto")

--- Enhanced save state with encryption
function M.save_state(state)
  local state_file = config.state_dir .. "/" .. config.state_file

  -- Add security metadata
  state.timestamp = state.timestamp or os.time()
  state.version = 2  -- Enhanced version
  state.checksum = crypto.calculate_checksum(vim.fn.json_encode(state))

  -- Encrypt sensitive data
  if config.encryption_enabled and state.session_data then
    state.session_data = crypto.encrypt(
      vim.fn.json_encode(state.session_data),
      secrets.get_encryption_key()
    )
  end

  -- Atomic write
  local temp_file = state_file .. ".tmp"
  local file = io.open(temp_file, "w")
  if not file then
    return false, "Could not open temp file for writing"
  end

  file:write(vim.fn.json_encode(state))
  file:close()

  -- Rename (atomic on POSIX systems)
  os.rename(temp_file, state_file)

  return true
end

--- Enhanced load state with decryption and validation
function M.load_state()
  local state_file = config.state_dir .. "/" .. config.state_file
  local file = io.open(state_file, "r")

  if not file then
    return nil, "State file not found"
  end

  local content = file:read("*all")
  file:close()

  if content == "" then
    return nil, "State file is empty"
  end

  -- Decode JSON
  local ok, state = pcall(vim.fn.json_decode, content)
  if not ok then
    -- Corrupted file, backup and return error
    M.backup_corrupted_state(state_file)
    return nil, "State file is corrupted"
  end

  -- Verify checksum
  local state_copy = vim.deepcopy(state)
  local checksum = state_copy.checksum
  state_copy.checksum = nil

  if checksum ~= crypto.calculate_checksum(vim.fn.json_encode(state_copy)) then
    return nil, "State file checksum mismatch"
  end

  -- Check expiration
  if state.timestamp and (os.time() - state.timestamp) > config.absolute_timeout then
    return nil, "Session expired"
  end

  -- Decrypt sensitive data
  if config.encryption_enabled and state.session_data then
    local decrypted = crypto.decrypt(
      state.session_data,
      secrets.get_encryption_key()
    )
    state.session_data = vim.fn.json_decode(decrypted)
  end

  return state
end

--- Validate session with comprehensive checks
function M.validate_session(session_id)
  local errors = {}

  -- Format validation
  if not session_id or session_id == "" then
    table.insert(errors, "Session ID is empty")
  elseif not session_id:match("^[a-zA-Z0-9-_]+$") then
    table.insert(errors, "Invalid session ID format")
  end

  -- State validation
  local state, err = M.load_state()
  if not state then
    table.insert(errors, err or "Could not load session state")
  end

  -- Timeout validation
  if state and state.timestamp then
    local age = os.time() - state.timestamp
    if age > config.session_timeout then
      table.insert(errors, "Session timed out (idle)")
    elseif age > config.absolute_timeout then
      table.insert(errors, "Session expired (absolute timeout)")
    end
  end

  if #errors > 0 then
    return false, errors
  end

  return true
end

return M
```

#### 2. Secure API Key Management

```lua
-- neotex/util/secrets.lua
local M = {}
local Path = require("plenary.path")

-- Secrets configuration
local secrets_dir = vim.fn.stdpath("data") .. "/secrets"
local encryption_key_file = secrets_dir .. "/master.key"

--- Load API key with validation
function M.load_api_key(service_name)
  local env_var = string.upper(service_name) .. "_API_KEY"
  local api_key = os.getenv(env_var)

  if not api_key or api_key == "" then
    vim.notify(
      string.format("API key for %s not found. Set %s environment variable.",
        service_name, env_var),
      vim.log.levels.ERROR
    )
    return nil
  end

  -- Validate format (example: sk_prod_xxxx_xxxx)
  if not M.validate_api_key_format(api_key) then
    vim.notify(
      string.format("Warning: API key for %s has unexpected format", service_name),
      vim.log.levels.WARN
    )
  end

  -- Log key usage (masked)
  M.log_api_key_usage(service_name, M.mask_api_key(api_key))

  return api_key
end

--- Validate API key format
function M.validate_api_key_format(api_key)
  -- Check for common patterns
  local patterns = {
    "^sk_[a-z]+_[a-zA-Z0-9]+_[a-zA-Z0-9]+$",  -- Stripe-like
    "^[a-zA-Z0-9-_]{32,}$",  -- Generic 32+ chars
  }

  for _, pattern in ipairs(patterns) do
    if api_key:match(pattern) then
      return true
    end
  end

  return false
end

--- Mask API key for logging
function M.mask_api_key(api_key)
  if not api_key or #api_key < 12 then
    return "***"
  end

  local prefix = string.sub(api_key, 1, 8)
  local suffix = string.sub(api_key, -4)

  return prefix .. "..." .. suffix
end

--- Log API key usage for audit
function M.log_api_key_usage(service, masked_key)
  local log_file = secrets_dir .. "/api_key_usage.log"
  local file = io.open(log_file, "a")

  if file then
    local log_entry = string.format(
      "[%s] Service: %s, Key: %s\n",
      os.date("%Y-%m-%d %H:%M:%S"),
      service,
      masked_key
    )
    file:write(log_entry)
    file:close()
  end
end

--- Get or generate encryption key for sensitive data
function M.get_encryption_key()
  -- Ensure secrets directory exists
  Path:new(secrets_dir):mkdir({ parents = true, exists_ok = true })

  -- Load existing key
  local file = io.open(encryption_key_file, "r")
  if file then
    local key = file:read("*all")
    file:close()
    return key
  end

  -- Generate new key
  local key = M.generate_random_key(32)
  file = io.open(encryption_key_file, "w")
  if file then
    -- Set restrictive permissions (Unix)
    os.execute(string.format("chmod 600 %s", encryption_key_file))
    file:write(key)
    file:close()
  end

  return key
end

--- Generate cryptographically random key
function M.generate_random_key(length)
  -- Use /dev/urandom on Unix systems
  local file = io.open("/dev/urandom", "rb")
  if file then
    local bytes = file:read(length)
    file:close()
    return M.base64_encode(bytes)
  end

  -- Fallback (less secure)
  math.randomseed(os.time() * os.clock())
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local key = {}
  for i = 1, length do
    local rand = math.random(1, #chars)
    table.insert(key, chars:sub(rand, rand))
  end
  return table.concat(key)
end

--- Base64 encode
function M.base64_encode(data)
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then return '' end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
    end
    return b64chars:sub(c + 1, c + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

return M
```

#### 3. Enhanced Avante Configuration

```lua
-- Update neotex/plugins/ai/avante.lua to use secrets manager
local secrets = require("neotex.util.secrets")

-- Replace direct environment variable access
local config = {
  providers = {
    claude = {
      api_key = secrets.load_api_key("anthropic"),
      -- ... rest of config
    },
    openai = {
      api_key = secrets.load_api_key("openai"),
      -- ... rest of config
    }
  }
}
```

### Migration Strategy

For existing implementations using direct environment variables:

1. **Phase 1: Add secrets manager**
   - Implement `secrets.lua` utility module
   - Keep backward compatibility with environment variables

2. **Phase 2: Update plugins**
   - Migrate Avante configuration
   - Migrate Claude session management
   - Add API key validation and logging

3. **Phase 3: Add encryption**
   - Implement `crypto.lua` for session encryption
   - Update session manager to use encryption
   - Generate master encryption key

4. **Phase 4: Security audit**
   - Review all authentication code
   - Run security scanning tools
   - Document security measures

---

## Conclusion

### Summary of Key Takeaways

1. **No Single Best Solution**
   - Authentication requirements vary by application type, scale, and security needs
   - Hybrid approaches often provide the best balance

2. **Security is Multi-Layered**
   - Authentication is just one component
   - Combine with rate limiting, MFA, monitoring, and secure coding practices

3. **Passwordless is the Future**
   - WebAuthn/FIDO2 adoption growing rapidly
   - Eliminates password-related vulnerabilities
   - Better user experience

4. **API Keys Need Proper Management**
   - Never hardcode in source code
   - Use secrets management systems
   - Implement rotation and monitoring

5. **Authentication-as-a-Service Reduces Complexity**
   - Auth0, Supabase, Clerk handle security updates
   - Faster time-to-market
   - Consider cost vs. control trade-offs

### Recommendations for Current Codebase

Based on the analysis of `/home/benjamin/.config/nvim/` codebase:

**Immediate Improvements (Low Effort, High Impact):**
1. Implement API key validation and masking
2. Add session timeout checking
3. Enable session encryption for sensitive data
4. Add audit logging for authentication events

**Medium-Term Enhancements (Moderate Effort):**
1. Migrate to secrets management system (HashiCorp Vault or AWS Secrets Manager)
2. Implement rate limiting for API calls
3. Add multi-device session management
4. Implement token refresh mechanism

**Long-Term Considerations (High Effort):**
1. Add OAuth 2.0 support for third-party integrations
2. Implement WebAuthn for passwordless authentication
3. Add MFA options (TOTP, WebAuthn)
4. Consider migration to authentication service (Supabase, Auth0)

### Further Resources

**Standards and Specifications:**
- OAuth 2.0: RFC 6749
- OpenID Connect Core 1.0
- WebAuthn Level 3: W3C Recommendation
- JWT: RFC 7519
- PKCE: RFC 7636

**Security Guidelines:**
- OWASP Authentication Cheat Sheet
- NIST Digital Identity Guidelines (SP 800-63B)
- FIDO Alliance Best Practices

**Implementation Libraries:**
- Lua: lua-resty-jwt, lua-resty-session, lua-resty-openidc
- Node.js: Passport.js, NextAuth.js, jose
- Python: PyJWT, Authlib, python-jose
- Go: go-oauth2, go-jose, webauthn-go

**Testing Tools:**
- OWASP ZAP (Security testing)
- Burp Suite (Penetration testing)
- jwt.io (JWT debugging)
- webauthn.io (WebAuthn testing)

---

## Appendix: Glossary

**API Key**: A simple token used to authenticate API requests, typically a long random string.

**Authentication**: Process of verifying the identity of a user or service.

**Authorization**: Process of determining what an authenticated entity is allowed to do.

**Argon2**: Modern password hashing algorithm, winner of Password Hashing Competition (2015).

**CSRF (Cross-Site Request Forgery)**: Attack that tricks authenticated users into performing unwanted actions.

**CTAP2**: Client to Authenticator Protocol, part of FIDO2 specification.

**FIDO2**: Authentication standard combining WebAuthn and CTAP2.

**JWT (JSON Web Token)**: Compact, URL-safe token format for securely transmitting information.

**MFA (Multi-Factor Authentication)**: Security method requiring two or more verification factors.

**mTLS (Mutual TLS)**: TLS authentication where both client and server present certificates.

**OAuth 2.0**: Authorization framework for delegated access to resources.

**OIDC (OpenID Connect)**: Identity layer built on top of OAuth 2.0.

**Passkey**: Synced WebAuthn credential, new term promoted by FIDO Alliance and platform vendors.

**PKCE**: Proof Key for Code Exchange, OAuth extension for public clients.

**TOTP**: Time-based One-Time Password, algorithm for generating temporary codes.

**WebAuthn**: Web Authentication API for passwordless authentication.

**XSS (Cross-Site Scripting)**: Injection vulnerability allowing attackers to execute scripts in victims' browsers.

---

**End of Report**

For questions or clarifications about this research, please refer to the specific sections or consult the linked resources.
