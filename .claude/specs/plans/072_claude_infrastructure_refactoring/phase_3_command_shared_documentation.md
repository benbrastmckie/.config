# Phase 3: Command Shared Documentation Completion

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 072_claude_infrastructure_refactoring.md
- **Objective**: Audit and complete command shared documentation, remove dead references
- **Complexity**: Low-Medium
- **Status**: PENDING
- **Dependencies**: None
- **Estimated Tasks**: 8 detailed tasks

## Overview

This phase addresses incomplete command shared documentation extraction. While the reference-based composition pattern achieved 61.3% reduction via 10 shared documentation files, several commands reference non-existent files (error-recovery.md, context-management.md), and additional common patterns remain unextracted.

### Current State

**Existing Shared Documentation** (`commands/shared/`):
- 10 documented patterns
- Reference-based composition working well
- commands/shared/README.md exists but incomplete

**Issues Identified**:
- Dead references in orchestrate.md (error-recovery.md, context-management.md)
- 3-5 additional common patterns not yet extracted
- No validation to prevent future dead references
- Shared documentation index needs standardization

### Target State

- All command references resolve to existing files
- 13-15 complete shared documentation files
- Standardized commands/shared/README.md as index
- Validation integrated into structure-validator.sh
- Zero dead references across all 21 commands

## Stage 1: Audit and Inventory

### Objective
Identify all command references to shared documentation and catalog missing files.

### Tasks

#### Task 1.1: Scan All Commands for Shared References
**Script**: Create audit script

```bash
#!/usr/bin/env bash
# Audit command shared documentation references

# Find all references to commands/shared/ in command files
echo "Scanning commands for shared documentation references..."

grep -rh "commands/shared/" .claude/commands/*.md | \
  grep -oE "commands/shared/[a-z0-9_-]+\.md" | \
  sort -u > /tmp/referenced_shared_docs.txt

echo "Found $(wc -l < /tmp/referenced_shared_docs.txt) unique shared doc references"

# Check which ones exist
echo ""
echo "Checking existence..."
while IFS= read -r ref; do
  if [[ -f ".claude/$ref" ]]; then
    echo "✓ $ref"
  else
    echo "✗ MISSING: $ref"
  fi
done < /tmp/referenced_shared_docs.txt
```

**Testing**: Run audit and capture missing files list

#### Task 1.2: Identify Common Patterns in Commands
**Analysis**: Find repeated patterns across commands

Search for common sections:
- Error handling patterns (try-catch, validation)
- Context management patterns (preservation, minimization)
- Agent invocation patterns (Task tool usage)
- Workflow coordination patterns (checkpoint, state)
- Testing patterns (validation, assertion)

```bash
# Find common section headings across commands
for cmd in .claude/commands/*.md; do
  echo "=== $(basename "$cmd") ==="
  grep "^##" "$cmd" | sed 's/^## //'
done | sort | uniq -c | sort -rn | head -20
```

**Expected common patterns**:
- Error Recovery (appears in orchestrate.md, implement.md, debug.md)
- Context Management (appears in orchestrate.md, plan.md)
- Agent Integration (appears in multiple commands)
- Checkpoint Management (appears in implement.md, resume-implement.md)
- Validation Workflows (appears in multiple commands)

#### Task 1.3: Create Audit Report
**File**: `.claude/specs/reports/command_shared_docs_audit.md`

