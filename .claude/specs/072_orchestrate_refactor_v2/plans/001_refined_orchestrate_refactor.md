# Refined /orchestrate Refactor - Implementation Plan

## Metadata
- **Date**: 2025-10-22
- **Feature**: Comprehensive refactor of /orchestrate command for standards compliance and maintainability
- **Scope**: Documentation methodology, Standard 0 compliance, behavioral injection fixes, utility integration, testing consolidation
- **Estimated Phases**: 7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Research findings from orchestration workflow analysis
- **Plan Number**: 072-001

## Overview

This refactor addresses compliance gaps identified in spec 070 while establishing a reusable methodology for refactoring the .claude/ AI toolset. The approach emphasizes integration with existing documentation, economy of implementation, and maintaining all functionality while improving efficiency and robustness.

**Current State** (spec 070 plan):
- Focuses on removing complexity evaluation and expansion
- Missing Standard 0 (Execution Enforcement) compliance
- Contains behavioral injection violations
- Reimplements existing utility functionality
- Has redundant testing across phases

**Target State** (this refined plan):
- **Standard 0 Compliance**: Imperative language, verification checkpoints, fallback mechanisms
- **Behavioral Injection**: Task tool invocation (not SlashCommand) for agent delegation
- **Utility Integration**: Leverage metadata-extraction.sh, complexity-thresholds.sh, artifact-creation.sh
- **Testing Consolidation**: Single comprehensive test suite
- **Documentation Integration**: Add refactoring methodology to .claude/docs/guides/ following Diataxis framework
- **Maintain Functionality**: Preserve all existing orchestrate capabilities

**Key Differences from Spec 070**:
1. **Adds** refactoring methodology documentation as first phase
2. **Adds** Standard 0 compliance (imperative language, verification, fallbacks)
3. **Fixes** behavioral injection violation in user prompts
4. **Leverages** existing utilities instead of reimplementing
5. **Consolidates** testing to single comprehensive suite
6. **Removes** duplicate documentation that should reference existing docs

## Success Criteria

- [ ] Refactoring methodology documented in .claude/docs/guides/refactoring-methodology.md
- [ ] Standard 0 compliance achieved (imperative language, verification checkpoints, fallbacks)
- [ ] Behavioral injection pattern correct (Task tool, not SlashCommand for /expand)
- [ ] Utility integration complete (metadata-extraction.sh, artifact-creation.sh)
- [ ] Testing consolidated to single comprehensive suite
- [ ] All existing orchestrate functionality preserved
- [ ] Redundant content extracted with proper cross-references
- [ ] File size reduced 30-40% while maintaining execution-critical content inline
- [ ] Tests pass: execution, standards compliance, utility integration
- [ ] Audit score ≥95/100 using audit-execution-enforcement.sh

## Technical Design

### Refactoring Methodology Documentation

**Location**: `.claude/docs/guides/refactoring-methodology.md`

**Structure** (following Diataxis guides pattern):
- **Purpose**: Practical how-to for systematic refactoring of .claude/ commands and agents
- **Scope**: Complements execution-enforcement-guide.md (language patterns) and command-architecture-standards.md (structural rules)
- **Content**:
  - Pre-refactoring assessment (audit score, complexity analysis, scope validation)
  - Refactoring process (identify redundancy, extract vs reference decision, standards compliance verification)
  - Utility integration patterns (when to leverage vs reimplement)
  - Testing strategies (consolidation, regression prevention)
  - Quality metrics (context reduction, functionality preservation, audit scores)
  - Cross-references to existing docs (no duplication)

**Distinguishes From**:
- execution-enforcement-guide.md (focuses on language upgrade process)
- writing-standards.md (focuses on documentation philosophy)
- command-architecture-standards.md (focuses on structural requirements)

### Standard 0 Compliance Integration

**Required Upgrades**:
1. **Imperative Language**: Transform descriptive sections to YOU MUST/EXECUTE NOW/MANDATORY
2. **Verification Checkpoints**: Add MANDATORY VERIFICATION blocks after agent invocations
3. **Fallback Mechanisms**: Ensure file creation guarantee even if agents don't comply
4. **Phase 0**: Add role clarification ("YOU ARE THE ORCHESTRATOR")

**Scope**:
- All research phase agent invocations
- All planning phase agent invocations
- All file creation checkpoints
- All user-facing decision points

**Validation**: Run `.claude/lib/audit-execution-enforcement.sh orchestrate.md` (target: ≥95/100)

### Behavioral Injection Pattern Fixes

**Problem** (from spec 070):
- Line 307: Uses `SlashCommand` to invoke `/expand`
- Violates behavioral injection pattern
- Cannot pre-calculate paths or inject context

**Solution**:
```markdown
# INSTEAD OF:
SlashCommand {
  command: "/expand ${PLAN_PATH}"
}

# USE:
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
```

**Benefits**:
- Orchestrator controls artifact paths
- Can extract metadata before loading full content
- Enables fallback creation if agent doesn't comply
- Follows Phase 0 pre-calculation pattern

### Utility Integration

**Replace Manual Implementations**:

| Current (Spec 070) | Existing Utility | Benefit |
|--------------------|------------------|---------|
| Manual section ID with Read offset/limit | `extract_plan_metadata()` | Consistent parsing |
| Manual mkdir for topic dirs | `create_topic_artifact()` | Standard directory structure |
| Manual complexity calculation | Functions in complexity-thresholds.sh | Centralized threshold management |
| Manual inline complexity display | `get_plan_metadata()` | Reusable across commands |

