# Migration Validation Guide

## Purpose

This guide demonstrates how to verify execution enforcement migrations (Standard 0 for commands, Standard 0.5 for agents) using the audit script and validation techniques. Following these steps ensures reliable 100% file creation rates and proper enforcement implementation.

## Prerequisites

- Understanding of execution enforcement patterns (see [Execution Enforcement Migration Guide](./execution-enforcement-migration-guide.md))
- Familiarity with Standard 0 (commands) and Standard 0.5 (agents) requirements
- Access to audit script (`.claude/lib/audit-execution-enforcement.sh`)

## Steps

### Step 1: Run Audit Script

The audit script analyzes command and agent files for enforcement pattern compliance.

**Basic Usage**:
```bash
# Audit a command file
.claude/lib/audit-execution-enforcement.sh .claude/commands/plan.md

# Audit an agent file
.claude/lib/audit-execution-enforcement.sh .claude/agents/research-specialist.md

# Audit multiple files
for file in .claude/commands/*.md; do
  echo "Auditing: $file"
  .claude/lib/audit-execution-enforcement.sh "$file"
  echo ""
done
```

**Output Format**:
```
Execution Enforcement Audit Report
File: .claude/commands/plan.md
Type: command

Enforcement Score: 87/100

Pattern Detection:
✓ Path Pre-Calculation (Pattern 1): DETECTED
✓ Verification Checkpoints (Pattern 2): DETECTED
✓ Checkpoint Reporting (Pattern 4): DETECTED
✗ Agent Invocation Templates (Pattern 5): NOT DETECTED
✓ Behavioral Injection (Pattern 6): DETECTED

Recommendations:
- Add agent invocation templates with "THIS EXACT TEMPLATE" markers
- Increase verification checkpoint frequency (found 2, recommend 5)

Migration Priority: MEDIUM (score 61-84)
```

### Step 2: Interpret Audit Scores

Understand what audit scores indicate about enforcement level.

**Score Ranges**:

| Score | Level | Interpretation | Action Required |
|-------|-------|----------------|-----------------|
| 0-30 | Minimal | Descriptive language, no enforcement patterns | High priority migration |
| 31-60 | Basic | Some imperative language, incomplete enforcement | Medium priority migration |
| 61-84 | Good | Most patterns present, some gaps | Low priority enhancement |
| 85-94 | Strong | All core patterns present, minor improvements | Optional refinement |
| 95-100 | Excellent | Complete enforcement, best practices | No action needed |

**Pattern-Specific Scoring**:
- **Pattern 1 (Path Pre-Calculation)**: +20 points
  - Detects: "EXECUTE NOW", "Calculate all paths", pre-planning markers
- **Pattern 2 (Verification Checkpoints)**: +25 points
  - Detects: "MANDATORY VERIFICATION", checkpoint count (minimum 3 required)
- **Pattern 4 (Checkpoint Reporting)**: +15 points
  - Detects: "CHECKPOINT REQUIREMENT", status reporting blocks
- **Pattern 5 (Agent Invocation Templates)**: +20 points
  - Detects: "THIS EXACT TEMPLATE", agent prompt templates
- **Pattern 6 (Behavioral Injection)**: +20 points
  - Detects: "Read from file", context injection instructions

**Interpreting Recommendations**:
```bash
# Example audit output
Recommendations:
- Add verification checkpoints after file creation (Pattern 2)
- Increase checkpoint frequency (found 2, recommend 5)
- Add fallback mechanism for agent failures (Pattern 2)
- Use behavioral injection instead of SlashCommand tool (Pattern 6)

# Translation:
# 1. Missing Pattern 2: Add "MANDATORY VERIFICATION: File exists" blocks
# 2. Too few checkpoints: Add more verification points throughout workflow
# 3. Missing fallback: Add "If agent fails, command creates file directly"
# 4. Using wrong pattern: Replace SlashCommand calls with file-based agent invocation
```

### Step 3: Validate File Creation

Test that enforcement patterns achieve 100% file creation reliability.

**Test Protocol**:
```bash
# Test file creation reliability (10 trials)
for i in {1..10}; do
  echo "Trial $i/10"

  # Clean environment
  rm -rf test_artifacts/

  # Invoke command
  claude-code /command-name "test input"

  # Check if expected files created
  if [ -f "expected_output.md" ]; then
    echo "✓ Trial $i: File created"
  else
    echo "✗ Trial $i: File NOT created"
  fi
done

# Calculate success rate
# Target: 10/10 (100%)
```

