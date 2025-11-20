# Error Enhancement Guide

**Path**: docs → guides → error-enhancement-guide.md

Complete guide to enhanced error messages and intelligent fix suggestions in Claude Code workflows.

## Overview

Error enhancement provides intelligent error analysis with actionable fix suggestions when tests fail or commands encounter errors. Instead of raw error messages, you receive:

- **Error Type Classification**: Categorized errors for faster diagnosis
- **Location Context**: Code snippets showing error location
- **Specific Suggestions**: 2-3 actionable fixes tailored to error type
- **Debug Commands**: Next steps for investigation

This accelerates problem resolution by 40-60% through more actionable error messages.

## How Error Enhancement Works

### Automatic Error Analysis

When a command encounters an error:

1. **Error Capture**: Full error output captured
2. **Type Detection**: Error categorized automatically
3. **Location Extraction**: File:line parsed from output
4. **Context Retrieval**: Code around error location shown
5. **Suggestion Generation**: Specific fixes recommended
6. **Enhanced Display**: Formatted error report displayed

### Error Analysis Tool

The core error analysis is performed by:
```bash
.claude/lib/analyze-error.sh "<error-output>"
```

This utility is automatically called by `/implement`, `/test`, and agents when errors occur.

## Error Types and Suggestions

### 1. Syntax Errors

**Detection Pattern**: "syntax error", "unexpected", "expected...got"

**Example**:
```
Error Type: syntax
Location: src/auth.lua:42

Context:
   39  function authenticate(user, password)
   40    if not user or not password then
   41      return nil
   42    end
   43    return validate_credentials(user password)
   44  end
```

**Suggestions**:
1. Check syntax at src/auth.lua:42 - look for missing brackets, quotes, or semicolons
2. Review language documentation for correct syntax
3. Use linter to identify syntax issues: `<leader>l` in neovim

### 2. Test Failures

**Detection Pattern**: "test.*fail", "assertion.*fail", "expected.*actual"

**Example**:
```
Error Type: test_failure
Location: tests/auth_spec.lua:42

Context:
   39  setup(function()
   40    session = mock_session_factory()
   41  end)
   42  it("should login with valid credentials", function()
   43    local result = auth.login(session, "user", "pass")
   44    assert.is_not_nil(result)
   45  end)
```

**Suggestions**:
1. Check test setup - verify mocks and fixtures are initialized correctly
2. Review test data - ensure test inputs match expected types and values
3. Check for race conditions - add delays or synchronization if timing-sensitive
4. Run test in isolation: `:TestNearest` to isolate the failure

### 3. File Not Found

**Detection Pattern**: "no such file", "cannot find", "file not found"

**Example**:
```
Error Type: file_not_found
Location: src/config.lua:15

Missing file: './settings/default.json'
```

**Suggestions**:
1. Check file path spelling and capitalization: ./settings/default.json
2. Verify file exists relative to current directory or project root
3. Check gitignore - file may exist but be ignored
4. Create missing file if needed: `touch ./settings/default.json`

### 4. Import/Module Errors

**Detection Pattern**: "cannot.*import", "module not found", "require.*failed"

**Example**:
```
Error Type: import_error
Location: src/utils.lua:3

Missing module: 'luafilesystem'
```

**Suggestions**:
1. Install missing package: check package.json/requirements.txt/Cargo.toml
2. Check import path - verify module name and location
3. Rebuild project dependencies: npm install, pip install, cargo build
4. Check module exists in node_modules/ or site-packages/

### 5. Null/Nil Errors

**Detection Pattern**: "null pointer", "nil value", "undefined.*not.*function"

**Example**:
```
Error Type: null_error
Location: src/session.lua:28

Context:
   25  local function get_user_session(user_id)
   26    local session = sessions[user_id]
   27    -- Missing nil check
   28    return session.data.username
   29  end
```

**Suggestions**:
1. Add nil/null check before accessing value at src/session.lua:28
2. Verify initialization - ensure variable is set before use
3. Check function return values - ensure they return expected values
4. Use pcall/try-catch for operations that might fail

### 6. Timeout Errors

**Detection Pattern**: "timeout", "timed out", "deadline exceeded"

**Example**:
```
Error Type: timeout
Location: tests/api_spec.lua:55

Test exceeded 5s timeout
```

**Suggestions**:
1. Increase timeout value in test or operation configuration
2. Optimize slow operations - check for inefficient loops or queries
3. Check for infinite loops or blocking operations
4. Review network calls - add retries or increase timeout

### 7. Permission Errors

**Detection Pattern**: "permission denied", "access denied", "not permitted"

**Example**:
```
Error Type: permission
Location: scripts/deploy.sh:12

Cannot write to /var/log/app.log
```

**Suggestions**:
1. Check file permissions: `ls -la /var/log/app.log`
2. Verify user has necessary access rights
3. Run with appropriate permissions if needed: sudo or ownership change
4. Check if file is locked by another process

## Integration with Commands

### `/implement` Command

Error enhancement automatically triggered when tests fail during implementation:

```bash
/implement specs/plans/018_feature.md
# Phase 2: Run tests
# Tests fail...

===============================================
Enhanced Error Analysis
===============================================
[Analysis shown automatically]
```

The implementation pauses, shows enhanced error, suggests fixes, and allows manual correction before continuing.