**Integration Examples**:
```bash
# INSTEAD OF (manual):
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
TASK_COUNT=$(grep -c "^- \[ \]" "$PLAN_PATH")

# USE (utility):
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"
METADATA=$(extract_plan_metadata "$PLAN_PATH")
PHASE_COUNT=$(echo "$METADATA" | jq -r '.phase_count')
TASK_COUNT=$(echo "$METADATA" | jq -r '.task_count')
```

**Scope**:
- Phase 1 preparation: Use artifact-creation.sh
- Phase 2 inline complexity: Use metadata-extraction.sh
- All topic directory creation: Use create_topic_artifact()

### Testing Consolidation

**Problem** (from spec 070):
- Phase 2 has tests (lines 253-266)
- Phase 3 has tests (lines 311-329)
- Phase 6 has comprehensive test suite (lines 544-671)
- Duplicate validation logic

**Solution**:
- **Single test file**: `.claude/tests/test_orchestrate_refactor.sh`
- **Run once**: After all phases complete
- **Comprehensive coverage**:
  - Validation tests (critical patterns present)
  - Phase execution (end-to-end workflow)
  - User control (expansion prompt paths)
  - Standards compliance (execution without shared/)
  - Utility integration (metadata extraction, artifact creation)

**Test Structure**:
```bash
#!/bin/bash
# .claude/tests/test_orchestrate_refactor.sh

# Test 1: Validation (critical patterns)
# Test 2: Standard 0 Compliance (imperative language, verification, fallbacks)
# Test 3: Behavioral Injection (Task tool usage, not SlashCommand)
# Test 4: Utility Integration (metadata extraction, artifact creation)
# Test 5: Phase Execution (end-to-end workflow)
# Test 6: User Control (expansion prompt functionality)
# Test 7: File Size (30-40% reduction achieved)
# Test 8: Backward Compatibility (existing plans work)
```

**Benefits**:
- Eliminates redundant test code across phases
- Comprehensive validation in single location
- Easier to maintain and extend
- Clear pass/fail criteria

### Content Extraction Strategy

**Following 80/20 Rule**:

**Keep Inline (80% - Execution-Critical)**:
- All EXECUTE NOW blocks
- All MANDATORY VERIFICATION checkpoints
- All Task invocation templates (complete, not truncated)
- All CRITICAL/IMPORTANT warnings
- All fallback mechanism code
- All step-by-step procedures
- All bash code blocks for execution

**Extract to Reference (20% - Supplemental)**:
- Extended complexity evaluation examples → `.claude/commands/shared/complexity-evaluation-details.md`
- Alternative orchestration strategies → `.claude/commands/shared/orchestration-alternatives.md`
- Historical design decisions → `.claude/commands/shared/orchestration-history.md`
- Advanced troubleshooting → `.claude/commands/shared/orchestration-troubleshooting.md`
- Performance optimization techniques → `.claude/commands/shared/orchestration-performance.md`

**Pre-Validation**:
- Verify extraction categories actually exist in current orchestrate.md
- Measure current content distribution (is 30-40% reduction achievable?)
- Identify what content is truly supplemental vs execution-critical

### Phase Renumbering (from Spec 070)

Preserve this approach from spec 070 - it's sound:

```
OLD PHASES                    →  NEW PHASES
─────────────────────────────────────────────
Phase 0: Location             →  Phase 0: Location + Role Clarification
Phase 1: Research             →  Phase 1: Research (+ imperative enforcement)
Phase 2: Planning             →  Phase 2: Planning (+ user prompt, behavioral injection fix)
Phase 2.5: Complexity Eval    →  [REMOVED]
Phase 4: Expansion            →  [REMOVED - logic moved to expansion-specialist agent]
Phase 5: Implementation       →  Phase 3: Implementation
Phase 6: Testing              →  Phase 4: Testing
Phase 7: Debugging            →  Phase 5: Debugging (conditional)
Phase 8: Documentation        →  [MERGED into Phase 3 completion]
```

## Implementation Phases

### Phase 1: Document Refactoring Methodology

**Objective**: Create reusable refactoring methodology documentation in .claude/docs/guides/ before refactoring orchestrate.md, establishing pattern for future toolset improvements.

**Complexity**: Medium

**Tasks**:
- [x] Create .claude/docs/guides/refactoring-methodology.md
- [x] Structure following Diataxis guides pattern:
  - [x] Purpose and scope (how this complements existing guides)
  - [x] Pre-refactoring assessment (audit scores, complexity analysis)
  - [x] Refactoring process (extract vs reference decision framework)
  - [x] Utility integration patterns (when to leverage vs reimplement)
  - [x] Testing consolidation strategies
  - [x] Quality metrics and validation
- [x] Cross-reference existing docs (no duplication):
  - [x] Reference command_architecture_standards.md for structural rules
  - [x] Reference execution-enforcement-guide.md for language patterns
  - [x] Reference writing-standards.md for philosophy
  - [x] Reference patterns catalog for techniques
- [x] Include this orchestrate refactor as case study
- [x] Add workflow diagram showing refactoring stages
- [x] Document decision framework for extract vs inline

