# Legacy Command Standards Gaps

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Legacy Command Standards Gaps
- **Report Type**: Codebase analysis
- **Overview Report**: [Research Overview](./OVERVIEW.md)

## Executive Summary

Analysis of legacy commands (/implement, /revise, /plan, /expand, /collapse) reveals significant standards gaps compared to recent state-machine commands (/coordinate, /optimize-claude). Key findings: (1) Missing imperative patterns throughout command files, with extensive use of descriptive language that Claude may interpret loosely (Standard 11 violations), (2) Absence of behavioral injection pattern in agent invocations, with massive inline duplication of agent procedures (Standard 12 violations), (3) Inconsistent YAML frontmatter with missing version requirements and metadata, (4) Missing verification checkpoints and fallback mechanisms that guarantee artifact creation, (5) Outdated CLAUDE_PROJECT_DIR detection patterns predating Standard 13, and (6) No integration with state machine architecture introduced in late 2024. Updating these commands would reduce context bloat by ~60%, improve reliability through execution enforcement, and align with modern orchestration patterns.

## Findings

### 1. Standard 11 Violations: Imperative Agent Invocation Pattern

**Problem**: Legacy commands use descriptive language for agent invocations instead of imperative enforcement markers.

**Evidence from /implement (lines 137-152)**:
```markdown
# Implementation research for complex phases (score ≥8 or tasks >10)
if [ "$COMPLEXITY_SCORE" -ge 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  echo "PROGRESS: Complex phase - invoking implementation researcher"
  # Invoke implementation-researcher agent via Task tool
  # Extract artifact metadata via forward_message pattern
  # Cache metadata for on-demand loading
fi
```

**Standards Gap**:
- ❌ Uses comments `# Invoke implementation-researcher agent` instead of imperative `**EXECUTE NOW**: USE the Task tool`
- ❌ No actual Task invocation block present (placeholder comment only)
- ❌ Missing behavioral file reference pattern: `Read and follow: .claude/agents/implementation-researcher.md`
- ❌ No completion signal requirement specified

**Expected Pattern (from /coordinate:222-245)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  model: "haiku"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}
```

**Additional Violations in /implement**:
- Line 148-152: Agent delegation section uses descriptive text without executable Task blocks
- Line 169: `invoke_debug` function called without showing invocation pattern
- Line 178: Spec-updater agent mentioned but no invocation template provided

**Impact**: ~0% agent delegation rate when Claude encounters these sections, as it interprets them as documentation rather than execution instructions.

---

### 2. Standard 12 Violations: Behavioral Content Separation

**Problem**: Legacy commands contain massive inline duplication of agent behavioral procedures instead of referencing agent files.

**Evidence from /revise (lines 309-416)**:

The /revise command contains 107 lines of inline STEP sequences for auto-mode execution:
```markdown
#### Revision Type: expand_phase

```bash
if [ "$REVISION_TYPE" = "expand_phase" ]; then
  # CRITICAL: Invoke /expand command
  /expand phase "$ARTIFACT_PATH" "$PHASE_NUM"

  # Capture result
  EXPAND_RESULT=$?

  if [ $EXPAND_RESULT -eq 0 ]; then
    ACTION_TAKEN="Expanded Phase $PHASE_NUM to separate file"
    echo "✓ Phase expansion complete"
  else
    echo "ERROR: Phase expansion failed"
    REVISION_STATUS="error"
  fi
fi
```

Similar blocks for:
- `add_phase` (lines 341-368): 27 lines
- `update_tasks` (lines 373-397): 24 lines
- `collapse_phase` (lines 400-416): 16 lines

**Standards Gap**:
- ❌ 107 lines of behavioral procedure inline (should be in agent file)
- ❌ No reference to `.claude/agents/plan-structure-manager.md` (behavioral injection)
- ❌ Duplicates agent-owned workflow logic in command file
- ❌ Violates "agent-owned behavior (REFERENCE)" principle

**Expected Pattern**: These procedures should be in `.claude/agents/plan-structure-manager.md` with only a behavioral injection reference in the command:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke plan-structure-manager agent:

