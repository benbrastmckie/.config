# Add Input Validation to User Authentication Endpoints - Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Input Validation for Authentication Endpoints
- **Scope**: Implement comprehensive server-side input validation with allowlist patterns, rate limiting, and security hardening for authentication endpoints
- **Estimated Phases**: 6
- **Estimated Hours**: 24
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Authentication Endpoint Analysis](../reports/001_authentication_endpoint_analysis.md)
  - [Security Vulnerabilities Prevention](../reports/002_security_vulnerabilities_prevention.md)
  - [Validation Testing Strategies](../reports/003_validation_testing_strategies.md)

## Overview

This plan implements comprehensive input validation for user authentication endpoints based on OWASP best practices and research findings. The implementation addresses SQL injection, XSS, user enumeration, credential stuffing, and input validation bypass vulnerabilities through server-side allowlist validation, rate limiting, generic error messages, and defense-in-depth strategies.

## Research Summary

Key findings from research reports:

**From Authentication Endpoint Analysis**:
- Existing codebase demonstrates strong validation patterns in OAuth modules (lines 157-190) with error collection and environment variable validation
- Shell script validation patterns show multi-level verification approach (existence → readability → content)
- OWASP standards emphasize server-side allowlist validation over blocklist approaches
- Password policies should allow all printable characters (15+ chars without MFA, 8+ with MFA, max 128)

**From Security Vulnerabilities Prevention**:
- Primary attack vectors: SQL injection, XSS, user enumeration, credential stuffing, CSRF, input validation bypass
- Generic error messages prevent user enumeration ("Authentication failed" for all failure types)
- Timing attack protection requires constant-time responses (dummy hash comparisons for non-existent users)
- Rate limiting should be multi-layered (per-IP: 5/15min, per-account: 10/hour)
- Breached password detection via Pwned Passwords API with k-anonymity model

**From Validation Testing Strategies**:
- Testing must cover positive cases (valid input), negative cases (malicious input), boundary conditions, and timing consistency
- Security testing includes SQL injection matrix, XSS vector matrix, encoding bypass attempts
- CI/CD automation with OWASP ZAP, Jest unit tests, integration tests, and coverage requirements (95%+)
- Multi-level validation pattern from codebase: format → type → range → semantic

## Success Criteria

- [ ] All authentication endpoints enforce server-side allowlist validation
- [ ] Email validation follows RFC 5321 constraints (max 254 chars, 64 char local part)
- [ ] Password validation enforces 15-char minimum (or 8 with MFA), 128-char maximum
- [ ] Generic error messages prevent user enumeration
- [ ] Rate limiting enforced per-IP and per-account
- [ ] SQL injection and XSS attacks blocked by validation layer
- [ ] Timing attacks mitigated through constant-time responses
- [ ] Unit test coverage ≥95% for validation logic
- [ ] Integration tests cover all authentication flows
- [ ] Security tests validate OWASP Top 10 attack vector resistance
- [ ] CI/CD pipeline includes automated security scanning
- [ ] Breached password detection integrated via Pwned Passwords API

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Authentication Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Input Validation Middleware                  │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  1. Type Validation (string, length)                  │  │
│  │  2. Format Validation (allowlist regex)               │  │
│  │  3. Canonicalization (decode, normalize, trim)        │  │
│  │  4. Sanitization (parameterized queries)              │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Rate Limiting Middleware                     │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  - Per-IP: 5 attempts / 15 minutes                    │  │
│  │  - Per-Account: 10 attempts / hour                    │  │
│  │  - CAPTCHA trigger after 3 failures                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │       Authentication Handler                          │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  1. User lookup (parameterized query)                 │  │
│  │  2. Constant-time hash comparison                     │  │
│  │  3. Dummy hash for non-existent users                 │  │
│  │  4. Generic error response                            │  │
│  │  5. Timing normalization (min 200ms)                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                            ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Security Enhancement Layer                   │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  - CSRF token validation                              │  │
│  │  - Security headers (CSP, HSTS, etc.)                 │  │
│  │  - Breach detection (Pwned Passwords)                 │  │
│  │  - Audit logging                                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Component Interactions