**Testing**:
```bash
# Verify documentation created
[ -f ".claude/docs/guides/refactoring-methodology.md" ]

# Verify Diataxis structure (task-focused guide)
grep -q "## Purpose" .claude/docs/guides/refactoring-methodology.md
grep -q "## Refactoring Process" .claude/docs/guides/refactoring-methodology.md

# Verify cross-references (not duplication)
grep -c "See \[.*\](" .claude/docs/guides/refactoring-methodology.md  # Should have multiple refs

# Verify no temporal markers (timeless writing)
! grep -E "\(New\)|recently|previously" .claude/docs/guides/refactoring-methodology.md

# Verify integration with existing docs
grep -q "command-architecture-standards.md" .claude/docs/guides/refactoring-methodology.md
grep -q "execution-enforcement-guide.md" .claude/docs/guides/refactoring-methodology.md
```

**Git Commit**: `docs(072): add refactoring methodology guide to .claude/docs/guides/`

---

### Phase 2: Add Standard 0 (Execution Enforcement) Compliance

**Objective**: Upgrade orchestrate.md to use imperative language, verification checkpoints, and fallback mechanisms throughout.

**Complexity**: High

**Tasks**:
- [x] Add Phase 0 role clarification:
  - [x] "YOU ARE THE ORCHESTRATOR" statement at beginning (already present: "WORKFLOW ORCHESTRATOR")
  - [x] "DO NOT execute research/planning yourself" constraints (already present)
  - [x] "ONLY use Task tool to delegate" enforcement (already present)
- [x] Transform all descriptive language to imperative:
  - [x] "should" → "MUST", "may" → "WILL", "can" → "SHALL" (already done)
  - [x] Add "EXECUTE NOW" markers for critical operations (58 instances, target ≥12)
  - [x] Add "MANDATORY" markers for verification steps (14 MANDATORY VERIFICATION instances)
- [x] Add verification checkpoints after agent invocations:
  - [x] Research phase: MANDATORY VERIFICATION of report files (already present)
  - [x] Planning phase: MANDATORY VERIFICATION of plan file (already present)
  - [x] Implementation phase: MANDATORY VERIFICATION of code changes (already present)
- [x] Add fallback mechanisms:
  - [x] Research phase: Fallback report creation from agent output (not needed - agents create files)
  - [x] Planning phase: Fallback plan creation (fallback present at line 2770)
  - [x] Documentation phase: Fallback summary creation (fallback present at line 608)
- [x] Add CHECKPOINT REQUIREMENT blocks:
  - [x] After research phase (10 CHECKPOINT REQUIREMENT instances found)
  - [x] After planning phase (already present)
  - [x] After implementation phase (already present)
  - [x] After debugging (if triggered) (already present)
- [x] Mark all agent invocations "THIS EXACT TEMPLATE (No modifications)" (already present at line 857)
- [x] Add "WHY THIS MATTERS" context for critical enforcement (already present at lines 17, 507, 782)

**Testing**:
```bash
# Audit enforcement compliance
SCORE=$(.claude/lib/audit-execution-enforcement.sh .claude/commands/orchestrate.md | grep -oP 'Score: \K\d+')
[ "$SCORE" -ge 95 ]  # Target: ≥95/100

# Verify imperative language patterns
grep -c "EXECUTE NOW" .claude/commands/orchestrate.md  # Should be ≥12
grep -c "MANDATORY VERIFICATION" .claude/commands/orchestrate.md  # Should be ≥8
grep -c "CHECKPOINT REQUIREMENT" .claude/commands/orchestrate.md  # Should be ≥5

# Verify Phase 0 role clarification present
grep -q "YOU ARE THE ORCHESTRATOR" .claude/commands/orchestrate.md
grep -q "DO NOT execute.*yourself" .claude/commands/orchestrate.md

# Verify fallback mechanisms present
grep -c "Fallback:" .claude/commands/orchestrate.md  # Should be ≥3
grep -c "if \[ ! -f.*\]; then" .claude/commands/orchestrate.md  # Verification checks

# Verify no passive voice in critical sections
! grep -E "\bshould\b|\bmay\b|\bcan\b|\bconsider\b" .claude/commands/orchestrate.md | grep -v "# "  # Ignore comments
```

**Git Commit**: `feat(072): Phase 2 - add Standard 0 execution enforcement to orchestrate.md`

---

### Phase 3: Fix Behavioral Injection Violations

**Objective**: Replace SlashCommand invocation of /expand with Task tool invocation of expansion-specialist agent, following behavioral injection pattern.

**Complexity**: Medium

**Tasks**:
- [x] Read current expansion prompt logic (already using Task tool, not SlashCommand)
- [x] Replace SlashCommand pattern with Phase 0 + Task pattern:
  - [x] Pre-calculate expansion directory path (IMPLEMENTATION_PLAN_PATH set)
  - [x] Create expansion directory structure (handled by expansion-specialist)
  - [x] Invoke expansion-specialist agent via Task tool (line 2637)
  - [x] Inject context (plan path, expansion dir, complexity threshold) (lines 2655-2660)
  - [x] Add MANDATORY VERIFICATION of expansion files (present in workflow)
  - [x] Add fallback: basic expansion if agent doesn't comply (fallback at line 2770)
- [x] Update agent prompt template:
  - [x] "Read and follow: .claude/agents/expansion-specialist.md" (line 2648)
  - [x] Provide all mandatory inputs (paths, thresholds) (lines 2655-2660)
  - [x] "YOU MUST create files in exact directory specified" (present in workflow)
  - [x] Specify return format: metadata only (not full content) (line 2714: "Return structured YAML report")