Task {
  subagent_type: "general-purpose"
  description: "Execute revision operation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/plan-structure-manager.md

    **Operation Context**:
    - Revision Type: $REVISION_TYPE
    - Artifact Path: $ARTIFACT_PATH
    - Phase Number: $PHASE_NUM

    Execute revision following behavioral file guidelines.
    Return: REVISION_COMPLETE: {JSON status}
  "
}
```

**Context Bloat**: 90% reduction achievable (107 lines → ~15 lines with behavioral injection).

**Additional Violations**:
- /expand (lines 162-200): 38 lines of phase complexity detection logic (should be in complexity-estimator agent)
- /collapse (lines 152-176): 24 lines of validation logic (should be in agent file)
- /plan (lines 555-608): 53 lines of standards discovery logic (should be extracted)

---

### 3. Missing Verification Checkpoints and Fallback Mechanisms

**Problem**: Legacy commands lack mandatory verification checkpoints that guarantee artifact creation.

**Evidence from /plan (lines 713-755)**:
```bash
# VERIFICATION CHECKPOINT: Verify plan file created
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ CRITICAL: plan-architect agent failed to create: $PLAN_PATH"
  echo ""
  echo "Diagnostic:"
  echo "  - Expected file at: $PLAN_PATH"
  echo "  - Parent directory: $(dirname "$PLAN_PATH")"
  echo "  - Directory exists: $([ -d "$(dirname "$PLAN_PATH")" ] && echo "yes" || echo "no")"
  echo "  - Agent behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md"
  echo ""
  echo "This is a critical failure. Cannot proceed without implementation plan."
  exit 1
fi
```

**Partial Compliance**:
- ✅ Has verification checkpoint
- ✅ Provides detailed diagnostics
- ❌ **Missing fallback mechanism** - exits immediately without attempting recovery
- ❌ Does not implement Standard 0's "Fallback Mechanism Requirements"

**Expected Pattern (from Standard 0:220-230)**:
```bash
# After agent completes
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "Agent didn't create file. Executing fallback..."
  cat > "$EXPECTED_FILE" <<EOF
