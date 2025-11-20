# Error Handling Flowchart

**Path**: docs → reference → decision-trees → error-handling-flowchart.md

Quick decision tree for diagnosing and resolving common Claude Code errors.

## Primary Decision Tree

```
┌─────────────────────────────────────────────┐
│ Claude Code workflow error encountered     │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │ What type of error is it?   │
    └──────────┬──────────────────┘
               │
     ┌─────────┼─────────┬─────────────┐
     │         │         │             │
     ▼         ▼         ▼             ▼
┌──────────┐ ┌─────┐ ┌──────┐  ┌──────────────┐
│ Agent    │ │File │ │Test  │  │ Command      │
│Delegation│ │Error│ │Error │  │Syntax/Config │
└────┬─────┘ └──┬──┘ └──┬───┘  └──────┬───────┘
     │          │       │              │
     ▼          ▼       ▼              ▼
  See A      See B    See C         See D
```

## [A] Agent Delegation Failures

### Symptom Checklist

- [ ] Files created in unexpected locations (e.g., `TODO1.md` instead of proper path)
- [ ] Agent invocations wrapped in markdown code blocks
- [ ] `MUST`, `WILL`, or `SHALL` language missing in invocations
- [ ] Behavioral files (`.claude/agents/*.md`) not referenced
- [ ] Task tool not used (only YAML documentation blocks)
- [ ] Agent returns but supervisor doesn't process result
- [ ] 0% delegation rate (validate with `.claude/lib/util/validate-agent-invocation-pattern.sh`)

### Diagnostic Commands

```bash
# Check for documentation-only YAML blocks
grep -n '```yaml' .claude/commands/YOUR-COMMAND.md

# Validate agent invocation pattern compliance
.claude/lib/util/validate-agent-invocation-pattern.sh

# Check delegation rate
find .claude/specs/*/reports -name "*.md" | wc -l  # Should be >0
find .claude/specs/*/plans -name "*.md" | wc -l    # Should be >0
```

### Quick Fix Decision Tree

```
Is agent invocation wrapped in code block?
├─ YES → Remove code fence wrappers
│         Add imperative instructions
│         Use actual Task tool invocation
│
└─ NO → Check for behavioral file reference
    ├─ Missing → Add: Read and follow: .claude/agents/AGENT-NAME.md
    │
    └─ Present → Check for imperative language
        ├─ Uses "should", "can", "may" → Change to MUST/WILL/SHALL
        │
        └─ Uses MUST/WILL/SHALL → Check completion signals
            └─ Missing → Add: REPORT_CREATED: or PLAN_CREATED:
```

### Solutions

**Solution 1: Apply Imperative Pattern**

❌ **Before** (documentation-only):
```markdown
Research should be conducted using agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: "Research authentication patterns..."
}
```
```

✅ **After** (imperative execution):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-analyst.

Instructions for Task tool invocation:
- subagent_type: "general-purpose"
- description: "Research authentication patterns"
- prompt: |
    Read and follow: .claude/agents/research-analyst.md
    You are acting as Research Analyst.

    Research authentication patterns for Node.js applications...

    SIGNAL COMPLETION: REPORT_CREATED: /path/to/report.md
```

**Solution 2: Fix File Creation**

❌ **Problem**: Files created as `TODO1.md`, `TODO2.md`

✅ **Fix**: Add verification checkpoints
```markdown
**STEP 1**: CREATE the report file.

**VERIFICATION CHECKPOINT**: Check file exists at correct path:
- EXECUTE: ls -la /expected/path/report.md
- IF file missing → RETRY file creation
- IF file present → PROCEED to next step

**STEP 2**: VERIFY file content is not placeholder...
```

**Solution 3: Add Completion Signals**

✅ **Pattern**: Always require explicit signals
```markdown
The agent MUST signal completion by outputting:

REPORT_CREATED: /full/path/to/report.md

Example output:
---
Analysis complete. Key findings documented.

REPORT_CREATED: .claude/specs/027_auth/reports/001_patterns.md
---
```

### References

- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md) - Complete guide
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Correct invocation pattern
- [Standard 11: Imperative Agent Invocation](../reference/architecture/overview.md#standard-11)

## [B] File Operation Errors

### Symptom Checklist

- [ ] File not found errors
- [ ] Permission denied errors
- [ ] Files created in wrong directory
- [ ] Path resolution failures
- [ ] Symlink issues

### Diagnostic Commands

```bash
# Check file exists
ls -la /expected/path/file.md

