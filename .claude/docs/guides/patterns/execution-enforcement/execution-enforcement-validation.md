# Execution Enforcement: Validation and Troubleshooting

**Related Documents**:
- [Overview](execution-enforcement-overview.md) - Introduction and standards
- [Patterns](execution-enforcement-patterns.md) - Language patterns
- [Migration](execution-enforcement-migration.md) - Migration process

---

## Validation Checklist

### Imperative Language (10 pts)

- [ ] All critical steps use "YOU MUST"
- [ ] "EXECUTE NOW" for critical operations
- [ ] "ABSOLUTE REQUIREMENT" for file creation
- [ ] Zero "should/may/can" in critical sections

### Sequential Dependencies (10 pts)

- [ ] Steps marked "REQUIRED BEFORE STEP N+1"
- [ ] Clear dependency chain
- [ ] No ambiguous ordering

### File Creation Priority (10 pts)

- [ ] Marked as "PRIMARY OBLIGATION"
- [ ] First in priority order
- [ ] WHY THIS MATTERS included

### Verification Checkpoints (10 pts)

- [ ] "MANDATORY VERIFICATION" blocks present
- [ ] Bash verification commands included
- [ ] Exit on failure

### Template Enforcement (10 pts)

- [ ] "THIS EXACT TEMPLATE" markers
- [ ] All sections marked REQUIRED
- [ ] Minimum counts specified

### Passive Voice Elimination (10 pts)

- [ ] Zero passive voice in critical sections
- [ ] All use MUST/WILL/SHALL
- [ ] Active imperatives only

### Completion Criteria (10 pts)

- [ ] Explicit checklist present
- [ ] "ALL REQUIRED" marker
- [ ] File path return format specified

### Why This Matters (10 pts)

- [ ] Rationale for enforcement
- [ ] Consequences of non-compliance
- [ ] Business justification

### Checkpoint Reporting (10 pts)

- [ ] "CHECKPOINT REQUIREMENT" blocks
- [ ] Status reporting template
- [ ] Progress markers

### Fallback Integration (10 pts)

- [ ] Compatible with command fallbacks
- [ ] Clear signal format
- [ ] Recovery path defined

## Scoring

Calculate score by adding points for each satisfied criterion:

```
Score = (criteria_passed / 10) * 100

Target: 95+ (9.5+ categories at full strength)
```

## Audit Script

```bash
#!/bin/bash
# audit_enforcement.sh

audit_file() {
  local file="$1"
  local score=0

  # Check imperative language
  if grep -q "YOU MUST\|EXECUTE NOW" "$file"; then
    ((score += 10))
  fi

  # Check sequential dependencies
  if grep -q "REQUIRED BEFORE STEP" "$file"; then
    ((score += 10))
  fi

  # Check file creation priority
  if grep -q "PRIMARY OBLIGATION" "$file"; then
    ((score += 10))
  fi

  # Check verification
  if grep -q "MANDATORY VERIFICATION" "$file"; then
    ((score += 10))
  fi

  # Check template enforcement
  if grep -q "THIS EXACT TEMPLATE" "$file"; then
    ((score += 10))
  fi

  # Check passive voice elimination
  weak_count=$(grep -c "should\|may\|can" "$file" || true)
  if [ "$weak_count" -lt 3 ]; then
    ((score += 10))
  fi

  # Check completion criteria
  if grep -q "ALL REQUIRED" "$file"; then
    ((score += 10))
  fi

  # Check rationale
  if grep -q "WHY THIS MATTERS" "$file"; then
    ((score += 10))
  fi

  # Check checkpoints
  if grep -q "CHECKPOINT" "$file"; then
    ((score += 10))
  fi

  # Check signal format
  if grep -q "CREATED:\|Return:" "$file"; then
    ((score += 10))
  fi

  echo "Score for $file: $score/100"
}

# Audit all agent files
for file in .claude/agents/*.md; do
  audit_file "$file"
done
```

## Troubleshooting

### Issue 1: Low File Creation Rate

**Symptom**: Files not created at expected paths.

**Cause**: Weak language not enforcing creation.

**Fix**:
```markdown
# Add PRIMARY OBLIGATION
**PRIMARY OBLIGATION - File Creation**

**ABSOLUTE REQUIREMENT**: Creating the file is your PRIMARY task.

**PRIORITY ORDER**:
1. FIRST: Create output file
2. SECOND: Conduct research
3. THIRD: Verify file exists
```

### Issue 2: Inconsistent Output Format

**Symptom**: Reports missing sections or wrong structure.

**Cause**: No template enforcement.

**Fix**:
```markdown
# Add template enforcement
**OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)**

## Overview
[REQUIRED - 2-3 sentences]

## Findings
[REQUIRED - Minimum 5 bullet points]

**ENFORCEMENT**: REQUIRED sections are NON-NEGOTIABLE.
```

### Issue 3: Steps Skipped

**Symptom**: Agent skips steps in sequence.

**Cause**: No step dependencies.

**Fix**:
```markdown
# Add step dependencies
**STEP 1 (REQUIRED BEFORE STEP 2)** - First Task
[instructions]

**STEP 2 (REQUIRED BEFORE STEP 3)** - Second Task
[instructions]
```

### Issue 4: No Verification

**Symptom**: Workflow proceeds despite failures.

**Cause**: Missing verification checkpoints.

**Fix**:
```markdown
# Add verification
**MANDATORY VERIFICATION - File Existence**

```bash
if [ ! -f "$PATH" ]; then
  echo "CRITICAL: File not created"
  exit 1
fi
```
```

### Issue 5: Wrong Signal Format

**Symptom**: Cannot parse agent output.

**Cause**: Signal format not specified.

**Fix**:
```markdown
# Add signal specification
**Return Format**:
```
CREATED: /path/to/file.md
TITLE: Report Title
STATUS: complete
```

Do NOT return prose. Return signals only.
```

## Quick Reference

### Language Transformation

| Before | After |
|--------|-------|
| should | MUST |
| may | WILL |
| can | SHALL |
| consider | YOU MUST |
| is created | YOU MUST create |

### Pattern Application

| Pattern | Marker |
|---------|--------|
| Execution | **EXECUTE NOW** |
| Verification | **MANDATORY VERIFICATION** |
| Template | **THIS EXACT TEMPLATE** |
| Completion | **ALL REQUIRED** |
| Rationale | **WHY THIS MATTERS** |

### File Locations

| Content Type | Location |
|--------------|----------|
| Agent behavior | `.claude/agents/*.md` |
| Command structure | `.claude/commands/*.md` |
| Standards reference | `.claude/docs/reference/` |

---

## Related Documentation

- [Overview](execution-enforcement-overview.md)
- [Patterns](execution-enforcement-patterns.md)
- [Migration](execution-enforcement-migration.md)
- [Architecture Standards](../reference/architecture/validation.md)