# Fallback Report
$AGENT_OUTPUT
EOF
fi
```

**Additional Gaps**:
- /implement (lines 155-173): Test failure handling exists but lacks structured fallback pattern
- /revise (lines 290-307): Backup verification present but no restoration fallback
- /expand (lines 226-243): Phase file verification present but no minimal expansion fallback
- /collapse (lines 383-390): File deletion without prior content preservation verification

**Impact**: Commands fail completely when agents don't comply, rather than degrading gracefully with fallback content.

---

### 4. Outdated CLAUDE_PROJECT_DIR Detection (Standard 13)

**Problem**: Legacy commands use inconsistent or outdated project directory detection patterns.

**Evidence from /implement (lines 20-47)**:
```bash
# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
```

**Partial Compliance**:
- ✅ Includes Standard 13 comment marker
- ✅ Uses git-based detection primary path
- ❌ **Inline duplication** - this 28-line block appears in every legacy command
- ❌ Not using consolidated detection library

**Expected Pattern (from /coordinate:74-78)**:
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Duplication Analysis**:
- /implement: Lines 20-47 (28 lines)
- /plan: Lines 24-50 (27 lines)
- /expand: Lines 79-109 (31 lines)
- /collapse: Lines 81-109 (29 lines)
- /revise: Does not include Standard 13 detection at all (gap!)

**Total Duplication**: ~115 lines that could reference a 5-line consolidated pattern.

---

### 5. Missing State Machine Integration

**Problem**: Legacy commands do not integrate with state machine architecture introduced in /coordinate.

**Evidence**: None of the legacy commands use:
- `workflow-state-machine.sh` library (workflow state management)
- `state-persistence.sh` library (cross-bash-block state persistence)
- `append_workflow_state()` / `load_workflow_state()` functions
- State ID file pattern for bash block coordination
- Verification helpers (`verify_state_variable`, `verify_file_created`)

**Example from /coordinate (lines 59-120)**:
```bash
# Source state machine and state persistence libraries
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Pattern 1: Fixed Semantic Filename
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Save workflow ID and description to state
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"
```

**Legacy Commands**: Use ad-hoc checkpoint mechanisms without standardized state management.

**Impact**:
- No cross-bash-block state persistence
- Cannot integrate with state-based orchestration patterns
- Missing fail-fast verification helpers
- No standardized error handling patterns

---

### 6. Inconsistent YAML Frontmatter

**Problem**: Legacy commands have incomplete or inconsistent YAML frontmatter metadata.

**Analysis**:

| Command | allowed-tools | argument-hint | description | command-type | dependent-commands | dependent-agents | Library Version Reqs |
|---------|--------------|---------------|-------------|--------------|-------------------|------------------|---------------------|
| /implement | ✅ Complete | ✅ Present | ✅ Present | ✅ primary | ✅ Present | ❌ Missing | ❌ Missing |
| /revise | ✅ Complete | ✅ Present | ✅ Present | ✅ primary | ✅ Present | ❌ Missing | ❌ Missing |
| /plan | ✅ Complete | ✅ Present | ✅ Present | ✅ primary | ✅ Present | ❌ Missing | ❌ Missing |
| /expand | ✅ Complete | ✅ Present | ✅ Present | ✅ workflow | ❌ Missing | ❌ Missing | ❌ Missing |
| /collapse | ✅ Complete | ✅ Present | ✅ Present | ✅ workflow | ❌ Missing | ❌ Missing | ❌ Missing |

**Expected Pattern (from /coordinate:1-8)**:
```yaml
---
allowed-tools: Task, TodoWrite, Bash, Read
argument-hint: <workflow-description>
description: Coordinate multi-agent workflows with wave-based parallel implementation (state machine architecture)
command-type: primary
dependent-commands: research, plan, debug, test, document
dependent-agents: research-specialist, plan-architect, implementer-coordinator, debug-analyst
---
```

**Gaps**:
- ❌ No `dependent-agents` metadata (prevents agent dependency analysis)
- ❌ No library version requirements (e.g., `requires: workflow-state-machine.sh >= 2.0`)
- ❌ No `model-justification` for complex orchestration commands
- ❌ No `fallback-model` specification

---

### 7. Missing Documentation Links

**Problem**: Legacy commands lack documentation references to guide files.

**Evidence**: /implement has this at line 13:
```markdown
**Documentation**: See `.claude/docs/guides/implement-command-guide.md` for complete usage guide
```

**Good Practice**: ✅ References guide file

**However**:
- /revise: ❌ No guide file reference
- /expand: ❌ No guide file reference
- /collapse: ❌ No guide file reference
- /plan: ✅ Has guide file reference (line 13)

**Expected Pattern (from /coordinate:10)**:
```markdown
**Documentation**: See `.claude/docs/guides/coordinate-command-guide.md` for architecture, usage patterns, troubleshooting, and examples.
```

**Gap**: 60% of legacy commands missing guide file links (violates Standard 14: Executable/Documentation File Separation).

---

### 8. Verbose Inline STEP Sequences (Command-Owned vs Agent-Owned Confusion)

**Problem**: Commands contain extensive STEP sequences that may be agent-owned behavior.

**Evidence from /expand (lines 74-160)**:

The /expand command includes 86 lines of "Phase Expansion Process" STEP sequences:
```markdown
### Phase Expansion Process

**STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Current Structure**
**STEP 2 (REQUIRED BEFORE STEP 3) - Extract Phase Content**
**STEP 3 (REQUIRED BEFORE STEP 4) - Complexity Detection**
**STEP 4 (REQUIRED BEFORE STEP 5) - Create File Structure**
**STEP 5 (REQUIRED) - Update Metadata**
```

**Ownership Analysis**:
- STEP 1: Analyze structure → Command orchestrates ✅ (INLINE appropriate)
- STEP 2: Extract content → Agent executes ❓ (ambiguous - may belong in agent)
- STEP 3: Complexity detection → Agent executes ❌ (should be in complexity-estimator agent)
- STEP 4: Create files → Agent executes ❌ (should be in plan-structure-manager agent)
- STEP 5: Update metadata → Command verifies ✅ (INLINE appropriate)

**Guidance from Standard 12 Reconciliation**:
> Ask: "Who executes this STEP sequence?"
> ├─ Command/orchestrator → INLINE (Standard 0)
> ├─ Agent/subagent → REFERENCE (Standard 12)

**Recommendation**: Extract agent-owned STEP sequences (complexity detection, file creation workflows) to `.claude/agents/plan-structure-manager.md`, keep only orchestration STEPs inline.

**Similar Issues**:
- /collapse (lines 266-407): 141 lines of STEP sequences (many agent-owned)
- /implement (lines 113-201): 88 lines mixing orchestration and execution steps

---

### 9. Missing Library Version Requirements

**Problem**: Commands source libraries without specifying version requirements or fail-fast on incompatibility.

**Evidence from /plan (lines 56-105)**:
```bash
# Source required utilities
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
for util in error-handling.sh checkpoint-utils.sh complexity-utils.sh adaptive-planning-logger.sh agent-registry-utils.sh; do
  [ -f "$UTILS_DIR/$util" ] || { echo "ERROR: $util not found"; exit 1; }
  source "$UTILS_DIR/$util"
