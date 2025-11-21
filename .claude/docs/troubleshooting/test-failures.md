# Test Failures Troubleshooting Guide

**Path**: docs → troubleshooting → test-failures.md

Comprehensive guide for diagnosing and resolving common test failure scenarios in the .claude system.

## Common Test Failure Patterns

### jq Filter Type Errors

**Symptom**: Test fails with error message like:
```
jq: error (at <stdin>:1): boolean (true/false) and string ("...") cannot have their containment checked
```

**Root Cause**: Operator precedence bug in jq filter causes boolean result to be piped to string function.

**Example of Incorrect Filter**:
```bash
# WRONG: Boolean AND result piped to contains()
jq 'select(.command == "test" and .error_message | contains("pattern"))'
# Evaluates as: (.command == "test" and .error_message) | contains("pattern")
# Result: boolean piped to contains() → TYPE ERROR
```

**Fix**: Add parentheses to ensure correct evaluation order:
```bash
# CORRECT: String operation grouped before AND
jq 'select(.command == "test" and (.error_message | contains("pattern")))'
# Evaluates as: .command == "test" and (.error_message | contains("pattern"))
# Result: boolean AND boolean → boolean (no error)
```

**Verification**:
```bash
# Test filter manually against sample data
echo '{"command":"test","error_message":"test error"}' | \
  jq 'select(.command == "test" and (.error_message | contains("error")))'
```