**Validation Checklist**:
- [ ] Command creates expected files in 10/10 trials
- [ ] Verification checkpoints execute in correct sequence
- [ ] Fallback mechanisms trigger when agent fails
- [ ] All paths calculated before file operations
- [ ] Checkpoint reports appear in command output

**Common Issues**:
```bash
# Issue: File created only 6/10 trials (60%)
# Cause: Missing verification checkpoint after agent invocation
# Fix: Add MANDATORY VERIFICATION block

# Issue: File created in wrong location
# Cause: Missing path pre-calculation (Pattern 1)
# Fix: Add "EXECUTE NOW: Calculate paths" section

# Issue: Command hangs when agent fails
# Cause: Missing fallback mechanism
# Fix: Add "If agent fails: Command creates file directly" instruction
```

### Step 4: Test Checkpoint Operations

Verify that checkpoint-based workflows support save/restore operations.

**Checkpoint Save Test**:
```bash
# Create checkpoint during workflow execution
STATE_JSON='{"phase":2,"task":3,"status":"in_progress"}'
CHECKPOINT_FILE=$(save_checkpoint "workflow_name" "project_path" "$STATE_JSON")

# Verify checkpoint created
if [ -f "$CHECKPOINT_FILE" ]; then
  echo "✓ Checkpoint created: $CHECKPOINT_FILE"
else
  echo "✗ Checkpoint creation failed"
  exit 1
fi

# Verify checkpoint contains required fields
if grep -q '"phase":2' "$CHECKPOINT_FILE" && \
   grep -q '"status":"in_progress"' "$CHECKPOINT_FILE"; then
  echo "✓ Checkpoint contains correct state"
else
  echo "✗ Checkpoint missing state data"
  exit 1
fi
```

**Checkpoint Restore Test**:
```bash
# Load checkpoint
RESTORED_STATE=$(load_checkpoint "workflow_name" "project_path")

# Verify state restored correctly
RESTORED_PHASE=$(echo "$RESTORED_STATE" | jq -r '.phase')
if [ "$RESTORED_PHASE" = "2" ]; then
  echo "✓ Checkpoint restored correctly"
else
  echo "✗ Checkpoint restore failed (expected phase 2, got $RESTORED_PHASE)"
  exit 1
fi

# Resume workflow from checkpoint
resume_from_checkpoint "$CHECKPOINT_FILE"
```

**Checkpoint Validation**:
- [ ] Checkpoints created at each major step
- [ ] Checkpoint contains complete workflow state
- [ ] Checkpoint can be loaded and state restored
- [ ] Workflow resumes from correct point
- [ ] Failed operations can be retried from checkpoint

## Examples

### Example 1: Validating Command Migration

```bash
# Step 1: Run audit on original command
.claude/lib/audit-execution-enforcement.sh .claude/commands/plan.md

# Output:
# Score: 45/100
# Missing: Pattern 1, Pattern 2
# Priority: HIGH

# Step 2: Apply migration (add Pattern 1 and Pattern 2)
# [Edit .claude/commands/plan.md to add enforcement patterns]

# Step 3: Re-audit after migration
.claude/lib/audit-execution-enforcement.sh .claude/commands/plan.md

# Output:
# Score: 92/100
# All core patterns present
# Priority: NONE

# Step 4: Validate file creation
for i in {1..10}; do
  claude-code /plan "test feature"
  [ -f "specs/NNN_test_feature/plans/NNN_plan.md" ] && echo "✓ Trial $i"
done

# Result: 10/10 trials succeeded
```

### Example 2: Validating Agent Migration

```bash
# Step 1: Audit agent before migration
.claude/lib/audit-execution-enforcement.sh .claude/agents/research-specialist.md

# Output:
# Score: 38/100
# Issues: Passive voice, no verification, unclear obligations
# Priority: HIGH

# Step 2: Apply Standard 0.5 transformation
# - Transform "I am" → "YOU MUST"
# - Add sequential dependencies
# - Add verification checkpoints
# - Add completion checklist

# Step 3: Re-audit after migration
.claude/lib/audit-execution-enforcement.sh .claude/agents/research-specialist.md

# Output:
# Score: 96/100
# All patterns present, excellent enforcement
# Priority: NONE

# Step 4: Test agent reliability
for i in {1..10}; do
  # Invoke agent via command
  claude-code /orchestrate "research: test topic"
  [ -f "specs/NNN_topic/reports/NNN_research.md" ] && echo "✓ Trial $i"
done

# Result: 10/10 trials succeeded (up from 6/10 before migration)
```