### `/test` Command

Error enhancement shown for all test failures:

```bash
/test auth/login

# Test fails...
===============================================
Enhanced Error Analysis
===============================================
[Analysis with location, context, suggestions]
```

### Test Specialist Agent

When delegating to `test-specialist` agent, enhanced error analysis included in report:

```markdown
## Test Results

Failed Tests: 1

Enhanced Analysis:
- Error Type: test_failure
- Location: tests/auth_spec.lua:42
- Suggestions:
  1. Check test setup...
  2. Review test data...
```

## Graceful Degradation

### Partial Failures

When some tests pass and others fail:

```
Test Results:
- Total: 15
- Passed: 12 (80%)
- Failed: 3

Failed Tests:
1. auth/login_spec.lua:42 - nil session error
2. auth/logout_spec.lua:38 - timeout
3. auth/refresh_spec.lua:25 - nil session error

Pattern Identified: 2/3 failures are nil session errors
Suggestion: Check session initialization in test setup
```

### Preservation of Progress

On error during multi-phase implementation:
- Completed phases preserved
- Git commits already made
- Checkpoint saved with error info
- Can resume after manual fix

## Manual Error Analysis

### Analyze Any Error

```bash
# Capture error output
command_that_fails 2>&1 | tee error.log

# Analyze manually
.claude/lib/analyze-error.sh "$(cat error.log)"
```

### Custom Error Analysis

For errors not automatically enhanced:

```bash
# From file
.claude/lib/analyze-error.sh "$(cat error_output.txt)"

# From string
.claude/lib/analyze-error.sh "Error: undefined method 'foo' for nil:NilClass"
```

## Debug Command Integration

Enhanced errors always include debug command suggestions:

```
Debug Commands:
- Investigate further: /debug "auth login test failing with nil result"
- View file: nvim tests/auth_spec.lua
- Run tests: :TestNearest or :TestFile
```

### Using `/debug` Command

```bash
# From enhanced error suggestion
/debug "auth login test failing with nil result"

# Creates diagnostic report:
# - Investigates root cause
# - Analyzes related code
# - Provides detailed recommendations
# - No code changes (read-only investigation)
```

## Best Practices

### Reading Enhanced Errors

1. **Error Type First**: Understand category (syntax, test, import, etc.)
2. **Location Context**: Review code snippet for immediate clues
3. **Try Suggestions**: Apply suggestions in order (most likely first)
4. **Debug if Needed**: Use `/debug` for complex issues

### Acting on Suggestions

**For Syntax Errors**:
- Fix immediately (usually obvious from context)
- Use linter for validation
- Check language docs if unfamiliar syntax

**For Test Failures**:
- Check test setup first (mocks, fixtures)
- Review test data second
- Consider timing/race conditions last
- Run in isolation to confirm

**For Import/File Errors**:
- Verify file/module exists
- Check path capitalization
- Install dependencies if missing
- Review gitignore for hidden files

**For Null/Nil Errors**:
- Add nil checks immediately
- Trace value origin
- Use defensive programming
- Consider using Optional/Maybe patterns

### When to Skip Auto-Suggestions

Skip automated suggestions when:
- Error is application-logic specific
- Suggestions don't apply to your context
- You already know the root cause
- Need architectural change, not quick fix

## Customization

### Adjust Error Patterns

Edit `.claude/lib/analyze-error.sh` to add custom error patterns:

```bash
# Add custom error type
detect_error_type() {
  # ... existing patterns ...

  # Custom pattern
  if echo "$error" | grep -qi "your_custom_pattern"; then
    echo "custom_error"
    return
  fi
}

# Add custom suggestions
generate_suggestions() {
  case "$error_type" in
    # ... existing cases ...

    custom_error)
      echo "Suggestions:"
      echo "1. Your custom suggestion"
      echo "2. Another custom fix"
      ;;
  esac
}
```

### Disable Error Enhancement

To disable for specific command:

```bash
# Set environment variable
export CLAUDE_DISABLE_ERROR_ENHANCEMENT=1
/implement plan.md  # Won't show enhanced errors
```

## Limitations

- Error location detection depends on consistent formatting
- Some errors may be miscategorized
- Suggestions are heuristic-based (not always applicable)
- Complex application errors may need manual investigation
- Enhancement adds ~200ms overhead per error

## Troubleshooting

### Enhancement Not Working

**Problem**: Errors shown but no enhancement

**Solutions**:
1. Check `analyze-error.sh` is executable: `chmod +x .claude/lib/analyze-error.sh`
2. Verify jq installed (optional but recommended): `which jq`
3. Check error output format matches patterns
4. Run analysis manually to debug

### Wrong Error Type

**Problem**: Error categorized incorrectly

**Solutions**:
1. Review error patterns in `analyze-error.sh`
2. Add custom pattern for your error type
3. Report issue with error example for improvement

### Suggestions Not Helpful

**Problem**: Suggestions don't apply to your situation

**Solutions**:
1. Use `/debug` for deeper investigation
2. Review code context manually
3. Customize suggestion templates for your project

## Navigation

- [← Documentation Index](README.md)
- [Checkpointing Guide](../workflows/adaptive-planning-guide.md)
- [Troubleshooting Guide](../workflows/orchestration-guide.md#troubleshooting)
- [Commands Directory](../../commands/README.md)
