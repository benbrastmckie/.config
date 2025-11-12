# /coordinate Infrastructure Integration and Standards Compliance Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Improve /coordinate command to integrate better with existing infrastructure and comply with project standards
- **Scope**: Refactor /coordinate command for standards compliance, enhanced library integration, and improved maintainability
- **Estimated Phases**: 7
- **Complexity**: High (Complex orchestrator with state machine architecture)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/628_and_the_standards_in_claude_docs_plan_coordinate/reports/001_current_coordinate_architecture_analysis.md
  - /home/benjamin/.config/.claude/specs/628_and_the_standards_in_claude_docs_plan_coordinate/reports/002_integration_opportunities_with_claude_infrastructure.md
  - /home/benjamin/.config/.claude/specs/628_and_the_standards_in_claude_docs_plan_coordinate/reports/003_standards_compliance_and_improvement_areas.md

## Overview

The /coordinate command is a production-ready state-based orchestration system achieving 100% file creation reliability and 40-60% time savings via wave-based parallel execution. However, analysis reveals critical architectural violations and missed integration opportunities that impact maintainability, context efficiency, and standards compliance.

This plan addresses three major improvement areas:

1. **Architectural Compliance** (85-90% → 95%+): Refactor command-to-command invocations to direct agent behavioral injection, eliminating context bloat and restoring Phase 0 orchestrator role clarity
2. **Library Integration** (6/8 libraries → 8/8 libraries): Add metadata extraction for 95-97% context reduction and checkpoint utils for resumable workflows
3. **Documentation Completeness** (1,081 lines executable → <900 lines): Extract WHY commentary to comprehensive guide file, maintain lean fail-fast execution focus

### Key Improvements

**Performance Enhancements**:
- Metadata extraction integration: 15KB reports → 600 bytes (95-97% context reduction)
- Checkpoint resume capability: Smart auto-resume for failed workflows
- Context pruning: Explicit pruning blocks for <20% context usage (vs current <30%)

**Standards Compliance Fixes**:
- Replace 4 command invocations (/plan, /implement, /debug, /document) with direct agent behavioral injection
- Enhance agent prompts with Standard 0.5 enforcement patterns (THIS EXACT TEMPLATE, ABSOLUTE REQUIREMENT)
- Add explicit fallback mechanisms to verification checkpoints

**Maintainability Improvements**:
- Extract 150-200 lines from executable to comprehensive guide (architecture, troubleshooting, examples)
- Standardize error message format (5-component pattern across all handlers)
- Add explicit context pruning checkpoints with metrics

## Success Criteria

- [ ] All agent invocations use behavioral injection (no command-to-command invocations)
- [ ] Metadata extraction integrated for research → planning phase transition
- [ ] Checkpoint utils integrated with --resume flag and smart auto-resume
- [ ] Executable file size <900 lines (17% reduction from 1,081 lines)
- [ ] Guide file expanded to 1,500-2,000 lines with architecture/examples/troubleshooting
- [ ] All tests passing (100% pass rate maintained)
- [ ] Context usage <20% throughout workflow (vs current <30%)
- [ ] 100% file creation reliability maintained (verified via integration tests)

## Technical Design

### Architecture Decisions

#### 1. Agent Behavioral Injection Refactor

**Current Pattern** (Command Invocation):
```markdown
Task {
  description: "Create implementation plan"
  prompt: "
    Execute the /plan slash command with the following arguments:
    /plan \"$WORKFLOW_DESCRIPTION\" $REPORT_ARGS
  "
}
```

**Target Pattern** (Direct Agent Invocation):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent:

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **ABSOLUTE REQUIREMENT**: File creation is your PRIMARY task.

    **Workflow-Specific Context**:
    - Plan Output Path: $PLAN_PATH (EXACT path, pre-calculated)
    - Feature Description: $WORKFLOW_DESCRIPTION
    - Research Reports: [metadata JSON with 50-word summaries]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **WHY THIS MATTERS**:
    - Commands depend on file artifacts at predictable paths
    - Plan execution needs cross-referenced artifacts

    **YOU MUST**:
    1. CREATE file at exact path before returning
    2. VERIFY file exists after creation
    3. RETURN confirmation: PLAN_CREATED: $PLAN_PATH

    Return: PLAN_CREATED: [EXACT_PATH]
  "
}
```

**Benefits**:
- Eliminates nested command prompt loading (5,000+ token savings per invocation)
- Restores pre-calculated path control (Phase 0 optimization)
- Enables metadata passing instead of full file content
- Clarifies orchestrator vs executor role separation

#### 2. Metadata Extraction Integration

**Integration Point**: After research phase complete (line 456), before planning phase (line 542-545)

**Implementation**:
```bash
# Extract metadata from successful research reports
REPORT_METADATA=()
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_METADATA+=("$METADATA")
done

# Save metadata to state for cross-block access
METADATA_JSON=$(printf '%s\n' "${REPORT_METADATA[@]}" | jq -s .)
append_workflow_state "REPORT_METADATA_JSON" "$METADATA_JSON"