1. **Validation Module** (`lib/validation.js`): Allowlist-based input validators
2. **Rate Limiter** (`middleware/rate-limit.js`): Multi-tier rate limiting
3. **Auth Handler** (`controllers/auth.js`): Constant-time authentication logic
4. **Error Handler** (`middleware/error-handler.js`): Generic error responses
5. **Security Middleware** (`middleware/security.js`): CSRF, headers, breach detection
6. **Test Suite** (`tests/authentication/`): Unit, integration, security tests

## Implementation Phases

### Phase 1: Foundation - Input Validation Module
dependencies: []

**Objective**: Create core input validation library with allowlist patterns for email, password, and username fields.

**Complexity**: Medium

**Tasks**:
- [ ] Create validation module structure (`lib/validation.js`)
- [ ] Implement email validation with RFC 5321 compliance (max 254 chars, 64 local, allowlist regex: `/^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/`)
- [ ] Implement password validation (length: 15-128 chars, 8-128 with MFA flag, allow all printable Unicode)
- [ ] Implement username validation (allowlist: `/^[a-zA-Z0-9_.-]{3,50}$/`)
- [ ] Add canonicalization function (URL decode → HTML decode → Unicode NFC → trim → lowercase)
- [ ] Create validation error response builder with generic messages
- [ ] Add type validation helpers (string type check, range validation)
- [ ] Document validation patterns with examples

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
npm run test:unit -- lib/validation.test.js
```

**Expected Duration**: 4 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 1 - Foundation - Input Validation Module`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Rate Limiting Implementation
dependencies: [1]

**Objective**: Implement multi-tier rate limiting middleware with per-IP and per-account throttling.

**Complexity**: Medium

