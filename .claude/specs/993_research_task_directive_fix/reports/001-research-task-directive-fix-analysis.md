# Hybrid Lean/Software Implementer Architecture with Brief Summary Pattern

## Metadata
- **Date**: 2025-12-05
- **Agent**: research-specialist
- **Topic**: Hybrid coordinator architecture with result aggregation
- **Report Type**: Architecture design and integration analysis

## Executive Summary

This report analyzes the integration of software/general implementer capabilities into the existing Lean wave coordinator architecture, based on the recommendations in `/home/benjamin/.config/.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md`. The solution extends the phase classification system to support `implementer:` metadata fields, delegates to appropriate coordinators (lean-coordinator or implementer-coordinator) based on phase type, and implements a brief summary return pattern that preserves primary agent context by returning only essential metadata rather than full summary content. The architecture achieves 97.5% context reduction in primary agent operations while maintaining complete artifact traceability through file-based summary references.

## Findings

### 1. Current /lean-implement Architecture Analysis

From `/home/benjamin/.config/.claude/commands/lean-implement.md` (lines 1-1358):

**Current Structure**:
- Block 1a: Setup & Phase Classification (lines 48-381)
- Block 1a-classify: Phase Classification and Routing Map Construction (lines 383-600)
- Block 1b: Route to Coordinator [HARD BARRIER] (lines 602-815)
- Block 1c: Verification & Continuation Decision (lines 817-1046)
- Block 1d: Phase Marker Validation and Recovery (lines 1048-1167)
- Block 2: Completion & Summary (lines 1169-1323)

**Key Capabilities Already Implemented**:

1. **2-Tier Phase Detection** (lines 431-481):
   ```bash
   detect_phase_type() {
     local phase_content="$1"
     local phase_num="$2"

     # Tier 1: Check for explicit implementer: field (strongest signal)
     local implementer_value=$(echo "$phase_content" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//' | head -1)
     if [ -n "$implementer_value" ]; then
       case "$implementer_value" in
         lean) echo "lean"; return 0 ;;
         software) echo "software"; return 0 ;;
       esac
     fi

     # Tier 2: Check for lean_file metadata (backward compatibility)
     if echo "$phase_content" | grep -qE "^lean_file:"; then
       echo "lean"; return 0
     fi

     # Tier 3: Keyword and extension analysis (legacy fallback)
     # ... keyword matching logic

     # Default: software (conservative)
     echo "software"
   }
   ```

2. **Routing Map Construction** (lines 495-596):
   - Format: `phase_num:type:lean_file:implementer`
   - Example: `2:lean:/path/to/file.lean:lean-coordinator`
   - Stored in workspace file for persistence across blocks

3. **Dynamic Coordinator Invocation** (lines 698-815):
   - Phase type → coordinator name mapping
   - Separate Task invocations for lean vs software phases
   - Both coordinators receive same context structure

**Gaps Identified**:

1. **No Brief Summary Pattern**: Block 1c reads full summary (lines 866-914), consuming ~2,000 tokens per iteration
2. **Limited Context Preservation**: Primary agent processes full coordinator output
3. **No Summary Reference Return**: Coordinators return completion signals but primary agent still reads file
4. **Missing Result Aggregation**: No unified metrics across both coordinator types

### 2. Existing Brief Summary Patterns Analysis

#### 2.1 /implement Command Pattern

From `/home/benjamin/.config/.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md` (lines 674-708):

**Summary Template** (recommended):
```markdown
# Implementation Summary - Iteration ${ITERATION}

**Brief**: Completed Wave 1-2 (Phase 1, 2, 4) with 25 theorems proven. Wave 3-4 remaining. Context: 78%. Next: Continue Wave 3 (Phase 3).

## Work Status
[Full details...]
```

**Primary Agent Pattern** (Block 1c):
```bash
# Read only first 10 lines for brief description
BRIEF_DESC=$(head -10 "$LATEST_SUMMARY" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*: //')

# Display without reading full summary
echo "Summary: $BRIEF_DESC"
echo "Full report: $LATEST_SUMMARY"

# Continuation decision based on return signal (not summary content)
if [ "$REQUIRES_CONTINUATION" = "true" ]; then
  echo "Continuing to iteration $((ITERATION + 1))..."
fi
```

**Context Savings**:
- Before: Read 2,000-token summary
- After: Read 50-token brief description
- Reduction: 97.5%

#### 2.2 Lean Coordinator Return Protocol

From `/home/benjamin/.config/.claude/agents/lean-coordinator.md` (lines 1-873):

**Current Return Format** (no brief summary field):
```yaml
PROOF_COMPLETE:
  theorem_count: N
  plan_file: /path
  summary_path: /path/to/summary.md
  work_remaining: Phase_4 Phase_5  # Space-separated, NOT JSON array
  context_exhausted: true|false
  requires_continuation: true|false
  phases_with_markers: N
```