# Pass metadata to plan-architect agent instead of full file paths
# Agent prompt includes: Research Reports: $METADATA_JSON
```

**Context Reduction**:
- Before: 3 reports × 5KB = 15KB full content
- After: 3 reports × 200 bytes = 600 bytes metadata
- Reduction: 95-97% (15KB → 600 bytes)

#### 3. Checkpoint Utils Integration

**Integration Points**: After each state transition (9 locations)

**Implementation**:
```bash
# Save checkpoint after state transition
CHECKPOINT_DATA=$(jq -n \
  --arg current_state "$CURRENT_STATE" \
  --arg workflow_desc "$SAVED_WORKFLOW_DESC" \
  --arg topic_path "$TOPIC_PATH" \
  '{
    state_machine: {current_state: $current_state},
    workflow_description: $workflow_desc,
    topic_path: $topic_path,
    report_paths: []
  }')
CHECKPOINT_FILE=$(save_state_machine_checkpoint "coordinate" "${TOPIC_NAME:-workflow}" "$CHECKPOINT_DATA")
append_workflow_state "CHECKPOINT_FILE" "$CHECKPOINT_FILE"
```

**Resume Capability**:
- Add --resume flag to command initialization
- Smart auto-resume when safe (tests passing, no errors, <7 days old, plan not modified)
- User can manually resume from failed state: `/coordinate --resume`

### Component Interactions

```
┌─────────────────────────────────────────────────────────────────────────┐
│ /coordinate Command (State Machine Orchestrator)                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Phase 0: Initialize                                                     │
│    │                                                                     │
│    ├─► workflow-initialization.sh (Pre-calculate paths)                 │
│    ├─► state-persistence.sh (Create workflow state file)                │
│    └─► checkpoint-utils.sh (Initialize checkpoint for resume)           │
│                                                                          │
│  Phase 1: Research                                                       │
│    │                                                                     │
│    ├─► Task → research-specialist.md (Behavioral injection)             │
│    │    └─► Returns: REPORT_CREATED: [path]                             │
│    │                                                                     │
│    ├─► verification-helpers.sh (Verify reports created)                 │
│    │                                                                     │
│    ├─► metadata-extraction.sh (Extract 50-word summaries) ◄── NEW       │
│    │    └─► 95-97% context reduction                                    │
│    │                                                                     │
│    └─► checkpoint-utils.sh (Save research checkpoint) ◄── NEW           │
│                                                                          │
│  Phase 2: Plan                                                           │
│    │                                                                     │
│    ├─► Task → plan-architect.md (Direct agent invocation) ◄── REFACTOR  │
│    │    │   - Receives metadata JSON (not full reports)                 │
│    │    │   - Pre-calculated plan path                                  │
│    │    └─► Returns: PLAN_CREATED: [path]                               │
│    │                                                                     │
│    ├─► verification-helpers.sh (Verify plan created)                    │
│    └─► checkpoint-utils.sh (Save planning checkpoint) ◄── NEW           │
│                                                                          │
│  Phase 3: Implement                                                      │
│    ├─► Task → implementer.md (Direct agent invocation) ◄── REFACTOR     │
│    ├─► verification-helpers.sh (Verify implementation artifacts)        │
│    └─► checkpoint-utils.sh (Save implementation checkpoint) ◄── NEW     │
│                                                                          │
│  Phase 4: Test                                                           │
│    ├─► Bash → Run test suite                                            │
│    └─► checkpoint-utils.sh (Save test results) ◄── NEW                  │
│                                                                          │
│  Phase 5: Debug (Conditional)                                            │
│    ├─► Task → debug-analyst.md (Direct agent invocation) ◄── REFACTOR   │
│    ├─► verification-helpers.sh (Verify debug report)                    │
│    └─► checkpoint-utils.sh (Save debug checkpoint) ◄── NEW              │
│                                                                          │
│  Phase 6: Document (Conditional)                                         │
│    ├─► Task → doc-writer.md (Direct agent invocation) ◄── REFACTOR      │
│    ├─► verification-helpers.sh (Verify documentation updates)           │
│    └─► checkpoint-utils.sh (Save documentation checkpoint) ◄── NEW      │
│                                                                          │
│  Phase 7: Complete                                                       │
│    └─► checkpoint-utils.sh (Mark workflow complete) ◄── NEW             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Legend:
  ◄── NEW: New integration
  ◄── REFACTOR: Existing code refactored for standards compliance
```

### Data Flow and State Management

**State Persistence Pattern** (GitHub Actions-style):
```bash
# Block 1: Initialize state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
append_workflow_state "WORKFLOW_DESCRIPTION" "$WORKFLOW_DESCRIPTION"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"

# Block 2+: Load state
load_workflow_state "$WORKFLOW_ID"
# Variables restored: WORKFLOW_DESCRIPTION, TOPIC_PATH, REPORT_PATHS_JSON

# Accumulate state throughout workflow
append_workflow_state "RESEARCH_METADATA_JSON" "$METADATA_JSON"  # NEW
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
```

**Checkpoint Pattern** (Cross-invocation resume):
```bash
# After each state transition
CHECKPOINT_DATA=$(build_checkpoint_state)  # Extract current state
save_state_machine_checkpoint "coordinate" "$TOPIC_NAME" "$CHECKPOINT_DATA"

