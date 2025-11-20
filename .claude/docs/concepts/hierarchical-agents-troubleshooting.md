# Hierarchical Agent Architecture: Troubleshooting

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Patterns](hierarchical-agents-patterns.md) - Design patterns
- [Examples](hierarchical-agents-examples.md) - Reference implementations

---

## Common Issues

### Issue 1: 0% Agent Delegation Rate

**Symptom**: Agents are never invoked despite Task blocks in command.

**Cause**: Documentation-only YAML blocks (wrapped in code fences).

**Solution**:
```markdown
# WRONG
Example:
```yaml
Task { ... }
```

# CORRECT
**EXECUTE NOW**: Invoke agent

Task { ... }
```

**Verification**:
```bash
# Check for YAML blocks without imperative instruction
grep -B5 '```yaml' .claude/commands/*.md | grep -v 'EXECUTE NOW'
```

---

### Issue 2: Missing Files After Workflow

**Symptom**: Expected files don't exist at specified paths.

**Causes**:
1. Agent returned text instead of creating file
2. Path calculation error
3. Directory doesn't exist

**Solution**:

Add verification checkpoints:
```bash
# Verify file creation
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: File not created at $EXPECTED_PATH"
  exit 1
fi
```

Add path pre-calculation:
```bash
# Ensure directory exists
mkdir -p "$(dirname "$EXPECTED_PATH")"
```

Add agent enforcement:
```markdown
**PRIMARY OBLIGATION**: You MUST create file at exact path.
Return: CREATED: ${PATH}
```

---

### Issue 3: Context Explosion

**Symptom**: Workflow fails with context limit errors.

**Cause**: Passing full content between hierarchy levels.

**Solution**: Use metadata extraction:
```bash
# Extract metadata only
TITLE=$(grep -m1 '^# ' "$REPORT" | sed 's/^# //')
SUMMARY=$(sed -n '/^## Overview/,/^##/p' "$REPORT" | head -c 200)

# Pass metadata, not full content
echo "TITLE: $TITLE"
echo "SUMMARY: $SUMMARY"
echo "PATH: $REPORT"
```

---

### Issue 4: Sequential Instead of Parallel Execution

**Symptom**: Workflow takes 4x expected time.

**Cause**: Agents invoked sequentially.

**Solution**:
```markdown
# WRONG: Sequential
**EXECUTE**: Task 1
[wait]
**EXECUTE**: Task 2

# CORRECT: Parallel (single message)
**EXECUTE NOW**: All tasks

Task { ... task 1 ... }
Task { ... task 2 ... }
Task { ... task 3 ... }
```

---

### Issue 5: Library Sourcing Failures

**Symptom**: `command not found` errors.

**Cause**: Functions called before library sourced.

**Solution**:
```bash
# Source FIRST
source "${LIB_DIR}/verification-helpers.sh"
source "${LIB_DIR}/error-handling.sh"

# THEN call functions
verify_state_variable "VAR_NAME" || exit 1
```

**Verification**:
```bash
# Check sourcing order
grep -n 'source.*lib/' command.md | head -20
grep -n 'verify_\|handle_' command.md | head -5
# Sourcing must come before function calls
```

---

### Issue 6: Behavioral Duplication

**Symptom**: Maintenance burden, inconsistent agent behavior.

**Cause**: Agent behavior duplicated in commands.

**Detection**:
```bash
# Count STEP sequences in commands (should be <5)
grep -c 'STEP [0-9]:' .claude/commands/*.md

# Count PRIMARY OBLIGATION (should be 0)
grep -c 'PRIMARY OBLIGATION' .claude/commands/*.md
```

**Solution**:
1. Move behavior to `.claude/agents/*.md`
2. Use behavioral injection pattern in commands

---

### Issue 7: Missing Verification

**Symptom**: Silent failures, incomplete workflows.

**Cause**: No verification after agent operations.

**Solution**: Add mandatory verification:
```markdown
## Verification Checkpoint

**MANDATORY VERIFICATION**: Check all files exist

```bash
for path in "${EXPECTED_PATHS[@]}"; do
  if [ ! -f "$path" ]; then
    echo "CRITICAL: Missing $path"
    exit 1
  fi
  echo "Verified: $path"
done
```
```

---

### Issue 8: Unclear Agent Contracts

**Symptom**: Agents return unexpected formats.

**Cause**: No defined input/output contract.

**Solution**: Define explicit contracts:
```markdown
## Input Contract
- topic: string (required)
- output_path: string (required, absolute)
- thinking_mode: enum [standard, think, think_hard]

## Output Contract
- CREATED: string (file path)
- TITLE: string (max 50 chars)
- SUMMARY: string (max 200 chars)
- STATUS: enum [complete, partial, failed]
```

---

## Diagnostic Commands

### Check Agent Invocation Pattern

```bash
# Find potentially broken invocations
find .claude/commands -name '*.md' -exec \
  grep -l 'Task {' {} \; | while read f; do
    if ! grep -B3 'Task {' "$f" | grep -q 'EXECUTE NOW\|INVOKE'; then
      echo "WARN: $f may have documentation-only Task blocks"
    fi
done
```

### Check Context Usage

```bash
# Estimate context per command
for cmd in .claude/commands/*.md; do
  lines=$(wc -l < "$cmd")
  echo "$cmd: $lines lines (~$(($lines * 4)) tokens)"
done
```

### Check Behavioral Duplication

```bash
# Find behavioral content in commands
echo "STEP sequences in commands:"
grep -c 'STEP [0-9]:' .claude/commands/*.md | grep -v ':0$'

echo ""
echo "PRIMARY OBLIGATION in commands (should be 0):"
grep -l 'PRIMARY OBLIGATION' .claude/commands/*.md
```

### Check File Creation Rate

```bash
# After running workflow, verify files created
expected=("report1.md" "report2.md" "plan.md")
created=0

for file in "${expected[@]}"; do
  if [ -f "$TOPIC_DIR/$file" ]; then
    ((created++))
  else
    echo "MISSING: $file"
  fi
done

echo "Created: $created/${#expected[@]}"
```

---

## Performance Metrics

### Target Metrics

| Metric | Target | Critical |
|--------|--------|----------|
| Agent delegation rate | >90% | <50% |
| File creation rate | 100% | <80% |
| Context efficiency | >90% reduction | <50% |
| Parallel speedup | 40-60% | <20% |

### Measuring Performance

```bash
# Time sequential vs parallel
time run_sequential_workflow
time run_parallel_workflow

# Context usage
wc -c "$STATE_FILE"  # State file size
wc -l "$COMMAND"     # Command complexity
```

---

## Quick Fixes

### Fix 1: Add Missing Imperative

```bash
# Before YAML Task blocks, add:
**EXECUTE NOW**: USE the Task tool to invoke [agent-name]
```

### Fix 2: Add Missing Verification

```bash
# After agent invocation, add:
if [ ! -f "$EXPECTED" ]; then
  echo "CRITICAL: Agent didn't create $EXPECTED"
  exit 1
fi
```

### Fix 3: Fix Sourcing Order

```bash
# Move library sourcing to top of bash block
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Then use functions
verify_state_variable "NAME" || exit 1
```

### Fix 4: Enable Parallel Execution

```bash
# Send all Tasks in single message, not sequential
# Remove [wait] between Task blocks
```

---

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Patterns](hierarchical-agents-patterns.md)
- [Architecture Standards](../reference/architecture/overview.md)