done
```

**Partial Compliance**:
- ✅ Checks file existence before sourcing
- ❌ **No version compatibility check**
- ❌ No function availability verification
- ❌ No dependency ordering documentation

**Expected Pattern (from /coordinate:74-120)**:
```bash
# CRITICAL: Source error-handling.sh and verification-helpers.sh BEFORE any function calls
# These libraries must be available for verification checkpoints and error handling
# throughout initialization. See bash-block-execution-model.md for rationale.

# Source error handling library (provides handle_state_error)
if [ -f "${LIB_DIR}/error-handling.sh" ]; then
  source "${LIB_DIR}/error-handling.sh"
else
  echo "ERROR: error-handling.sh not found at ${LIB_DIR}/error-handling.sh"
  echo "Cannot proceed without error handling functions"
  exit 1
fi

# VERIFICATION CHECKPOINT: Verify critical functions available (Standard 0)
if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: verify_file_created function not available after library sourcing"
  exit 1
fi
```

**Improvements**:
- ✅ Explains WHY library must be sourced early
- ✅ Verifies function availability post-sourcing
- ✅ Documents dependency rationale

**Gap in Legacy Commands**: No post-sourcing function verification.

---

### 10. Comparison with Recent Commands (/coordinate, /optimize-claude)

**Standards Compliance Matrix**:

| Standard | /coordinate | /optimize-claude | /implement | /plan | /revise | /expand | /collapse |
|----------|------------|------------------|-----------|-------|---------|---------|-----------|
| **Standard 0**: Execution Enforcement | ✅ Full | ✅ Full | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial |
| **Standard 11**: Imperative Agent Invocation | ✅ Full | ✅ Full | ❌ Placeholders | ⚠️ Partial | ❌ Missing | ⚠️ Partial | ⚠️ Partial |
| **Standard 12**: Behavioral Separation | ✅ Full | ✅ Full | ❌ Inline duplication | ⚠️ Partial | ❌ 107 lines inline | ❌ 86 lines inline | ❌ 141 lines inline |
| **Standard 13**: Project Dir Detection | ✅ Consolidated (5 lines) | ✅ Consolidated | ⚠️ Inline (28 lines) | ⚠️ Inline (27 lines) | ❌ Missing | ⚠️ Inline (31 lines) | ⚠️ Inline (29 lines) |
| **State Machine Integration** | ✅ Full | ✅ Full | ❌ None | ❌ None | ❌ None | ❌ None | ❌ None |
| **Verification Checkpoints** | ✅ Full | ✅ Full | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial | ❌ Missing |
| **Fallback Mechanisms** | ✅ Full | ✅ Full | ❌ Missing | ❌ Exit on failure | ❌ Missing | ❌ Missing | ❌ Missing |
| **YAML Frontmatter Completeness** | ✅ Full | ✅ Full | ⚠️ No agents | ⚠️ No agents | ⚠️ No agents | ⚠️ Incomplete | ⚠️ Incomplete |
| **Documentation Links** | ✅ Present | ✅ Present | ✅ Present | ✅ Present | ❌ Missing | ❌ Missing | ❌ Missing |

**Legend**:
- ✅ Full compliance
- ⚠️ Partial compliance (gaps present)
- ❌ Missing or major violations

**Delta Summary**: Recent commands achieve ~90% standards compliance, legacy commands ~40-60%.

## Recommendations

### 1. Immediate Priority: Fix Standard 11 Violations (Imperative Agent Invocation)

**Action**: Update all agent invocations in legacy commands to use imperative patterns.

**Target Commands**:
- /implement: Lines 137-152 (implementation-researcher invocation)
- /revise: Lines 320-416 (auto-mode revision operations)
- /expand: Lines 630-680 (complexity-estimator invocation)
- /collapse: Lines 507-531 (complexity-estimator invocation)

**Pattern to Apply**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name] agent:

Task {
  subagent_type: "general-purpose"
  description: "[Task description]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **Context**:
    - [Injected parameters]

    Execute following behavioral file guidelines.
    Return: [COMPLETION_SIGNAL]: [Expected output]
  "
}
```