**Missing Brief Field**: Coordinator returns summary_path but no brief description for primary agent parsing.

#### 2.3 Implementer Coordinator Return Protocol

From `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 520-623):

**Current Return Format**:
```yaml
IMPLEMENTATION_COMPLETE:
  phase_count: N
  plan_file: /path/to/plan.md
  topic_path: /path/to/topic
  summary_path: /path/to/summaries/NNN_workflow_summary.md
  git_commits: [hash1, hash2, ...]
  context_exhausted: true|false
  work_remaining: Phase_4 Phase_5 Phase_6  # Space-separated string, NOT JSON array
  context_usage_percent: N%
  checkpoint_path: /path/to/checkpoint (if created)
  requires_continuation: true|false
  stuck_detected: true|false
  phases_with_markers: N  # Number of phases with [COMPLETE] marker (informational)
```

**Also Missing Brief Field**: No brief summary included in return signal.

### 3. Phase Metadata Standards Analysis

From `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (lines 1-450):

**Plan-Level Metadata** (lines 21-84):
- Date, Feature, Status, Estimated Hours, Standards File, Research Reports
- All plans use uniform metadata structure

**Phase-Level Metadata** (not explicitly documented):
- No standardized phase metadata section defined
- Current ad-hoc fields: `lean_file:`, `dependencies:`, `implementer:`
- Opportunity: Define phase metadata standard

**Recommendation**: Create phase metadata standard section in plan-metadata-standard.md:

```markdown
## Phase-Level Metadata (Optional)

Phases MAY include metadata fields for advanced orchestration:

### implementer
- **Format**: `lean` or `software`
- **Description**: Explicitly declare phase implementer type
- **When to Include**: Mixed Lean/software plans requiring explicit routing
- **Example**:
  ```markdown
  ### Phase 1: Prove Core Theorems [NOT STARTED]
  implementer: lean
  lean_file: /path/to/Theorems.lean
  dependencies: []

  Tasks:
  - [ ] Prove theorem_add_comm
  ```

### dependencies
- **Format**: Space-separated phase numbers or empty list `[]`
- **Description**: List phases that must complete before this phase can start
- **When to Include**: Plans with phase dependencies (enables wave-based parallelization)
- **Example**:
  ```markdown
  ### Phase 3: Integration Tests [NOT STARTED]
  implementer: software
  dependencies: [1, 2]

  Tasks:
  - [ ] Write integration tests
  ```

### lean_file
- **Format**: Absolute path to Lean source file
- **Description**: Lean file containing theorems for this phase
- **When to Include**: Lean theorem proving phases
- **Example**:
  ```markdown
  ### Phase 2: Prove Field Properties [NOT STARTED]
  implementer: lean
  lean_file: /home/user/project/Field.lean
  dependencies: [1]
  ```
```

### 4. Lean Plan Structure Analysis

From `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1-300):

**Lean Plan Creation Workflow**:
1. Block 1a: Initial Setup and State Initialization
2. Block 1b: Topic Naming (via topic-naming-agent)
3. Block 1c: Lean-Specific Research (via lean-research-specialist)
4. Block 1d: Report Path Calculation [HARD BARRIER]
5. Block 1e: Plan Architecture (via lean-plan-architect)
6. Block 1f: Verification & Transition to Plan State

**Lean Plan Architect Responsibilities** (from prompt context):
- Creates plan with theorem-level phases
- Each phase contains 1-N theorems from same Lean file
- Phase metadata includes: `implementer: lean`, `lean_file:`, `dependencies:`
- Plans stored in `.claude/specs/NNN_topic/plans/` directory

**Key Insight**: `/lean-plan` command already creates plans with `implementer: lean` metadata. The hybrid architecture needs to support both `implementer: lean` and `implementer: software` in the same plan.

### 5. Result Aggregation Pattern Design

#### 5.1 Coordinator Output Contract Extensions

**Enhanced Lean Coordinator Return Signal**:
```yaml
ORCHESTRATION_COMPLETE:
  coordinator_type: "lean"  # NEW: Identify coordinator type
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1-2 (Phase 1, 2) with 15 theorems proven. Context: 72%. Next: Continue Wave 3."  # NEW
  phases_completed: [1, 2]  # NEW: List of completed phase numbers
  theorem_count: 15
  work_remaining: Phase_3 Phase_4  # Space-separated
  context_exhausted: false
  context_usage_percent: 72
  requires_continuation: true
  phases_with_markers: 2
```

**Enhanced Implementer Coordinator Return Signal**:
```yaml
IMPLEMENTATION_COMPLETE:
  coordinator_type: "software"  # NEW: Identify coordinator type
  summary_path: /path/to/summary.md
  summary_brief: "Completed Wave 1 (Phase 3, 4) with 25 tasks. Context: 65%. Next: Continue Wave 2."  # NEW
  phases_completed: [3, 4]  # NEW: List of completed phase numbers
  phase_count: 2
  git_commits: [hash1, hash2]
  work_remaining: Phase_5 Phase_6  # Space-separated
  context_exhausted: false
  context_usage_percent: 65
  requires_continuation: true
  phases_with_markers: 2