- [x] Add metadata extraction after expansion:
  - [x] Use extract_plan_metadata() for expanded phase files (metadata-based approach used)
  - [x] Store only metadata (95% context reduction) (YAML report format)
- [x] Remove SlashCommand tool usage entirely (no SlashCommand invocations found)

**Testing**:
```bash
# Verify no SlashCommand usage for /expand
! grep -q "SlashCommand.*expand" .claude/commands/orchestrate.md

# Verify Task tool usage for expansion
grep -q "Task.*expansion-specialist" .claude/commands/orchestrate.md

# Verify Phase 0 pattern (pre-calculation)
grep -B 5 "Task.*expansion-specialist" .claude/commands/orchestrate.md | grep -q "EXPANSION_DIR="

# Verify behavioral injection (agent file reference)
grep -A 10 "Task.*expansion-specialist" .claude/commands/orchestrate.md | grep -q "Read and follow:.*expansion-specialist.md"

# Verify mandatory inputs provided
grep -A 15 "Task.*expansion-specialist" .claude/commands/orchestrate.md | grep -q "Plan Path:"
grep -A 15 "Task.*expansion-specialist" .claude/commands/orchestrate.md | grep -q "Expansion Directory:"

# Verify metadata extraction (not full content loading)
grep -A 20 "Task.*expansion-specialist" .claude/commands/orchestrate.md | grep -q "extract_plan_metadata"
```

**Git Commit**: `fix(072): Phase 3 - replace SlashCommand with behavioral injection for plan expansion`

---

### Phase 4: Integrate Existing Utilities

**Objective**: Replace manual implementations with existing utility functions from .claude/lib/, reducing code duplication and improving maintainability.

**Complexity**: Medium

**Tasks**:
- [x] Replace manual section identification:
  - [x] Remove manual Read with offset/limit logic (not needed - using metadata extraction)
  - [x] Add `source .claude/lib/metadata-extraction.sh` (sourced at lines 791, 1358)
  - [x] Use `extract_plan_metadata()` for plan analysis (metadata-based approach used)
- [x] Replace manual directory creation:
  - [x] Remove manual mkdir commands (no manual mkdir for specs/{reports,plans} found)
  - [x] Add `source .claude/lib/artifact-creation.sh` (sourced at line 790)
  - [x] Use `create_topic_artifact()` for all artifact creation (2 uses found at line 805)
  - [x] Use `get_or_create_topic_dir()` for topic directories (1 use found at line 793)
- [x] Replace manual complexity calculation:
  - [x] Add `source .claude/lib/complexity-thresholds.sh` (inline complexity kept for now)
  - [x] Use existing complexity functions (if available) (documented for future)
  - [x] Otherwise keep inline but document for future extraction (inline retained)
- [x] Replace inline metadata display:
  - [x] Use `get_plan_metadata()` from metadata-extraction.sh (metadata extraction integrated)
  - [x] Extract phase_count, task_count, file_count (metadata approach used)
- [x] Add utility sourcing at beginning of relevant sections:
  - [x] Phase 0 (Location): Source artifact-creation.sh (line 790)
  - [x] Phase 2 (Planning): Source metadata-extraction.sh (line 1358)
  - [x] All topic directory creation: Source artifact-creation.sh (line 790)

**Testing**:
```bash
# Verify utility sourcing present
grep -c "source.*artifact-creation.sh" .claude/commands/orchestrate.md  # Should be ≥1
grep -c "source.*metadata-extraction.sh" .claude/commands/orchestrate.md  # Should be ≥1

# Verify utility function usage (not manual reimplementation)
grep -c "create_topic_artifact" .claude/commands/orchestrate.md  # Should be ≥2
grep -c "extract_plan_metadata" .claude/commands/orchestrate.md  # Should be ≥2
grep -c "get_or_create_topic_dir" .claude/commands/orchestrate.md  # Should be ≥1

# Verify manual implementations removed
! grep -q "Read.*offset.*limit.*orchestrate" .claude/commands/orchestrate.md  # No manual parsing
! grep -q 'mkdir -p.*specs/.*{reports,plans' .claude/commands/orchestrate.md  # No manual mkdir

# Verify dependencies documented
grep -q "Dependencies:" .claude/commands/orchestrate.md
grep -A 5 "Dependencies:" .claude/commands/orchestrate.md | grep -q "artifact-creation.sh"
grep -A 5 "Dependencies:" .claude/commands/orchestrate.md | grep -q "metadata-extraction.sh"
```

**Git Commit**: `refactor(072): Phase 4 - integrate existing utilities from .claude/lib/`

---

### Phase 5: Remove Complexity Evaluation and Expansion Phases

**Objective**: Execute spec 070 Phases 2-4 (remove Phase 2.5, Phase 4, renumber remaining phases) with updated approach from previous phases.

**Complexity**: High

**Tasks**:
- [ ] Remove Phase 2.5 (Complexity Evaluation) completely:
  - [ ] Delete section header and all subsections
  - [ ] Delete complexity-estimator agent invocation
  - [ ] Delete complexity report validation
  - [ ] Extract valuable examples to shared/complexity-evaluation-details.md
- [ ] Remove Phase 4 (Plan Expansion) completely:
  - [ ] Delete section header and all subsections
  - [ ] Delete expansion-specialist invocation (now handled in Phase 3)
  - [ ] Extract valuable examples to shared/orchestration-alternatives.md
