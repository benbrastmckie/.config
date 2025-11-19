# Authentication Endpoint Analysis and Current Implementation Patterns

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Authentication endpoint implementations in the codebase
- **Report Type**: codebase analysis

## Executive Summary

This report analyzes authentication endpoint implementations in the codebase and industry best practices for input validation. The codebase contains OAuth2 implementations for email authentication in Neovim plugins, primarily focused on credential management and token refresh flows. Industry best practices from OWASP emphasize server-side allowlist validation, generic error messages to prevent enumeration, and permissive password policies to support password managers and passphrases.

## Findings

### Current Authentication Implementations in Codebase

#### 1. OAuth Configuration Module (Neovim Himalaya Plugin)
**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/oauth.lua`

**Key Functions and Validation Patterns**:
- `M.validate(account_name)` (lines 157-190): Validates OAuth configuration completeness
- **Validation Approach**: Checks for required fields (refresh_command, client_id_env, client_secret_env)
- **Environment Variable Validation**: Verifies environment variables are set before proceeding
- **Error Collection Pattern**: Accumulates all validation errors in array for comprehensive feedback
- **Return Pattern**: Returns boolean success status and error array tuple

**Code Example**:
```lua
-- Lines 157-190
function M.validate(account_name)
  local oauth_config = module_state.oauth_configs[account_name]
  if not oauth_config then
    return true -- No OAuth configured is valid
  end

  local errors = {}

  -- Check required fields
  if not oauth_config.refresh_command then
    table.insert(errors, account_name .. ": OAuth refresh_command not configured")
  end

  if not oauth_config.client_id_env then
    table.insert(errors, account_name .. ": OAuth client_id_env not configured")
  end

  if not oauth_config.client_secret_env then
    table.insert(errors, account_name .. ": OAuth client_secret_env not configured")
  end

  -- Check if environment variables are set
  if oauth_config.client_id_env and not M.get_client_id(account_name) then
    table.insert(errors, account_name .. ": OAuth client ID environment variable '" ..
                        oauth_config.client_id_env .. "' not set")
  end

  if oauth_config.client_secret_env and not M.get_client_secret(account_name) then
    table.insert(errors, account_name .. ": OAuth client secret environment variable '" ..
                        oauth_config.client_secret_env .. "' not set")
  end

  return #errors == 0, errors
end
```

**Validation Strengths**:
- Comprehensive field presence checking
- Environment variable existence validation
- Descriptive error messages with context
- Non-nil and non-empty string checks (lines 143-144)

**Validation Gaps**:
- No format validation for environment variable values
- No length constraints on configuration values
- No sanitization of account_name parameter

#### 2. OAuth Token Management Module
**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/sync/oauth.lua`

**Security Patterns Observed**:
- **Token Existence Checking**: Uses external `secret-tool` for secure credential storage (lines 51-67)
- **Cooldown Protection**: Prevents rapid refresh attempts with time-based throttling (lines 147-154)
- **State Management**: Tracks refresh status to prevent concurrent operations (lines 137-143)
- **Async Validation**: Non-blocking token validation via callbacks (lines 111-130)

**Code Example - Cooldown Protection**:
```lua
-- Lines 147-154
local last_refresh = state.get("oauth.last_refresh", 0)
local last_refresh_failed = state.get("oauth.last_refresh_failed", false)
if last_refresh_failed and os.time() - last_refresh < REFRESH_RETRY_COOLDOWN then
  logger.info('OAuth refresh on cooldown')
  if callback then
    callback(false, "cooldown")
  end
  return
end
```

**Security Strengths**:
- Rate limiting via cooldown (300s success, 60s failure)
- Concurrent operation prevention
- External secure credential storage
- Command injection protection via array-based command construction (line 238)

**Validation Gaps**:
- No validation of account name format
- Token name construction vulnerable to injection if account contains special chars (lines 55-60)
- No validation of refresh script path before execution

#### 3. HTTP Authentication Module (Node.js)
**Location**: `/home/benjamin/.config/node_modules/needle/lib/auth.js`

**Authentication Schemes Implemented**:
- Basic Authentication (lines 22-25)
- Digest Authentication (lines 60-105)

**Code Example - Basic Auth**:
```javascript
// Lines 22-25
function basic(user, pass) {
  var str  = typeof pass == 'undefined' ? user : [user, pass].join(':');
  return 'Basic ' + Buffer.from(str).toString('base64');
}
```

**Validation Gaps**:
- No input validation on user/pass parameters
- No length limits on credentials
- No character sanitization before encoding
- Direct string concatenation without escaping (line 23)
- MD5 used for digest auth (deprecated, line 18)

### Shell Script Validation Patterns in .claude Library

**Location**: `/home/benjamin/.config/.claude/lib/`

**Common Validation Patterns Observed**:

1. **Parameter Existence Checks** (backup-command-file.sh:12):
```bash
if [[ -z "$FILE_PATH" ]]; then
  echo "ERROR: FILE_PATH required"
  return 1
fi
```

2. **File Existence Validation** (backup-command-file.sh:18):
```bash
if [[ ! -f "$FILE_PATH" ]]; then
  echo "ERROR: File not found: $FILE_PATH"
  return 1
fi
```

3. **State Validation** (checkbox-utils.sh:33):
```bash
if [[ "$new_state" != "x" && "$new_state" != " " ]]; then
  echo "ERROR: Invalid state '$new_state'. Must be 'x' or ' '"
  return 1
fi
```

4. **Comprehensive Verification Functions** (verification-helpers.sh:73):
- `verify_file_created()`: Multi-level validation (exists, readable, non-empty)
- `verify_state_variable()`: State file variable validation
- Pattern: Check, validate, provide context-rich error messages

### Industry Best Practices (OWASP 2025)

#### Input Validation Standards

**1. Server-Side Validation (Mandatory)**
- All validation MUST occur server-side
- Client-side validation only for UX, never security
- No trust in any client-provided data

**2. Allowlist Over Blocklist**
- Define exactly what IS authorized (allowlist)
- Everything else automatically denied
- Blocklists easily bypassed via encoding/obfuscation

**3. Two-Level Validation**
- **Syntactic**: Correct format (email structure, date format)
- **Semantic**: Business logic validity (date ranges, authorized values)

#### Authentication-Specific Validation

**Username/Email Validation**:
- Permit email addresses as usernames (with verification)
- Email format: two parts separated by '@'
- Domain: letters, numbers, hyphens, periods only
- Local part: max 63 characters
- Total email: max 254 characters
- No dangerous characters (HTML/SQL injection risk)
- Semantic validation via time-limited verification tokens (32+ chars, single-use)

**Password Field Requirements**:
- **Minimum Length**: 8 chars with MFA, 15 chars without MFA
- **Maximum Length**: Support at least 64 characters (passphrases)
- **Character Policy**: Allow ALL printable characters (Unicode, whitespace, special)
- **No Composition Rules**: Don't mandate uppercase/lowercase/numbers/special
- **Allow Pasting**: Support password managers
- **Breach Detection**: Check against known breached password databases
- **No Silent Truncation**: Reject or warn if password exceeds max

**Authentication Endpoint Security**:
- **Generic Error Messages**: "Login failed; Invalid user ID or password"
- **No Enumeration Hints**: Identical response for wrong username vs wrong password
- **Transport Security**: TLS required for all credential transmission
- **Rate Limiting**: Protect against brute force attacks
- **Reauthentication**: Require for sensitive operations (password change, email update)

#### Common Vulnerability Patterns to Prevent

**1. SQL Injection**:
- Attack: `' OR '1'='1` in username field
- Prevention: Parameterized queries, input validation, prepared statements

**2. Cross-Site Scripting (XSS)**:
- Attack: `<script>malicious.js</script>` in input fields
- Prevention: Output encoding, Content Security Policy, input sanitization

**3. Cross-Site Request Forgery (CSRF)**:
- Attack: Malicious link triggers authenticated action
- Prevention: CSRF tokens, SameSite cookies, request validation

**4. User Enumeration**:
- Attack: Different responses reveal valid usernames
- Prevention: Generic error messages, timing attack protection

**5. Credential Stuffing**:
- Attack: Breached credentials from other sites
- Prevention: Breach detection, MFA, rate limiting, CAPTCHA

**6. Input Validation Bypass**:
- Attack: Encoding tricks to evade blocklists (`<scr<script>ipt>`)
- Prevention: Allowlist validation, canonical form validation

## Recommendations

### 1. Implement Server-Side Allowlist Validation for All Authentication Endpoints

**Priority**: Critical

**Implementation**:
- Define explicit allowlists for username/email formats
- Use regular expressions with anchors (`^...$`) to prevent bypass
- Validate on server-side before any database queries or business logic
- Reject invalid input with generic error messages

**Example Pattern**:
```javascript
// Email allowlist validation
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]{1,63}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

function validateEmail(email) {
  if (!email || email.length > 254) {
    return { valid: false, error: "Invalid input format" };
  }

  if (!EMAIL_REGEX.test(email)) {
    return { valid: false, error: "Invalid input format" };
  }

  // Additional semantic validation
  const [localPart, domain] = email.split('@');
  if (localPart.length > 63) {
    return { valid: false, error: "Invalid input format" };
  }

  return { valid: true };
}
```

### 2. Add Rate Limiting and Cooldown Protection

**Priority**: High

**Implementation**:
- Implement request throttling (e.g., 5 attempts per 15 minutes per IP)
- Add progressive delays after failed attempts (exponential backoff)
- Track by both IP address and username (if provided)
- Consider CAPTCHA after threshold