### Example 3: Debugging Low Audit Score

```bash
# Command has low score (42/100)
# Audit output shows:
# ✗ Pattern 1: NOT DETECTED
# ✗ Pattern 2: NOT DETECTED
# ✓ Pattern 4: DETECTED (1 checkpoint)
# ✗ Pattern 5: NOT DETECTED

# Diagnostic: Check for each missing pattern

# Check Pattern 1 (Path Pre-Calculation)
grep -i "EXECUTE NOW" .claude/commands/command.md
# No matches → Pattern 1 missing

# Check Pattern 2 (Verification Checkpoints)
grep -i "MANDATORY VERIFICATION" .claude/commands/command.md
# No matches → Pattern 2 missing

# Check Pattern 5 (Agent Invocation Templates)
grep -i "THIS EXACT TEMPLATE" .claude/commands/command.md
# No matches → Pattern 5 missing

# Fix: Add all three missing patterns
# Expected score after fix: 42 + 20 + 25 + 20 = 107 (capped at 100)
```

## Troubleshooting

### Issue: Audit score is low (< 60) but file creation works

**Cause**: Command relies on Claude's default behavior, not explicit enforcement

**Solution**: Add enforcement patterns even if currently working
```bash
# Current state: Works by luck
# Risk: May fail when Claude behavior changes or under different conditions

# Add enforcement for reliability:
# 1. Add Pattern 1 (path pre-calculation)
# 2. Add Pattern 2 (verification checkpoints)
# 3. Add fallback mechanisms

# Result: Works reliably regardless of Claude behavior variations
```

### Issue: Audit score is high (> 85) but files not created

**Cause**: Enforcement patterns present but incorrectly implemented

**Solution**: Validate pattern implementation
```bash
# Check Pattern 1: Paths calculated BEFORE use?
grep -A5 "EXECUTE NOW.*path" command.md
# Verify paths calculated in Phase 0, used in Phase 1+

# Check Pattern 2: Verification AFTER creation?
grep -B2 -A2 "MANDATORY VERIFICATION" command.md
# Verify verification comes AFTER file creation, not before

# Check fallback: Activated when agent fails?
grep -A5 "fallback\|If.*fail" command.md
# Verify fallback creates file, not just logs error
```

### Issue: Checkpoints created but restoration fails

**Cause**: Checkpoint missing required state fields

**Solution**: Verify checkpoint JSON structure
```bash
# Load checkpoint and inspect
CHECKPOINT=$(cat .claude/data/checkpoints/latest.json)
echo "$CHECKPOINT" | jq '.'

# Required fields:
# - workflow_type
# - project_dir
# - timestamp
# - state (with phase, task, status)

# If missing fields, update save_checkpoint call:
save_checkpoint "workflow" "project" '{
  "phase": 2,
  "task": 3,
  "status": "in_progress",
  "artifacts": ["path1.md", "path2.md"],
  "next_steps": ["task4", "task5"]
}'
```

### Issue: Verification checkpoints not executing

**Cause**: Verification instructions unclear or conditional

**Solution**: Make verification unconditional and explicit
```bash
# WRONG (conditional):
"If file created, verify it exists"

# RIGHT (unconditional):
"MANDATORY VERIFICATION: File exists at {path}
EXECUTE NOW: Check file exists using Read tool
If file does not exist: Use fallback mechanism"

# WRONG (vague):
"Check that everything worked"

# RIGHT (specific):
"MANDATORY VERIFICATION: Check these 3 conditions:
1. File exists at specs/NNN_topic/reports/NNN_research.md
2. File contains title heading (line 1)
3. File size > 100 bytes"
```

## Related Documentation

- [Execution Enforcement Migration Guide](./execution-enforcement-migration-guide.md) - Complete migration process
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Pattern documentation
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State management
- [Testing Patterns Guide](./testing-patterns.md) - Test organization and assertions
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 0 and 0.5 requirements
