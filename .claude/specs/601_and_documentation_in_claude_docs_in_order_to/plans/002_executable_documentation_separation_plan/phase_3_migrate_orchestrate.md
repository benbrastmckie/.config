# Phase 3 Detailed Specification: Migrate /orchestrate Command

## Overview

**Objective**: Apply executable/documentation separation pattern to orchestrate.md (5,439 lines)

**Parent Plan**: `/home/benjamin/.config/.claude/specs/601_and_documentation_in_claude_docs_in_order_to/plans/002_executable_documentation_separation_plan.md`

**Complexity**: Medium (6/10) - Large file with complex multi-phase structure, but pattern established from Phase 2 pilot

**Duration**: 2-3 hours

**Dependencies**:
- Phase 1 (templates created)
- Phase 2 (coordinate.md pilot validated)

---

## Current State Analysis

### File Statistics

```bash
# Total line count
wc -l /home/benjamin/.config/.claude/commands/orchestrate.md
# Output: 5439 /home/benjamin/.config/.claude/commands/orchestrate.md

# Structural outline
grep -n "^## " /home/benjamin/.config/.claude/commands/orchestrate.md
```

### Actual Structure (Based on File Analysis)

**orchestrate.md Current Layout** (5,439 lines):

```
Lines 1-7:       Frontmatter (allowed-tools, argument-hint, description, metadata)
Lines 8-37:      Critical architectural pattern warnings (HTML comments)
Lines 38-75:     Role statement and execution model
Lines 76-98:     Reference files section
Lines 99-117:    Dry-run mode introduction
Lines 118-387:   Workflow infrastructure documentation:
                 - Workflow analysis
                 - Workflow execution infrastructure
                 - Workflow initialization (TodoWrite, state structure, checkpoints)
                 - Shared utilities integration
                 - Error handling strategy
                 - Progress streaming patterns
                 - Workflow description parsing steps
Lines 388-555:   Phase 0 documentation (location determination, unified library)
Lines 556-2085:  Phase 1 documentation (research phase, parallel execution, complexity)
Lines 2086-3027: Phase 3 documentation (implementation, wave-based execution, debugging)
Lines 3028-3269: Phase 4 documentation (comprehensive testing)
Lines 3270-5360: Phase 5+6 documentation (debugging, documentation, hierarchy updates)
Lines 5361-5439: Checkpoint detection, resume workflow, cleanup procedures
```

### Executable vs Documentation Content

**Documentation Sections** (~4,900 lines):
- Lines 38-75: Role and execution model (38 lines) - KEEP (minimal role statement)
- Lines 76-98: Reference files (23 lines) - MOVE (detailed references belong in guide)
- Lines 99-387: Infrastructure documentation (289 lines) - MOVE (how things work)
- Lines 388-555: Phase 0 detailed explanation (168 lines) - MOVE (pattern explanation)
- Lines 556-2085: Phase 1 detailed explanation (1,530 lines) - MOVE (complexity algorithms, patterns)
- Lines 2086-3027: Phase 3 detailed explanation (942 lines) - MOVE (wave-based details)
- Lines 3028-3269: Phase 4 detailed explanation (242 lines) - MOVE (testing patterns)
- Lines 3270-5360: Phase 5+6 detailed explanation (2,091 lines) - MOVE (debugging, docs, hierarchy)
- Lines 5361-5439: Checkpoint patterns (79 lines) - MOVE (checkpoint implementation details)

**Executable Sections** (~500 lines estimated):
- Lines 1-7: Frontmatter - KEEP
- Lines 8-37: Critical warnings - KEEP (prevents anti-pattern violations)
- Lines 38-75: Minimal role statement - KEEP (stripped to essentials)
- Embedded bash blocks throughout phases - EXTRACT and CONSOLIDATE
- Agent invocation templates - EXTRACT and CONSOLIDATE
- Verification checkpoints - EXTRACT and CONSOLIDATE

---

## Target Structure

### NEW orchestrate.md (~250 lines)

