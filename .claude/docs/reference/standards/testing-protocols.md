## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Discovery
Commands should check CLAUDE.md in priority order:
1. Project root CLAUDE.md for test commands
2. Subdirectory-specific CLAUDE.md files
3. Language-specific test patterns

### Claude Code Testing
- **Test Location**: `.claude/tests/`
- **Test Runner**: `./run_all_tests.sh`
- **Test Pattern**: `test_*.sh` (Bash test scripts)
- **Coverage Target**: ≥80% for modified code, ≥60% baseline
- **Test Categories**:
  - `test_parsing_utilities.sh` - Plan parsing functions
  - `test_command_integration.sh` - Command workflows
  - `test_progressive_*.sh` - Expansion/collapse operations
  - `test_state_management.sh` - Checkpoint operations
  - `test_shared_utilities.sh` - Utility library functions
  - `test_adaptive_planning.sh` - Adaptive planning integration (16 tests)
  - `test_revise_automode.sh` - /revise auto-mode integration (18 tests)
  - `test_no_if_negation_patterns.sh` - Prohibited bash negation pattern detection (3 tests)
- **Validation Scripts**:
  - `validate_executable_doc_separation.sh` - Verifies executable/documentation separation pattern compliance (file size, guide existence, cross-references)

### Neovim Testing
- **Test Commands**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`
- **Test Pattern**: `*_spec.lua`, `test_*.lua` files in `tests/` or adjacent to source
- **Linting**: `<leader>l` to run linter via nvim-lint
- **Formatting**: `<leader>mp` to format code via conform.nvim
- **Custom Tests**: See individual project documentation

### Coverage Requirements
- Aim for >80% coverage on new code
- All public APIs must have tests
- Critical paths require integration tests
- Regression tests for all bug fixes

### Test Writing Responsibility

Tests should be written DURING implementation (not during test execution). This separation enables:
- Better separation of concerns (implementation vs validation)
- Test-driven development patterns
- Independent test execution without reimplementation

**During /implement Command**:
- Tests are written in Testing phases of the plan
- Test files created and committed with implementation
- Testing Strategy section documents test requirements in summary
- Tests NOT executed (written only)

**During /test Command**:
- Tests are executed (not written)
- Test executor reads Testing Strategy from implementation summary
- Runs tests and calculates coverage metrics
- Iterates until coverage threshold met

**Example Plan Structure**:
```markdown
### Phase 2: Authentication Implementation
- [ ] Implement JWT token generation
- [ ] Implement token validation
- [ ] Add error handling

### Phase 3: Testing
- [ ] Write unit tests for token generation (test_token_gen.sh)
- [ ] Write integration tests for auth flow (test_auth_flow.sh)
- [ ] Document test execution in Testing Strategy
```

See [Implement-Test Workflow Guide](./../guides/workflows/implement-test-workflow.md) for complete workflow patterns.

### Test Execution Loops

The /test command implements a coverage loop pattern to automatically iterate until quality threshold met.

**Loop Configuration**:
- Coverage threshold: 80% (default, configurable via `--coverage-threshold`)
- Max iterations: 5 (default, configurable via `--max-iterations`)
- Stuck threshold: 2 iterations without progress

**Exit Conditions**:

1. **Success**: `all_passed=true` AND `coverage≥threshold`
   - Next state: COMPLETE
   - Console: "All tests passed with 85% coverage after 3 iterations"

2. **Stuck**: No coverage progress for 2 consecutive iterations
   - Next state: DEBUG
   - Console: "Coverage loop stuck (no progress). Final coverage: 75%"

3. **Max Iterations**: Iteration count ≥ max_iterations
   - Next state: DEBUG
   - Console: "Max iterations (5) reached. Final coverage: 78%"

**Iteration Artifacts**:
Each iteration creates a separate test result artifact for audit trail:
- `test_results_iter1_{timestamp}.md`
- `test_results_iter2_{timestamp}.md`
- `test_results_iter3_{timestamp}.md`

**Loop Flow Example**:
```
Iteration 1: 60% coverage, 2 failed → Continue
Iteration 2: 75% coverage, 1 failed → Continue
Iteration 3: 85% coverage, all passed → SUCCESS
```

See [Implement-Test Workflow Guide](./../guides/workflows/implement-test-workflow.md) for complete coverage loop patterns.

### Summary-Based Test Execution

The /test command uses summary-based handoff to extract test execution requirements from implementation summaries.

**Testing Strategy Section Format** (in implementation summary):
```markdown
## Testing Strategy