**Tasks**:
- [ ] Install rate limiting dependencies (`express-rate-limit`, `rate-limit-redis` or in-memory store)
- [ ] Create rate limiter middleware (`middleware/rate-limit.js`)
- [ ] Implement per-IP rate limiter (5 attempts / 15 minutes, status 429)
- [ ] Implement per-account rate limiter (10 attempts / hour, tracked separately)
- [ ] Add progressive delay calculation (exponential backoff after failures)
- [ ] Create CAPTCHA trigger logic (after 3 failed attempts)
- [ ] Add rate limit bypass for whitelisted IPs (admin, testing)
- [ ] Implement rate limit reset endpoint (admin-only)
- [ ] Add rate limit headers to responses (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`)
- [ ] Document rate limiting configuration and thresholds

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
npm run test:unit -- middleware/rate-limit.test.js
npm run test:integration -- tests/authentication/rate-limiting.test.js
```

**Expected Duration**: 4 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 2 - Rate Limiting Implementation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Authentication Handler Hardening
dependencies: [1, 2]

**Objective**: Refactor authentication logic to prevent user enumeration and timing attacks.

**Complexity**: High

**Tasks**:
- [ ] Refactor authentication endpoint (`controllers/auth.js`) to use validation middleware
- [ ] Implement constant-time response function (minimum 200ms delay normalization)
- [ ] Add dummy hash comparison for non-existent users (use bcrypt with fixed dummy hash)
- [ ] Standardize error responses (single message: "Authentication failed. Please check your credentials.")
- [ ] Remove all user-revealing error messages (no "user not found", "incorrect password")
- [ ] Ensure identical HTTP status codes for all failure types (401 Unauthorized)
- [ ] Add detailed server-side logging (log actual failure reason, never expose to client)
- [ ] Implement parameterized database queries for user lookup (prevent SQL injection)
- [ ] Add session token generation with cryptographic randomness (32+ bytes)
- [ ] Update password reset flow to use generic messages

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
npm run test:unit -- controllers/auth.test.js
npm run test:integration -- tests/authentication/auth-flow.test.js
npm run test:security -- tests/authentication/user-enumeration.test.js
```

**Expected Duration**: 5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 3 - Authentication Handler Hardening`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Security Enhancement Layer
dependencies: [3]

**Objective**: Add CSRF protection, security headers, and breached password detection.

**Complexity**: High

**Tasks**:
- [ ] Install security dependencies (`csurf`, `helmet`, `express-validator`)
- [ ] Create CSRF protection middleware (`middleware/csrf.js`) with synchronizer token pattern
- [ ] Configure helmet.js for security headers (CSP: `default-src 'self'`, HSTS, X-Frame-Options, X-Content-Type-Options)
- [ ] Implement SameSite cookie configuration (`sameSite: 'strict'`, `httpOnly: true`, `secure: true`)
- [ ] Create breach detection module (`lib/breach-detection.js`) integrating Pwned Passwords API
- [ ] Implement k-anonymity hash prefix lookup (SHA-1 first 5 chars, compare suffixes)
- [ ] Add breach check to registration endpoint (reject if count > 0)
- [ ] Add breach check to password change endpoint
- [ ] Implement graceful degradation if Pwned Passwords API unavailable (log warning, allow operation)
- [ ] Add audit logging for security events (failed logins, rate limits, breach attempts)
- [ ] Configure Content Security Policy with nonce-based script/style loading

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
npm run test:unit -- lib/breach-detection.test.js
npm run test:integration -- tests/authentication/csrf.test.js
npm run test:security -- tests/authentication/security-headers.test.js
```

**Expected Duration**: 5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 4 - Security Enhancement Layer`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Comprehensive Test Suite
dependencies: [4]

**Objective**: Create comprehensive unit, integration, and security tests achieving 95%+ coverage.

**Complexity**: High

**Tasks**:
- [ ] Create test directory structure (`tests/authentication/{unit,integration,security}/`)
- [ ] Write unit tests for email validation (valid cases, boundary conditions, invalid formats, SQL injection patterns, XSS patterns)
- [ ] Write unit tests for password validation (length boundaries, Unicode support, breach detection)
- [ ] Write unit tests for rate limiting (within limit, exceeding limit, window reset, per-account independence)
- [ ] Write integration tests for registration → verification → login → access flow
- [ ] Write integration tests for MFA flow (credentials → MFA prompt → code validation → success)
- [ ] Write security tests for SQL injection matrix (comment injection, OR conditions, UNION, stacked queries)
- [ ] Write security tests for XSS vector matrix (script tags, event handlers, javascript: protocol, encoded attacks)
- [ ] Write security tests for user enumeration prevention (timing consistency, identical messages)
- [ ] Write security tests for CSRF protection (valid token, missing token, invalid token)
- [ ] Write encoding bypass tests (HTML entities, URL encoding, double encoding, Unicode, nested tags)
- [ ] Configure test coverage reporting (Istanbul/nyc, target: 95%+)
- [ ] Create test documentation with attack vector catalog

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
npm run test:coverage
npm run test:security
```

**Expected Duration**: 4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 5 - Comprehensive Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: CI/CD Integration and Documentation
dependencies: [5]

**Objective**: Automate security testing in CI/CD pipeline and create comprehensive documentation.

**Complexity**: Low

**Tasks**:
- [ ] Create GitHub Actions workflow (`.github/workflows/auth-tests.yml`)
- [ ] Configure automated unit test execution on push/PR
- [ ] Configure automated integration test execution with test database
- [ ] Add OWASP ZAP baseline scan step (docker: `owasp/zap2docker-stable`)
- [ ] Configure ZAP to fail pipeline on high/critical findings
- [ ] Add coverage upload to Codecov or similar service
- [ ] Create security testing documentation (`docs/SECURITY_TESTING.md`)
- [ ] Document validation patterns and allowlist rules (`docs/VALIDATION_PATTERNS.md`)
- [ ] Create attack vector catalog with test coverage map (`docs/ATTACK_VECTORS.md`)
- [ ] Update main README with security features section
- [ ] Add inline code comments documenting security considerations
- [ ] Create runbook for security incident response

**Testing**:
```bash
# Verify CI/CD configuration locally
act push -j test
# Verify documentation completeness
npm run docs:validate
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(016): complete Phase 6 - CI/CD Integration and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **Scope**: Individual validation functions, rate limiters, error handlers
- **Coverage Target**: 95%+ line coverage
- **Tools**: Jest, Sinon for mocking
- **Focus Areas**: Positive cases, negative cases, boundary conditions, attack patterns

### Integration Testing
- **Scope**: Complete authentication flows (registration → verification → login → access)
- **Coverage**: All endpoint combinations, MFA flows, password reset flows
- **Tools**: Supertest for HTTP assertions
- **Focus Areas**: State transitions, middleware chaining, database interactions

### Security Testing
- **Scope**: OWASP Top 10 attack vectors
- **Coverage**: SQL injection, XSS, CSRF, user enumeration, timing attacks, encoding bypasses
- **Tools**: OWASP ZAP, custom penetration scripts
- **Focus Areas**: Attack vector matrix, timing consistency, error message analysis

### Performance Testing
- **Scope**: Rate limiter effectiveness, timing attack mitigation
- **Coverage**: High-load scenarios, concurrent requests, timing variance
- **Tools**: Artillery, custom timing tests
- **Focus Areas**: Response time consistency, rate limit accuracy

### Test Automation
- **CI/CD**: GitHub Actions pipeline on every push/PR
- **Security Scans**: OWASP ZAP baseline scan (fail on high/critical)
- **Coverage**: Automated coverage reporting with threshold enforcement (95%)
- **Regression**: Full test suite on every commit

## Documentation Requirements

### Code Documentation
- [ ] Inline comments for all validation patterns explaining security rationale
- [ ] JSDoc comments for all public functions with parameter validation rules
- [ ] Security consideration notes in authentication handlers

### Architecture Documentation
- [ ] Update system architecture diagram with validation layer
- [ ] Document defense-in-depth strategy
- [ ] Create threat model document

### Security Documentation
- [ ] Security testing guide with attack vector catalog
- [ ] Validation pattern reference (allowlist rules, length constraints)
- [ ] Incident response runbook
- [ ] Security configuration guide

### Developer Documentation
- [ ] API documentation with validation requirements
- [ ] Testing guide with examples
- [ ] Contributing guide with security review process

## Dependencies

### External Dependencies
- **express-rate-limit**: Rate limiting middleware (MIT license)
- **csurf**: CSRF protection middleware (MIT license)
- **helmet**: Security headers middleware (MIT license)
- **bcrypt**: Password hashing (MIT license)
- **express-validator**: Input validation utilities (MIT license)
- **axios**: HTTP client for Pwned Passwords API (MIT license)

### Development Dependencies
- **jest**: Testing framework
- **supertest**: HTTP assertion library
- **sinon**: Mocking library
- **nyc/istanbul**: Coverage reporting
- **owasp/zap2docker-stable**: Security scanning

### Infrastructure Dependencies
- **Redis** (optional): Distributed rate limiting (can use in-memory for MVP)
- **PostgreSQL/MySQL**: User database with parameterized query support
- **HTTPS**: TLS encryption for all authentication endpoints

### External Services
- **Pwned Passwords API**: Breach detection (haveibeenpwned.com/API)
- **CAPTCHA Service**: reCAPTCHA or hCaptcha for bot protection (optional)

## Risk Assessment

### Technical Risks
- **Risk**: Pwned Passwords API outage breaks registration
  - **Mitigation**: Graceful degradation, log warning, allow operation
  - **Impact**: Low (availability > security for registration, still validated)

- **Risk**: Timing attack mitigation adds latency
  - **Mitigation**: Configurable minimum delay (default 200ms), acceptable for auth
  - **Impact**: Low (200ms acceptable for security-critical operation)

- **Risk**: Rate limiting false positives (shared IPs, NAT)
  - **Mitigation**: Per-account rate limiting, whitelist capability, CAPTCHA fallback
  - **Impact**: Medium (mitigated by multi-tier approach)

### Security Risks
- **Risk**: New attack vectors not covered by validation
  - **Mitigation**: Regular security testing, bug bounty, OWASP Top 10 tracking
  - **Impact**: Medium (ongoing monitoring required)

- **Risk**: Bypass via encoding tricks
  - **Mitigation**: Canonical form validation, multi-layer defense
  - **Impact**: Low (tested extensively)

### Operational Risks
- **Risk**: Test suite execution time increases development cycle
  - **Mitigation**: Parallel test execution, CI/CD caching
  - **Impact**: Low (test speed optimized)

## Rollout Strategy

### Phase 1: Development Environment
1. Implement and test validation in dev environment
2. Run full security test suite
3. Verify no regressions in existing functionality

### Phase 2: Staging Environment
1. Deploy to staging with monitoring
2. Run penetration testing
3. Load testing to verify rate limiter performance
4. Timing attack testing with production-like data

### Phase 3: Production Rollout
1. Deploy rate limiting first (observe, tune thresholds)
2. Enable validation with warning logs (1 week observation)
3. Enable enforcement mode with generic errors
4. Enable CSRF protection and security headers
5. Monitor error rates and user feedback

### Rollback Plan
- Feature flags for each security layer (validation, rate limiting, CSRF)
- Database backups before deployment
- Quick rollback scripts for each phase
- Monitoring alerts for error rate spikes