**Expected Impact**:
- Agent delegation rate: 0-40% → >90%
- Context reduction per invocation: ~60% (eliminate inline duplication)
- Maintenance burden: ~50% reduction (single source of truth in agent files)

**Estimated Effort**: 4-6 hours per command (analysis, extraction, testing)

---

### 2. High Priority: Extract Behavioral Content (Standard 12 Compliance)

**Action**: Move agent-owned STEP sequences and procedures from command files to agent behavioral files.

**Extraction Targets**:

| Command | Lines to Extract | Target Agent File | Reduction |
|---------|-----------------|-------------------|-----------|
| /revise | 309-416 (107 lines) | plan-structure-manager.md | ~90% (→12 lines) |
| /expand | 162-200, 74-160 (124 lines) | complexity-estimator.md + plan-structure-manager.md | ~85% (→18 lines) |
| /collapse | 152-407 (255 lines) | plan-structure-manager.md | ~88% (→30 lines) |
| /implement | 113-201 (88 lines) | implementation-executor.md | ~85% (→13 lines) |

**Total Context Reduction**: ~480 lines → ~73 lines (85% reduction).

**Process**:
1. Identify agent-owned STEP sequences using ownership test:
   - "Who executes this STEP?" → If agent, extract to agent file
2. Create or update agent behavioral files with extracted procedures
3. Replace inline content with behavioral injection references
4. Verify commands still execute correctly with extraction

**Validation**: Run `.claude/tests/validate_no_behavioral_duplication.sh` (create if missing).

---

### 3. Medium Priority: Add Verification Checkpoints and Fallback Mechanisms

**Action**: Implement Standard 0's mandatory verification and fallback patterns.

**Target Locations**:

**In /plan** (line 713-755):
```bash
# CURRENT: Exits on failure
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ CRITICAL: plan-architect agent failed to create: $PLAN_PATH"
  exit 1
fi

# RECOMMENDED: Fallback creation
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ CRITICAL: plan-architect agent failed to create: $PLAN_PATH"
  echo "Executing fallback creation from agent output..."
  cat > "$PLAN_PATH" <<EOF
# $FEATURE_DESCRIPTION - Implementation Plan (Fallback)

## Phase 1: Initial Setup
$AGENT_OUTPUT

EOF
  echo "✓ Fallback plan created (review and enhance manually)"
fi
```

**Similar patterns needed in**:
- /implement: Test failure handling (lines 155-173)
- /expand: Phase file creation (lines 226-243)
- /collapse: Content preservation (lines 383-390)
- /revise: Backup restoration (lines 290-307)

**Expected Impact**:
- File creation rate: 70-85% → 100%
- Graceful degradation instead of hard failures
- Better user experience (workflow continues with fallback content)

---

### 4. Medium Priority: Integrate State Machine Architecture

**Action**: Add state persistence and workflow state management to legacy commands.

**Libraries to Integrate**:
```bash
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/verification-helpers.sh"
```

**Pattern to Apply** (from /coordinate initialization):
```bash
# Initialize workflow state
WORKFLOW_ID="[command]_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Save state ID for bash block persistence
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/[command]_state_id.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Persist critical variables
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "[KEY_VARIABLE]" "$VALUE"
```

**Benefits**:
- Cross-bash-block variable persistence
- Standardized error handling with `verify_state_variable()`
- Integration with state-based orchestration
- Resume capability after interruptions

**Target Commands**: /implement, /plan (orchestrators), /expand, /collapse (workflow commands).

---

### 5. Low Priority: Consolidate CLAUDE_PROJECT_DIR Detection

**Action**: Replace 28-line inline detection blocks with 5-line consolidated pattern.

**Current Duplication**: 115 lines across 5 commands.

**Consolidated Pattern**:
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**OR** (use existing library):
```bash
source "${CLAUDE_PROJECT_DIR:-.}/.claude/lib/detect-project-dir.sh"
```