**See Also**: [jq Filter Safety](../reference/standards/testing-protocols.md#jq-filter-safety-and-operator-precedence)

### Error Log Routing Issues

**Symptom**: Test errors appear in production log (`data/logs/errors.jsonl`) instead of test log (`tests/logs/test-errors.jsonl`).

**Root Cause**: Test environment not properly detected.

**Diagnostic**:
```bash
# Check production log for recent test entries
tail -10 /path/to/.claude/data/logs/errors.jsonl | \
  jq -c '{timestamp, environment, command, error_message}'

# Look for environment: "production" when it should be "test"
```

**Fix Options**:

1. **Set CLAUDE_TEST_MODE explicitly** (Recommended):
   ```bash
   # Add to test script initialization
   export CLAUDE_TEST_MODE=1
   ```

2. **Move test script to .claude/tests/ directory**:
   ```bash
   # Automatic detection based on script path
   # Scripts in .claude/tests/ automatically route to test log
   ```

3. **Verify TEST_LOG_DIR is set**:
   ```bash
   # In error-handling.sh initialization
   TEST_LOG_DIR="${CLAUDE_CONFIG}/.claude/tests/logs"
   ```

**Verification**:
```bash
# Run test and check environment field
./test_script.sh
tail -1 tests/logs/test-errors.jsonl | jq '.environment'
# Should output: "test"

# Verify production log unchanged
BEFORE=$(wc -l < data/logs/errors.jsonl)
./test_script.sh
AFTER=$(wc -l < data/logs/errors.jsonl)
[ "$BEFORE" -eq "$AFTER" ] && echo "Production log isolated"
```

**See Also**: [Test Environment Separation](../concepts/patterns/error-handling.md#test-environment-separation)

### Low Error Capture Rate

**Symptom**: Test suite reports capture rate below 90% target.

**Root Cause**: Errors not being logged or search pattern not matching actual error messages.

**Diagnostic Steps**:

1. **Verify errors are being logged**:
   ```bash
   # Check if error log has recent entries
   tail -10 tests/logs/test-errors.jsonl | jq -c '{timestamp, error_message}'
   ```

2. **Check search pattern**:
   ```bash
   # Manually search for expected error
   cat tests/logs/test-errors.jsonl | jq -r '.error_message' | grep -i "pattern"
   ```

3. **Verify error trap is registered**:
   ```bash
   # Check test script calls setup_bash_error_trap
   grep "setup_bash_error_trap" test_script.sh
   ```

4. **Check error trap coverage**:
   ```bash
   # ERR trap catches command failures (exit code 127, etc.)
   # EXIT trap catches unbound variables (set -u violations)
   # Both are needed for 100% coverage
   ```

**Fix Options**:

1. **Ensure both ERR and EXIT traps are registered**:
   ```bash
   # error-handling.sh already registers both
   setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
   ```

2. **Search in multiple fields**:
   ```bash
   # Search both error_message and context.command
   jq 'select((.error_message | contains("pattern")) or (.context.command // "" | contains("pattern")))'
   ```

3. **Adjust search pattern to match actual error format**:
   ```bash
   # Error messages have standard format:
   # "Bash error at line N: exit code M"
   # Context field has failed command details
   ```

**Verification**:
```bash
# Run test suite
./test_bash_error_integration.sh

# Check capture rate in summary
# Should show: Capture Rate: 100%
```

**See Also**: [Error Handling Pattern](../concepts/patterns/error-handling.md)

### Test Log File Missing

**Symptom**: Test fails with error `NOT_FOUND:log_file_missing`.

**Root Cause**: Test log directory or file not created.

**Diagnostic**:
```bash
# Check if test log directory exists
ls -la .claude/tests/logs/

# Check if test log file exists
test -f .claude/tests/logs/test-errors.jsonl && echo "EXISTS" || echo "MISSING"
```

**Fix**:
```bash
# Create test log directory
mkdir -p .claude/tests/logs

# Initialize test log file (optional - created automatically)
touch .claude/tests/logs/test-errors.jsonl
```

**Automatic Creation**: The error-handling.sh library creates the test log directory and file automatically when CLAUDE_TEST_MODE is set or test environment is detected.

### jq Command Not Found

**Symptom**: Test fails with error `jq: command not found`.

**Root Cause**: jq not installed or not in PATH.

**Fix**:
```bash
# Check if jq is installed
which jq

# Install jq if missing (example for Ubuntu/Debian)
sudo apt-get install jq

# Or download binary from https://stedolan.github.io/jq/
```

**Verification**:
```bash
# Test jq installation
echo '{"test":"value"}' | jq '.test'
# Should output: "value"
```

## Test Diagnostic Commands

### Check Recent Test Errors

```bash
# View last 10 test errors with key fields
tail -10 .claude/tests/logs/test-errors.jsonl | \
  jq -c '{timestamp, command, error_type, error_message}'
```

### Search for Specific Error Pattern

```bash
# Search test log for errors containing pattern
cat .claude/tests/logs/test-errors.jsonl | \
  jq -r 'select(.error_message | contains("pattern")) | {timestamp, command, error_message}'
```

### Compare Test vs Production Logs

```bash
# Count entries in each log
echo "Test log: $(wc -l < .claude/tests/logs/test-errors.jsonl 2>/dev/null || echo 0) entries"
echo "Production log: $(wc -l < .claude/data/logs/errors.jsonl 2>/dev/null || echo 0) entries"

# Check environment distribution
echo "Test environment entries:"
jq -r 'select(.environment == "test") | .timestamp' .claude/data/logs/errors.jsonl | wc -l
echo "Production environment entries:"
jq -r 'select(.environment == "production") | .claude/data/logs/errors.jsonl | wc -l
```

### Verify jq Filter Syntax

```bash
# Test filter against sample log entry
tail -1 .claude/tests/logs/test-errors.jsonl | \
  jq 'select(.command == "/test" and (.error_message | contains("error")))'
```

### Clear Test Logs

```bash
# Use cleanup script
.claude/tests/scripts/cleanup_test_logs.sh

# Or manual backup and clear
cp .claude/tests/logs/test-errors.jsonl \
   .claude/tests/logs/test-errors.jsonl.backup_$(date +%s)
> .claude/tests/logs/test-errors.jsonl
```

## Prevention Best Practices

1. **Always Use CLAUDE_TEST_MODE in Test Scripts**:
   ```bash
   export CLAUDE_TEST_MODE=1
   ```

2. **Add Parentheses to jq Filters with Pipes**:
   ```bash
   jq 'select(.field == "value" and (.message | contains("pattern")))'
   ```

3. **Test jq Filters Manually Before Use**:
   ```bash
   echo '{"field":"value"}' | jq 'your_filter_here'
   ```

4. **Capture jq Errors in Test Scripts**:
   ```bash
   local jq_stderr=$(mktemp)
   local result=$(cat data.json | jq 'filter' 2>"$jq_stderr")
   if [ -s "$jq_stderr" ]; then
     echo "jq error: $(cat "$jq_stderr")"
   fi
   rm -f "$jq_stderr"
   ```

5. **Verify Test Environment Isolation**:
   ```bash
   # Count production log entries before and after test
   BEFORE=$(wc -l < data/logs/errors.jsonl)
   ./run_tests.sh
   AFTER=$(wc -l < data/logs/errors.jsonl)
   [ "$BEFORE" -eq "$AFTER" ] && echo "Isolated"
   ```

## Related Documentation

- [Testing Protocols](../reference/standards/testing-protocols.md) - Test discovery, patterns, and coverage requirements
- [Error Handling Pattern](../concepts/patterns/error-handling.md) - Centralized error logging architecture
- [jq Filter Safety](../reference/standards/testing-protocols.md#jq-filter-safety-and-operator-precedence) - Operator precedence best practices
