# Refactoring Methodology

**Document Type**: Practical Guide
**Scope**: Systematic refactoring of .claude/ commands and agents
**Status**: ACTIVE - Use for all command/agent refactoring projects
**Last Updated**: 2025-10-22

---

## Table of Contents

1. [Purpose](#purpose)
2. [Pre-Refactoring Assessment](#pre-refactoring-assessment)
3. [Refactoring Process](#refactoring-process)
4. [Utility Integration](#utility-integration)
5. [Testing Consolidation](#testing-consolidation)
6. [Quality Metrics](#quality-metrics)
7. [Case Study: Orchestrate Refactor](#case-study-orchestrate-refactor)
8. [Quick Reference](#quick-reference)

---

## Purpose

This guide provides a systematic methodology for refactoring .claude/ commands and agents to improve:
- **Standards compliance** - Align with execution enforcement patterns
- **Maintainability** - Reduce duplication, leverage shared utilities
- **Efficiency** - Reduce file size and context consumption
- **Robustness** - Add verification checkpoints and fallback mechanisms

### Scope and Relationship to Other Guides

This guide focuses on **practical refactoring workflows** and complements:

- **[Execution Enforcement Guide](execution-enforcement/execution-enforcement-overview.md)** - Language patterns and enforcement standards
- **[Command Architecture Standards](../reference/architecture/overview.md)** - Structural requirements and standards
- **[Writing Standards](../concepts/writing-standards.md)** - Documentation philosophy and timeless writing
- **[Command Development Guide](../development/command-development/command-development-fundamentals.md)** - Creating new commands
- **[Agent Development Guide](../development/agent-development/agent-development-fundamentals.md)** - Creating new agents

Use this guide when improving existing commands/agents; use development guides when creating new ones.

---

## Pre-Refactoring Assessment

### 1. Audit Current State

Before starting any refactor, establish baseline metrics:

#### Execution Enforcement Audit

```bash
# Run enforcement audit (if available)
.claude/lib/audit-execution-enforcement.sh .claude/commands/your-command.md

# Target scores:
# - Production commands: ≥95/100
# - Beta commands: ≥80/100
# - Experimental: ≥60/100
```

Audit checks for:
- Imperative language usage (MUST/WILL/SHALL vs should/may/can)
- EXECUTE NOW markers for critical operations
- MANDATORY VERIFICATION checkpoints
- Fallback mechanisms for agent operations
- CHECKPOINT REQUIREMENT blocks

#### Complexity Analysis

```bash
# Measure file metrics
wc -l .claude/commands/your-command.md
grep -c "```bash" .claude/commands/your-command.md
grep -c "Task {" .claude/commands/your-command.md
grep -c "CRITICAL:\|IMPORTANT:" .claude/commands/your-command.md
```

Key metrics:
- **Total line count** - Baseline for size reduction targets
- **Code blocks** - Inline bash execution patterns
- **Agent invocations** - Task tool usage
- **Critical warnings** - Must-keep content

#### Functionality Inventory

Document existing capabilities:
- [ ] What phases/steps does it execute?
- [ ] Which agents does it invoke?
- [ ] What files does it create?
- [ ] What user interactions does it have?
- [ ] What are the success criteria?

### 2. Identify Refactoring Scope

Determine what needs improvement:

```bash
# Standards compliance gaps
grep -E "\bshould\b|\bmay\b|\bcan\b" .claude/commands/your-command.md | wc -l
# High count = needs imperative language upgrade

# Utility duplication
grep -A 5 "mkdir -p.*specs/" .claude/commands/your-command.md
grep -A 5 "grep.*Phase" .claude/commands/your-command.md
# Manual implementations = candidates for utility integration

# Behavioral injection violations
grep "SlashCommand" .claude/commands/your-command.md
# SlashCommand usage = needs Task tool migration
```

### 3. Set Refactoring Goals

Define measurable targets:

**Required Goals** (must achieve):
- [ ] Standards compliance: Audit score ≥95/100
- [ ] Functionality preservation: All existing features work
- [ ] Test coverage: All execution paths validated

**Optimization Goals** (should achieve):
- [ ] File size reduction: 30-40% smaller
- [ ] Utility integration: Replace manual implementations
- [ ] Testing consolidation: Single comprehensive suite
- [ ] Context reduction: Improved metadata extraction

**Documentation Goals**:
- [ ] Update CLAUDE.md references
- [ ] Update command README
- [ ] Cross-reference related docs
- [ ] Remove temporal markers

### 4. Validate Scope

Prevent scope creep:

```markdown
## In-Scope (this refactor)
- Fix behavioral injection violations
- Add Standard 0 compliance
- Integrate existing utilities
- Consolidate testing

## Out-of-Scope (future work)
- Adding new features
- Changing workflow order
- Modifying output formats
- Performance optimizations
```

---

## Refactoring Process

### Phase 1: Documentation First

**Why**: Establishes methodology and context before code changes.

**Actions**:
1. Create or update refactoring plan in `specs/{NNN_topic}/plans/`
2. Document current state, target state, key differences
3. Define success criteria and quality metrics
4. Identify dependencies and breaking changes

**Decision Framework**: Create new methodology docs if pattern is reusable across multiple commands.

### Phase 2: Standards Compliance

**Focus**: Imperative language, verification checkpoints, fallbacks.

See [Execution Enforcement Guide](execution-enforcement/execution-enforcement-overview.md) for complete patterns.

**Extract vs Inline Decision**:

| Content Type | Keep Inline | Extract to Reference |
|--------------|-------------|---------------------|
| EXECUTE NOW blocks | ✓ Always | ✗ Never |
| MANDATORY VERIFICATION | ✓ Always | ✗ Never |
| Task invocation templates | ✓ Always | ✗ Never |
| CRITICAL/IMPORTANT warnings | ✓ Always | ✗ Never |
| Fallback mechanisms | ✓ Always | ✗ Never |
| Step-by-step procedures | ✓ Always | ✗ Never |
| Extended examples | Consider | ✓ If supplemental |
| Historical rationale | ✗ Never | ✓ If valuable |
| Alternative approaches | Consider | ✓ If not primary |
| Troubleshooting details | Consider | ✓ If edge cases |

**Apply the 80/20 Rule**:
- 80% of execution value should come from inline content
- 20% supplemental context can be external references
- Test independence: Command must execute without reference files

**Verification**:
```bash
# Validate standards compliance
.claude/lib/audit-execution-enforcement.sh your-command.md

# Must pass with score ≥95
```

### Phase 3: Behavioral Injection Pattern

**Problem**: SlashCommand invocations violate behavioral injection pattern.

**Solution**: Use Task tool with context injection.

**Before** (incorrect):
```markdown
# Invoke expansion command
SlashCommand {
  command: "/expand ${PLAN_PATH}"
}
```

**After** (correct):
```markdown
# Phase 0: Pre-calculate expansion paths
EXPANSION_DIR="${PLAN_DIR}/phase_files"
mkdir -p "$EXPANSION_DIR"

# Invoke expansion-specialist agent with context injection
Task {
  subagent_type: "general-purpose"
  description: "Expand plan with phase organization"
  prompt: |
    Read and follow: .claude/agents/expansion-specialist.md

    **Plan Path**: ${PLAN_PATH}
    **Expansion Directory**: ${EXPANSION_DIR}
    **Complexity Threshold**: ${COMPLEXITY_THRESHOLD}

    YOU MUST create phase expansion files in the exact directory specified.
    Return metadata: {phase_count, expanded_files[], complexity_score}
}

# MANDATORY VERIFICATION
if [ ! -d "$EXPANSION_DIR" ] || [ -z "$(ls -A $EXPANSION_DIR 2>/dev/null)" ]; then
  echo "ERROR: Expansion agent did not create files"
  # Fallback: Create basic expansion yourself
fi
```

**Benefits**:
- Orchestrator controls artifact paths
- Enables metadata extraction before loading full content
- Supports fallback creation if agent doesn't comply
- Follows Phase 0 pre-calculation pattern

See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for complete documentation.

### Phase 4: Utility Integration

**Objective**: Replace manual implementations with existing utilities.

**Discovery Process**:
```bash
# Find available utilities
ls -1 .claude/lib/*.sh

# Common utilities:
# - metadata-extraction.sh - Extract plan/report metadata
# - artifact-creation.sh - Create topic directories and artifacts
# - complexity-utils.sh - Complexity analysis
# - checkpoint-utils.sh - State management
# - unified-logger.sh - Logging with rotation
```

**Integration Checklist**:

```bash
# 1. Source utility at beginning of relevant section
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

# 2. Replace manual implementations
# BEFORE (manual):
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
TASK_COUNT=$(grep -c "^- \[ \]" "$PLAN_PATH")

# AFTER (utility):
METADATA=$(extract_plan_metadata "$PLAN_PATH")
PHASE_COUNT=$(echo "$METADATA" | jq -r '.phase_count')
TASK_COUNT=$(echo "$METADATA" | jq -r '.task_count')

# 3. Replace manual directory creation
# BEFORE (manual):
mkdir -p "specs/${TOPIC_NUM}_${TOPIC_NAME}/reports"
mkdir -p "specs/${TOPIC_NUM}_${TOPIC_NAME}/plans"

# AFTER (utility):
TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_NAME")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research_findings.md")
```

**When to Leverage vs Reimplement**:

| Scenario | Use Utility | Reimplement |
|----------|-------------|-------------|
| Standard parsing (plans, reports) | ✓ | ✗ |
| Directory creation (specs structure) | ✓ | ✗ |
| Metadata extraction | ✓ | ✗ |
| Logging with rotation | ✓ | ✗ |
| Command-specific logic | ✗ | ✓ |
| Novel parsing needs | ✗ | ✓ (then extract) |
| Experimental features | ✗ | ✓ (extract when stable) |

**Validation**:
```bash
# Verify utility sourcing
grep -c "source.*\.claude/lib/" your-command.md

# Verify utility usage (not manual reimplementation)
grep -c "extract_plan_metadata\|create_topic_artifact" your-command.md
```

### Phase 5: Content Extraction

**Objective**: Reduce file size while maintaining execution independence.

**Extraction Strategy (80/20 Rule)**:

**Keep Inline (80% - Execution-Critical)**:
- All EXECUTE NOW blocks
- All MANDATORY VERIFICATION checkpoints
- All Task invocation templates (complete, not truncated)
- All CRITICAL/IMPORTANT warnings
- All fallback mechanism code
- All step-by-step procedures
- All bash code blocks for execution

**Extract to Reference (20% - Supplemental)**:
- Extended complexity evaluation examples
- Alternative workflow strategies
- Historical design decisions
- Advanced troubleshooting scenarios
- Performance optimization techniques

**Extraction Process**:

1. **Pre-validate extraction targets**:
```bash
# Verify content actually exists before planning extraction
grep -n "complexity evaluation" your-command.md
grep -n "alternative.*approach" your-command.md
grep -n "historical" your-command.md

# Measure achievable reduction
CURRENT_LINES=$(wc -l < your-command.md)
echo "Target reduction: $((CURRENT_LINES * 30 / 100)) to $((CURRENT_LINES * 40 / 100)) lines"
```

2. **Create shared reference files**:
```bash
mkdir -p .claude/commands/shared/
# Create files with descriptive names:
# - {command}-details.md
# - {command}-alternatives.md
# - {command}-troubleshooting.md
# - {command}-performance.md
```

3. **Extract and replace**:
```markdown
<!-- BEFORE (long inline example) -->
## Complexity Evaluation

Complexity is calculated using the following formula:

... (500 lines of examples and edge cases)

<!-- AFTER (concise inline + reference) -->
## Complexity Evaluation

Complexity score determines when plans should be expanded. The formula considers phase count, task count, and file references.

For extended details including formula derivation, threshold tuning, and edge case handling:
See [Orchestration Complexity Details](../../.claude/lib/plan/complexity-utils.sh)
```

4. **Validate extraction quality**:
```bash
# CRITICAL TEST: Execution independence
mv .claude/commands/shared .claude/commands/shared.backup
# Run command with simple test case
# Expected: Command completes successfully
mv .claude/commands/shared.backup .claude/commands/shared

# Verify execution-critical content remains
grep -c "EXECUTE NOW" your-command.md  # Should be sufficient
grep -c "MANDATORY VERIFICATION" your-command.md  # Should be sufficient
```

---

## Utility Integration

### Available Utilities

Reference the complete catalog:

| Utility | Purpose | Key Functions |
|---------|---------|---------------|
| metadata-extraction.sh | Extract metadata from plans/reports | extract_plan_metadata(), extract_report_metadata() |
| artifact-creation.sh | Create spec directories and files | create_topic_artifact(), get_or_create_topic_dir() |
| complexity-utils.sh | Complexity analysis | get_complexity_threshold(), calculate_phase_complexity() |
| checkpoint-utils.sh | State management | save_checkpoint(), restore_checkpoint() |
| unified-logger.sh | Logging with rotation | log_info(), log_error(), query_logs() |
| plan-core-bundle.sh | Plan parsing | parse_plan_file(), extract_phase_info() |

See individual utility files for complete API documentation.

### Integration Patterns

**Pattern 1: Metadata Extraction**
```bash
# Source utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"

# Extract metadata
METADATA=$(extract_plan_metadata "$PLAN_PATH")

# Use metadata (not full content)
PHASE_COUNT=$(echo "$METADATA" | jq -r '.phase_count')
COMPLEXITY=$(echo "$METADATA" | jq -r '.complexity_score')
```

**Pattern 2: Artifact Creation**
```bash
# Source utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

# Create topic directory and artifacts
TOPIC_DIR=$(get_or_create_topic_dir "auth_feature")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001_research.md")
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "001_implementation.md")
```

**Pattern 3: Checkpoint Management**
```bash
# Source utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh"

# Save state before risky operation
save_checkpoint "before_implementation" "$PLAN_PATH" "$PHASE_NUM"

# Restore if needed
if [ $? -ne 0 ]; then
  restore_checkpoint "before_implementation"
fi
```

See [Context Management Pattern](../concepts/patterns/context-management.md) for complete utility usage patterns.

---

## Testing Consolidation

### Problem: Redundant Testing

Commands often have duplicate test logic across multiple phases:
- Phase 2: Validate intermediate state
- Phase 5: Validate final state
- Phase 7: Comprehensive test suite

This creates:
- Redundant validation logic (~300+ lines)
- Inconsistent test criteria
- Difficult maintenance

### Solution: Single Comprehensive Suite

Create one test file covering all validation:

```bash
#!/bin/bash
# .claude/tests/test_{command}_refactor.sh

set -e

COMMAND_FILE=".claude/commands/{command}.md"

echo "=== {Command} Refactor Test Suite ==="

# Test 1: Standard 0 Compliance
test_standard_0_compliance() {
  echo "Test 1: Standard 0 Compliance..."

  SCORE=$(.claude/lib/audit-execution-enforcement.sh "$COMMAND_FILE" | grep -oP 'Score: \K\d+')
  [ "$SCORE" -ge 95 ] || { echo "FAIL: Audit score $SCORE < 95"; exit 1; }

  [ $(grep -c "EXECUTE NOW" "$COMMAND_FILE") -ge 12 ] || { echo "FAIL: Missing EXECUTE NOW"; exit 1; }
  [ $(grep -c "MANDATORY VERIFICATION" "$COMMAND_FILE") -ge 8 ] || { echo "FAIL: Missing verification"; exit 1; }

  echo "✓ Standard 0 Compliance passed"
}

# Test 2: Behavioral Injection
test_behavioral_injection() {
  echo "Test 2: Behavioral Injection..."

  ! grep -q "SlashCommand.*{agent}" "$COMMAND_FILE" || { echo "FAIL: Still using SlashCommand"; exit 1; }
  grep -q "Task.*{agent}-specialist" "$COMMAND_FILE" || { echo "FAIL: No Task tool"; exit 1; }

  echo "✓ Behavioral Injection passed"
}

# Test 3: Utility Integration
test_utility_integration() {
  echo "Test 3: Utility Integration..."

  [ $(grep -c "source.*artifact-creation.sh" "$COMMAND_FILE") -ge 1 ] || { echo "FAIL: Missing utility"; exit 1; }
  [ $(grep -c "create_topic_artifact" "$COMMAND_FILE") -ge 2 ] || { echo "FAIL: Not using utilities"; exit 1; }

  echo "✓ Utility Integration passed"
}

# Test 4: File Size Reduction
test_file_size() {
  echo "Test 4: File Size..."

  LINE_COUNT=$(wc -l < "$COMMAND_FILE")
  ORIGINAL=6051
  REDUCTION=$(echo "scale=2; (($ORIGINAL - $LINE_COUNT) / $ORIGINAL) * 100" | bc)

  [ $(echo "$REDUCTION >= 30" | bc) -eq 1 ] || { echo "FAIL: Reduction ${REDUCTION}% < 30%"; exit 1; }

  echo "✓ File Size passed (${REDUCTION}% reduction)"
}

# Test 5: Execution Independence
test_execution_independence() {
  echo "Test 5: Execution Independence..."

  grep -c "EXECUTE NOW" "$COMMAND_FILE" | grep -q "[1-9][0-9]*" || { echo "FAIL: Missing critical content"; exit 1; }
  grep -c "```bash" "$COMMAND_FILE" | grep -q "[1-9][0-9]*" || { echo "FAIL: Missing code blocks"; exit 1; }

  echo "✓ Execution Independence passed"
}

# Run all tests
test_standard_0_compliance
test_behavioral_injection
test_utility_integration
test_file_size
test_execution_independence

echo ""
echo "=== All Tests Passed (5/5) ==="
```

### Testing Consolidation Checklist

- [ ] Create single test file: `.claude/tests/test_{command}_refactor.sh`
- [ ] Remove per-phase test blocks from command file
- [ ] Cover all critical validation:
  - [ ] Standards compliance (audit score ≥95)
  - [ ] Behavioral injection (Task tool usage)
  - [ ] Utility integration (proper sourcing and usage)
  - [ ] File size reduction (30-40% target)
  - [ ] Execution independence (runs without shared/)
- [ ] Add to test suite: `./run_all_tests.sh`

---

## Quality Metrics

### Success Criteria

Refactoring is complete when all criteria pass:

**Required Criteria**:
- [ ] Audit score ≥95/100 (execution enforcement)
- [ ] All existing functionality preserved
- [ ] All tests pass (comprehensive suite)
- [ ] No SlashCommand violations (behavioral injection)
- [ ] Utilities integrated (no manual reimplementation)

**Optimization Criteria**:
- [ ] File size reduced 30-40%
- [ ] Context reduction improved (metadata extraction)
- [ ] Testing consolidated (single comprehensive suite)
- [ ] Documentation updated (CLAUDE.md, READMEs)

**Quality Metrics Dashboard**:

```bash
# Standards compliance
AUDIT_SCORE=$(.claude/lib/audit-execution-enforcement.sh your-command.md | grep -oP 'Score: \K\d+')
echo "Audit Score: $AUDIT_SCORE/100 (target: ≥95)"

# File size reduction
ORIGINAL_LINES=6051  # Record before refactoring
FINAL_LINES=$(wc -l < your-command.md)
REDUCTION=$(echo "scale=2; (($ORIGINAL_LINES - $FINAL_LINES) / $ORIGINAL_LINES) * 100" | bc)
echo "Size Reduction: ${REDUCTION}% (target: 30-40%)"

# Utility integration
UTILITY_COUNT=$(grep -c "source.*\.claude/lib/" your-command.md)
FUNCTION_USAGE=$(grep -c "extract_.*metadata\|create_topic_artifact" your-command.md)
echo "Utilities: $UTILITY_COUNT sourced, $FUNCTION_USAGE function calls"

# Testing consolidation
TEST_FILE_SIZE=$(wc -l < .claude/tests/test_${command}_refactor.sh 2>/dev/null || echo 0)
echo "Test Suite: $TEST_FILE_SIZE lines (consolidated)"
```

### Validation Checklist

Before marking refactor complete:

- [ ] Run comprehensive test suite: All tests pass
- [ ] Run audit enforcement: Score ≥95/100
- [ ] Test execution independence: Command works without shared/
- [ ] Verify functionality: All original features work
- [ ] Check documentation: CLAUDE.md and READMEs updated
- [ ] Validate no temporal markers: Timeless writing maintained
- [ ] Confirm breaking changes documented

---

## Case Study: Orchestrate Refactor

### Background

The `/orchestrate` command required refactoring to:
- Add Standard 0 compliance (imperative language, verification, fallbacks)
- Fix behavioral injection violation (SlashCommand → Task tool)
- Integrate existing utilities (metadata extraction, artifact creation)
- Consolidate testing (single comprehensive suite)
- Reduce file size 30-40% while maintaining all functionality

### Refactoring Plan

See [Spec 072: Orchestrate Refactor](../../specs/072_orchestrate_refactor_v2/plans/001_refined_orchestrate_refactor.md) for complete plan.

**Key Phases**:
1. Document Refactoring Methodology (this guide)
2. Add Standard 0 Compliance
3. Fix Behavioral Injection Violations
4. Integrate Existing Utilities
5. Remove Complexity Evaluation and Expansion Phases
6. Content Extraction and Size Reduction
7. Comprehensive Testing and Documentation

### Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Audit Score | 62/100 | 98/100 | +36 points |
| File Size | 6,051 lines | 3,876 lines | 36% reduction |
| Phase Count | 8 phases | 6 phases | 25% reduction |
| Test Lines | ~500 (scattered) | 243 (consolidated) | 51% reduction |
| Utility Usage | 0 functions | 8 functions | DRY achieved |
| Behavioral Injection | 1 violation | 0 violations | 100% compliance |

### Key Lessons

**What Worked**:
- **Documentation first** - Establishing methodology before refactoring provided clear roadmap
- **Phased approach** - Breaking into 7 phases allowed systematic validation
- **Utility integration** - Leveraging existing utilities eliminated 200+ lines of manual code
- **Testing consolidation** - Single test suite easier to maintain and extend
- **Extract vs inline clarity** - 80/20 rule prevented over-extraction

**What Could Improve**:
- **Earlier utility discovery** - Should have cataloged available utilities before planning
- **Test creation timing** - Could have created test suite earlier for regression prevention
- **Content audit** - More thorough pre-validation of extraction targets

**Reusable Patterns**:
- Phase 0 pre-calculation for agent invocations
- MANDATORY VERIFICATION after all file creation
- Fallback mechanisms for agent-dependent operations
- Metadata extraction for context reduction
- Comprehensive test suite structure

---

## Quick Reference

### Refactoring Workflow

```
1. Pre-Assessment
   ├─ Run audit: .claude/lib/audit-execution-enforcement.sh
   ├─ Measure complexity: Line count, code blocks, agent invocations
   ├─ Inventory functionality: Phases, agents, files created
   └─ Define goals: Required, optimization, documentation

2. Standards Compliance
   ├─ Apply imperative language (MUST/WILL/SHALL)
   ├─ Add EXECUTE NOW markers
   ├─ Add MANDATORY VERIFICATION checkpoints
   ├─ Add fallback mechanisms
   └─ Validate: Audit score ≥95/100

3. Behavioral Injection
   ├─ Find SlashCommand usage
   ├─ Replace with Task tool invocation
   ├─ Add Phase 0 pre-calculation
   ├─ Add context injection
   └─ Add MANDATORY VERIFICATION + fallback

4. Utility Integration
   ├─ Source utilities: artifact-creation.sh, metadata-extraction.sh
   ├─ Replace manual parsing with extract_plan_metadata()
   ├─ Replace manual mkdir with create_topic_artifact()
   └─ Validate: No manual reimplementation remains

5. Content Extraction (80/20)
   ├─ Keep inline: EXECUTE NOW, MANDATORY VERIFICATION, Task templates
   ├─ Extract: Examples, alternatives, history, troubleshooting
   ├─ Validate: Command works without shared/
   └─ Measure: 30-40% reduction achieved

6. Testing Consolidation
   ├─ Create: .claude/tests/test_{command}_refactor.sh
   ├─ Remove: Per-phase test blocks
   ├─ Cover: Standards, injection, utilities, size, independence
   └─ Validate: All tests pass

7. Documentation
   ├─ Update: CLAUDE.md references
   ├─ Update: Command README
   ├─ Cross-reference: Related docs
   └─ Remove: Temporal markers
```

### Extract vs Inline Decision Tree

```
Is content execution-critical?
├─ YES: EXECUTE NOW, MANDATORY VERIFICATION, Task templates, fallbacks
│   └─ Keep inline (always)
└─ NO: Is it the primary workflow?
    ├─ YES: Step-by-step procedures, critical warnings
    │   └─ Keep inline
    └─ NO: Is it supplemental context?
        ├─ YES: Examples, alternatives, history, troubleshooting
        │   └─ Extract to shared/ (if >50 lines)
        └─ NO: Experimental, deprecated, or historical
            └─ Extract or remove
```

### Quality Metrics Targets

```bash
# Standards compliance
Audit Score: ≥95/100

# File size reduction
Reduction: 30-40%

# Utility integration
Utilities sourced: ≥2
Function calls: ≥5

# Testing
Test file: 1 comprehensive suite
Coverage: All execution paths

# Behavioral injection
SlashCommand violations: 0
Task tool usage: ≥1 per agent invocation
```

### Common Pitfalls

| Pitfall | How to Avoid |
|---------|-------------|
| Over-extraction | Keep all EXECUTE NOW blocks inline |
| Broken execution independence | Test without shared/ directory |
| Passive language remains | Run audit enforcement validation |
| Manual utility reimplementation | Check for existing utilities first |
| Scattered testing | Consolidate to single test file |
| Scope creep | Define in-scope vs out-of-scope upfront |
| Missing verification | Add MANDATORY VERIFICATION after file creation |
| No fallback mechanisms | Always add fallback for agent operations |

---

## References

### Related Documentation

- [Execution Enforcement Guide](execution-enforcement/execution-enforcement-overview.md) - Imperative language patterns
- [Command Architecture Standards](../reference/architecture/overview.md) - Structural requirements
- [Writing Standards](../concepts/writing-standards.md) - Documentation philosophy
- [Command Development Guide](../development/command-development/command-development-fundamentals.md) - Creating new commands
- [Agent Development Guide](../development/agent-development/agent-development-fundamentals.md) - Creating new agents

### Patterns

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Task tool context injection
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - File creation guarantees
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - State preservation
- [Context Management Pattern](../concepts/patterns/context-management.md) - Metadata extraction

### Utilities

- `.claude/lib/workflow/metadata-extraction.sh` - Plan/report metadata extraction
- `.claude/lib/artifact/artifact-creation.sh` - Topic directory and artifact creation
- `.claude/lib/plan/complexity-utils.sh` - Complexity analysis
- `.claude/lib/workflow/checkpoint-utils.sh` - State management
- `.claude/lib/core/unified-logger.sh` - Logging with rotation

---

**Last Updated**: 2025-10-22
**Maintainer**: .claude/ toolset team
**Status**: Active - use for all command/agent refactoring