**Structure**:
```
Lines 1-7:       Frontmatter (unchanged)
Lines 8-37:      Critical architectural warnings (unchanged)
Lines 38-50:     Minimal role statement + documentation link
Lines 51-80:     Phase 0: Location detection (bash block + agent invocation)
Lines 81-110:    Phase 1: Research coordination (agent invocation template)
Lines 111-140:   Phase 2: Planning (agent invocation template)
Lines 141-170:   Phase 3: Implementation (agent invocation template)
Lines 171-200:   Phase 4: Testing (agent invocation template)
Lines 201-230:   Phase 5: Debugging (conditional agent invocation)
Lines 231-250:   Phase 6: Documentation (agent invocation + completion)
```

**Content Strategy**:
1. **Frontmatter**: Preserve exactly as-is (tools, arguments, metadata)
2. **Critical Warnings**: Preserve HTML comment warnings (anti-pattern enforcement)
3. **Role Statement**: Reduce to 3-5 sentences with guide link
4. **Phase Blocks**: Each phase gets 25-30 lines:
   - Phase header (1 line)
   - Minimal objective statement (2-3 lines)
   - Executable bash block or agent invocation (15-20 lines)
   - Verification checkpoint (3-5 lines)
   - Completion signal (1 line)

### NEW orchestrate-command-guide.md (~5,000 lines)

**Structure**:
```
Lines 1-50:      Header, overview, quick start, table of contents
Lines 51-200:    Architecture Overview
                 - Multi-agent orchestration pattern
                 - Behavioral injection pattern
                 - Context reduction through metadata passing
                 - Checkpoint recovery pattern
Lines 201-400:   Workflow Infrastructure
                 - TodoWrite initialization patterns
                 - Workflow state structure
                 - Shared utilities integration
                 - Error handling strategies
                 - Progress streaming format
Lines 401-700:   Phase 0: Location Determination
                 - Unified library integration
                 - Topic directory structure
                 - Artifact path calculation
                 - Verification procedures
Lines 701-2200:  Phase 1: Research Coordination
                 - Parallel execution pattern
                 - Complexity scoring algorithm
                 - Thinking mode determination
                 - Report path pre-calculation
                 - Agent invocation examples
                 - Verification and error recovery
Lines 2201-2700: Phase 2: Planning
                 - Plan architect agent integration
                 - Research report metadata passing
                 - Plan validation procedures
Lines 2701-3400: Phase 3: Implementation
                 - Wave-based parallel execution
                 - Implementer-coordinator agent
                 - Debugging loop patterns
                 - Test-driven development
Lines 3401-3700: Phase 4: Comprehensive Testing
                 - Test specialist integration
                 - Test output format requirements
                 - Context reduction patterns
Lines 3701-4400: Phase 5: Debugging Loop
                 - Conditional debugging triggers
                 - Debug specialist invocation
                 - Iteration control (max 3)
                 - Fix application patterns
Lines 4401-4800: Phase 6: Documentation
                 - Doc writer agent integration
                 - Plan hierarchy updates
                 - Workflow summary generation
Lines 4801-5000: Advanced Topics
                 - Checkpoint detection and resume
                 - Dry-run mode implementation
                 - Reference files integration
                 - Troubleshooting common issues
```

---

## Implementation Steps

### Step 1: Create Backup (5 minutes)

**EXECUTE NOW**:

```bash
# Navigate to commands directory
cd /home/benjamin/.config/.claude/commands

# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp orchestrate.md "orchestrate.md.backup_${TIMESTAMP}"

# Verify backup created
ls -lh orchestrate.md.backup_*

# Output expected:
# -rw-r--r-- 1 user group 180K Nov  7 14:23 orchestrate.md.backup_20251107_142300
```

**Success Criteria**:
- [ ] Backup file created with timestamp
- [ ] Backup file size matches original (~180K)
- [ ] Backup readable and intact

---

### Step 2: Extract Documentation to Guide File (45 minutes)

**EXECUTE NOW - Create orchestrate-command-guide.md**:

```bash
# Navigate to guides directory
cd /home/benjamin/.config/.claude/docs/guides

# Create guide file with header
cat > orchestrate-command-guide.md << 'EOF'
# /orchestrate Command - Complete Guide

**Executable**: `.claude/commands/orchestrate.md`

**Quick Start**: Run `/orchestrate "<workflow-description>" [--parallel] [--sequential] [--create-pr] [--dry-run]`

**Purpose**: Coordinate multi-agent workflows through 7-phase development lifecycle (location → research → planning → implementation → testing → debugging → documentation)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Workflow Infrastructure](#workflow-infrastructure)
4. [Phase 0: Location Determination](#phase-0-location-determination)
5. [Phase 1: Research Coordination](#phase-1-research-coordination)
6. [Phase 2: Planning](#phase-2-planning)
7. [Phase 3: Implementation](#phase-3-implementation)
8. [Phase 4: Comprehensive Testing](#phase-4-comprehensive-testing)
9. [Phase 5: Debugging Loop](#phase-5-debugging-loop)
10. [Phase 6: Documentation](#phase-6-documentation)
11. [Advanced Topics](#advanced-topics)
12. [Troubleshooting](#troubleshooting)

---

## Overview

EOF

echo "✓ Guide file header created"
```

**EXECUTE NOW - Extract Documentation Sections**:

Use sed to extract specific line ranges from orchestrate.md into the guide:

```bash
# Set source and target paths
SOURCE="/home/benjamin/.config/.claude/commands/orchestrate.md"
TARGET="/home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md"

# Extract Architecture section (lines 76-98: Reference files)
echo "" >> "$TARGET"
echo "## Architecture" >> "$TARGET"
echo "" >> "$TARGET"
echo "### Multi-Agent Orchestration Pattern" >> "$TARGET"
echo "" >> "$TARGET"
echo "The /orchestrate command uses a pure orchestration model where the command itself NEVER executes work directly. Instead, it delegates all execution to specialized agents via the Task tool." >> "$TARGET"
echo "" >> "$TARGET"
echo "### Reference Files" >> "$TARGET"
sed -n '76,98p' "$SOURCE" >> "$TARGET"

# Extract Workflow Infrastructure (lines 118-387)
echo "" >> "$TARGET"
echo "## Workflow Infrastructure" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '118,387p' "$SOURCE" >> "$TARGET"

# Extract Phase 0 documentation (lines 388-555)
echo "" >> "$TARGET"
echo "## Phase 0: Location Determination" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '388,555p' "$SOURCE" >> "$TARGET"

# Extract Phase 1 documentation (lines 556-2085)
echo "" >> "$TARGET"
echo "## Phase 1: Research Coordination" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '556,2085p' "$SOURCE" >> "$TARGET"

# Extract Phase 2 documentation (will need to identify line range)
# Note: Phase 2 appears between Phase 1 and Phase 3
echo "" >> "$TARGET"
echo "## Phase 2: Planning" >> "$TARGET"
echo "" >> "$TARGET"
echo "(Extract planning phase documentation from original file)" >> "$TARGET"

# Extract Phase 3 documentation (lines 2086-3027)
echo "" >> "$TARGET"
echo "## Phase 3: Implementation" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '2086,3027p' "$SOURCE" >> "$TARGET"

# Extract Phase 4 documentation (lines 3028-3269)
echo "" >> "$TARGET"
echo "## Phase 4: Comprehensive Testing" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '3028,3269p' "$SOURCE" >> "$TARGET"

# Extract Phase 5+6 documentation (lines 3270-5360)
echo "" >> "$TARGET"
echo "## Phase 5: Debugging Loop" >> "$TARGET"
echo "" >> "$TARGET"
echo "(Extract Phase 5 section)" >> "$TARGET"
echo "" >> "$TARGET"
echo "## Phase 6: Documentation" >> "$TARGET"
echo "" >> "$TARGET"
sed -n '3270,5360p' "$SOURCE" >> "$TARGET"

# Extract Advanced Topics (lines 5361-5439)
echo "" >> "$TARGET"
echo "## Advanced Topics" >> "$TARGET"
echo "" >> "$TARGET"
echo "### Checkpoint Detection and Resume" >> "$TARGET"
sed -n '5361,5439p' "$SOURCE" >> "$TARGET"

# Add troubleshooting section
echo "" >> "$TARGET"
echo "## Troubleshooting" >> "$TARGET"
echo "" >> "$TARGET"
echo "### Common Issues" >> "$TARGET"
echo "" >> "$TARGET"
echo "**Issue**: Meta-confusion loops (recursive invocations)" >> "$TARGET"
echo "**Cause**: Mixed documentation and executable content" >> "$TARGET"
echo "**Solution**: This has been resolved via executable/documentation separation" >> "$TARGET"
echo "" >> "$TARGET"
echo "**Issue**: Agent fails to create expected files" >> "$TARGET"
echo "**Cause**: Verification checkpoints not enforced" >> "$TARGET"
echo "**Solution**: All phases include mandatory verification checkpoints" >> "$TARGET"
echo "" >> "$TARGET"
echo "**Issue**: Workflow interrupted mid-execution" >> "$TARGET"
echo "**Cause**: System crash, timeout, or user cancellation" >> "$TARGET"
echo "**Solution**: Use checkpoint detection to resume from last completed phase" >> "$TARGET"

echo "✓ Documentation sections extracted to guide file"
```