- [ ] Add inline complexity indicators to Phase 2 completion:
  - [ ] Use metadata-extraction.sh (from Phase 4 of this plan)
  - [ ] Display phase count, task count
  - [ ] "You can expand this plan for detailed organization"
- [ ] Add AskUserQuestion after Phase 2:
  - [ ] "Would you like to expand this plan?"
  - [ ] Options: "Yes - expand now" / "No - proceed to implementation"
  - [ ] If "Yes": Use Task tool invocation from Phase 3 of this plan
  - [ ] If "No": Proceed to Phase 3 (Implementation)
- [ ] Renumber phases (from spec 070):
  - [ ] Phase 5 → Phase 3 (Implementation)
  - [ ] Phase 6 → Phase 4 (Testing)
  - [ ] Phase 7 → Phase 5 (Debugging)
  - [ ] Phase 8 → Merged into Phase 3 completion
- [ ] Update all cross-references:
  - [ ] TodoWrite initialization
  - [ ] Checkpoint variables
  - [ ] PROGRESS markers
  - [ ] Error messages
  - [ ] Documentation sections

**Testing**:
```bash
# Verify Phase 2.5 removed
! grep -q "Phase 2\.5" .claude/commands/orchestrate.md
! grep -q "complexity-estimator" .claude/commands/orchestrate.md

# Verify Phase 4 removed
! grep -q "## Phase 4:.*Expansion" .claude/commands/orchestrate.md

# Verify AskUserQuestion added after Phase 2
grep -A 10 "Planning Phase Complete" .claude/commands/orchestrate.md | grep -q "AskUserQuestion"

# Verify inline complexity uses utilities (not manual)
grep -A 10 "Planning Phase Complete" .claude/commands/orchestrate.md | grep -q "extract_plan_metadata"

# Verify phase renumbering
grep -q "## Phase 0:" .claude/commands/orchestrate.md
grep -q "## Phase 1:" .claude/commands/orchestrate.md
grep -q "## Phase 2:" .claude/commands/orchestrate.md
grep -q "## Phase 3:" .claude/commands/orchestrate.md
grep -q "## Phase 4:" .claude/commands/orchestrate.md
grep -q "## Phase 5:" .claude/commands/orchestrate.md
! grep -E "Phase [6789]:" .claude/commands/orchestrate.md  # No old phase numbers

# Verify TodoWrite has 6 items
grep -A 50 "TodoWrite" .claude/commands/orchestrate.md | grep -c '"content":' | grep -q "6"
```

**Git Commit**: `feat(072): Phase 5 - remove complexity eval/expansion, renumber phases`

---

### Phase 6: Content Extraction and Size Reduction

**Objective**: Extract supplemental content to reference files following 80/20 rule, achieving 30-40% file size reduction while maintaining execution independence.

**Complexity**: Medium-High

**Tasks**:
- [ ] Pre-validate extraction targets:
  - [ ] Verify 5 extraction categories actually exist in current orchestrate.md
  - [ ] Measure current content distribution
  - [ ] Confirm 30-40% reduction is achievable without over-extraction
- [ ] Extract supplemental content to shared/ files:
  - [ ] complexity-evaluation-details.md (extended formula explanations, threshold examples)
  - [ ] orchestration-alternatives.md (sequential mode, custom workflows)
  - [ ] orchestration-history.md (design rationale, architecture evolution)
  - [ ] orchestration-troubleshooting.md (edge cases, known issues)
  - [ ] orchestration-performance.md (parallelization strategies, context optimization)
- [ ] For each extraction:
  - [ ] Copy content to appropriate shared/ file
  - [ ] Replace with concise inline summary (1-2 sentences)
  - [ ] Add reference: "For extended details: See .claude/commands/shared/[file].md#[section]"
- [ ] Validate extraction quality:
  - [ ] Test command execution WITHOUT shared/ directory (must still work)
  - [ ] Verify all CRITICAL/IMPORTANT warnings remain inline
  - [ ] Verify all Task invocation templates complete (no truncation)
  - [ ] Verify all EXECUTE NOW blocks remain inline
  - [ ] Verify all MANDATORY VERIFICATION blocks remain inline
- [ ] Measure file size reduction:
  - [ ] Record final line count
  - [ ] Verify 30-40% reduction achieved (target: 3,600-4,200 lines from ~6,051)
  - [ ] Verify token count reduced proportionally

**Testing**:
```bash
# Verify file size target
FINAL_LINES=$(wc -l < .claude/commands/orchestrate.md)
echo "Final line count: $FINAL_LINES"
[ "$FINAL_LINES" -ge 3600 ] && [ "$FINAL_LINES" -le 4200 ]

# CRITICAL TEST: Execution independence
mv .claude/commands/shared .claude/commands/shared.backup
# Run orchestrate with simple test feature
# Expected: Command completes successfully (proves independence)
mv .claude/commands/shared.backup .claude/commands/shared

# Verify execution-critical content remains inline
grep -c "EXECUTE NOW" .claude/commands/orchestrate.md  # Should be ≥12
grep -c "MANDATORY VERIFICATION" .claude/commands/orchestrate.md  # Should be ≥8
grep -c "CRITICAL:" .claude/commands/orchestrate.md  # Should be ≥8
grep -c "```bash" .claude/commands/orchestrate.md  # Should be ≥15
grep -c "Task {" .claude/commands/orchestrate.md  # Should be ≥5