# Check directory permissions
ls -ld /expected/directory/

# Check for symlinks
file /expected/path/file.md

# Verify working directory
pwd

# Check absolute vs relative paths
realpath ./relative/path
```

### Quick Fix Decision Tree

```
File operation failed?
├─ Path not found
│  ├─ Using relative path? → Convert to absolute path
│  └─ Using absolute path? → Check directory exists
│      └─ Directory missing → Create parent directories first
│
├─ Permission denied
│  ├─ Check ownership: ls -l path
│  └─ Check permissions: chmod if needed
│
└─ File exists in wrong location
    └─ Check working directory: pwd
        └─ Commands may change directory context
```

### Solutions

**Solution 1: Use Absolute Paths**

❌ **Before**:
```bash
cat reports/001_findings.md
```

✅ **After**:
```bash
cat /home/benjamin/.config/.claude/specs/027_auth/reports/001_findings.md
```

**Solution 2: Create Parent Directories**

```bash
# Create directory structure if missing
mkdir -p .claude/specs/027_auth/reports/

# Then create file
echo "content" > .claude/specs/027_auth/reports/001_findings.md
```

**Solution 3: Verify Before Proceeding**

```bash
# Check directory exists
test -d .claude/specs/027_auth/reports/ || mkdir -p .claude/specs/027_auth/reports/

# Check file created successfully
if [ -f .claude/specs/027_auth/reports/001_findings.md ]; then
  echo "✓ File created successfully"
else
  echo "✗ File creation failed"
  exit 1
fi
```

## [C] Test Failures

### Symptom Checklist

- [ ] Syntax errors in test files
- [ ] Import/dependency errors
- [ ] Assertion failures
- [ ] Test runner not found
- [ ] Configuration errors

### Diagnostic Commands

```bash
# Check test runner availability
which pytest  # Python
which npm     # Node.js (npm test)
which jest    # JavaScript

# Run tests with verbose output
pytest -v
npm test -- --verbose

# Check test file syntax
bash -n test_file.sh  # Bash
python -m py_compile test_file.py  # Python
```

### Quick Fix Decision Tree

```
Tests failing?
├─ Syntax error
│  ├─ Run syntax check: bash -n file.sh
│  └─ Fix syntax, re-run tests
│
├─ Import/dependency error
│  ├─ Check dependencies installed
│  └─ Verify PYTHONPATH / NODE_PATH
│
├─ Assertion failure
│  ├─ Review test expectations
│  ├─ Check if implementation matches plan
│  └─ Debug with print statements
│
└─ Test runner not found
    └─ Check Testing Protocols in CLAUDE.md
```

### Solutions

**Solution 1: Fix Test Syntax**

```bash
# Check syntax before running
bash -n .claude/tests/test_parsing.sh

# Fix any syntax errors reported
# Re-run tests
bash .claude/tests/test_parsing.sh
```

**Solution 2: Install Missing Dependencies**

```bash
# Python
pip install -r requirements.txt

# Node.js
npm install

# Check installation
pip list | grep pytest
npm list | grep jest
```

**Solution 3: Debug Assertion Failures**

```bash
# Add debug output
echo "DEBUG: Variable value = $variable"

# Run with verbose mode
pytest -v -s  # -s shows print statements

# Check test expectations vs actual behavior
```

### References

- [Testing Protocols](../../../CLAUDE.md#testing_protocols) - Project test standards
- [Test Patterns Guide](../guides/patterns/testing-patterns.md) - Testing best practices

## [D] Command Syntax / Configuration Errors

### Symptom Checklist

- [ ] "Command not found" errors
- [ ] Invalid argument errors
- [ ] CLAUDE.md section not found
- [ ] Standards discovery failures
- [ ] Library function errors

### Diagnostic Commands

```bash
# Check command exists
ls -la .claude/commands/YOUR-COMMAND.md

# Validate command syntax
grep -A 5 "^---" .claude/commands/YOUR-COMMAND.md