```markdown
# Command Shared Documentation Audit Report

## Date
2025-10-18

## Summary

**Existing Shared Docs**: 10 files
**Referenced but Missing**: [count] files
**Common Patterns Identified**: [count] patterns

## Missing Documentation

### Dead References
- `commands/shared/error-recovery.md` (referenced in orchestrate.md)
- `commands/shared/context-management.md` (referenced in orchestrate.md)
- [Additional missing files]

### Command Context
For each missing file:
- **error-recovery.md**
  - Referenced by: orchestrate.md (line 234, 456)
  - Context: Multi-level error detection, retry strategies, escalation
  - Estimated length: 150-200 lines

## Extractable Common Patterns

### Pattern 1: Checkpoint Management
**Found in**:
- implement.md (save_checkpoint, restore_checkpoint)
- resume-implement.md (checkpoint recovery)
- expand.md (checkpoint for rollback)

**Proposed file**: `commands/shared/checkpoint-patterns.md`
**Estimated length**: 120-150 lines

### Pattern 2: Agent Invocation Patterns
**Found in**:
- orchestrate.md (parallel Task tool invocations)
- plan.md (research-specialist, plan-architect)
- implement.md (code-writer agent)

**Proposed file**: `commands/shared/agent-invocation-patterns.md`
**Estimated length**: 180-220 lines

[Additional patterns...]

## Recommendations

1. Create missing documentation or remove dead references
2. Extract common patterns to shared files
3. Standardize commands/shared/README.md
4. Add validation to structure-validator.sh
```

**Testing**: Review audit report for completeness

---

## Stage 2: Create Missing Documentation

### Objective
Create all missing shared documentation files or remove dead references.

### Tasks

#### Task 2.1: Create error-recovery.md
**File**: `.claude/commands/shared/error-recovery.md`

```markdown
# Error Recovery Patterns

## Multi-Level Error Detection

### Error Types

**Timeout Errors**:
- Agent execution exceeds time limits
- Command invocation stalls
- Long-running operations

**Tool Access Errors**:
- Permission denied
- File not found
- Tool unavailable

**Validation Failures**:
- Output doesn't meet criteria
- Required fields missing
- Schema non-compliance

**Integration Errors**:
- Slash command failures
- External tool errors
- Dependency issues

### Detection Patterns

```bash
# Timeout detection
timeout 120 some_command || handle_timeout_error

# Tool access detection
if ! command -v jq >/dev/null 2>&1; then
  error "jq not available"
  return 1
fi

# Validation detection
if ! validate_output "$result"; then
  error "Validation failed: $result"
  return 1
fi
```

## Retry Strategies

### Automatic Retry (max 3 attempts)

**Retry Pattern**:
```bash
retry_with_backoff() {
  local max_attempts=3
  local attempt=1
  local delay=2

  while [[ $attempt -le $max_attempts ]]; do
    if execute_operation; then
      return 0
    fi

    echo "Attempt $attempt failed, retrying in ${delay}s..."
    sleep "$delay"
    ((attempt++))
    ((delay*=2))  # Exponential backoff
  done

  error "Max retry attempts exceeded"
  return 1
}
```

**Retry with Modified Parameters**:
```bash
# Retry 1: Extend timeout
timeout 180 command  # 1.5x original

# Retry 2: Simplify input
command --simple-mode

# Retry 3: Alternative approach
alternative_command
```

## Escalation Mechanism

### When to Escalate

- Max retries exceeded (3 attempts)
- Critical failures (data loss risk)
- Context overflow (cannot compress)
- Architectural decisions needed

### Escalation Format

```markdown
⚠ Manual Intervention Required

**Issue**: [Brief description]
**Phase**: [Current workflow phase]
**Attempts**: [Number of retries]

**Error History**:
[Chronological list of attempts and results]

**Options**:
1. Review error logs and continue manually
2. Modify approach and resume
3. Rollback to last checkpoint
4. Terminate workflow

Please provide guidance.
```

### User Response Handling

After escalation:
- Pause workflow execution
- Preserve all checkpoints
- Maintain error history
- Await user input

**Response options**:
- `continue`: Resume with manual fixes
- `retry [phase]`: Retry specific phase
- `rollback [checkpoint]`: Return to checkpoint
- `terminate`: End workflow gracefully

## See Also

- [Checkpoint Patterns](checkpoint-patterns.md)
- [Context Management](context-management.md)
- [Validation Workflows](validation-workflows.md)
```

**Testing**: Verify references in orchestrate.md resolve correctly

#### Task 2.2: Create context-management.md
**File**: `.claude/commands/shared/context-management.md`