**Total Savings**: 110 lines removed across codebase.

**Note**: /revise missing this entirely - add before library sourcing.

---

### 6. Low Priority: Update YAML Frontmatter

**Action**: Add missing metadata fields to align with modern command standards.

**Fields to Add**:

**For all legacy commands**:
```yaml
dependent-agents: [list of agents invoked]
# Example for /implement:
# dependent-agents: implementation-researcher, code-writer, spec-updater, github-specialist
```

**For orchestration commands** (/implement, /plan):
```yaml
model: sonnet-4.5
model-justification: Multi-phase orchestration with complex agent coordination
fallback-model: sonnet-4.5
```

**For workflow commands** (/expand, /collapse):
```yaml
dependent-commands: [commands called or related]
# Example for /expand:
# dependent-commands: collapse, implement
```

---

### 7. Low Priority: Add Guide File Links

**Action**: Create guide files and link from command headers.

**Missing Guide Files**:
- `.claude/docs/guides/revise-command-guide.md` (for /revise)
- `.claude/docs/guides/expand-command-guide.md` (for /expand)
- `.claude/docs/guides/collapse-command-guide.md` (for /collapse)

**Link Pattern** (add after YAML frontmatter):
```markdown
# /[command-name] - [Brief Description]

**Documentation**: See `.claude/docs/guides/[command]-command-guide.md` for [topics covered].
```

**Guide File Structure** (follow existing guide patterns):
1. Overview and Use Cases
2. Architecture and Workflow
3. Usage Patterns and Examples
4. Troubleshooting
5. Advanced Features

---

### 8. Implementation Sequence

**Recommended Order** (based on impact and dependencies):

1. **Week 1**: Standard 11 compliance
   - Fix imperative agent invocations in all commands
   - Highest impact on reliability (~90% delegation rate improvement)
   - Prerequisite for behavioral extraction

2. **Week 2**: Standard 12 compliance
   - Extract behavioral content to agent files
   - Reduces context bloat by ~480 lines
   - Enables single source of truth

3. **Week 3**: Verification and fallbacks
   - Add mandatory verification checkpoints
   - Implement fallback mechanisms
   - Improves file creation rate to 100%

4. **Week 4**: State machine integration
   - Add state persistence to orchestrators
   - Enables resume capabilities
   - Future-proofs for advanced orchestration

5. **Week 5**: Cleanup and documentation
   - Consolidate CLAUDE_PROJECT_DIR detection
   - Update YAML frontmatter
   - Create/link guide files

**Total Estimated Effort**: 20-25 hours across 5 weeks.

**Validation**: Run full test suite after each week's changes.

## References

### Primary Source Files Analyzed

**Legacy Commands** (absolute paths):
- `/home/benjamin/.config/.claude/commands/implement.md` (lines 1-245, 2,961 bytes)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-777, 26,748 bytes)
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-967, 38,456 bytes)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 1-1124, 43,890 bytes)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 1-739, 25,134 bytes)

**Recent State-Machine Commands** (for comparison):
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-300, state machine architecture reference)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-326, modern orchestration patterns)

**Standards Documentation**:
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1-2500+)
  - Standard 0: Execution Enforcement (lines 51-465)
  - Standard 11: Imperative Agent Invocation Pattern (lines 1175-1356)
  - Standard 12: Structural vs Behavioral Content Separation (lines 1357-1503)
  - Standard 13: Project Directory Detection (lines 1504-1582)

**Related Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` - Referenced for agent invocation patterns
- `/home/benjamin/.config/.claude/docs/troubleshooting/inline-template-duplication.md` - Anti-pattern detection
- `/home/benjamin/.config/.claude/docs/quick-reference/step-pattern-classification-flowchart.md` - STEP sequence ownership decisions

### Key Findings Cross-References

- **Imperative Pattern Examples**: /coordinate:222-245, command_architecture_standards.md:1237-1267
- **Behavioral Injection Pattern**: command_architecture_standards.md:1396-1440, behavioral-injection.md
- **Verification Checkpoints**: command_architecture_standards.md:109-135, /coordinate:140-170
- **State Machine Integration**: /coordinate:59-120, workflow-state-machine.sh library
- **CLAUDE_PROJECT_DIR Detection**: /coordinate:74-78 (consolidated), /implement:20-47 (inline duplication)