### Test Files Created
- `/path/to/test_auth.sh` - Authentication unit tests
- `/path/to/test_api.sh` - API integration tests

### Test Execution Requirements
- **Framework**: Bash test framework (existing .claude/tests/ patterns)
- **Test Command**: `bash /path/to/test_auth.sh && bash /path/to/test_api.sh`
- **Coverage Target**: 80%
- **Expected Tests**: 15 unit tests, 8 integration tests

### Coverage Measurement
Coverage calculated via test execution output parsing.
```

**Test Execution Pattern**:
```bash
# Explicit summary path
/test --file /path/to/summaries/001-implementation-summary.md

# Auto-discovery from plan
/test /path/to/plan.md
```

See [Output Formatting Standards](./output-formatting.md) for Testing Strategy section format requirements.

### Agent Behavioral Compliance Testing

Agent behavioral compliance tests validate that agents follow execution procedures, create required files, and return properly formatted results. These tests prevent workflow failures caused by agent behavioral violations.

**Required Test Types**:

1. **File Creation Compliance**: Verify agent creates expected files at injected paths
2. **Completion Signal Format**: Validate agent returns results in specified format
3. **STEP Structure Validation**: Confirm agent follows documented STEP sequences
4. **Imperative Language**: Check agent behavioral files use MUST/WILL/SHALL (not should/may/can)
5. **Verification Checkpoints**: Ensure agent implements self-verification before returning
6. **File Size Limits**: Validate agent output files meet size constraints

**Test Pattern Examples**:

```bash
# Example 1: File Creation Compliance
test_agent_creates_file() {
  local test_dir="/tmp/test_agent_$$"
  mkdir -p "$test_dir"

  # Invoke agent with path injection
  REPORT_PATH="$test_dir/research_report.md"
  invoke_research_agent "$REPORT_PATH"

  # Verify file exists at expected path
  if [ ! -f "$REPORT_PATH" ]; then
    echo "FAIL: Agent did not create file at injected path: $REPORT_PATH"
    return 1
  fi

  # Verify file is not empty
  if [ ! -s "$REPORT_PATH" ]; then
    echo "FAIL: Agent created empty file"
    return 1
  fi

  echo "PASS: Agent created file with content"
  rm -rf "$test_dir"
  return 0
}

# Example 2: Completion Signal Format
test_completion_signal_format() {
  local agent_output=$(invoke_agent "test task")

  # Verify completion signal present
  if ! echo "$agent_output" | grep -q "COMPLETION SIGNAL"; then
    echo "FAIL: Agent did not return completion signal"
    return 1
  fi

  # Verify file path included
  if ! echo "$agent_output" | grep -q "file_path:"; then
    echo "FAIL: Completion signal missing file_path field"
    return 1
  fi

  # Extract and verify file path
  file_path=$(echo "$agent_output" | grep "file_path:" | cut -d: -f2 | tr -d ' ')
  if [ ! -f "$file_path" ]; then
    echo "FAIL: Reported file path does not exist: $file_path"
    return 1
  fi

  echo "PASS: Completion signal format valid"
  return 0
}