```markdown
# Context Management Patterns

## Orchestrator Context Minimization

### Target: <30% Context Usage

**Principles**:
- Store file paths, not file contents
- Use summaries (max 200 words), not full outputs
- Reference artifacts, not inline content
- Prune completed phase data

### Context Reduction Techniques

**Metadata-Only Passing**:
```bash
# Instead of passing full report (5000 tokens)
research_report=$(cat specs/reports/042_analysis.md)

# Pass metadata only (250 tokens)
research_summary=$(extract_report_metadata specs/reports/042_analysis.md)
# Returns: {path, title, 50-word summary, key_findings[]}
```

**Forward Message Pattern**:
```bash
# No paraphrasing - pass subagent response directly
forward_message "$subagent_output"

# Instead of:
# summary=$(summarize "$subagent_output")  # Doubles context
```

**Artifact References**:
```bash
# Store reference, not content
completed_phases=("specs/plans/042_auth/phase_1_foundation.md")

# Not:
# completed_phases[0]=$(cat specs/plans/042_auth/phase_1_foundation.md)
```

## Subagent Context (Comprehensive)

### Each Subagent Receives

- Complete task description
- Necessary context from prior phases (summaries only)
- Project standards reference (CLAUDE.md path)
- Explicit success criteria
- Expected output format
- Error handling guidance

**No routing logic or orchestration details**

### Context Injection Template

```markdown
# Task: [Specific objective]

## Context
- Workflow: [1-line original request]
- Research findings: [200-word summary if applicable]
- Project standards: /path/to/CLAUDE.md

## Objective
[Clear description of what this agent must accomplish]

## Requirements
- [Specific requirement 1]
- [Specific requirement 2]

## Expected Output
[Exact format and structure expected]

## Success Criteria
- [Measurable criterion 1]
- [Measurable criterion 2]
```

## Context Pruning

### Aggressive Cleanup

**After Phase Completion**:
```bash
# Prune full subagent outputs
prune_subagent_output "$agent_response"

# Keep only: {status, artifact_path, 50-word summary}

# Prune phase metadata
prune_phase_metadata "$completed_phase"

# Keep only: {phase_num, status, files_modified[]}
```

**Pruning Policy**:
- Research phase: Reduce to 200-word synthesis
- Planning phase: Keep plan path only
- Implementation phase: Keep files_modified[] and test status
- Debugging phase: Keep error summary and resolution
- Documentation phase: Keep updated_files[]

### Context Overflow Prevention

**Detection**:
```bash
# Monitor context usage
if [[ $context_usage -gt 30 ]]; then
  apply_aggressive_pruning
fi
```

**Recovery**:
1. Compress summaries (200 → 100 words)
2. Offload detailed data to files
3. Keep only absolute essentials
4. Graceful degradation (skip optional phases)

## See Also

- [Hierarchical Agent Patterns](../../docs/concepts/hierarchical_agents.md)
- [Forward Message Patterns](forward-message-patterns.md)
- [Metadata Extraction](../../lib/metadata-extraction.sh)
```

**Testing**: Verify references resolve and examples are current

#### Task 2.3: Extract Additional Common Patterns

Based on audit, extract 3-5 additional patterns:

**checkpoint-patterns.md**:
- save_checkpoint structure
- restore_checkpoint usage
- Checkpoint data format
- Rollback procedures

**agent-invocation-patterns.md**:
- Task tool usage for parallel agents
- Behavioral injection pattern
- Agent prompt templates
- Response parsing

**validation-workflows.md**:
- Schema validation patterns
- Output validation
- Cross-reference checking
- Compliance verification

---

## Stage 3: Standardize Shared Documentation Index

### Objective
Create comprehensive commands/shared/README.md as authoritative index.

### Tasks

#### Task 3.1: Update commands/shared/README.md
**File**: `.claude/commands/shared/README.md`