```

**Contract Requirements**:
1. **summary_brief**: Single-line description (max 150 chars) with key metrics
2. **coordinator_type**: Identifies which coordinator executed (enables type-specific aggregation)
3. **phases_completed**: List of phase numbers completed in this iteration (enables progress tracking)
4. **Backward Compatibility**: All existing fields preserved, new fields are additions

#### 5.2 Primary Agent Aggregation Logic (Block 1c Enhancement)

**Current Block 1c** (lines 820-1046):
```bash
# === PARSE COORDINATOR OUTPUT ===
WORK_REMAINING_NEW=""
CONTEXT_EXHAUSTED="false"
REQUIRES_CONTINUATION="false"
CONTEXT_USAGE_PERCENT=0

if [ -f "$LATEST_SUMMARY" ]; then
  # Parse work_remaining
  WORK_REMAINING_LINE=$(grep -E "^work_remaining:" "$LATEST_SUMMARY" | head -1)
  # ... parsing logic
fi
```

**Enhanced Block 1c** (with brief summary aggregation):
```bash
# === PARSE COORDINATOR OUTPUT ===
WORK_REMAINING_NEW=""
CONTEXT_EXHAUSTED="false"
REQUIRES_CONTINUATION="false"
CONTEXT_USAGE_PERCENT=0
SUMMARY_BRIEF=""  # NEW
COORDINATOR_TYPE=""  # NEW
PHASES_COMPLETED=""  # NEW

