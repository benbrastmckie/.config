# Execution Enforcement Audit Guide

## Overview

This guide explains how to audit commands and agents for execution enforcement patterns, identify gaps, and prioritize fixes.

## Audit Process

### 1. Run the Audit Script

```bash
cd .claude/lib
./audit-execution-enforcement.sh ../commands/orchestrate.md
```

For JSON output:
```bash
./audit-execution-enforcement.sh ../commands/orchestrate.md --json
```

### 2. Review the Score

The script evaluates 10 enforcement patterns and provides a score out of 100:

| Grade | Score | Status |
|-------|-------|--------|
| A | 90-100 | Excellent enforcement |
| B | 80-89 | Good enforcement, minor gaps |
| C | 70-79 | Adequate enforcement, some gaps |
| D | 60-69 | Weak enforcement, major gaps |
| F | <60 | Insufficient enforcement |

### 3. Analyze Findings

Review the findings list for specific gaps:
- Missing imperative language
- No verification checkpoints
- Passive voice usage
- Missing fallback mechanisms

### 4. Prioritize Fixes

Use this priority matrix:

**Priority 1 (Critical)**: Commands that:
- Invoke multiple agents (≥3)
- Handle file creation
- Score <70
- Example: /orchestrate, /implement, /plan

**Priority 2 (High)**: Commands that:
- Invoke 1-2 agents
- Handle critical operations
- Score 70-79
- Example: /expand, /debug

**Priority 3 (Medium)**: Commands that:
- Are standalone (no agents)
- Have descriptive content
- Score 80-89

## Audit Patterns Explained

### Pattern 1: Imperative Language (20 points)

**What to Look For**:
- "YOU MUST" for mandatory actions
- "EXECUTE NOW" for immediate execution

**Why It Matters**:
- Transforms descriptive guidance into executable commands
- Prevents Claude from interpreting instructions as optional

**Example**:
```markdown
❌ BEFORE: "First, create a report file"
✅ AFTER: "**EXECUTE NOW** - YOU MUST create a report file"
```

### Pattern 2: Step Dependencies (15 points)

**What to Look For**:
- `### STEP N (REQUIRED BEFORE STEP N+1)` markers
- Sequential dependencies explicitly stated

**Why It Matters**:
- Enforces execution order
- Prevents Claude from skipping or reordering steps

**Example**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Calculate Path
### STEP 2 (REQUIRED BEFORE STEP 3) - Create File
```

### Pattern 3: Verification Checkpoints (20 points)

**What to Look For**:
- "MANDATORY VERIFICATION" markers
- "CHECKPOINT" markers at phase boundaries

**Why It Matters**:
- Guarantees validation occurs
- Provides audit trail of execution

**Example**:
```markdown
**MANDATORY VERIFICATION - File Created**

YOU MUST verify the file exists before proceeding.
```

### Pattern 4: Fallback Mechanisms (10 points)

**What to Look For**:
- Fallback creation when primary path fails
- Automatic recovery procedures

**Why It Matters**:
- Guarantees 100% success rate
- Prevents silent failures

**Example**:
```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "Creating fallback report..."
  # Create minimal report from agent output
fi
```

### Pattern 5: Critical Requirements (10 points)

**What to Look For**:
- "CRITICAL" markers for non-negotiable actions
- "ABSOLUTE REQUIREMENT" for mandatory steps

**Why It Matters**:
- Highlights operations that cannot be skipped
- Emphasizes importance to Claude

### Pattern 6: Path Verification (10 points)

**What to Look For**:
- Absolute path verification code
- Path validation before file operations

**Why It Matters**:
- Prevents path mismatch errors
- Ensures files created in correct locations

### Pattern 7: File Creation Enforcement (10 points)

**What to Look For**:
- File-first pattern (create BEFORE operations)
- Explicit "Create FIRST" language

**Why It Matters**:
- Guarantees artifact creation
- Prevents loss if operations fail

### Pattern 8: Return Format Specification (5 points)

**What to Look For**:
- "return ONLY" specifications
- Exact return format examples

**Why It Matters**:
- Standardizes agent outputs
- Enables automated parsing

### Pattern 9: Passive Voice Detection (Anti-Pattern)

**What to Avoid**:
- "should", "may", "can" (conditional language)
- "I am", "I will" (descriptive, not imperative)

**Why It Matters**:
- Passive voice allows Claude to skip steps
- Descriptive language is advisory, not executable

### Pattern 10: Error Handling (10 points)

**What to Look For**:
- `exit 1` on critical failures
- ERROR message logging

**Why It Matters**:
- Explicit failure handling
- Prevents silent errors

## Batch Auditing

To audit all commands:

```bash
for cmd in .claude/commands/*.md; do
  echo "Auditing: $cmd"
  ./audit-execution-enforcement.sh "$cmd" --json >> audit-results.json
done
```

To audit all agents:

```bash
for agent in .claude/agents/*.md; do
  echo "Auditing: $agent"
  ./audit-execution-enforcement.sh "$agent" --json >> audit-results.json
done
```

## Interpreting Results

### High Scores (90-100)
- Excellent enforcement
- All critical patterns present
- Ready for production use
- Example: Updated orchestrate.md, research-specialist.md

### Medium Scores (70-89)
- Good foundation
- Minor gaps to address
- Prioritize based on command importance
- Quick wins available

### Low Scores (<70)
- Significant gaps
- Priority for improvement
- May have reliability issues
- Focus on critical patterns first

## CI/CD Integration

Add audit to pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash

CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.claude/(commands|agents)/.*\.md$')

for file in $CHANGED_FILES; do
  SCORE=$(./claude/lib/audit-execution-enforcement.sh "$file" --json | jq '.score')

  if [ "$SCORE" -lt 70 ]; then
    echo "ERROR: $file has enforcement score below 70 ($SCORE/100)"
    echo "Run: ./claude/lib/audit-execution-enforcement.sh $file"
    exit 1
  fi
done
```

## Next Steps

After auditing:

1. **Prioritize**: Focus on low-scoring, high-impact files
2. **Fix Critical Gaps**: Add missing imperative language and checkpoints
3. **Re-Audit**: Verify improvements
4. **Document**: Update command documentation with new patterns

## Resources

- **Audit Script**: `.claude/lib/audit-execution-enforcement.sh`
- **Checklist Template**: `.claude/templates/audit-checklist.md`
- **Pattern Examples**: See Phase 1-2.5 implementation commits
- **Standards**: `.claude/docs/reference/command_architecture_standards.md`