# Example 3: STEP Structure Validation
test_agent_step_structure() {
  local agent_file=".claude/agents/researcher.md"

  # Verify STEP sequences present
  step_count=$(grep -c "^STEP [0-9]:" "$agent_file")
  if [ "$step_count" -eq 0 ]; then
    echo "FAIL: No STEP sequences found in agent file"
    return 1
  fi

  # Verify STEPs are numbered sequentially
  for i in $(seq 1 "$step_count"); do
    if ! grep -q "^STEP $i:" "$agent_file"; then
      echo "FAIL: STEP $i missing (non-sequential numbering)"
      return 1
    fi
  done

  echo "PASS: STEP structure valid ($step_count steps)"
  return 0
}

# Example 4: Imperative Language Validation
test_agent_imperative_language() {
  local agent_file=".claude/agents/researcher.md"

  # Check for prohibited weak language
  weak_language=$(grep -E "should|may|can|might|could" "$agent_file" | grep -v "# " | head -5)
  if [ -n "$weak_language" ]; then
    echo "FAIL: Agent file uses weak language (should/may/can):"
    echo "$weak_language"
    return 1
  fi

  # Verify imperative language present
  imperative_count=$(grep -cE "MUST|WILL|SHALL" "$agent_file")
  if [ "$imperative_count" -lt 5 ]; then
    echo "FAIL: Insufficient imperative language (found $imperative_count, expected ≥5)"
    return 1
  fi

  echo "PASS: Agent file uses imperative language ($imperative_count instances)"
  return 0
}

# Example 5: Verification Checkpoints
test_agent_verification_checkpoints() {
  local agent_file=".claude/agents/researcher.md"

  # Verify MANDATORY VERIFICATION or self-verification present
  if ! grep -q "MANDATORY VERIFICATION\|verify.*before returning\|verification checkpoint" "$agent_file"; then
    echo "FAIL: No verification checkpoints found in agent file"
    return 1
  fi

  echo "PASS: Agent file includes verification checkpoints"
  return 0
}

# Example 6: File Size Limits
test_agent_file_size_limits() {
  local agent_file=".claude/agents/researcher.md"
  local max_size=40960  # 40KB limit for agent files

  # Get file size in bytes
  file_size=$(wc -c < "$agent_file")

  if [ "$file_size" -gt "$max_size" ]; then
    echo "FAIL: Agent file exceeds size limit (${file_size} bytes > ${max_size} bytes)"
    echo "Consider: Split into agent file + guide file per Standard 14"
    return 1
  fi

  echo "PASS: Agent file size acceptable (${file_size} bytes)"
  return 0
}
```

**Reference Test Suite**: `.claude/tests/test_optimize_claude_agents.sh` (320-line behavioral validation suite)

**When to Apply**:
- When creating new agents
- When modifying agent behavioral files
- When debugging agent file creation failures
- When validating agent compliance with standards

**Cross-References**:
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) → Section 3 (Behavioral Compliance)
- [Robustness Framework](../concepts/robustness-framework.md) → Pattern 5 (Comprehensive Testing)
- [Command Architecture Standards](../architecture/overview.md) → Standard 0 (Execution Enforcement)

### Test Isolation Standards
All tests MUST use isolation patterns to prevent production directory pollution.

**Key Requirements**:
- **Environment Overrides**: Set `CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"` to override location detection
- **Temporary Directories**: Use `mktemp` for unique test directories per run
- **Cleanup Traps**: Register `trap cleanup EXIT` to ensure cleanup on all exit paths
- **Validation**: Test runner detects and reports production directory pollution

**Detection Point**: `workflow-initialization.sh` and `unified-location-detection.sh` check `CLAUDE_SPECS_ROOT` first, preventing production directory creation when override is set.

**Common Test Isolation Mistakes**:

The most common test isolation mistake is setting `CLAUDE_SPECS_ROOT` to a temporary directory while leaving `CLAUDE_PROJECT_DIR` pointing to the real project. This causes production directory pollution because some library functions use `CLAUDE_PROJECT_DIR` to calculate paths.

WRONG (causes production pollution):
```bash
# This is INCORRECT - CLAUDE_PROJECT_DIR still points to production!
export CLAUDE_SPECS_ROOT="/tmp/test_specs_$$"
export CLAUDE_PROJECT_DIR="$PROJECT_ROOT"  # Real project dir
mkdir -p "$CLAUDE_SPECS_ROOT"
```