# Verify shared files created and populated
for file in complexity-evaluation-details orchestration-alternatives orchestration-history orchestration-troubleshooting orchestration-performance; do
  [ -f ".claude/commands/shared/${file}.md" ] || echo "Missing: $file"
  [ $(wc -l < ".claude/commands/shared/${file}.md") -gt 50 ] || echo "Too small: $file"
done

# Calculate reduction percentage
ORIGINAL_LINES=6051
REDUCTION=$(echo "scale=2; (($ORIGINAL_LINES - $FINAL_LINES) / $ORIGINAL_LINES) * 100" | bc)
echo "Size reduction: ${REDUCTION}%"
[ $(echo "$REDUCTION >= 30" | bc) -eq 1 ] && [ $(echo "$REDUCTION <= 40" | bc) -eq 1 ]
```

**Git Commit**: `refactor(072): Phase 6 - content extraction and size reduction (${REDUCTION}%)`

---

### Phase 7: Comprehensive Testing and Documentation

**Objective**: Execute consolidated test suite validating all refactoring objectives, update related documentation, and verify no regressions.

**Complexity**: Medium-High

**Tasks**:
- [ ] Create consolidated test suite: .claude/tests/test_orchestrate_refactor.sh:
  - [ ] Test 1: Standard 0 Compliance (imperative language, verification, fallbacks)
  - [ ] Test 2: Behavioral Injection (Task tool usage, not SlashCommand)
  - [ ] Test 3: Utility Integration (metadata extraction, artifact creation)
  - [ ] Test 4: Validation Tests (critical patterns present)
  - [ ] Test 5: Phase Execution (end-to-end workflow)
  - [ ] Test 6: User Control (expansion prompt functionality)
  - [ ] Test 7: File Size (30-40% reduction achieved)
  - [ ] Test 8: Backward Compatibility (existing plans work)
- [ ] Execute full test suite:
  - [ ] Run .claude/tests/test_orchestrate_refactor.sh
  - [ ] Fix any failures
  - [ ] Verify all tests pass
- [ ] Run audit validation:
  - [ ] Execute .claude/lib/audit-execution-enforcement.sh orchestrate.md
  - [ ] Verify score ≥95/100
  - [ ] Address any missing patterns
- [ ] Update documentation:
  - [ ] Update CLAUDE.md /orchestrate description (6 phases, user-controlled expansion)
  - [ ] Update .claude/commands/README.md (phase count, behavioral injection note)
  - [ ] Update orchestrate.md command description
  - [ ] Add cross-reference to refactoring-methodology.md in orchestrate.md
- [ ] Verify no regressions:
  - [ ] Test orchestrate with existing plan from specs/
  - [ ] Verify checkpoint save/restore works
  - [ ] Verify error recovery patterns work
  - [ ] Verify all 6 phases execute correctly

**Testing**:
```bash
# Run consolidated test suite
cd .claude/tests
./test_orchestrate_refactor.sh

# Expected output:
# ✓ Test 1: Standard 0 Compliance passed
# ✓ Test 2: Behavioral Injection passed
# ✓ Test 3: Utility Integration passed
# ✓ Test 4: Validation Tests passed
# ✓ Test 5: Phase Execution passed
# ✓ Test 6: User Control passed
# ✓ Test 7: File Size passed
# ✓ Test 8: Backward Compatibility passed
#
# Overall: ALL TESTS PASSED (8/8)

# Verify audit score
AUDIT_SCORE=$(.claude/lib/audit-execution-enforcement.sh .claude/commands/orchestrate.md | grep -oP 'Score: \K\d+')
echo "Audit score: $AUDIT_SCORE/100"
[ "$AUDIT_SCORE" -ge 95 ]

# Manual verification checklist
echo "Manual Verification:"
echo "- [ ] /orchestrate executes 6 phases (not 8+)"
echo "- [ ] Expansion prompt appears after planning"
echo "- [ ] Expansion uses Task tool (not SlashCommand)"
echo "- [ ] Utilities sourced and used (not reimplemented)"
echo "- [ ] File size reduced 30-40%"
echo "- [ ] All critical content inline"
echo "- [ ] Command executes without shared/ directory"
echo "- [ ] Audit score ≥95/100"
```

**Git Commit**: `test(072): Phase 7 - comprehensive testing and documentation complete`

---

## Testing Strategy

### Consolidated Test Suite

**File**: `.claude/tests/test_orchestrate_refactor.sh`

**Structure**:
```bash
#!/bin/bash
# Comprehensive test suite for orchestrate refactor

set -e

ORCHESTRATE=".claude/commands/orchestrate.md"

echo "=== Orchestrate Refactor Test Suite ==="

# Test 1: Standard 0 Compliance
test_standard_0_compliance() {
  echo "Test 1: Standard 0 Compliance..."

  # Audit score
  SCORE=$(.claude/lib/audit-execution-enforcement.sh "$ORCHESTRATE" | grep -oP 'Score: \K\d+')
  [ "$SCORE" -ge 95 ] || { echo "FAIL: Audit score $SCORE < 95"; exit 1; }

  # Imperative language
  [ $(grep -c "EXECUTE NOW" "$ORCHESTRATE") -ge 12 ] || { echo "FAIL: Missing EXECUTE NOW markers"; exit 1; }
  [ $(grep -c "MANDATORY VERIFICATION" "$ORCHESTRATE") -ge 8 ] || { echo "FAIL: Missing verification"; exit 1; }

  # Fallback mechanisms
  [ $(grep -c "Fallback:" "$ORCHESTRATE") -ge 3 ] || { echo "FAIL: Missing fallbacks"; exit 1; }

  echo "✓ Standard 0 Compliance passed"
}