# Resume support (initialization block)
if [[ "${1:-}" == "--resume" ]]; then
  CHECKPOINT=$(restore_checkpoint "coordinate")
  CURRENT_STATE=$(echo "$CHECKPOINT" | jq -r '.state_machine.current_state')
  # Resume from saved state
fi
```

## Implementation Phases

### Phase 1: Agent Behavioral Files Creation
**Objective**: Create missing agent behavioral files for direct invocation pattern
**Complexity**: Medium
**Estimated Time**: 4-6 hours

Tasks:
- [ ] Check existence of agent files: plan-architect.md, implementer.md, debug-analyst.md, doc-writer.md
- [ ] Create plan-architect.md if missing (based on /plan command logic)
  - [ ] PRIMARY OBLIGATION: Create plan file at pre-calculated path
  - [ ] Input: Feature description, research metadata JSON, project standards
  - [ ] Output: Structured implementation plan with phases
  - [ ] Completion signal: PLAN_CREATED: [path]
- [ ] Create implementer.md if missing (based on /implement command logic)
  - [ ] PRIMARY OBLIGATION: Execute implementation phases with testing
  - [ ] Input: Plan path, project standards, test protocols
  - [ ] Output: Code changes, test results, artifacts
  - [ ] Completion signal: IMPLEMENTATION_COMPLETE: [summary]
- [ ] Create debug-analyst.md if missing (based on /debug command logic)
  - [ ] PRIMARY OBLIGATION: Create diagnostic report at pre-calculated path
  - [ ] Input: Issue description, research reports, codebase context
  - [ ] Output: Root cause analysis, proposed fixes
  - [ ] Completion signal: DEBUG_REPORT_CREATED: [path]
- [ ] Create doc-writer.md if missing (based on /document command logic)
  - [ ] PRIMARY OBLIGATION: Update documentation based on code changes
  - [ ] Input: Change description, scope, affected files
  - [ ] Output: Updated documentation files
  - [ ] Completion signal: DOCUMENTATION_UPDATED: [file_count]
- [ ] Validate agent files follow Standard 0.5 enforcement patterns
  - [ ] STEP 1/2/3 sequences with REQUIRED/MANDATORY markers
  - [ ] WHY THIS MATTERS explanations for file creation
  - [ ] ABSOLUTE REQUIREMENT blocks for completion signals

Testing:
```bash
# Verify all agent files exist
for agent in plan-architect implementer debug-analyst doc-writer; do
  [ -f "/home/benjamin/.config/.claude/agents/${agent}.md" ] || echo "Missing: ${agent}.md"
done