**Example Pattern** (from codebase oauth.lua):
```lua
-- Cooldown pattern already implemented in oauth.lua:147-154
local REFRESH_COOLDOWN = 300 -- 5 minutes success
local REFRESH_RETRY_COOLDOWN = 60 -- 1 minute failure

if last_refresh_failed and os.time() - last_refresh < REFRESH_RETRY_COOLDOWN then
  return { success: false, error: "Too many attempts. Please try again later." }
end
```

### 3. Standardize Generic Error Messages Across All Endpoints

**Priority**: High

**Implementation**:
- Use identical messages for all authentication failures
- Never reveal whether username exists or password was wrong
- Add timing consistency to prevent timing attacks
- Log detailed errors server-side only

**Example**:
```javascript
// BAD - Reveals information
if (!userExists) return "User not found";
if (!passwordMatches) return "Incorrect password";

// GOOD - Generic message
return "Authentication failed. Please check your credentials and try again.";
```

### 4. Implement Comprehensive Input Sanitization

**Priority**: High

**Implementation**:
- Sanitize all inputs before processing or storage
- Escape special characters for SQL/HTML contexts
- Use parameterized queries for database operations
- Apply canonical form conversion before validation

**Gaps to Address**:
- oauth.lua account_name parameter (no sanitization before use)
- auth.js user/pass parameters (no validation or sanitization)
- Token name construction in oauth.lua lines 55-60

### 5. Add Password Policy Enforcement

**Priority**: Medium

**Implementation**:
- Minimum 8 characters with MFA, 15 without
- Maximum 64+ characters (support passphrases)
- Allow all printable characters (Unicode, special, whitespace)
- Check against breached password databases (Pwned Passwords API)
- Provide strength meter (zxcvbn-ts library)
- Never silently truncate passwords

**Example**:
```javascript
function validatePassword(password) {
  const MIN_LENGTH_WITH_MFA = 8;
  const MIN_LENGTH_NO_MFA = 15;
  const MAX_LENGTH = 128;

  if (password.length < MIN_LENGTH_NO_MFA) {
    return { valid: false, error: "Password must be at least 15 characters (or 8 with MFA)" };
  }

  if (password.length > MAX_LENGTH) {
    return { valid: false, error: "Password exceeds maximum length of 128 characters" };
  }

  // Check against breached passwords
  const isBreached = await checkPwnedPasswords(password);
  if (isBreached) {
    return { valid: false, error: "This password has been found in data breaches. Please choose a different password." };
  }

  return { valid: true };
}
```

### 6. Implement Validation Error Collection Pattern

**Priority**: Medium

**Implementation**:
- Collect all validation errors before returning (from oauth.lua pattern)
- Provide comprehensive feedback for debugging (server-side logs)
- Return generic message to client with error tracking ID
- Enable developers to trace issues without exposing vulnerabilities

**Pattern from codebase** (oauth.lua:163-189):
```lua
local errors = {}
-- Collect all validation failures
if not field1 then table.insert(errors, "Field 1 error") end
if not field2 then table.insert(errors, "Field 2 error") end
-- Return summary
return #errors == 0, errors
```

### 7. Add Security Headers and Transport Encryption

**Priority**: Critical

**Implementation**:
- Enforce TLS/HTTPS for all authentication endpoints
- Set Strict-Transport-Security header
- Implement Content Security Policy
- Use SameSite=Strict for authentication cookies
- Add X-Frame-Options, X-Content-Type-Options headers

### 8. Enhance Logging and Monitoring

**Priority**: Medium

**Implementation**:
- Log all authentication attempts with timestamps, IP addresses
- Track failed attempt patterns for anomaly detection
- Monitor for credential stuffing attacks
- Alert on unusual patterns (geographic anomalies, velocity)
- Never log passwords or tokens (log only success/failure)

## References

### Codebase Files Analyzed
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/config/oauth.lua` (lines 1-192)
  - Validation function: lines 157-190
  - Credential checking: lines 139-145
  - Configuration management: lines 26-53

- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/sync/oauth.lua` (lines 1-423)
  - Token validation: lines 92-109
  - Cooldown protection: lines 147-154
  - Refresh mechanism: lines 133-297
  - Token info retrieval: lines 314-347

- `/home/benjamin/.config/node_modules/needle/lib/auth.js` (lines 1-112)
  - Basic authentication: lines 22-25
  - Digest authentication: lines 60-105
  - MD5 usage: line 18

- `/home/benjamin/.config/.claude/lib/backup-command-file.sh` (lines 12, 18, 32, 41, 52)
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` (lines 28, 33, 62, 87, 110, 131-164)
- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` (lines 73-173, 223-258)

### External References
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Input Validation Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- OWASP Top 10 A07:2025 - Identification and Authentication Failures
- CWE-20: Improper Input Validation
- Pwned Passwords API for breach detection
- zxcvbn-ts library for password strength estimation