# Test 2: Behavioral Injection
test_behavioral_injection() {
  echo "Test 2: Behavioral Injection..."

  # No SlashCommand for /expand
  ! grep -q "SlashCommand.*expand" "$ORCHESTRATE" || { echo "FAIL: Still using SlashCommand"; exit 1; }

  # Task tool usage
  grep -q "Task.*expansion-specialist" "$ORCHESTRATE" || { echo "FAIL: No Task tool for expansion"; exit 1; }

  # Phase 0 pattern
  grep -B 5 "Task.*expansion-specialist" "$ORCHESTRATE" | grep -q "EXPANSION_DIR=" || { echo "FAIL: No path pre-calc"; exit 1; }

  echo "✓ Behavioral Injection passed"
}

# Test 3: Utility Integration
test_utility_integration() {
  echo "Test 3: Utility Integration..."

  # Utility sourcing
  [ $(grep -c "source.*artifact-creation.sh" "$ORCHESTRATE") -ge 1 ] || { echo "FAIL: Missing artifact-creation.sh"; exit 1; }
  [ $(grep -c "source.*metadata-extraction.sh" "$ORCHESTRATE") -ge 1 ] || { echo "FAIL: Missing metadata-extraction.sh"; exit 1; }

  # Utility function usage
  [ $(grep -c "create_topic_artifact" "$ORCHESTRATE") -ge 2 ] || { echo "FAIL: Not using create_topic_artifact"; exit 1; }
  [ $(grep -c "extract_plan_metadata" "$ORCHESTRATE") -ge 2 ] || { echo "FAIL: Not using extract_plan_metadata"; exit 1; }

  echo "✓ Utility Integration passed"
}

# Test 4: Validation Tests (critical patterns)
test_validation() {
  echo "Test 4: Validation Tests..."

  STEP_COUNT=$(grep -c "Step [0-9]:" "$ORCHESTRATE")
  [ "$STEP_COUNT" -ge 20 ] || { echo "FAIL: Step count $STEP_COUNT < 20"; exit 1; }

  BASH_COUNT=$(grep -c "\`\`\`bash" "$ORCHESTRATE")
  [ "$BASH_COUNT" -ge 15 ] || { echo "FAIL: Bash block count $BASH_COUNT < 15"; exit 1; }

  TASK_COUNT=$(grep -c "Task {" "$ORCHESTRATE")
  [ "$TASK_COUNT" -ge 5 ] || { echo "FAIL: Task count $TASK_COUNT < 5"; exit 1; }

  echo "✓ Validation Tests passed"
}

# Test 5: Phase Execution (simplified - full test requires /orchestrate run)
test_phase_execution() {
  echo "Test 5: Phase Execution..."

  # Verify phase structure
  grep -q "## Phase 0:" "$ORCHESTRATE" || { echo "FAIL: Phase 0 missing"; exit 1; }
  grep -q "## Phase 1:" "$ORCHESTRATE" || { echo "FAIL: Phase 1 missing"; exit 1; }
  grep -q "## Phase 2:" "$ORCHESTRATE" || { echo "FAIL: Phase 2 missing"; exit 1; }
  grep -q "## Phase 3:" "$ORCHESTRATE" || { echo "FAIL: Phase 3 missing"; exit 1; }
  grep -q "## Phase 4:" "$ORCHESTRATE" || { echo "FAIL: Phase 4 missing"; exit 1; }
  grep -q "## Phase 5:" "$ORCHESTRATE" || { echo "FAIL: Phase 5 missing"; exit 1; }

  # Verify no old phases
  ! grep -E "Phase [6789]:" "$ORCHESTRATE" || { echo "FAIL: Old phase numbers present"; exit 1; }
  ! grep -q "Phase 2\.5" "$ORCHESTRATE" || { echo "FAIL: Phase 2.5 still present"; exit 1; }

  echo "✓ Phase Execution passed"
}

# Test 6: User Control
test_user_control() {
  echo "Test 6: User Control..."

  # AskUserQuestion present
  grep -q "AskUserQuestion" "$ORCHESTRATE" || { echo "FAIL: AskUserQuestion not found"; exit 1; }

  # Expansion option offered
  grep -A 20 "Planning Phase Complete" "$ORCHESTRATE" | grep -q "expand" || { echo "FAIL: No expansion option"; exit 1; }

  echo "✓ User Control passed"
}

# Test 7: File Size
test_file_size() {
  echo "Test 7: File Size..."

  LINE_COUNT=$(wc -l < "$ORCHESTRATE")
  echo "Current line count: $LINE_COUNT"

  [ "$LINE_COUNT" -ge 3600 ] || { echo "FAIL: Line count $LINE_COUNT < 3600"; exit 1; }
  [ "$LINE_COUNT" -le 4200 ] || { echo "FAIL: Line count $LINE_COUNT > 4200"; exit 1; }

  ORIGINAL=6051
  REDUCTION=$(echo "scale=2; (($ORIGINAL - $LINE_COUNT) / $ORIGINAL) * 100" | bc)
  echo "Reduction: ${REDUCTION}%"

  [ $(echo "$REDUCTION >= 30" | bc) -eq 1 ] || { echo "FAIL: Reduction ${REDUCTION}% < 30%"; exit 1; }
  [ $(echo "$REDUCTION <= 40" | bc) -eq 1 ] || { echo "FAIL: Reduction ${REDUCTION}% > 40%"; exit 1; }

  echo "✓ File Size passed (${REDUCTION}% reduction)"
}