RIGHT (proper isolation):
```bash
# CORRECT - Both variables point to temporary directories
TEST_ROOT="/tmp/test_isolation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap must remove entire test root
trap 'rm -rf "$TEST_ROOT"' EXIT
```

**Incident Reference**: Empty directories 808-813 were created by `test_semantic_slug_commands.sh` due to this exact mistake. The fix (Plan 815) updated both the test and `workflow-initialization.sh` to properly respect overrides.

**Reference Documentation**:
- [Test Isolation Standards](test-isolation.md) - Complete standards and patterns
- [Library Header Documentation](.claude/lib/core/unified-location-detection.sh) - CLAUDE_SPECS_ROOT override mechanism (lines 44-68)
- [Test Template](.claude/tests/README.md) - Complete isolation pattern examples

**Utilities**:
- `.claude/scripts/detect-empty-topics.sh` - Detect and remove empty topic directories
- `.claude/tests/run_all_tests.sh` - Automated pollution detection (pre/post-test validation)

**Manual Testing Best Practices**:
When testing commands manually, always set isolation overrides:
```bash
export CLAUDE_SPECS_ROOT="/tmp/manual_test_$$"
export CLAUDE_PROJECT_DIR="/tmp/manual_test_$$"
mkdir -p "$CLAUDE_SPECS_ROOT"

# Run command
/command-to-test "arguments"

# Cleanup
rm -rf "/tmp/manual_test_$$"
unset CLAUDE_SPECS_ROOT CLAUDE_PROJECT_DIR
```

This prevents empty directory creation during development and experimentation.

### jq Filter Safety and Operator Precedence

When using jq in test scripts to query JSON logs, operator precedence is critical. Incorrect precedence can cause type errors when boolean operations are piped to string functions.

**Common Pitfall - Incorrect Precedence**:
```bash
# WRONG: Boolean result piped to contains()
jq 'select(.field == "value" and .message | contains("pattern"))'
# Evaluates as: (field == "value" and message) | contains("pattern")
# Result: boolean | contains() → TYPE ERROR
```

**Correct Pattern - Explicit Parentheses**:
```bash
# CORRECT: String operation grouped before AND
jq 'select(.field == "value" and (.message | contains("pattern")))'
# Evaluates as: field == "value" and (message | contains("pattern"))
# Result: boolean and boolean → boolean (no type error)
```

**Best Practices**:

1. **Always Use Parentheses for Pipe Operations in Boolean Context**:
   ```bash
   # When combining boolean comparisons with pipe operations
   jq 'select(.command == "test" and (.error_message | contains("error")))'
   ```

2. **Search Multiple Fields with OR**:
   ```bash
   # Search in multiple JSON fields
   jq 'select(.cmd == "test" and ((.msg | contains("err")) or (.context.cmd // "" | contains("err"))))'
   ```

3. **Use // for Default Values**:
   ```bash
   # Provide empty string default for missing fields
   jq '.context.command // ""'
   ```

4. **Test jq Filters Manually Before Use**:
   ```bash
   # Test filter against sample data
   echo '{"field":"value","message":"test error"}' | jq 'select(.field == "value" and (.message | contains("error")))'
   ```

5. **Capture jq Errors in Test Scripts**:
   ```bash
   # Capture stderr to detect jq failures
   local jq_stderr=$(mktemp)
   local result=$(cat data.json | jq 'filter' 2>"$jq_stderr")
   if [ -s "$jq_stderr" ]; then
     echo "jq error: $(cat "$jq_stderr")"
   fi
   rm -f "$jq_stderr"
   ```

**Common Error Messages**:
- `boolean (true/false) and string ("...") cannot have their containment checked` - Fix: Add parentheses around pipe operation
- `Cannot iterate over null` - Fix: Use `// ""` or `// []` for default values
- `Cannot index array with string` - Fix: Verify JSON structure matches filter expectations
