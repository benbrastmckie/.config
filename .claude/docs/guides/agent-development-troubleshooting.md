# Agent Development: Troubleshooting

**Related Documents**:
- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Patterns](agent-development-patterns.md) - Invocation patterns
- [Testing](agent-development-testing.md) - Testing and validation

---

## Common Issues

### Issue 1: Agent Not Invoked (0% Delegation Rate)

**Symptom**: Task block present but agent never executes.

**Cause**: Documentation-only YAML block (wrapped in code fence).

**Solution**:
```markdown
# WRONG
```yaml
Task { ... }
```

# CORRECT
**EXECUTE NOW**: USE the Task tool to invoke agent

Task { ... }
```

**Verification**:
```bash
# Find potential issues
grep -B3 'Task {' .claude/commands/*.md | grep -v 'EXECUTE NOW'
```

---

### Issue 2: File Not Created

**Symptom**: Agent completes but file doesn't exist.

**Causes**:
1. Agent returned text summary instead of creating file
2. Directory doesn't exist
3. Path calculation error

**Solution**:
```markdown
# Strengthen agent prompt
**PRIMARY OBLIGATION**: You MUST create file at exact path.
File creation is your FIRST task, not last.

# Ensure directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Use absolute paths
Output Path: /home/user/project/.claude/specs/report.md  # Absolute
NOT: specs/report.md  # Relative - will fail
```

---

### Issue 3: Wrong Output Format

**Symptom**: File exists but format doesn't match specification.

**Cause**: Agent file doesn't specify format strongly enough.

**Solution**:
```markdown
## Output Format - THIS EXACT TEMPLATE

YOUR REPORT MUST contain these sections IN THIS ORDER:

```markdown
# [Title]

## Overview
[REQUIRED - 2-3 sentences]

## Findings
[REQUIRED - Minimum 5 bullet points]

## Recommendations
[REQUIRED - Minimum 3 items]
```

**ENFORCEMENT**: Sections marked REQUIRED are NON-NEGOTIABLE.
```

---

### Issue 4: Missing Return Signal

**Symptom**: Cannot parse agent output.

**Cause**: Agent doesn't return expected signal format.

**Solution**:
```markdown
# In agent file
## Expected Output
Return EXACTLY:
```
CREATED: /path/to/file.md
TITLE: Report Title
STATUS: complete
```

Do NOT return prose description. Return signals only.

# In command verification
if ! echo "$OUTPUT" | grep -q "^CREATED:"; then
  echo "ERROR: Missing CREATED signal"
  exit 1
fi
```

---

### Issue 5: Context Overflow

**Symptom**: Agent fails with context limit error.

**Cause**: Too much content passed to agent.

**Solution**:
```markdown
# Pass metadata, not full content
Topic: Authentication  # Good
Topic: [5000 word description]  # Bad

# Use file references
Read this file: ${PATH}  # Good
Here is the content: [content]  # Bad

# Extract before passing
SUMMARY=$(head -c 500 "$REPORT")  # Limited
```

---

### Issue 6: Behavioral Inconsistency

**Symptom**: Same agent behaves differently across invocations.

**Cause**: Behavior duplicated in commands, versions diverged.

**Solution**:
```yaml
# Always reference single source
Read and follow: .claude/agents/research-specialist.md

# Never duplicate behavior
# WRONG
Task {
  prompt: |
    You are a research specialist who...
    [custom behavior that differs from agent file]
}
```

---

### Issue 7: Tool Restriction Violation

**Symptom**: Agent tries to use disallowed tool.

**Cause**: Tool not in `allowed-tools` frontmatter.

**Solution**:
```yaml
---
allowed-tools: Grep, Read, Write, WebSearch, WebFetch
# Add missing tools here
---
```

---

### Issue 8: Slow Execution

**Symptom**: Agent takes much longer than expected.

**Causes**:
1. Wrong model for task complexity
2. Excessive thinking mode
3. Large context

**Solution**:
```yaml
# Use appropriate model
model: haiku-4.5  # For simple, deterministic tasks
model: sonnet-4.5  # For standard complexity
model: opus-4  # For critical complexity

# Match thinking mode to task
Thinking Mode: standard  # Simple tasks
Thinking Mode: think  # Moderate complexity
Thinking Mode: think hard  # High complexity
```

---

## Diagnostic Commands

### Check Agent Invocation Pattern

```bash
# Find all Task blocks
grep -n 'Task {' .claude/commands/*.md

# Find potentially broken (no imperative)
for cmd in .claude/commands/*.md; do
  if grep -q 'Task {' "$cmd"; then
    if ! grep -B5 'Task {' "$cmd" | grep -q 'EXECUTE NOW'; then
      echo "WARN: $cmd may have doc-only Task blocks"
    fi
  fi
done
```

### Check Agent Files

```bash
# List all agents
ls -la .claude/agents/*.md

# Check for required sections
for agent in .claude/agents/*.md; do
  echo "=== $agent ==="
  grep "^## " "$agent" | head -5
  echo ""
done
```

### Check Output Files

```bash
# After workflow, verify outputs
find .claude/specs -name "*.md" -mmin -10 -ls

# Check file contents
for f in .claude/specs/*/reports/*.md; do
  echo "=== $f ==="
  head -20 "$f"
  echo ""
done
```

### Check Signals

```bash
# Parse signals from agent output
parse_signals() {
  local output="$1"
  echo "Signals found:"
  echo "$output" | grep -E '^[A-Z_]+:'
}
```

---

## Quick Fixes

### Fix 1: Add Imperative Instruction

Before every Task block:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name]
```

### Fix 2: Ensure Directory Exists

```bash
mkdir -p "$(dirname "$OUTPUT_PATH")"
```

### Fix 3: Use Absolute Paths

```bash
# Convert relative to absolute
OUTPUT_PATH="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC}/reports/001.md"
```

### Fix 4: Add Verification

```bash
if [ ! -f "$OUTPUT_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  exit 1
fi
```

### Fix 5: Strengthen Output Requirements

```markdown
**PRIMARY OBLIGATION**: File creation is MANDATORY.
Return: CREATED: /path/to/file.md
```

---

## Debugging Workflow

### Step 1: Enable Verbose Mode

Add to agent prompt:
```markdown
Emit progress:
- PROGRESS: Starting
- PROGRESS: [each major step]
- PROGRESS: Complete
```

### Step 2: Capture Full Output

```bash
OUTPUT=$(invoke_agent 2>&1)
echo "$OUTPUT" > debug.log
```

### Step 3: Check Each Component

```bash
# Check signal
grep "^CREATED:" debug.log

# Check file
ls -la "$EXPECTED_PATH"

# Check content
head -50 "$EXPECTED_PATH"
```

### Step 4: Isolate Issue

1. Does agent receive correct input?
2. Does agent execute expected tools?
3. Does agent create file?
4. Does file have correct format?
5. Does agent return correct signal?

---

## Error Messages

### "command not found: verify_state_variable"

**Cause**: Library not sourced before use.

**Fix**: Source library first:
```bash
source "${LIB_DIR}/verification-helpers.sh"
verify_state_variable "NAME"
```

### "CRITICAL: File not created"

**Cause**: Agent didn't create file.

**Fix**: Strengthen agent prompt, verify directory exists.

### "Missing CREATED signal"

**Cause**: Agent returned prose instead of signals.

**Fix**: Specify exact return format in agent file.

---

## Related Documentation

- [Fundamentals](agent-development-fundamentals.md)
- [Patterns](agent-development-patterns.md)
- [Testing](agent-development-testing.md)
- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md)