# Check CLAUDE.md sections
grep "SECTION:" CLAUDE.md

# Test library function
source .claude/lib/LIBRARY.sh && FUNCTION_NAME
```

### Quick Fix Decision Tree

```
Command error?
├─ Command not found
│  ├─ Check command file exists
│  └─ Verify SlashCommand tool invocation
│
├─ Invalid arguments
│  ├─ Check argument-hint in frontmatter
│  └─ Review command documentation
│
├─ Standards discovery failure
│  ├─ Check CLAUDE.md exists
│  ├─ Verify section tags: <!-- SECTION: name -->
│  └─ Check [Used by: ...] metadata
│
└─ Library function error
    ├─ Check library file exists
    ├─ Verify function sourced correctly
    └─ Check function signature
```

### Solutions

**Solution 1: Fix Command Invocation**

❌ **Before**:
```bash
/nonexistent-command arg1 arg2
```

✅ **After**:
```bash
# Check available commands
ls -la .claude/commands/

# Use correct command name
/plan "feature description"
```

**Solution 2: Fix Standards Discovery**

❌ **Problem**: Section not found in CLAUDE.md

✅ **Fix**: Add section tags
```markdown
<!-- SECTION: testing_protocols -->
## Testing Protocols
[Used by: /test, /test-all, /implement]

...

<!-- END_SECTION: testing_protocols -->
```

**Solution 3: Fix Library Sourcing**

```bash
# Source library before use
source .claude/lib/workflow/metadata-extraction.sh

# Then call function
extract_report_metadata "/path/to/report.md"
```

### References

- [Command Reference](../reference/standards/command-reference.md) - All available commands
- [CLAUDE.md Section Schema](../reference/standards/claude-md-schema.md) - Section format
- [Library API Reference](../reference/library-api/overview.md) - Library functions

## General Troubleshooting Steps

### 1. Check Logs

```bash
# Adaptive planning logs
tail -100 .claude/data/logs/adaptive-planning.log

# Command execution logs (if available)
tail -100 .claude/data/logs/command-execution.log
```

### 2. Validate Configuration

```bash
# Check CLAUDE.md exists
test -f CLAUDE.md && echo "✓ CLAUDE.md found" || echo "✗ CLAUDE.md missing"

# Check .claude/ structure
ls -la .claude/{commands,agents,lib,tests}/

# Validate agent invocation patterns
.claude/lib/util/validate-agent-invocation-pattern.sh
```

### 3. Run Tests

```bash
# Run all tests
.claude/tests/run_all_tests.sh

# Run specific test
bash .claude/tests/test_parsing_utilities.sh
```

### 4. Check Context Usage

Context window exhaustion can cause unexpected failures:

```bash
# Commands should stay <30% context usage
# If context is high (>60%), consider:
# - Metadata-only passing (not full content)
# - Context pruning after phases
# - Aggressive cleanup of completed work
```

### 5. Fresh Session

Sometimes starting a fresh session resolves issues:

```bash
# Note current state
echo "Context: 150K/200K tokens (75%)"

# Start new session
# Previous context cleared
# Resume from checkpoint if available
```

## Error Prevention

### Best Practices

1. **Use Verification Checkpoints**
   - Always verify file creation
   - Check file content not placeholder
   - Validate before proceeding

2. **Apply Imperative Language**
   - Use MUST/WILL/SHALL for required actions
   - Never use should/may/can
   - Be explicit about execution

3. **Signal Completion**
   - Always output REPORT_CREATED:, PLAN_CREATED:, etc.
   - Include full file paths
   - Make completion unambiguous

4. **Use Absolute Paths**
   - Avoid relative paths in critical operations
   - Always verify working directory
   - Use realpath to resolve paths

5. **Test Before Committing**
   - Run tests after each phase
   - Verify all assertions pass
   - Check coverage requirements

## Related Documentation

- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md) - Complete guide
- [Orchestration Troubleshooting](../guides/orchestration/orchestration-troubleshooting.md) - Workflow debugging
- [Command Architecture Standards](../reference/architecture/overview.md) - Architecture requirements
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Correct invocation
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - Checkpoint pattern

## Navigation

**Docs Index**: [← Back to Docs](../README.md)
**Quick Reference**: [← Back to Quick Reference](./README.md)