**Verify extraction**:

```bash
# Check guide file size (should be ~5000 lines)
wc -l /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md

# Verify structure
grep "^## " /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md

# Expected output:
## Architecture
## Workflow Infrastructure
## Phase 0: Location Determination
## Phase 1: Research Coordination
## Phase 2: Planning
## Phase 3: Implementation
## Phase 4: Comprehensive Testing
## Phase 5: Debugging Loop
## Phase 6: Documentation
## Advanced Topics
## Troubleshooting
```

**Success Criteria**:
- [ ] Guide file created in `/home/benjamin/.config/.claude/docs/guides/`
- [ ] All documentation sections extracted
- [ ] Guide file ~4500-5500 lines
- [ ] Table of contents includes all phases
- [ ] Cross-reference to executable file present

---

### Step 3: Create New Lean Executable File (60 minutes)

**EXECUTE NOW - Create Minimal orchestrate.md**:

```bash
# Navigate to commands directory
cd /home/benjamin/.config/.claude/commands

# Move original to temp location
mv orchestrate.md orchestrate.md.original

# Create new lean executable file
cat > orchestrate.md << 'EOF'
---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: research, plan, implement, debug, test, document, github-specialist
---

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE                 -->
<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- /orchestrate MUST NEVER invoke other slash commands             -->
<!-- FORBIDDEN TOOLS: SlashCommand                                   -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents                -->
<!-- ═══════════════════════════════════════════════════════════════ -->

# Multi-Agent Workflow Orchestration

YOU MUST orchestrate a 7-phase development workflow by delegating to specialized subagents.

**Documentation**: See `.claude/docs/guides/orchestrate-command-guide.md`

**YOUR ROLE**: Workflow orchestrator (NOT executor)
- Use ONLY Task tool to invoke specialized agents
- Coordinate agents, verify outputs, manage checkpoints
- Forward agent results without re-summarization

**EXECUTION MODEL**: Pure orchestration (Phases 0-6)
- Phase 0: Location detection (unified library)
- Phase 1: Research (2-4 parallel agents)
- Phase 2: Planning (plan-architect agent)
- Phase 3: Implementation (implementer-coordinator with waves)
- Phase 4: Testing (test-specialist)
- Phase 5: Debugging (conditional, max 3 iterations)
- Phase 6: Documentation (doc-writer + summary)

---

## Phase 0: Location Determination

```bash
# Source unified location detection library
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")

# Extract topic directory paths
if command -v jq &>/dev/null; then
  TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | jq -r '.topic_number')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | jq -r '.topic_name')
  ARTIFACT_REPORTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
  ARTIFACT_PLANS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
  ARTIFACT_SUMMARIES=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')
  ARTIFACT_DEBUG=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.debug')
  ARTIFACT_SCRIPTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.scripts')
  ARTIFACT_OUTPUTS=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.outputs')