```markdown
# Command Shared Documentation

This directory contains reusable documentation patterns extracted from command files to reduce duplication and maintain consistency.

## Purpose

Commands follow a reference-based composition pattern where common sections are extracted to shared files and referenced via links. This achieves:
- **61.3% file size reduction** (13,193 → 5,100 lines in command files)
- **Zero duplication** of common patterns
- **Consistent guidance** across all commands
- **Easier maintenance** (update once, apply everywhere)

## Index

### Error Handling
- [error-recovery.md](error-recovery.md) - Multi-level error detection, retry strategies, escalation mechanisms

### Context Management
- [context-management.md](context-management.md) - Orchestrator context minimization (<30%), subagent context injection, pruning patterns

### Agent Coordination
- [agent-invocation-patterns.md](agent-invocation-patterns.md) - Task tool usage, parallel execution, behavioral injection
- [forward-message-patterns.md](forward-message-patterns.md) - No-paraphrase handoffs, response parsing

### Workflow Patterns
- [checkpoint-patterns.md](checkpoint-patterns.md) - Save/restore checkpoints, rollback procedures
- [validation-workflows.md](validation-workflows.md) - Schema validation, output verification, compliance checking

### Phase Coordination
- [phase-dependencies.md](phase-dependencies.md) - Wave-based execution, parallel opportunities
- [adaptive-planning-patterns.md](adaptive-planning-patterns.md) - Complexity triggers, replan logic, loop prevention

### Testing and Validation
- [testing-patterns.md](testing-patterns.md) - Unit, integration, regression test approaches
- [backward-compatibility-patterns.md](backward-compatibility-patterns.md) - Wrapper patterns, migration strategies

### Documentation Standards
- [documentation-update-patterns.md](documentation-update-patterns.md) - Cross-referencing, navigation updates, archive handling

## Usage

### In Command Files

Reference shared documentation using relative links:

```markdown
## Error Recovery

For comprehensive error recovery strategies, see [Error Recovery Patterns](shared/error-recovery.md).

### Quick Reference

[Brief 2-3 line summary specific to this command]

For detailed retry strategies and escalation mechanisms, see the full documentation.
```

### Pattern Application

1. **Identify common section** in command file
2. **Check if shared doc exists** in this index
3. **Replace inline content** with reference link
4. **Add command-specific context** (1-3 lines)
5. **Link to shared documentation**

### Creating New Shared Documentation

When creating new shared docs:
1. Extract from ≥2 commands (avoid premature extraction)
2. Generalize examples (remove command-specific details)
3. Include "See Also" section with cross-references
4. Update this README index
5. Update commands to reference new doc

## Statistics

- **Total shared docs**: 13 files
- **Total commands using shared docs**: 21/21 (100%)
- **Average references per command**: 4.2
- **File size reduction**: 61.3% (8,093 lines saved)
- **Last updated**: 2025-10-18

## See Also

- [Command Reference](../../docs/reference/command-reference.md)
- [Creating Commands Guide](../../docs/guides/creating-commands.md)
- [Command Architecture Standards](../../docs/reference/command_architecture_standards.md)
```

**Testing**: Verify all links resolve correctly

---

## Stage 4: Validation Integration

### Objective
Add validation to structure-validator.sh to prevent future dead references.

### Tasks

#### Task 4.1: Add Shared Doc Reference Validation
**File**: `.claude/lib/structure-validator.sh` (update or create)