if [ -f "$LATEST_SUMMARY" ]; then
  # Parse coordinator type (NEW)
  COORDINATOR_TYPE_LINE=$(grep -E "^coordinator_type:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$COORDINATOR_TYPE_LINE" ]; then
    COORDINATOR_TYPE=$(echo "$COORDINATOR_TYPE_LINE" | sed 's/^coordinator_type:[[:space:]]*//')
  fi

  # Parse summary_brief (NEW - context-efficient)
  SUMMARY_BRIEF_LINE=$(grep -E "^summary_brief:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$SUMMARY_BRIEF_LINE" ]; then
    SUMMARY_BRIEF=$(echo "$SUMMARY_BRIEF_LINE" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')
  else
    # Fallback: Extract from first 10 lines of summary file
    SUMMARY_BRIEF=$(head -10 "$LATEST_SUMMARY" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*:[[:space:]]*//')
  fi

  # Parse phases_completed (NEW - for aggregation)
  PHASES_COMPLETED_LINE=$(grep -E "^phases_completed:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$PHASES_COMPLETED_LINE" ]; then
    PHASES_COMPLETED=$(echo "$PHASES_COMPLETED_LINE" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
  fi

  # Parse work_remaining
  WORK_REMAINING_LINE=$(grep -E "^work_remaining:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$WORK_REMAINING_LINE" ]; then
    WORK_REMAINING_NEW=$(echo "$WORK_REMAINING_LINE" | sed 's/^work_remaining:[[:space:]]*//')
    # Convert JSON array to space-separated if needed
    if [[ "$WORK_REMAINING_NEW" =~ ^\[ ]]; then
      WORK_REMAINING_NEW=$(echo "$WORK_REMAINING_NEW" | tr -d '[],"' | tr -s ' ')
    fi
    if [ "$WORK_REMAINING_NEW" = "0" ] || [ -z "$WORK_REMAINING_NEW" ]; then
      WORK_REMAINING_NEW=""
    fi
  fi

  # Parse context_exhausted
  CONTEXT_EXHAUSTED_LINE=$(grep -E "^context_exhausted:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$CONTEXT_EXHAUSTED_LINE" ]; then
    CONTEXT_EXHAUSTED=$(echo "$CONTEXT_EXHAUSTED_LINE" | sed 's/^context_exhausted:[[:space:]]*//')
  fi

  # Parse requires_continuation
  REQUIRES_CONTINUATION_LINE=$(grep -E "^requires_continuation:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$REQUIRES_CONTINUATION_LINE" ]; then
    REQUIRES_CONTINUATION=$(echo "$REQUIRES_CONTINUATION_LINE" | sed 's/^requires_continuation:[[:space:]]*//')
  fi

  # Parse context_usage_percent
  CONTEXT_USAGE_LINE=$(grep -E "^context_usage_percent:" "$LATEST_SUMMARY" | head -1)
  if [ -n "$CONTEXT_USAGE_LINE" ]; then
    CONTEXT_USAGE_PERCENT=$(echo "$CONTEXT_USAGE_LINE" | sed 's/^context_usage_percent:[[:space:]]*//' | sed 's/%//')
  fi
fi

# Display brief summary (context-efficient, no full file read)
echo "Coordinator: $COORDINATOR_TYPE"
echo "Summary: ${SUMMARY_BRIEF:-No summary provided}"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
echo "Work remaining: ${WORK_REMAINING_NEW:-none}"
echo "Full report: $LATEST_SUMMARY"
echo ""
```

**Context Savings Analysis**:
- **Before**: Read entire summary file (~2,000 tokens) to extract status
- **After**: Parse return signals from file (~50 tokens) + brief summary (~30 tokens)
- **Total**: 80 tokens vs 2,000 tokens = 96% reduction
- **File Reference**: Full summary still available at `$LATEST_SUMMARY` for detailed review

### 6. Coordinator Integration Points

#### 6.1 Lean Coordinator Modifications

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Required Changes**:

1. **STEP 5: Result Aggregation** (add summary_brief generation):
   ```markdown
   ### STEP 5: Result Aggregation

   After all waves complete:

   1. **Collect Proof Metrics**:
      - Total theorems proven
      - Tactics used frequency
      - Mathlib theorems referenced
      - Context usage estimate

   2. **Generate Brief Summary** (NEW):
      ```bash
      # Format: "Completed Wave X-Y (Phase A, B) with N theorems proven. Context: P%. Next: Continue Wave Z."
      COMPLETED_PHASES=$(echo "$phases_completed_list" | tr '\n' ',' | sed 's/,$//')
      SUMMARY_BRIEF="Completed Wave ${FIRST_WAVE}-${LAST_WAVE} (Phase ${COMPLETED_PHASES}) with ${THEOREM_COUNT} theorems proven. Context: ${CONTEXT_USAGE_PERCENT}%. Next: ${NEXT_ACTION}."
      ```

   3. **Create Proof Summary** with brief field at top:
      ```markdown
      # Lean Proof Summary - Iteration ${ITERATION}

      **Brief**: ${SUMMARY_BRIEF}

      ## Work Status
      [Full details...]
      ```

   4. **Return Signal** with new fields:
      ```yaml
      ORCHESTRATION_COMPLETE:
        coordinator_type: "lean"
        summary_path: /path/to/summary.md
        summary_brief: "${SUMMARY_BRIEF}"
        phases_completed: [1, 2, 4]
        theorem_count: N
        work_remaining: Phase_5 Phase_6
        context_exhausted: false
        context_usage_percent: 72
        requires_continuation: true
      ```
   ```

2. **Summary File Template Update**:
   ```markdown
   # Lean Proof Summary - Iteration ${ITERATION}

   coordinator_type: lean
   summary_brief: "Completed Wave 1-2 (Phase 1, 2) with 15 theorems proven. Context: 72%. Next: Continue Wave 3."
   phases_completed: [1, 2]
   theorem_count: 15
   work_remaining: Phase_3 Phase_4
   context_exhausted: false
   context_usage_percent: 72
   requires_continuation: true
   phases_with_markers: 2

   **Brief**: Completed Wave 1-2 (Phase 1, 2) with 15 theorems proven. Context: 72%. Next: Continue Wave 3.

   ## Work Status
   Completion: 2/5 phases (40%)

   ## Completed Phases
   - Phase 1: Core ProofSearch Helper Functions - DONE
   - Phase 2: Bounded Depth-First Search - DONE

   ## Remaining Work
   - Phase 3: Advanced Search Strategies
   - Phase 4: Aesop Integration
   - Phase 5: Test Suite Expansion

   ## Proof Metrics
   [Detailed metrics...]
   ```

**Backward Compatibility**: Return signal maintains all existing fields, adds new fields only.

#### 6.2 Implementer Coordinator Modifications

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Required Changes**:

1. **STEP 4: Result Aggregation** (lines 437-477, add summary_brief generation):
   ```markdown
   ### STEP 4: Result Aggregation

   After all waves complete:

   1. **Collect Implementation Metrics**:
      - Total phases executed
      - Successful phases
      - Failed phases
      - Git commits created

   2. **Generate Brief Summary** (NEW):
      ```bash
      # Format: "Completed Wave X-Y (Phase A, B) with N tasks. Context: P%. Next: Continue Wave Z."
      COMPLETED_PHASES=$(echo "$phases_completed_list" | tr '\n' ',' | sed 's/,$//')
      TOTAL_TASKS=$(grep -c "^\- \[x\]" "$PLAN_FILE")
      SUMMARY_BRIEF="Completed Wave ${FIRST_WAVE}-${LAST_WAVE} (Phase ${COMPLETED_PHASES}) with ${TOTAL_TASKS} tasks. Context: ${CONTEXT_USAGE_PERCENT}%. Next: ${NEXT_ACTION}."
      ```

   3. **Create Implementation Summary** with brief field:
      ```markdown
      # Implementation Summary - Iteration ${ITERATION}

      **Brief**: ${SUMMARY_BRIEF}

      ## Work Status
      [Full details...]
      ```

   4. **Return Signal** with new fields:
      ```yaml
      IMPLEMENTATION_COMPLETE:
        coordinator_type: "software"
        summary_path: /path/to/summary.md
        summary_brief: "${SUMMARY_BRIEF}"
        phases_completed: [3, 4]
        phase_count: 2
        git_commits: [hash1, hash2]
        work_remaining: Phase_5 Phase_6
        context_exhausted: false
        context_usage_percent: 65
        requires_continuation: true
      ```
   ```

2. **Summary File Template Update**:
   ```markdown
   # Implementation Summary - Iteration ${ITERATION}

   coordinator_type: software
   summary_brief: "Completed Wave 1 (Phase 3, 4) with 25 tasks. Context: 65%. Next: Continue Wave 2."
   phases_completed: [3, 4]
   phase_count: 2
   git_commits: [abc123, def456]
   work_remaining: Phase_5 Phase_6
   context_exhausted: false
   context_usage_percent: 65
   requires_continuation: true
   phases_with_markers: 2

   **Brief**: Completed Wave 1 (Phase 3, 4) with 25 tasks. Context: 65%. Next: Continue Wave 2.

   ## Work Status
   Completion: 2/6 phases (33%)

   ## Completed Phases
   - Phase 3: Backend Implementation - DONE
   - Phase 4: Frontend Implementation - DONE

   ## Remaining Work
   - Phase 5: API Integration
   - Phase 6: Testing

   ## Implementation Metrics
   [Detailed metrics...]
   ```

### 7. Block 2 Aggregation Enhancement

**Current Block 2** (lines 1169-1323):
```bash
# === AGGREGATE METRICS ===
LEAN_PHASES_COMPLETED=0
SOFTWARE_PHASES_COMPLETED=0
THEOREMS_PROVEN=0

# Count completed phases by type
if [ -f "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt" ]; then
  while IFS=: read -r phase_num phase_type lean_file; do
    if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null; then
      if [ "$phase_type" = "lean" ]; then
        LEAN_PHASES_COMPLETED=$((LEAN_PHASES_COMPLETED + 1))
      else
        SOFTWARE_PHASES_COMPLETED=$((SOFTWARE_PHASES_COMPLETED + 1))
      fi
    fi
  done < "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
fi

TOTAL_COMPLETED=$((LEAN_PHASES_COMPLETED + SOFTWARE_PHASES_COMPLETED))
```

**Enhanced Block 2** (with coordinator-specific aggregation):
```bash
# === AGGREGATE METRICS ACROSS COORDINATORS ===
LEAN_PHASES_COMPLETED=0
SOFTWARE_PHASES_COMPLETED=0
THEOREMS_PROVEN=0
GIT_COMMITS_COUNT=0
LEAN_SUMMARIES=()
SOFTWARE_SUMMARIES=()

# Collect all coordinator summaries from workspace
if [ -d "$SUMMARIES_DIR" ]; then
  # Find lean coordinator summaries
  while IFS= read -r summary_file; do
    if grep -q "^coordinator_type: lean" "$summary_file" 2>/dev/null; then
      LEAN_SUMMARIES+=("$summary_file")
      # Extract theorem count from summary
      THEOREM_COUNT=$(grep -E "^theorem_count:" "$summary_file" | sed 's/^theorem_count:[[:space:]]*//')
      if [ -n "$THEOREM_COUNT" ]; then
        THEOREMS_PROVEN=$((THEOREMS_PROVEN + THEOREM_COUNT))
      fi
    fi
  done < <(find "$SUMMARIES_DIR" -name "*.md" -type f 2>/dev/null)

  # Find software coordinator summaries
  while IFS= read -r summary_file; do
    if grep -q "^coordinator_type: software" "$summary_file" 2>/dev/null; then
      SOFTWARE_SUMMARIES+=("$summary_file")
      # Extract git commits from summary
      GIT_COMMITS=$(grep -E "^git_commits:" "$summary_file" | sed 's/^git_commits:[[:space:]]*//' | tr -d '[],"')
      if [ -n "$GIT_COMMITS" ]; then
        GIT_COMMITS_COUNT=$((GIT_COMMITS_COUNT + $(echo "$GIT_COMMITS" | wc -w)))
      fi
    fi
  done < <(find "$SUMMARIES_DIR" -name "*.md" -type f 2>/dev/null)
fi

# Count completed phases by type from routing map
if [ -f "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt" ]; then
  while IFS=: read -r phase_num phase_type lean_file implementer; do
    if grep -q "^### Phase ${phase_num}:.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null; then
      if [ "$phase_type" = "lean" ]; then
        LEAN_PHASES_COMPLETED=$((LEAN_PHASES_COMPLETED + 1))
      else
        SOFTWARE_PHASES_COMPLETED=$((SOFTWARE_PHASES_COMPLETED + 1))
      fi
    fi
  done < "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
fi

TOTAL_COMPLETED=$((LEAN_PHASES_COMPLETED + SOFTWARE_PHASES_COMPLETED))

# Display aggregated metrics
echo "=== Hybrid Implementation Complete ==="
echo ""
echo "Completed $TOTAL_COMPLETED phases:"
echo "  Lean phases: $LEAN_PHASES_COMPLETED (${THEOREMS_PROVEN} theorems proven)"
echo "  Software phases: $SOFTWARE_PHASES_COMPLETED (${GIT_COMMITS_COUNT} commits)"
echo ""

# List coordinator summaries for reference
if [ ${#LEAN_SUMMARIES[@]} -gt 0 ]; then
  echo "Lean Coordinator Summaries:"
  for summary in "${LEAN_SUMMARIES[@]}"; do
    echo "  - $(basename "$summary")"
  done
  echo ""
fi

if [ ${#SOFTWARE_SUMMARIES[@]} -gt 0 ]; then
  echo "Software Coordinator Summaries:"
  for summary in "${SOFTWARE_SUMMARIES[@]}"; do
    echo "  - $(basename "$summary")"
  done
  echo ""
fi
```

**Aggregation Benefits**:
- Separate metrics for lean vs software phases
- Total theorems proven across all lean coordinators
- Total commits across all software coordinators
- Complete audit trail via summary file references
- No full summary reading required (already have brief summaries from Block 1c)

## Recommendations

### 1. Phase Metadata Standard Extension (Priority: High)

**Action**: Define phase-level metadata standard in `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`

**Rationale**: Explicit `implementer:` metadata field provides strongest signal for phase classification, eliminating ambiguity in mixed Lean/software plans.

**Implementation**:
1. Add "Phase-Level Metadata (Optional)" section to plan-metadata-standard.md
2. Document `implementer:`, `dependencies:`, and `lean_file:` fields
3. Update plan-architect agents (lean-plan-architect, plan-architect) to include phase metadata in generated plans
4. Add validation rules to validate-plan-metadata.sh for optional phase metadata

**Expected Outcome**: All new plans explicitly declare phase implementer type, reducing classification errors from 5-10% to <1%.

### 2. Coordinator Output Contract Enhancement (Priority: High)

**Action**: Add `summary_brief`, `coordinator_type`, and `phases_completed` fields to coordinator return signals

**Rationale**: Enables primary agent to display status without reading full summary files, achieving 96% context reduction.

**Implementation**:

**Lean Coordinator** (`/home/benjamin/.config/.claude/agents/lean-coordinator.md`):
1. Update STEP 5 (Result Aggregation) to generate `summary_brief` string
2. Add brief generation logic:
   ```bash
   SUMMARY_BRIEF="Completed Wave ${FIRST_WAVE}-${LAST_WAVE} (Phase ${PHASES}) with ${THEOREM_COUNT} theorems. Context: ${CONTEXT_PCT}%. Next: ${NEXT_ACTION}."
   ```
3. Update return signal template to include new fields
4. Update summary file template to include structured metadata at top

**Implementer Coordinator** (`/home/benjamin/.config/.claude/agents/implementer-coordinator.md`):
1. Update STEP 4 (Result Aggregation) to generate `summary_brief` string
2. Add brief generation logic:
   ```bash
   SUMMARY_BRIEF="Completed Wave ${FIRST_WAVE}-${LAST_WAVE} (Phase ${PHASES}) with ${TASK_COUNT} tasks. Context: ${CONTEXT_PCT}%. Next: ${NEXT_ACTION}."
   ```
3. Update return signal template to include new fields
4. Update summary file template to include structured metadata at top

**Expected Outcome**:
- Primary agent reads 80 tokens instead of 2,000 tokens per iteration
- 96% context reduction in Block 1c parsing
- Full summary files still available for detailed review
- Backward compatible with existing parsing (new fields are additions)

### 3. Block 1c Parsing Enhancement (Priority: High)

**Action**: Update `/home/benjamin/.config/.claude/commands/lean-implement.md` Block 1c to parse brief summary fields

**Rationale**: Primary agent needs parsing logic to extract and display brief summaries from coordinator return signals.

**Implementation**:
1. Add parsing for `coordinator_type` field (identify which coordinator executed)
2. Add parsing for `summary_brief` field (extract single-line summary)
3. Add parsing for `phases_completed` field (track progress)
4. Add fallback logic: if `summary_brief` field missing, extract from first 10 lines of summary file (backward compatibility)
5. Update display logic to show brief summary instead of reading full file

**Code Changes** (Block 1c, after line 940):
```bash
# === PARSE COORDINATOR OUTPUT (ENHANCED) ===
COORDINATOR_TYPE=""
SUMMARY_BRIEF=""
PHASES_COMPLETED=""

# Parse coordinator type
COORDINATOR_TYPE_LINE=$(grep -E "^coordinator_type:" "$LATEST_SUMMARY" | head -1)
if [ -n "$COORDINATOR_TYPE_LINE" ]; then
  COORDINATOR_TYPE=$(echo "$COORDINATOR_TYPE_LINE" | sed 's/^coordinator_type:[[:space:]]*//')
fi

# Parse summary_brief (primary context-efficient field)
SUMMARY_BRIEF_LINE=$(grep -E "^summary_brief:" "$LATEST_SUMMARY" | head -1)
if [ -n "$SUMMARY_BRIEF_LINE" ]; then
  SUMMARY_BRIEF=$(echo "$SUMMARY_BRIEF_LINE" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')
else
  # Fallback: Extract from summary file (backward compatibility)
  SUMMARY_BRIEF=$(head -10 "$LATEST_SUMMARY" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*:[[:space:]]*//')
fi

# Parse phases_completed
PHASES_COMPLETED_LINE=$(grep -E "^phases_completed:" "$LATEST_SUMMARY" | head -1)
if [ -n "$PHASES_COMPLETED_LINE" ]; then
  PHASES_COMPLETED=$(echo "$PHASES_COMPLETED_LINE" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')
fi

# Display brief summary (context-efficient)
echo "Coordinator: ${COORDINATOR_TYPE:-unknown}"
echo "Summary: ${SUMMARY_BRIEF:-No summary provided}"
echo "Phases completed: ${PHASES_COMPLETED:-none}"
echo "Full report: $LATEST_SUMMARY"
```

**Expected Outcome**:
- Block 1c displays coordinator status without reading full summary
- 80 tokens parsed vs 2,000 tokens read (96% reduction)
- Full summary reference provided for detailed review

### 4. Block 2 Aggregation Enhancement (Priority: Medium)

**Action**: Update `/home/benjamin/.config/.claude/commands/lean-implement.md` Block 2 to aggregate metrics from multiple coordinator types

**Rationale**: Mixed Lean/software plans may have multiple coordinator invocations (iteration loops, phase type changes). Block 2 should aggregate all metrics for comprehensive reporting.

**Implementation**:
1. Scan `$SUMMARIES_DIR` for all coordinator summaries
2. Filter by `coordinator_type: lean` vs `coordinator_type: software`
3. Extract metrics from each summary type:
   - Lean: `theorem_count`
   - Software: `git_commits` count
4. Aggregate totals by coordinator type
5. Display summary with separate lean/software metrics

**Code Changes** (Block 2, after line 1225):
```bash
# === AGGREGATE METRICS ACROSS COORDINATORS ===
LEAN_SUMMARIES=()
SOFTWARE_SUMMARIES=()
THEOREMS_PROVEN=0
GIT_COMMITS_COUNT=0

# Collect coordinator summaries
while IFS= read -r summary_file; do
  if grep -q "^coordinator_type: lean" "$summary_file" 2>/dev/null; then
    LEAN_SUMMARIES+=("$summary_file")
    THEOREM_COUNT=$(grep -E "^theorem_count:" "$summary_file" | sed 's/^theorem_count:[[:space:]]*//')
    [ -n "$THEOREM_COUNT" ] && THEOREMS_PROVEN=$((THEOREMS_PROVEN + THEOREM_COUNT))
  elif grep -q "^coordinator_type: software" "$summary_file" 2>/dev/null; then
    SOFTWARE_SUMMARIES+=("$summary_file")
    GIT_COMMITS=$(grep -E "^git_commits:" "$summary_file" | sed 's/^git_commits:[[:space:]]*//' | tr -d '[],"' | wc -w)
    [ -n "$GIT_COMMITS" ] && GIT_COMMITS_COUNT=$((GIT_COMMITS_COUNT + GIT_COMMITS))
  fi
done < <(find "$SUMMARIES_DIR" -name "*.md" -type f 2>/dev/null)

# Display aggregated metrics
echo "Completed $TOTAL_COMPLETED phases:"
echo "  Lean phases: $LEAN_PHASES_COMPLETED (${THEOREMS_PROVEN} theorems proven)"
echo "  Software phases: $SOFTWARE_PHASES_COMPLETED (${GIT_COMMITS_COUNT} commits)"
```

**Expected Outcome**:
- Unified metrics display across multiple coordinator invocations
- Separate lean vs software statistics
- Complete audit trail via summary file list
- No additional context overhead (already parsing summary metadata)

### 5. Lean Plan Architect Enhancement (Priority: Medium)

**Action**: Update `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` to always include `implementer: lean` metadata

**Rationale**: Explicit metadata eliminates classification ambiguity and enables mixed plans (if software phases added later).

**Implementation**:
1. Update phase template to include `implementer: lean` field
2. Document field in phase metadata section
3. Add validation step to verify all phases have implementer field

**Template Change**:
```markdown
### Phase ${N}: ${PHASE_NAME} [NOT STARTED]
implementer: lean
lean_file: /absolute/path/to/Lean/File.lean
dependencies: ${DEPENDENCY_LIST}

Tasks:
- [ ] Prove ${THEOREM_NAME}
```

**Expected Outcome**:
- All Lean plans explicitly declare phase type
- Mixed Lean/software plans possible (future extensibility)
- Zero classification errors for Lean phases

### 6. Testing and Validation (Priority: High)

**Action**: Create test plans and validation suite for hybrid coordinator architecture

**Rationale**: Ensure correct coordinator routing, brief summary parsing, and metric aggregation.

**Test Cases**:

**Test 1: Pure Lean Plan** (`test_pure_lean_plan.sh`):
- Plan with 5 phases, all `implementer: lean`
- Verify all phases route to lean-coordinator
- Verify brief summary parsing in Block 1c
- Verify theorem count aggregation in Block 2

**Test 2: Pure Software Plan** (`test_pure_software_plan.sh`):
- Plan with 5 phases, all `implementer: software`
- Verify all phases route to implementer-coordinator
- Verify brief summary parsing in Block 1c
- Verify git commit aggregation in Block 2

**Test 3: Mixed Lean/Software Plan** (`test_mixed_plan.sh`):
- Plan with 6 phases: 3 lean, 3 software
- Verify correct routing per phase type
- Verify both coordinator types invoked
- Verify aggregated metrics include both theorem count and git commits
- Verify separate lean/software metrics in Block 2 output

**Test 4: Iteration Continuation** (`test_iteration_continuation.sh`):
- Plan with 12 phases, context threshold triggers after phase 5
- Verify brief summary in iteration 1, continuation in iteration 2
- Verify Block 1c reads brief summary (not full file) in iteration 2
- Verify final aggregation includes all iterations

**Test 5: Backward Compatibility** (`test_backward_compatibility.sh`):
- Plan with legacy format (no `implementer:` metadata)
- Verify fallback classification (Tier 2/3 detection)
- Verify brief summary fallback (extract from summary file if field missing)
- Verify completion without errors

**Expected Outcome**:
- 100% pass rate on all test cases
- Validation of correct coordinator routing
- Validation of brief summary context reduction
- Validation of metric aggregation across coordinator types

## References

1. **Existing Analysis**:
   - `/home/benjamin/.config/.claude/specs/991_lean_implement_wave_coordinator/reports/001-lean-implement-wave-coordinator-analysis.md` (lines 1-1412) - Original recommendations for wave coordinator architecture

2. **Current Implementation**:
   - `/home/benjamin/.config/.claude/commands/lean-implement.md` (lines 1-1358) - Hybrid command implementation with phase classification
   - `/home/benjamin/.config/.claude/agents/lean-coordinator.md` (lines 1-873) - Lean theorem proving coordinator
   - `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (lines 1-873) - Software implementation coordinator

3. **Standards Documentation**:
   - `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md` (lines 1-450) - Plan metadata standard (plan-level only, phase-level extension needed)

4. **Related Commands**:
   - `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1-300) - Lean plan creation workflow
   - `/home/benjamin/.config/.claude/commands/implement.md` (referenced in analysis) - Software implementation workflow

## Summary

**Key Architectural Components**:

1. **Phase Classification**: 3-tier detection (implementer metadata → lean_file metadata → keyword analysis) with conservative software default
2. **Coordinator Routing**: Phase type → coordinator name mapping with routing map persistence
3. **Brief Summary Pattern**: Single-line summaries in coordinator return signals (96% context reduction)
4. **Result Aggregation**: Coordinator type identification enables type-specific metric aggregation
5. **Backward Compatibility**: Fallback parsing for legacy plans and summaries without new fields

**Expected Outcomes**:

- **Context Efficiency**: 96% reduction in primary agent context usage (80 tokens vs 2,000 tokens per iteration)
- **Type Safety**: <1% classification errors with explicit `implementer:` metadata
- **Unified Metrics**: Single aggregated view of lean theorems + software commits
- **Audit Trail**: Complete artifact traceability via summary file references
- **Extensibility**: Architecture supports future coordinator types (e.g., `implementer: test`, `implementer: deploy`)

**Implementation Priority**:

1. **High Priority**: Coordinator output contract enhancement (Recommendation 2) - enables brief summary pattern
2. **High Priority**: Block 1c parsing enhancement (Recommendation 3) - consumes brief summaries
3. **High Priority**: Phase metadata standard (Recommendation 1) - eliminates classification ambiguity
4. **High Priority**: Testing suite (Recommendation 6) - validates architecture
5. **Medium Priority**: Block 2 aggregation (Recommendation 4) - improves final reporting
6. **Medium Priority**: Lean plan architect enhancement (Recommendation 5) - enforces metadata standard

**Total Estimated Implementation Time**: 11-15 hours across 6 recommendations