else
  # Fallback parsing without jq
  TOPIC_PATH=$(echo "$LOCATION_JSON" | grep -o '"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NUMBER=$(echo "$LOCATION_JSON" | grep -o '"topic_number": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  TOPIC_NAME=$(echo "$LOCATION_JSON" | grep -o '"topic_name": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  ARTIFACT_REPORTS="${TOPIC_PATH}/reports"
  ARTIFACT_PLANS="${TOPIC_PATH}/plans"
  ARTIFACT_SUMMARIES="${TOPIC_PATH}/summaries"
  ARTIFACT_DEBUG="${TOPIC_PATH}/debug"
  ARTIFACT_SCRIPTS="${TOPIC_PATH}/scripts"
  ARTIFACT_OUTPUTS="${TOPIC_PATH}/outputs"
fi

# Store in workflow state
export WORKFLOW_TOPIC_DIR="$TOPIC_PATH"
export WORKFLOW_TOPIC_NUMBER="$TOPIC_NUMBER"
export WORKFLOW_TOPIC_NAME="$TOPIC_NAME"

echo "✓ Phase 0 Complete: $TOPIC_PATH"
```

**Verify**: Topic directory structure created at `$TOPIC_PATH`

---

## Phase 1: Research Coordination

**EXECUTE NOW**: Invoke research-specialist agents in parallel

```yaml
# Agent invocation (2-4 parallel agents based on complexity)
Task {
  subagent_type: "general-purpose"
  description: "Research [topic] for workflow implementation"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    Research Topic: [topic_name]
    Report Path: ${ARTIFACT_REPORTS}/[topic].md

    Complete research and create report.
}
```

**Verify**: All report files exist at `${ARTIFACT_REPORTS}/`

---

## Phase 2: Planning

**EXECUTE NOW**: Invoke plan-architect agent

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Research Reports: [list of report paths]
    Plan Output: ${ARTIFACT_PLANS}/001_implementation.md

    Create detailed implementation plan.
}
```

**Verify**: Plan file exists at `${ARTIFACT_PLANS}/001_implementation.md`

---

## Phase 3: Implementation

**EXECUTE NOW**: Invoke implementer-coordinator agent

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallel execution"
  timeout: 900000
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    Implementation Plan: ${ARTIFACT_PLANS}/001_implementation.md
    Topic Directory: ${WORKFLOW_TOPIC_DIR}

    Execute plan with wave-based parallelization.
}
```

**Verify**: Implementation complete, files modified

---

## Phase 4: Comprehensive Testing

**EXECUTE NOW**: Invoke test-specialist agent

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive test suite"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

    Test Output: ${ARTIFACT_OUTPUTS}/test_results.txt

    Run full test suite, save results to file.
}
```

**Verify**: Test results saved to `${ARTIFACT_OUTPUTS}/test_results.txt`

---

## Phase 5: Debugging (Conditional)

**EXECUTE IF**: Phase 4 tests failed

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Debug test failures (iteration [N] of 3)"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-specialist.md

    Test Failures: [list of failed tests]
    Debug Report: ${ARTIFACT_DEBUG}/debug_iteration_[N].md

    Investigate and fix test failures.
}
```

**Verify**: Debug report created, fixes applied, tests re-run

---

## Phase 6: Documentation

**EXECUTE NOW**: Invoke doc-writer agent and generate summary

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Generate documentation and workflow summary"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

    Implementation Summary: ${ARTIFACT_SUMMARIES}/workflow_summary.md

    Generate comprehensive workflow summary.
}
```

**Verify**: Summary created at `${ARTIFACT_SUMMARIES}/workflow_summary.md`

---

**Workflow Complete**: All phases executed, artifacts organized in `${WORKFLOW_TOPIC_DIR}`

**Troubleshooting**: See guide for detailed patterns and error recovery procedures.
EOF

echo "✓ New lean orchestrate.md created"
```

**Verify new executable structure**:

```bash
# Check line count (should be <260 lines)
wc -l /home/benjamin/.config/.claude/commands/orchestrate.md

# Check structure
grep "^## Phase" /home/benjamin/.config/.claude/commands/orchestrate.md

# Expected output:
## Phase 0: Location Determination
## Phase 1: Research Coordination
## Phase 2: Planning
## Phase 3: Implementation
## Phase 4: Comprehensive Testing
## Phase 5: Debugging (Conditional)
## Phase 6: Documentation
```

**Success Criteria**:
- [ ] New orchestrate.md under 260 lines
- [ ] All 7 phases present (0-6)
- [ ] Documentation link at top
- [ ] Critical warnings preserved
- [ ] Each phase has bash block or agent invocation
- [ ] Verification checkpoints included

---

### Step 4: Add Cross-References (10 minutes)

**EXECUTE NOW - Update Guide with Executable Reference**:

```bash
# Add cross-reference to top of guide file
TARGET="/home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md"

# Create temporary file with updated header
cat > /tmp/guide_header.txt << 'EOF'
# /orchestrate Command - Complete Guide