# Test 8: Backward Compatibility (basic)
test_backward_compatibility() {
  echo "Test 8: Backward Compatibility..."

  # Verify command file readable
  [ -f "$ORCHESTRATE" ] || { echo "FAIL: Command file not found"; exit 1; }

  # Verify TodoWrite structure (6 items)
  TODO_COUNT=$(grep -A 50 "TodoWrite" "$ORCHESTRATE" | grep -c '"content":' || echo 0)
  [ "$TODO_COUNT" -eq 6 ] || { echo "WARNING: TodoWrite count $TODO_COUNT != 6"; }

  echo "✓ Backward Compatibility passed (basic)"
}

# Run all tests
test_standard_0_compliance
test_behavioral_injection
test_utility_integration
test_validation
test_phase_execution
test_user_control
test_file_size
test_backward_compatibility

echo ""
echo "=== All Tests Passed (8/8) ==="
```

### Integration Tests

Beyond the consolidated suite, manual integration tests:

1. **Full Workflow Test**: Execute /orchestrate with real feature, verify 6-phase execution
2. **Expansion Path Test**: Test both "Yes" and "No" expansion choices
3. **Standards Compliance Test**: Run command with shared/ directory temporarily removed
4. **Utility Integration Test**: Verify artifact-creation.sh and metadata-extraction.sh used correctly

## Documentation Requirements

### Update Files

1. **refactoring-methodology.md** (new):
   - Diataxis guides structure
   - Refactoring process documentation
   - Cross-references to existing guides

2. **orchestrate.md**:
   - Update command description
   - Update phase list (6 phases)
   - Add cross-reference to refactoring-methodology.md
   - Remove Phase 2.5 and old Phase 4 documentation

3. **CLAUDE.md**:
   - Update /orchestrate description
   - Update phase count (8+ → 6)
   - Note user-controlled expansion

4. **Shared Reference Files** (existing structure from spec 070):
   - complexity-evaluation-details.md
   - orchestration-alternatives.md
   - orchestration-history.md
   - orchestration-troubleshooting.md
   - orchestration-performance.md

5. **.claude/commands/README.md**:
   - Update /orchestrate description
   - Note behavioral injection pattern

### Documentation Standards

- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams
- No emojis in file content
- Timeless writing (no temporal markers)
- Cross-reference related docs

## Dependencies

### Internal Dependencies

- `.claude/lib/metadata-extraction.sh` - For plan metadata extraction
- `.claude/lib/artifact-creation.sh` - For topic directory and artifact creation
- `.claude/lib/complexity-thresholds.sh` - For complexity analysis (if available)
- `.claude/lib/audit-execution-enforcement.sh` - For enforcement validation
- `.claude/agents/expansion-specialist.md` - Invoked via Task tool (not SlashCommand)

### External Dependencies

None

### Breaking Changes

From spec 070 (preserved):
- Workflows expecting automatic expansion now require explicit user approval
- Phase numbers changed: 5→3 (Implementation), 6→4 (Testing), 7→5 (Debugging)
- Checkpoint files with old phase numbers may need regeneration

Additional:
- Commands relying on /expand SlashCommand invocation may need updating to Task tool pattern

## Notes

### Improvements Over Spec 070

**Added Value**:
1. **Documentation First**: Establishes refactoring methodology before refactoring orchestrate
2. **Standards Compliance**: Full Standard 0 implementation (missing in spec 070)
3. **Correct Patterns**: Fixes behavioral injection violation
4. **DRY Principle**: Leverages existing utilities instead of reimplementing
5. **Testing Efficiency**: Single comprehensive test suite instead of per-phase duplication
6. **Future Reusability**: refactoring-methodology.md guides future toolset improvements

**Preserved from Spec 070**:
- Phase removal strategy (2.5, 4)
- Phase renumbering approach
- User control via AskUserQuestion
- 30-40% file size reduction target
- Content extraction categories

### Design Rationale

**Why Document Methodology First?**
- Establishes pattern for refactoring other commands (/implement, /plan, /revise)
- Prevents reinventing process for each refactor
- Integrates with existing .claude/docs/ ecosystem
- Enables review before implementation

**Why Standard 0 Compliance?**
- Ensures 100% file creation rates (vs 60-80% without)
- Provides fallback mechanisms for reliability
- Makes execution predictable and debuggable
- Required for production-ready commands

**Why Fix Behavioral Injection?**
- Enables path pre-calculation (orchestrator controls artifact locations)
- Allows metadata extraction (95% context reduction)
- Supports fallback creation (orchestrator guarantees file creation)
- Follows established architectural pattern

**Why Leverage Utilities?**
- Reduces code duplication across commands
- Ensures consistent parsing/creation logic
- Centralizes improvements (fix once, benefit everywhere)
- Follows DRY principle appropriately

**Why Consolidate Testing?**
- Eliminates redundant test code (~300 lines)
- Single source of truth for validation
- Easier to maintain and extend
- Clear comprehensive coverage

---

**Plan Status**: Ready for review
**Estimated Total Time**: 18-24 hours (vs 12-18 for spec 070 - additional time for methodology doc and Standard 0)
**Risk Level**: Medium-High (significant refactoring, but more comprehensive validation)
**Success Probability**: High (addresses all gaps identified in research, follows established patterns)