```bash
#!/usr/bin/env bash
# Structure Validator - Check .claude/ directory compliance

source "$(dirname "${BASH_SOURCE[0]}")/base-utils.sh"

# Validate command shared documentation references
validate_command_shared_refs() {
  echo "Validating command shared documentation references..."

  local commands_dir=".claude/commands"
  local shared_dir="$commands_dir/shared"
  local errors=0

  # Find all references to shared/ in command files
  while IFS= read -r cmd_file; do
    local cmd_name
    cmd_name=$(basename "$cmd_file")

    # Extract shared doc references
    while IFS= read -r ref; do
      local shared_file="$commands_dir/$ref"

      if [[ ! -f "$shared_file" ]]; then
        error "Dead reference in $cmd_name: $ref"
        ((errors++))
      fi
    done < <(grep -oE "shared/[a-z0-9_-]+\.md" "$cmd_file" || true)
  done < <(find "$commands_dir" -maxdepth 1 -name "*.md" -type f)

  if [[ $errors -eq 0 ]]; then
    echo "✓ All shared documentation references valid"
    return 0
  else
    error "Found $errors dead references"
    return 1
  fi
}

# Validate shared doc index completeness
validate_shared_index() {
  echo "Validating shared documentation index..."

  local shared_dir=".claude/commands/shared"
  local index_file="$shared_dir/README.md"
  local errors=0

  # Find all shared docs
  while IFS= read -r shared_file; do
    local filename
    filename=$(basename "$shared_file")

    # Skip README
    if [[ "$filename" == "README.md" ]]; then
      continue
    fi

    # Check if referenced in index
    if ! grep -q "$filename" "$index_file"; then
      error "Shared doc not in index: $filename"
      ((errors++))
    fi
  done < <(find "$shared_dir" -maxdepth 1 -name "*.md" -type f)

  if [[ $errors -eq 0 ]]; then
    echo "✓ Shared documentation index complete"
    return 0
  else
    error "Found $errors missing index entries"
    return 1
  fi
}

# Run all validations
main() {
  local failed=0

  validate_command_shared_refs || ((failed++))
  validate_shared_index || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo ""
    echo "All structure validations passed ✓"
    return 0
  else
    echo ""
    error "$failed validation(s) failed"
    return 1
  fi
}

main "$@"
```

**Testing**: Run validator and verify it catches dead references

#### Task 4.2: Create Pre-Commit Hook (Optional)
**File**: `.claude/hooks/pre-commit-structure-check.sh`

```bash
#!/usr/bin/env bash
# Pre-commit hook for structure validation

# Run structure validator
.claude/lib/structure-validator.sh

exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  echo ""
  echo "Structure validation failed. Please fix errors before committing."
  echo "Run: .claude/lib/structure-validator.sh for details"
  exit 1
fi

exit 0
```

**Usage**: Install with `ln -s ../../.claude/hooks/pre-commit-structure-check.sh .git/hooks/pre-commit`

---

## Success Criteria Validation

- [ ] Audit report created with all missing docs identified
- [ ] All dead references removed or files created
- [ ] error-recovery.md created and referenced correctly
- [ ] context-management.md created and referenced correctly
- [ ] 3-5 additional common patterns extracted
- [ ] commands/shared/README.md comprehensive and complete
- [ ] structure-validator.sh includes shared doc validation
- [ ] All 21 commands reference only existing shared docs
- [ ] Zero dead references across all commands
- [ ] Shared documentation index includes all 13-15 files

## Testing Strategy

### Unit Testing
```bash
# Test structure validator
.claude/lib/structure-validator.sh

# Test specific validation
validate_command_shared_refs
validate_shared_index
```

### Integration Testing
```bash
# Test all command references resolve
for cmd in .claude/commands/*.md; do
  echo "Checking $cmd..."
  # Extract links and verify existence
done
```

### Regression Testing
```bash
# Ensure no commands broken
# Run sample commands with new shared docs
/plan "test feature"
/report "test topic"
```

## Performance Metrics

**Before**:
- Shared docs: 10 files
- Dead references: 2-3
- Validation: None
- Index: Incomplete

**After**:
- Shared docs: 13-15 files
- Dead references: 0
- Validation: Automated
- Index: Comprehensive

## Documentation Updates

### Files to Update

- [ ] `.claude/commands/shared/README.md` - Complete index
- [ ] `.claude/lib/README.md` - Add structure-validator.sh
- [ ] `.claude/docs/reference/command-reference.md` - Reference shared docs
- [ ] `CLAUDE.md` - Update command documentation section

## Next Phase

Phase 4: Documentation Integration and Navigation Updates