**Executable**: `.claude/commands/orchestrate.md`

**Quick Start**: Run `/orchestrate "<workflow-description>" [--parallel] [--sequential] [--create-pr] [--dry-run]`

**Purpose**: Coordinate multi-agent workflows through 7-phase development lifecycle

**IMPORTANT**: This is the DOCUMENTATION file. For execution, Claude loads `.claude/commands/orchestrate.md`. This guide provides architectural context, detailed patterns, and troubleshooting.

---
EOF

# Merge with existing content (skip old header)
tail -n +6 "$TARGET" >> /tmp/guide_header.txt
mv /tmp/guide_header.txt "$TARGET"

echo "✓ Cross-reference added to guide"
```

**Verify cross-references**:

```bash
# Check executable references guide
grep "orchestrate-command-guide.md" /home/benjamin/.config/.claude/commands/orchestrate.md

# Check guide references executable
grep "commands/orchestrate.md" /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md

# Both should return matches
```

**Success Criteria**:
- [ ] Executable file links to guide
- [ ] Guide file links to executable
- [ ] Guide header emphasizes documentation purpose

---

### Step 5: Update CLAUDE.md (10 minutes)

**EXECUTE NOW - Update Project Commands Section**:

```bash
# Update CLAUDE.md to reference new guide
sed -i 's|/orchestrate <workflow> - Multi-agent workflow coordination|/orchestrate <workflow> - Multi-agent workflow coordination (see [orchestrate-command-guide.md](.claude/docs/guides/orchestrate-command-guide.md))|' /home/benjamin/.config/CLAUDE.md

# Verify update
grep "orchestrate" /home/benjamin/.config/CLAUDE.md
```

**Alternative: Manual Update**:

Edit CLAUDE.md section `<!-- SECTION: project_commands -->` and update orchestrate entry:

```markdown
- `/orchestrate <workflow-description>` - Multi-agent workflow coordination (research → plan → implement → debug → document)
  - **Guide**: [Orchestrate Command Guide](.claude/docs/guides/orchestrate-command-guide.md)
  - **Architecture**: 7-phase lifecycle with wave-based parallel implementation
  - **Performance**: <30% context usage, 40-60% time savings
```

**Success Criteria**:
- [ ] CLAUDE.md references orchestrate-command-guide.md
- [ ] Link functional and points to correct path
- [ ] Description updated to reflect current architecture

---

### Step 6: Test Execution (30 minutes)

**Test Case 1: Simple Workflow (No Meta-Confusion)**

```bash
# EXECUTE NOW - Test basic orchestration
/orchestrate "research best practices for error handling in Bash scripts"

# Expected behavior:
# 1. No recursive invocation loops
# 2. Executes Phase 0 immediately (location detection)
# 3. Proceeds to Phase 1 (research)
# 4. Creates research reports
# 5. Completes without errors

# Failure modes to watch for:
# ❌ "Now let me invoke /orchestrate" (meta-confusion)
# ❌ "Permission denied: /home/benjamin/.config/.claude/commands/orchestrate.md" (trying to execute as script)
# ❌ Multiple recursive calls before first bash block executes
```

**Test Case 2: Multi-Phase Workflow**

```bash
# EXECUTE NOW - Test full workflow execution
/orchestrate "add rate limiting middleware to API endpoints with comprehensive tests"

# Expected behavior:
# 1. Phase 0: Location detection creates topic directory
# 2. Phase 1: 2-3 research reports created (middleware patterns, rate limiting, testing)
# 3. Phase 2: Implementation plan created
# 4. Phase 3: Code changes applied (implementer-coordinator)
# 5. Phase 4: Tests executed
# 6. Phase 5: Conditional debugging (if tests fail)
# 7. Phase 6: Documentation and summary created

# Verification checkpoints:
# ✓ Topic directory exists: specs/NNN_rate_limiting/
# ✓ Reports created: specs/NNN_rate_limiting/reports/*.md
# ✓ Plan created: specs/NNN_rate_limiting/plans/001_implementation.md
# ✓ Test results: specs/NNN_rate_limiting/outputs/test_results.txt
# ✓ Summary: specs/NNN_rate_limiting/summaries/workflow_summary.md
```

**Test Case 3: Error Handling**

```bash
# EXECUTE NOW - Test with empty description
/orchestrate ""