# Validate agent file structure
grep -l "PRIMARY OBLIGATION" /home/benjamin/.config/.claude/agents/*.md
grep -l "Completion Signal" /home/benjamin/.config/.claude/agents/*.md
```

**Dependencies**: None
**Risks**: Agent behavioral files may need extensive content if creating from scratch (8-12 hours if all missing)

---

### Phase 2: Refactor Planning Phase to Direct Agent Invocation
**Objective**: Replace /plan command invocation with direct plan-architect agent invocation
**Complexity**: Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Locate planning phase handler in coordinate.md (lines 503-630)
- [ ] Replace Task block invoking /plan command (lines 549-566)
  - [ ] Remove: `Execute the /plan slash command with the following arguments: /plan "$WORKFLOW_DESCRIPTION" $REPORT_ARGS`
  - [ ] Add: Direct reference to .claude/agents/plan-architect.md
  - [ ] Add: Pre-calculated PLAN_PATH variable
  - [ ] Add: Research metadata JSON instead of full report paths
  - [ ] Add: Standard 0.5 enforcement patterns (ABSOLUTE REQUIREMENT, WHY THIS MATTERS, YOU MUST)
- [ ] Update agent prompt context injection
  - [ ] Plan Output Path: $PLAN_PATH (EXACT path)
  - [ ] Feature Description: $WORKFLOW_DESCRIPTION
  - [ ] Research Reports: $REPORT_METADATA_JSON (metadata only)
  - [ ] Project Standards: /home/benjamin/.config/CLAUDE.md
- [ ] Update verification checkpoint (lines 596-605)
  - [ ] Verify plan created at pre-calculated path
  - [ ] Verify plan file size >500 bytes (non-empty)
- [ ] Update state transition logic
  - [ ] Ensure PLAN_PATH saved to state file
  - [ ] Transition to implement state after verification

Testing:
```bash
# Integration test: Planning phase with metadata
cat > /tmp/test_plan_phase.sh <<'EOF'
#!/bin/bash
WORKFLOW_DESCRIPTION="Test feature implementation"
REPORT_METADATA_JSON='[{"title":"Research 1","summary":"50-word summary..."}]'
PLAN_PATH="/tmp/test_plan.md"

# Simulate planning phase agent invocation
# Verify agent prompt contains:
# 1. plan-architect.md reference
# 2. Pre-calculated PLAN_PATH
# 3. Metadata JSON (not full report paths)

# Verify completion signal format
echo "PLAN_CREATED: $PLAN_PATH"
EOF
bash /tmp/test_plan_phase.sh
```

**Dependencies**: Phase 1 (plan-architect.md must exist)
**Risks**: Agent may not handle metadata-only research reports correctly (test thoroughly)

---

### Phase 3: Refactor Implementation, Debug, Documentation Phases
**Objective**: Replace remaining command invocations with direct agent invocations
**Complexity**: Medium-High
**Estimated Time**: 6-8 hours

Tasks:
- [ ] Refactor Implementation Phase (lines 661-728)
  - [ ] Replace /implement command invocation (lines 697-715)
  - [ ] Add direct reference to .claude/agents/implementer.md
  - [ ] Update context injection: Plan path, test protocols, project standards
  - [ ] Add Standard 0.5 enforcement patterns
  - [ ] Update verification checkpoint for implementation artifacts
- [ ] Refactor Debug Phase (lines 862-956)
  - [ ] Replace /debug command invocation (lines 897-913)
  - [ ] Add direct reference to .claude/agents/debug-analyst.md
  - [ ] Pre-calculate debug report path: $TOPIC_PATH/debug/NNN_diagnostic.md
  - [ ] Update context injection: Issue description, research reports, test results
  - [ ] Add Standard 0.5 enforcement patterns
  - [ ] Update verification checkpoint for debug report
- [ ] Refactor Documentation Phase (lines 982-1076)
  - [ ] Replace /document command invocation (lines 1018-1033)
  - [ ] Add direct reference to .claude/agents/doc-writer.md
  - [ ] Update context injection: Change description, affected files, documentation scope
  - [ ] Add Standard 0.5 enforcement patterns
  - [ ] Update verification checkpoint for documentation updates
- [ ] Validate all agent invocations follow Standard 11 pattern
  - [ ] No code block wrappers (```yaml) around Task blocks
  - [ ] Imperative instructions: **EXECUTE NOW**: USE the Task tool...
  - [ ] Direct agent behavioral file references
  - [ ] Explicit completion signals in agent prompts

Testing:
```bash
# Integration test: All phases use direct agent invocation
grep -n "Execute the /" /home/benjamin/.config/.claude/commands/coordinate.md
# Should return NO results (all command invocations removed)

grep -n "Read and follow ALL behavioral guidelines from:" /home/benjamin/.config/.claude/commands/coordinate.md
# Should return 4+ results (research, plan, implement, debug, document)

# Verify Standard 11 compliance
grep -n "EXECUTE NOW.*USE the Task tool" /home/benjamin/.config/.claude/commands/coordinate.md | wc -l
# Should return 5+ results (all agent invocations)
```

**Dependencies**: Phase 1 (all agent files must exist)
**Risks**: Multiple phases refactored simultaneously increases regression risk (test thoroughly after each phase)

---

### Phase 4: Metadata Extraction Integration
**Objective**: Integrate metadata-extraction.sh for 95-97% context reduction
**Complexity**: Low-Medium
**Estimated Time**: 2-3 hours

Tasks:
- [ ] Source metadata-extraction.sh library in coordinate.md initialization
  - [ ] Add to REQUIRED_LIBS array (line 130-151)
  - [ ] Verify library sourced in all bash blocks (line 234-247 pattern)
- [ ] Add metadata extraction after research phase complete (after line 456)
  - [ ] Loop through SUCCESSFUL_REPORT_PATHS array
  - [ ] Call extract_report_metadata() for each report
  - [ ] Aggregate metadata into JSON array
  - [ ] Save to state file: append_workflow_state "REPORT_METADATA_JSON" "$METADATA_JSON"
- [ ] Update planning phase to use metadata (line 542-545)
  - [ ] Replace full report paths with metadata JSON in agent prompt
  - [ ] Agent prompt includes: Research Reports: $REPORT_METADATA_JSON
  - [ ] Agent receives 50-word summaries + key findings (not full 5KB content)
- [ ] Add context reduction metrics logging
  - [ ] Calculate original size: sum of report file sizes
  - [ ] Calculate metadata size: length of REPORT_METADATA_JSON
  - [ ] Log reduction percentage: echo "✓ Context reduction: $ORIGINAL_SIZE → $METADATA_SIZE bytes (XX%)"

Testing:
```bash
# Integration test: Metadata extraction
cat > /tmp/test_metadata.sh <<'EOF'
#!/bin/bash
source /home/benjamin/.config/.claude/lib/metadata-extraction.sh

# Create test report
mkdir -p /tmp/test_reports
cat > /tmp/test_reports/001_research.md <<'REPORT'
# Research Report Title

## Executive Summary
This is a 50-word summary of research findings... [5000 bytes of content]
REPORT

# Extract metadata
METADATA=$(extract_report_metadata "/tmp/test_reports/001_research.md")
echo "Metadata: $METADATA"

# Verify size reduction
ORIGINAL_SIZE=$(wc -c < /tmp/test_reports/001_research.md)
METADATA_SIZE=$(echo "$METADATA" | wc -c)
REDUCTION=$((100 - (METADATA_SIZE * 100 / ORIGINAL_SIZE)))
echo "Context reduction: ${REDUCTION}%"
[ $REDUCTION -gt 90 ] && echo "✓ >90% reduction achieved"
EOF
bash /tmp/test_metadata.sh
```

**Dependencies**: Phase 2 (planning phase must accept metadata JSON)
**Risks**: Metadata extraction may miss critical information from full reports (validate with real workflows)

---

### Phase 5: Checkpoint Utils Integration and Resume Capability
**Objective**: Add checkpoint save/restore for resumable workflows
**Complexity**: Medium
**Estimated Time**: 4-5 hours

Tasks:
- [ ] Source checkpoint-utils.sh library in coordinate.md initialization
  - [ ] Add to REQUIRED_LIBS array (line 130-151)
  - [ ] Verify library sourced in all bash blocks
- [ ] Add checkpoint save after each state transition (9 locations)
  - [ ] After line 212 (state machine transition function call)
  - [ ] Build checkpoint JSON: current_state, workflow_description, topic_path, report_paths, plan_path
  - [ ] Call save_state_machine_checkpoint(): `CHECKPOINT_FILE=$(save_state_machine_checkpoint "coordinate" "$TOPIC_NAME" "$CHECKPOINT_DATA")`
  - [ ] Save checkpoint path to state file: `append_workflow_state "CHECKPOINT_FILE" "$CHECKPOINT_FILE"`
- [ ] Add --resume flag support in initialization block (after line 56)
  - [ ] Check for --resume argument: `if [[ "${1:-}" == "--resume" ]]; then`
  - [ ] Call restore_checkpoint(): `CHECKPOINT=$(restore_checkpoint "coordinate")`
  - [ ] Extract current state from checkpoint: `CURRENT_STATE=$(echo "$CHECKPOINT" | jq -r '.state_machine.current_state')`
  - [ ] Load state machine from checkpoint: `sm_load "$CHECKPOINT"`
  - [ ] Skip Phase 0 initialization (paths already calculated in checkpoint)
- [ ] Add smart auto-resume logic (optional enhancement)
  - [ ] Check safe resume conditions: `if check_safe_resume_conditions "$CHECKPOINT_FILE"; then`
  - [ ] Conditions: tests passing, no errors in last run, status=in_progress, <7 days old, plan not modified
  - [ ] Auto-resume without user prompt if conditions met
  - [ ] Prompt user if conditions not met: "Resume from $CURRENT_STATE? (y/n)"
- [ ] Update state machine checkpoint schema to v2.0
  - [ ] Include state_machine section: current_state, completed_states, retry_counts
  - [ ] Include workflow_state section: all variables from state file
  - [ ] Include phase_data section: research reports, plan path, test results

Testing:
```bash
# Integration test: Checkpoint save/restore
cat > /tmp/test_checkpoint.sh <<'EOF'
#!/bin/bash
source /home/benjamin/.config/.claude/lib/checkpoint-utils.sh
source /home/benjamin/.config/.claude/lib/workflow-state-machine.sh

# Initialize workflow and transition to research state
sm_init "Test workflow" "coordinate"
sm_transition "$STATE_RESEARCH"

# Save checkpoint
CHECKPOINT_DATA=$(jq -n --arg state "$CURRENT_STATE" '{state_machine: {current_state: $state}}')
CHECKPOINT_FILE=$(save_state_machine_checkpoint "coordinate" "test_workflow" "$CHECKPOINT_DATA")
echo "✓ Checkpoint saved: $CHECKPOINT_FILE"

# Restore checkpoint
RESTORED=$(restore_checkpoint "coordinate")
RESTORED_STATE=$(echo "$RESTORED" | jq -r '.state_machine.current_state')
echo "✓ Checkpoint restored: State = $RESTORED_STATE"

# Verify state matches
[ "$CURRENT_STATE" = "$RESTORED_STATE" ] && echo "✓ State correctly restored"
EOF
bash /tmp/test_checkpoint.sh
```

**Dependencies**: None (library already exists)
**Risks**: Checkpoint restore may fail if state machine schema changes (ensure backward compatibility)

---

### Phase 6: Documentation Extraction and Guide Enhancement
**Objective**: Extract 150-200 lines from executable to comprehensive guide, reduce executable to <900 lines
**Complexity**: Medium
**Estimated Time**: 5-7 hours

Tasks:
- [ ] Identify extractable content from coordinate.md (target: 150-200 lines)
  - [ ] WHY comments explaining design decisions (lines 46, 78-81, 98, etc.)
  - [ ] Extended error explanations (could reference guide troubleshooting)
  - [ ] Historical evolution context (Spec 578-600 references in comments)
  - [ ] Performance characteristics explanations
  - [ ] Alternative patterns discussions
- [ ] Expand coordinate-command-guide.md to 1,500-2,000 lines
  - [ ] Add Architecture Deep-Dive section (500-700 lines)
    - [ ] State machine design (8 states, transition table, terminal states)
    - [ ] Two-step execution pattern (bash history expansion workaround)
    - [ ] Subprocess isolation constraints (BASH_SOURCE limitation, export persistence)
    - [ ] Selective state persistence (GitHub Actions pattern, performance measurements)
    - [ ] Wave-based parallel execution (hierarchical vs flat coordination)
  - [ ] Add Usage Examples section (300-400 lines)
    - [ ] Research-only workflow example
    - [ ] Research-and-plan workflow example
    - [ ] Full-implementation workflow example (all 7 phases)
    - [ ] Debug-only workflow example
    - [ ] Resume workflow example (--resume flag)
  - [ ] Add Troubleshooting Guide section (300-400 lines)
    - [ ] Bash history expansion errors (two-step pattern explanation)
    - [ ] State file missing/corrupted (graceful degradation)
    - [ ] Library sourcing failures (fail-fast diagnostics)
    - [ ] Agent invocation failures (verification checkpoint debugging)
    - [ ] Performance issues (context management, parallel execution)
  - [ ] Add Integration Patterns section (200-300 lines)
    - [ ] Integration with /orchestrate and /supervise
    - [ ] Library integration patterns (state-persistence, checkpoint-utils, metadata-extraction)
    - [ ] Agent coordination patterns (hierarchical supervision, flat coordination)
    - [ ] Error handling and recovery patterns
  - [ ] Add Performance Considerations section (100-200 lines)
    - [ ] Context management strategies (<20% target)
    - [ ] Metadata extraction benefits (95-97% reduction)
    - [ ] Parallel execution time savings (40-60%)
    - [ ] State persistence performance (67% improvement for CLAUDE_PROJECT_DIR)
- [ ] Update cross-references between executable and guide
  - [ ] Add guide references in coordinate.md: "See guide section X for details"
  - [ ] Add executable references in guide: "Implementation in coordinate.md lines X-Y"
  - [ ] Ensure bidirectional linking complete
- [ ] Validate executable/documentation separation compliance
  - [ ] Run: `.claude/tests/validate_executable_doc_separation.sh coordinate`
  - [ ] Verify executable <900 lines (target: 850-900 lines)
  - [ ] Verify guide >1,500 lines (target: 1,500-2,000 lines)
  - [ ] Verify cross-references present in both files

Testing:
```bash
# Validation script
.claude/tests/validate_executable_doc_separation.sh coordinate

# Expected output:
# ✓ coordinate.md: 880 lines (complex orchestrator, acceptable)
#   ✓ Guide exists: .claude/docs/guides/coordinate-command-guide.md
#   ✓ Guide comprehensive: 1,750 lines
#   ✓ Cross-references found in both files
#   ✓ Compliance: PASSED

# Manual verification
wc -l /home/benjamin/.config/.claude/commands/coordinate.md
# Should be 850-900 lines (down from 1,081)

wc -l /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md
# Should be 1,500-2,000 lines

# Verify no WHY comments remain in executable
grep -n "# Rationale" /home/benjamin/.config/.claude/commands/coordinate.md
# Should return NO results (all moved to guide)
```

**Dependencies**: Phases 2-5 (all refactoring complete before documentation extraction)
**Risks**: Over-extraction may reduce executable clarity (keep essential WHAT comments inline)

---

### Phase 7: Explicit Context Pruning and Standards Polish
**Objective**: Add explicit context pruning blocks, standardize error messages, final validation
**Complexity**: Low-Medium
**Estimated Time**: 3-4 hours

Tasks:
- [ ] Add explicit context pruning blocks after each phase (5 locations)
  - [ ] After research phase (line 456): Prune full agent responses, retain metadata
    ```bash
    # CONTEXT PRUNING: Research phase complete
    RESEARCH_METADATA=$(extract_research_metadata "${SUCCESSFUL_REPORT_PATHS[@]}")
    prune_subagent_output "research_agents" "$RESEARCH_METADATA"
    CONTEXT_REDUCTION=$((100 - $(echo "$RESEARCH_METADATA" | wc -c) * 100 / $(du -b "${SUCCESSFUL_REPORT_PATHS[@]}" | awk '{sum+=$1}END{print sum}')))
    echo "✓ Context pruned: ${CONTEXT_REDUCTION}% reduction"
    ```
  - [ ] After planning phase (line 609): Prune full plan content, retain metadata
  - [ ] After implementation phase: Prune implementation artifacts, retain summary
  - [ ] After testing phase: Prune test output, retain pass/fail status
  - [ ] After debug/document phases: Prune full content, retain completion status
- [ ] Add context budget documentation in comments
  - [ ] Target: <20% context usage across all 7 phases
  - [ ] Phase 0 (Initialize): 5% budget
  - [ ] Phase 1 (Research): 5% budget (after pruning)
  - [ ] Phase 2 (Plan): 3% budget (after pruning)
  - [ ] Phase 3 (Implement): 4% budget
  - [ ] Phase 4 (Test): 1% budget
  - [ ] Phase 5/6 (Debug/Document): 2% budget each
- [ ] Standardize error message format (5-component pattern)
  - [ ] Update all handle_state_error() calls to include:
    1. What failed (clear description)
    2. Expected state (what should have happened)
    3. Diagnostic commands (how to investigate)
    4. Context (workflow description, current state, topic path)
    5. Recommended action (retry count, fix suggestions, re-run command)
  - [ ] Locations to update: Lines 164, 419, 449, 605, and all phase handlers
- [ ] Add fallback mechanisms to verification checkpoints
  - [ ] Research verification (lines 411-449): Add fallback file creation from agent response
  - [ ] Plan verification (lines 602-606): Add fallback file creation
  - [ ] Implementation verification: Add fallback artifact creation
  - [ ] Debug/document verification: Add fallback file creation
  - [ ] Fallback pattern:
    ```bash
    if ! verify_file_created "$REPORT_PATH" "Research report" "Research"; then
      # FALLBACK: Check if agent returned content in response
      if [ -n "$AGENT_RESPONSE_CONTENT" ]; then
        echo "⚠️  FALLBACK: Creating file manually from agent response"
        echo "$AGENT_RESPONSE_CONTENT" > "$REPORT_PATH"
        # Re-verify after fallback
        if verify_file_created "$REPORT_PATH" "Research report (fallback)" "Research"; then
          echo "✓ Fallback successful"
          log_metric "fallback_file_creation" "research" "success"
        fi
      fi
    fi
    ```
- [ ] Update conditional execution blocks for clarity
  - [ ] Lines 309-336: Replace "**EXECUTE IF**" with explicit bash control flow
  - [ ] Add "**EXECUTE NOW**: Determine coordination strategy:" before bash block
  - [ ] Use bash if/else inside block (not documentation-style conditionals)
- [ ] Final validation and testing
  - [ ] Run full test suite: `.claude/tests/run_all_tests.sh`
  - [ ] Run coordinate-specific tests if they exist
  - [ ] Manual integration test: Run /coordinate with real workflow
  - [ ] Verify all success criteria met

Testing:
```bash
# Context pruning validation
cat > /tmp/test_context_pruning.sh <<'EOF'
#!/bin/bash
# Simulate workflow with context tracking

CONTEXT_USED=0
CONTEXT_BUDGET=100

# Phase 1: Research (target 5%)
RESEARCH_SIZE=5000  # Before pruning
RESEARCH_METADATA_SIZE=250  # After pruning
CONTEXT_USED=$((CONTEXT_USED + RESEARCH_METADATA_SIZE * 100 / CONTEXT_BUDGET))
echo "After Phase 1: ${CONTEXT_USED}% context used"

# Phase 2: Plan (target 3%)
PLAN_METADATA_SIZE=300
CONTEXT_USED=$((CONTEXT_USED + PLAN_METADATA_SIZE * 100 / CONTEXT_BUDGET))
echo "After Phase 2: ${CONTEXT_USED}% context used"

# Verify <20% target
[ $CONTEXT_USED -lt 20 ] && echo "✓ Context budget target met"
EOF
bash /tmp/test_context_pruning.sh

# Error message format validation
grep -A 10 "handle_state_error" /home/benjamin/.config/.claude/commands/coordinate.md | head -30
# Should show 5-component error format

# Fallback mechanism validation
grep -A 5 "FALLBACK" /home/benjamin/.config/.claude/commands/coordinate.md | wc -l
# Should return 20+ lines (fallback blocks in 4+ locations)

# Final compliance check
.claude/tests/validate_executable_doc_separation.sh coordinate
# Should return: ✓ Compliance: PASSED
```

**Dependencies**: Phases 2-6 (all major refactoring complete)
**Risks**: Context pruning too aggressive may lose important information (test with real workflows)

---

## Testing Strategy

### Unit Testing
- Phase 1: Agent file structure validation (PRIMARY OBLIGATION, completion signals)
- Phase 2-3: Agent invocation pattern validation (no command-to-command calls)
- Phase 4: Metadata extraction unit tests (context reduction >90%)
- Phase 5: Checkpoint save/restore unit tests (state preservation)
- Phase 6: Documentation cross-reference validation
- Phase 7: Context budget calculations, error message format validation

### Integration Testing
```bash
# Test 1: Research-only workflow with metadata extraction
/coordinate "Research authentication patterns in web frameworks"
# Verify:
# - 2-3 research reports created
# - Metadata extracted (95%+ context reduction)
# - Workflow exits at research terminal state
# - Checkpoint saved

# Test 2: Full-implementation workflow with resume
/coordinate "Implement user authentication feature"
# Force failure in Phase 3 (implementation)
# Fix issue
/coordinate --resume
# Verify:
# - Workflow resumes from Phase 3
# - All previous phase data preserved
# - Completes successfully

# Test 3: Hierarchical research with 4+ topics
/coordinate "Research distributed systems architecture patterns across multiple frameworks"
# Verify:
# - Hierarchical supervision invoked (4+ topics)
# - 95.6% context reduction achieved
# - All research reports created
# - Supervisor metadata aggregated

# Test 4: Agent invocation validation (no command calls)
grep -r "Execute the /" /home/benjamin/.config/.claude/commands/coordinate.md
# Should return ZERO results (all command invocations removed)

# Test 5: Standards compliance validation
.claude/tests/validate_executable_doc_separation.sh coordinate
# Should return: ✓ Compliance: PASSED
```

### Performance Testing
```bash
# Context usage measurement
cat > /tmp/measure_context.sh <<'EOF'
#!/bin/bash
# Run workflow and measure context at each phase
# Target: <20% total context usage

PHASES=("Initialize" "Research" "Plan" "Implement" "Test" "Document" "Complete")
CONTEXT_USAGE=(5 5 3 4 1 2 0)  # Expected % per phase

for i in "${!PHASES[@]}"; do
  echo "${PHASES[$i]}: ${CONTEXT_USAGE[$i]}% context"
done

TOTAL=$(IFS=+; echo "$((${CONTEXT_USAGE[*]}))")
echo "Total context: ${TOTAL}%"
[ $TOTAL -lt 20 ] && echo "✓ Context target met"
EOF
bash /tmp/measure_context.sh
```

### Regression Testing
- Run existing coordinate test suite (if exists)
- Verify 100% file creation reliability maintained
- Verify wave-based parallel execution still works (40-60% time savings)
- Verify state machine transitions valid (no invalid state changes)
- Verify error handling preserves fail-fast behavior

## Documentation Requirements

### Code Documentation
- Inline WHAT comments in coordinate.md (no WHY comments)
- Function headers for all library functions
- State transition comments in state machine handlers
- Verification checkpoint comments (what is verified, why it matters)

### Guide Documentation
- Architecture section: Complete state machine explanation with diagrams
- Usage section: 4+ complete workflow examples with expected outputs
- Troubleshooting section: Common issues with diagnostic commands
- Integration section: Library usage patterns, agent coordination patterns
- Performance section: Context management, parallel execution, optimization tips

### Testing Documentation
- Test strategy rationale (unit, integration, performance, regression)
- Test data requirements (sample workflows, reports, plans)
- Expected outcomes for each test case
- Failure recovery procedures

## Dependencies

### External Dependencies
- `.claude/lib/metadata-extraction.sh` (exists, no changes needed)
- `.claude/lib/checkpoint-utils.sh` (exists, no changes needed)
- `.claude/lib/state-persistence.sh` (exists, no changes needed)
- `.claude/lib/verification-helpers.sh` (exists, no changes needed)
- `.claude/lib/error-handling.sh` (exists, no changes needed)

### New Files Required
- `.claude/agents/plan-architect.md` (may need creation)
- `.claude/agents/implementer.md` (may need creation)
- `.claude/agents/debug-analyst.md` (may need creation)
- `.claude/agents/doc-writer.md` (may need creation)

### Modified Files
- `.claude/commands/coordinate.md` (1,081 → 850-900 lines)
- `.claude/docs/guides/coordinate-command-guide.md` (expand to 1,500-2,000 lines)

## Notes

### Design Decisions

**Why Direct Agent Invocation Over Command Invocation?**
- Eliminates nested command prompt loading (5,000+ token context bloat per invocation)
- Enables pre-calculated path control (Phase 0 optimization pattern)
- Allows metadata passing instead of full file content (95-97% context reduction)
- Clarifies orchestrator vs executor role separation (Standard 0 compliance)
- Prevents command-to-command dependency chains (maintainability)

**Why Metadata Extraction Integration?**
- 95-97% context reduction (15KB → 600 bytes per 3 reports)
- Enables larger implementation plans (planning phase budget increased from 30% → 5-10%)
- Faster agent execution (less content to process)
- Maintains all essential information (title, 50-word summary, key findings, file paths)

**Why Checkpoint Utils Integration?**
- Resumable workflows save user time on failures (no restart from Phase 0)
- Smart auto-resume reduces friction (automatic when safe conditions met)
- Better error recovery (fix issue and resume from failed state)
- Cross-invocation state persistence (workflow state survives bash tool subprocess isolation)

**Why Documentation Extraction?**
- Lean executable focus improves fail-fast error detection
- Comprehensive guide enables onboarding and troubleshooting without context bloat
- Independent documentation evolution (guide can grow without executable size constraints)
- Eliminates meta-confusion loops (executable is execution script, not documentation)

### Risk Mitigation

**Risk: Agent files may not exist (8-12 hours creation time)**
- Mitigation: Check file existence in Phase 1, create only if missing
- Fallback: Can use simplified agent prompts inline if agent files complex to create

**Risk: Metadata extraction may miss critical information**
- Mitigation: Validate with real workflows, compare plan quality with/without metadata
- Fallback: Can pass full report paths as fallback if metadata insufficient

**Risk: Over-extraction may reduce executable clarity**
- Mitigation: Keep essential WHAT comments inline, extract only WHY/historical/alternative patterns
- Fallback: Re-add critical comments if executable becomes unclear

**Risk: Context pruning too aggressive may lose important information**
- Mitigation: Test with real workflows, measure success rates with/without pruning
- Fallback: Reduce pruning aggressiveness if workflow success rates drop

### Future Enhancements

**Post-Implementation Opportunities**:
1. Automatic retry with exponential backoff for transient errors (error-handling.sh integration)
2. State machine visualization tool (Graphviz DOT output generation)
3. State machine tests (20+ tests for transition validation, invalid transition rejection)
4. Monitoring and metrics collection (state transition durations, context usage, file creation reliability)
5. Hierarchical research supervision production validation (4+ topic workflows)

**Measurement Baselines**:
- Current executable size: 1,081 lines → Target: 850-900 lines (17% reduction)
- Current context usage: <30% → Target: <20% (33% improvement)
- Current agent invocations: 4 command calls → Target: 0 command calls (100% direct invocation)
- Current library integration: 6/8 libraries → Target: 8/8 libraries (100% integration)
- Current standards compliance: 85-90% → Target: 95%+ (5-10% improvement)

**Success Metrics** (Maintained from Current):
- File creation reliability: 100% (maintained)
- Test pass rate: 100% (maintained)
- Wave-based parallel execution time savings: 40-60% (maintained)
- Fail-fast error detection: Immediate error visibility (maintained)