# Expected behavior:
# Error message: "Workflow description required"
# Usage guidance displayed
# No file creation or agent invocation

# EXECUTE NOW - Test with invalid flag
/orchestrate "test workflow" --invalid-flag

# Expected behavior:
# Error message: "Unknown flag: --invalid-flag"
# Valid flags listed: --parallel, --sequential, --create-pr, --dry-run
```

**Test Case 4: Dry-Run Mode**

```bash
# EXECUTE NOW - Test dry-run preview
/orchestrate "implement OAuth2 authentication" --dry-run

# Expected behavior:
# 1. Workflow analysis displayed
# 2. Research topics identified
# 3. Agent assignments previewed
# 4. Duration estimates shown
# 5. Artifact preview (files that would be created)
# 6. NO actual agent invocations
# 7. NO file creation
```

**Automated Test Script**:

```bash
#!/usr/bin/env bash
# test_orchestrate_separation.sh

echo "Testing /orchestrate executable/documentation separation..."

FAILED=0

# Test 1: File size
EXEC_LINES=$(wc -l < /home/benjamin/.config/.claude/commands/orchestrate.md)
if [ "$EXEC_LINES" -gt 300 ]; then
  echo "❌ FAIL: orchestrate.md too large ($EXEC_LINES lines, max 300)"
  FAILED=$((FAILED + 1))
else
  echo "✅ PASS: orchestrate.md size acceptable ($EXEC_LINES lines)"
fi

# Test 2: Guide exists
if [ -f /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md ]; then
  echo "✅ PASS: Guide file exists"
else
  echo "❌ FAIL: Guide file missing"
  FAILED=$((FAILED + 1))
fi

# Test 3: Cross-references
if grep -q "orchestrate-command-guide.md" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "✅ PASS: Executable references guide"
else
  echo "❌ FAIL: Executable missing guide reference"
  FAILED=$((FAILED + 1))
fi

if grep -q "commands/orchestrate.md" /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md; then
  echo "✅ PASS: Guide references executable"
else
  echo "❌ FAIL: Guide missing executable reference"
  FAILED=$((FAILED + 1))
fi

# Test 4: Critical warnings preserved
if grep -q "CRITICAL ARCHITECTURAL PATTERN" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "✅ PASS: Critical warnings preserved"
else
  echo "❌ FAIL: Critical warnings missing"
  FAILED=$((FAILED + 1))
fi

# Test 5: All phases present
for phase in "Phase 0" "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5" "Phase 6"; do
  if grep -q "$phase" /home/benjamin/.config/.claude/commands/orchestrate.md; then
    echo "✅ PASS: $phase present"
  else
    echo "❌ FAIL: $phase missing"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✅ All tests passed"
  exit 0
else
  echo "❌ $FAILED test(s) failed"
  exit 1
fi
```

**Success Criteria**:
- [ ] No meta-confusion loops in any test case
- [ ] All phases execute correctly
- [ ] Agents invoked successfully
- [ ] Files created at expected paths
- [ ] Error handling works as expected
- [ ] Dry-run mode functional
- [ ] Automated test script passes

---

## Rollback Procedures

### If Issues Discovered During Testing

**Immediate Rollback**:

```bash
# Navigate to commands directory
cd /home/benjamin/.config/.claude/commands

# Find most recent backup
BACKUP=$(ls -t orchestrate.md.backup_* | head -1)

# Restore original
mv orchestrate.md orchestrate.md.failed
cp "$BACKUP" orchestrate.md

# Delete failed guide
mv /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md \
   /home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md.failed

# Verify restoration
wc -l orchestrate.md  # Should be 5439 lines

# Test original functionality
/orchestrate "test workflow"

echo "✓ Rollback complete - original orchestrate.md restored"
```

**Partial Rollback (Keep Guide, Restore Executable)**:

```bash
# Useful if guide is good but executable has issues
cd /home/benjamin/.config/.claude/commands

BACKUP=$(ls -t orchestrate.md.backup_* | head -1)
cp "$BACKUP" orchestrate.md

echo "✓ Partial rollback - executable restored, guide preserved"
```

**Document Rollback Reason**:

```bash
# Create rollback report
cat > /tmp/orchestrate_rollback_report.md << EOF
# Rollback Report: /orchestrate Migration

**Date**: $(date)
**Phase**: Phase 3 - Migrate /orchestrate Command
**Action**: Rollback to original orchestrate.md

## Reason for Rollback

[Describe what went wrong]

## Failed Test Cases

[List which tests failed]

## Issues Encountered

[Detail specific problems]

## Next Steps

[What needs to be fixed before re-attempting migration]

## Files Affected

- Restored: .claude/commands/orchestrate.md (from backup)
- Removed: .claude/docs/guides/orchestrate-command-guide.md
- Preserved: Backup file for future analysis

EOF

# Save to debug directory
mv /tmp/orchestrate_rollback_report.md \
   /home/benjamin/.config/.claude/specs/601_and_documentation_in_claude_docs_in_order_to/debug/
```

---

## Success Criteria

### File Size Requirements

- [ ] orchestrate.md: <300 lines (target: ~250 lines)
- [ ] orchestrate-command-guide.md: 4500-5500 lines (target: ~5000 lines)
- [ ] Combined size reduction: 5439 → 5250 (minimal overhead from headers/cross-refs)

### Content Requirements

**Executable File (orchestrate.md)**:
- [ ] Frontmatter preserved exactly
- [ ] Critical architectural warnings preserved
- [ ] Minimal role statement (3-5 sentences)
- [ ] Documentation link prominent
- [ ] All 7 phases present (Phase 0-6)
- [ ] Each phase has executable code or agent invocation template
- [ ] Verification checkpoints included
- [ ] No prose documentation (patterns, examples, explanations)

**Guide File (orchestrate-command-guide.md)**:
- [ ] Header with cross-reference to executable
- [ ] Table of contents with all sections
- [ ] Architecture overview
- [ ] Workflow infrastructure patterns
- [ ] All 7 phases documented in detail
- [ ] Advanced topics (checkpoints, dry-run, etc.)
- [ ] Troubleshooting section
- [ ] Examples with expected output

### Functional Requirements

- [ ] No meta-confusion loops during execution
- [ ] All phases execute in correct order
- [ ] Agents invoked successfully
- [ ] Files created at expected paths
- [ ] Error messages clear and actionable
- [ ] Dry-run mode works without agent invocation
- [ ] Checkpoint detection and resume functional

### Documentation Requirements

- [ ] CLAUDE.md updated with guide link
- [ ] Cross-references bidirectional (exec ↔ guide)
- [ ] Guide emphasizes documentation purpose
- [ ] No broken links
- [ ] Examples copy-paste ready

---

## Deliverables

1. **Backup File**: `/home/benjamin/.config/.claude/commands/orchestrate.md.backup_[timestamp]`
2. **New Executable**: `/home/benjamin/.config/.claude/commands/orchestrate.md` (~250 lines)
3. **Guide File**: `/home/benjamin/.config/.claude/docs/guides/orchestrate-command-guide.md` (~5000 lines)
4. **Updated CLAUDE.md**: Reference to orchestrate-command-guide.md
5. **Test Script**: `test_orchestrate_separation.sh` (automated validation)
6. **Test Results**: Documentation of all 4 test cases with outcomes

---

## Time Estimates

| Step | Duration | Cumulative |
|------|----------|------------|
| Step 1: Create backup | 5 min | 5 min |
| Step 2: Extract documentation | 45 min | 50 min |
| Step 3: Create lean executable | 60 min | 110 min |
| Step 4: Add cross-references | 10 min | 120 min |
| Step 5: Update CLAUDE.md | 10 min | 130 min |
| Step 6: Test execution | 30 min | 160 min |
| **Total** | **2h 40min** | |

**Recommended Approach**: Execute steps sequentially with verification after each step. Do NOT proceed to next step if verification fails.

---

## Notes

- **Complexity Justification**: Rated 6/10 due to large file size (5439 lines) and complex multi-phase structure, but pattern is established from Phase 2 pilot
- **Risk**: Medium - Large extraction operation, but clear boundaries between phases minimize risk
- **Dependencies**: Requires Phase 2 completion to validate pattern effectiveness
- **Future Maintenance**: Guide can grow without bloating executable; new phases can be added to both files independently
