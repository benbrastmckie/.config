# /orchestrate Command Systematic Refactor - Implementation Plan

## Metadata
- **Date**: 2025-10-22
- **Feature**: Systematic refactor of /orchestrate command
- **Scope**: Remove automatic complexity evaluation and expansion, simplify phase architecture, enhance user control
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Context**: TODO3.md requirements, command architecture standards compliance
- **Plan Number**: 070-001

## Overview

This refactor addresses the concerns raised in TODO3.md by systematically removing the automatic complexity evaluation (Phase 2.5) and automatic expansion pipeline (Phase 4) from `/orchestrate`, simplifying the command to a clean 6-phase architecture that respects user agency and adheres strictly to command architecture standards documented in `.claude/docs/`.

**Current State**:
- File size: 206KB (6,051 lines, 56,849 tokens)
- Phase structure: 8+ phases including 2 automatic/conditional phases
- Automatic expansion pipeline: Phase 2.5 (complexity-evaluator) → Phase 4 (expansion-specialist)
- Standards violations: Removes user control, over-engineered complexity

**Target State**:
- File size: ~120-140KB (3,600-4,200 lines, target 30-40% reduction)
- Phase structure: Clean 6-phase linear workflow (0→1→2→3→4→5)
- User control: AskUserQuestion after planning offers optional expansion via /expand
- Standards compliance: Full adherence to command architecture standards
- Expansion logic: Transferred to /expand command and expansion-specialist agent

**Key Architectural Changes**:
1. **Remove Phase 2.5** (Complexity Evaluation): 347 lines of automatic complexity analysis
2. **Remove Phase 4** (Plan Expansion): 470 lines of automatic expansion logic
3. **Simplify Phase Numbering**: 0→1→2→5→6→7→8 becomes 0→1→2→3→4→5
4. **Add User Prompt**: After Phase 2 (Planning), present AskUserQuestion to optionally expand plan
5. **Transfer Expansion Logic**: Move Phase 4 expansion patterns to /expand command
6. **Update References**: Fix all phase number references throughout command

## Success Criteria

- [ ] Phase 2.5 (Complexity Evaluation) completely removed from /orchestrate
- [ ] Phase 4 (Plan Expansion) completely removed from /orchestrate
- [ ] Phase numbering simplified to sequential 0-5 (no gaps)
- [ ] AskUserQuestion added after Phase 2 offering expansion option
- [ ] Expansion logic transferred to /expand command (if invoked by user)
- [ ] All phase cross-references updated (documentation, checkpoints, error messages)
- [ ] File size reduced by 30-40% (target: 3,600-4,200 lines)
- [ ] Command executes successfully with simplified workflow
- [ ] All execution-critical content remains inline per architecture standards
- [ ] Tests pass: command validation, phase execution, user control verification

## Technical Design

### Architecture Changes

**Phase Renumbering Map**:
```
OLD PHASES                    →  NEW PHASES
─────────────────────────────────────────────
Phase 0: Location             →  Phase 0: Location (unchanged)
Phase 1: Research             →  Phase 1: Research (unchanged)
Phase 2: Planning             →  Phase 2: Planning (+ user prompt)
Phase 2.5: Complexity Eval    →  [REMOVED]
Phase 4: Expansion            →  [REMOVED - moved to /expand]
Phase 5: Implementation       →  Phase 3: Implementation
Phase 6: Testing              →  Phase 4: Testing
Phase 7: Debugging            →  Phase 5: Debugging (conditional)
Phase 8: Documentation        →  [MERGED into Phase 3 completion]
```

**User Control Enhancement**:
After Phase 2 (Planning) completes:
1. Extract plan complexity indicators (inline, without agent)
2. Present AskUserQuestion:
   - "Would you like to expand this plan for detailed phase organization?"
   - Options: "Yes - expand now" / "No - proceed to implementation" / "Review plan first"
3. If "Yes": Invoke `/expand` command (via SlashCommand tool) with plan path
4. If "No": Proceed directly to Phase 3 (Implementation)
5. If "Review": Display plan summary, re-prompt

**Expansion Logic Transfer**:
- Extract Phase 4 expansion algorithm to /expand command
- Move complexity-evaluator agent integration to /expand command
- Move expansion-specialist agent integration to /expand command
- Update /expand to begin with complexity evaluation (per TODO3.md requirement)
- Ensure /expand can recursively expand generated phase files

**Content Extraction Strategy** (30-40% reduction):
Following the 80/20 rule from command architecture standards:

**Keep Inline (Execution-Critical - 80%)**:
- Step-by-step phase execution procedures
- Complete Task invocation templates (all 5 agents)
- CRITICAL/IMPORTANT/NEVER warnings
- Verification checkpoint bash blocks
- Error recovery patterns with fallback code
- Dependency validation logic
- Wave-based parallelization algorithm
- File creation enforcement patterns

**Extract to Reference Files (Supplemental - 20%)**:
- Extended complexity evaluation examples → `.claude/commands/shared/complexity-evaluation-details.md`
- Alternative orchestration strategies → `.claude/commands/shared/orchestration-alternatives.md`
- Historical design decisions and rationale → `.claude/commands/shared/orchestration-history.md`
- Advanced troubleshooting scenarios → `.claude/commands/shared/orchestration-troubleshooting.md`
- Performance optimization techniques → `.claude/commands/shared/orchestration-performance.md`

**What Gets Removed Entirely**:
- Phase 2.5 section (347 lines): Automatic complexity evaluation
- Phase 4 section (470 lines): Automatic expansion pipeline
- Complexity-evaluator agent invocation code (embedded in Phase 2.5)
- Expansion-specialist agent invocation code (embedded in Phase 4)
- Phase 2→2.5→4→5 branching logic
- ~817 lines total direct removal

### Verification and Testing

**Validation Checkpoints**:
1. **Content Integrity**: Grep tests for critical patterns (minimum counts)
   - `grep -c "Step [0-9]:" orchestrate.md` ≥ 20 (numbered steps present)
   - `grep -c "CRITICAL:" orchestrate.md` ≥ 8 (critical warnings preserved)
   - `grep -c "```bash" orchestrate.md` ≥ 15 (execution blocks present)
   - `grep -c "Task {" orchestrate.md` ≥ 5 (agent invocations complete)
   - `grep -c "EXECUTE NOW" orchestrate.md` ≥ 12 (imperative enforcement)

2. **Phase Numbering Consistency**:
   - No references to "Phase 2.5" or "Phase 4" (expansion)
   - All phase numbers sequential 0-5
   - Checkpoint variables use correct phase numbers
   - Error messages reference correct phases

3. **User Control Verification**:
   - AskUserQuestion invocation present after Phase 2
   - Expansion is optional, not automatic
   - User can skip expansion and proceed to implementation

4. **File Size Target**:
   - Final line count: 3,600-4,200 lines (30-40% reduction from 6,051)
   - Token count: ~35,000-40,000 tokens (30-40% reduction from 56,849)

**Testing Strategy**:
1. **Phase Execution Test**: Run /orchestrate with simple feature, verify 6-phase execution
2. **User Control Test**: Verify expansion prompt appears, test both "Yes" and "No" paths
3. **Standards Compliance Test**: Verify command can execute without shared/ directory (independence check)
4. **Extraction Validation Test**: Verify all execution-critical content remains inline
5. **Backward Compatibility Test**: Verify existing plans work with new phase numbering

### Dependencies

**Internal Dependencies**:
- `.claude/commands/expand.md` - Must be enhanced to accept complexity evaluation responsibility
- `.claude/agents/complexity-estimator.md` - Unchanged, now used only by /expand
- `.claude/agents/expansion-specialist.md` - Unchanged, now invoked only by /expand
- `.claude/lib/complexity-thresholds.sh` - Unchanged, utility library

**External Dependencies**: None

**Breaking Changes**:
- Workflows expecting automatic expansion will now require explicit user choice
- Phase numbers changed for Implementation/Testing/Debugging (5→3, 6→4, 7→5)
- Checkpoint files with old phase numbers need migration (or regeneration)

## Implementation Phases

### Phase 1: Preparation and Analysis
**Objective**: Analyze current orchestrate.md structure, identify all Phase 2.5 and Phase 4 references, create extraction targets, and prepare workspace.

**Complexity**: Low

**Tasks**:
- [ ] Create topic directory structure: `.claude/specs/070_orchestrate_refactor/{plans,reports,summaries,debug}/`
- [ ] Read complete orchestrate.md file (use multiple Read calls with offset/limit due to size)
- [ ] Identify all sections to remove:
  - [ ] Phase 2.5 section (lines ~1909-2256, 347 lines)
  - [ ] Phase 4 section (lines ~2257-2727, 470 lines)
  - [ ] Complexity-evaluator agent invocation code
  - [ ] Expansion-specialist agent invocation code
- [ ] Identify all phase number references to update:
  - [ ] Checkpoint variable names (CHECKPOINT_PHASE_5 → CHECKPOINT_PHASE_3)
  - [ ] Error messages referencing phases
  - [ ] TodoWrite phase descriptions
  - [ ] Progress markers (PROGRESS: Phase N)
  - [ ] Cross-references in documentation sections
- [ ] Create extraction target files in `.claude/commands/shared/`:
  - [ ] `complexity-evaluation-details.md` (extended examples)
  - [ ] `orchestration-alternatives.md` (alternative approaches)
  - [ ] `orchestration-history.md` (historical context, design decisions)
  - [ ] `orchestration-troubleshooting.md` (advanced scenarios)
  - [ ] `orchestration-performance.md` (optimization techniques)
- [ ] Document current line numbers and sections in phase map
- [ ] Create backup of orchestrate.md: `orchestrate.md.backup-$(date +%Y%m%d)`

**Testing**:
```bash
# Verify topic directory created
[ -d ".claude/specs/070_orchestrate_refactor" ]

# Verify backup created
[ -f ".claude/commands/orchestrate.md.backup-$(date +%Y%m%d)" ]

# Verify extraction target files created
for file in complexity-evaluation-details orchestration-alternatives orchestration-history orchestration-troubleshooting orchestration-performance; do
  [ -f ".claude/commands/shared/${file}.md" ] || echo "Missing: $file"
done

# Count current phases references
grep -c "Phase [0-9]" .claude/commands/orchestrate.md
```

**Git Commit**: `feat(070): Phase 1 - preparation and analysis complete`

---

### Phase 2: Remove Phase 2.5 (Complexity Evaluation)
**Objective**: Completely remove the automatic complexity evaluation section (Phase 2.5) from orchestrate.md and update all branching logic.

**Complexity**: Medium

**Tasks**:
- [ ] Read Phase 2.5 section completely (lines 1909-2256)
- [ ] Extract valuable content for reference files:
  - [ ] Complexity formula documentation → `shared/complexity-evaluation-details.md`
  - [ ] Threshold loading examples → `shared/complexity-evaluation-details.md`
  - [ ] Complexity metrics parsing → `shared/complexity-evaluation-details.md`
- [ ] Remove Phase 2.5 section from orchestrate.md:
  - [ ] Delete section header: "## Phase 2.5: Complexity Evaluation and Expansion Analysis"
  - [ ] Delete all subsections (Steps 1-6)
  - [ ] Delete complexity-estimator agent invocation template
  - [ ] Delete complexity report validation code
  - [ ] Delete complexity metrics extraction code
  - [ ] Delete workflow state updates for complexity
  - [ ] Delete conditional branching decision code
- [ ] Update Phase 2 (Planning) completion:
  - [ ] Remove transition to Phase 2.5
  - [ ] Add AskUserQuestion invocation for expansion choice
  - [ ] Add inline complexity indicator display (simple, no agent):
    ```bash
    # Display plan summary
    PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")
    TASK_COUNT=$(grep -c "^- \[ \]" "$PLAN_PATH")
    echo "Plan created: $PHASE_COUNT phases, $TASK_COUNT tasks"
    echo ""
    echo "You can expand this plan for more detailed phase organization."
    ```
  - [ ] Add conditional branch: expansion yes/no → Phase 3 or /expand
- [ ] Remove Phase 2.5 references from:
  - [ ] TodoWrite initialization (remove Phase 2.5 todo item)
  - [ ] Workflow state tracking variables
  - [ ] Checkpoint save operations
  - [ ] Error messages and recovery logic
- [ ] Update documentation sections mentioning Phase 2.5

**Testing**:
```bash
# Verify Phase 2.5 completely removed
! grep -q "Phase 2\.5" .claude/commands/orchestrate.md

# Verify no complexity-estimator agent invocations in orchestrate
! grep -q "complexity-estimator" .claude/commands/orchestrate.md

# Verify AskUserQuestion added after Phase 2
grep -A 10 "Planning Phase Complete" .claude/commands/orchestrate.md | grep -q "AskUserQuestion"

# Verify line count reduced
CURRENT_LINES=$(wc -l < .claude/commands/orchestrate.md)
[ "$CURRENT_LINES" -lt 5700 ]  # Should be ~5700 after removing 347 lines
```

**Git Commit**: `feat(070): Phase 2 - remove automatic complexity evaluation (Phase 2.5)`

---

### Phase 3: Remove Phase 4 (Plan Expansion)
**Objective**: Completely remove the automatic plan expansion section (Phase 4) and transfer expansion logic to /expand command.

**Complexity**: Medium-High

**Tasks**:
- [ ] Read Phase 4 section completely (lines ~2257-2727, 470 lines)
- [ ] Extract valuable content for /expand enhancement:
  - [ ] Expansion-specialist agent invocation template → Transfer to `/expand` command
  - [ ] Phase expansion algorithm → Document in `/expand` command
  - [ ] Recursive expansion logic → Transfer to `/expand` command
  - [ ] Expansion verification patterns → Transfer to `/expand` command
- [ ] Extract supplemental content for reference files:
  - [ ] Extended expansion examples → `shared/orchestration-alternatives.md`
  - [ ] Expansion strategy alternatives → `shared/orchestration-alternatives.md`
- [ ] Remove Phase 4 section from orchestrate.md:
  - [ ] Delete section header: "## Phase 4: Plan Expansion"
  - [ ] Delete all subsections
  - [ ] Delete expansion-specialist agent invocation template
  - [ ] Delete expansion file verification code
  - [ ] Delete recursive expansion logic
  - [ ] Delete expansion checkpoint code
- [ ] Update /expand command (`.claude/commands/expand.md`):
  - [ ] Add Phase 0: Complexity Evaluation (using complexity-estimator agent)
  - [ ] Transfer Phase 4 expansion logic as new Phase 1
  - [ ] Add recursive expansion capability (expand generated phase files if warranted)
  - [ ] Ensure /expand can be invoked standalone or from /orchestrate
  - [ ] Update /expand to accept plan path as argument
- [ ] Remove Phase 4 references from orchestrate.md:
  - [ ] Conditional branching from Phase 2.5 → Phase 4
  - [ ] TodoWrite phase items
  - [ ] Workflow state variables
  - [ ] Checkpoint operations
  - [ ] Error messages
- [ ] Update Phase 2→Phase 3 transition:
  - [ ] If user chooses expansion: Invoke /expand command via SlashCommand
  - [ ] If user skips expansion: Proceed directly to Phase 3 (Implementation)
  - [ ] After /expand completes: Resume with Phase 3 (Implementation)

**Testing**:
```bash
# Verify Phase 4 completely removed from orchestrate
! grep -q "Phase 4:" .claude/commands/orchestrate.md
! grep -q "Plan Expansion" .claude/commands/orchestrate.md

# Verify no expansion-specialist invocations in orchestrate
! grep -q "expansion-specialist" .claude/commands/orchestrate.md

# Verify /expand command enhanced
grep -q "Phase 0: Complexity Evaluation" .claude/commands/expand.md
grep -q "complexity-estimator" .claude/commands/expand.md

# Verify line count further reduced
CURRENT_LINES=$(wc -l < .claude/commands/orchestrate.md)
[ "$CURRENT_LINES" -lt 5300 ]  # Should be ~5230 after removing 470 more lines

# Test /expand can be invoked standalone
# (Manual test: /expand specs/plans/001_test_plan.md)
```

**Git Commit**: `feat(070): Phase 3 - remove automatic expansion and enhance /expand command`

---

### Phase 4: Renumber Phases and Update Cross-References
**Objective**: Renumber all remaining phases sequentially (0-5) and update all cross-references throughout the command.

**Complexity**: Medium

**Tasks**:
- [ ] Renumber phase sections in orchestrate.md:
  - [ ] Phase 5 (Implementation) → Phase 3 (Implementation)
  - [ ] Phase 6 (Testing) → Phase 4 (Testing)
  - [ ] Phase 7 (Debugging) → Phase 5 (Debugging)
  - [ ] Phase 8 (Documentation) → [MERGE into Phase 3 completion or keep as Phase 6]
- [ ] Update phase section headers:
  - [ ] Find: `## Phase 5:` → Replace: `## Phase 3:`
  - [ ] Find: `## Phase 6:` → Replace: `## Phase 4:`
  - [ ] Find: `## Phase 7:` → Replace: `## Phase 5:`
- [ ] Update TodoWrite initialization:
  - [ ] Update todo item descriptions to reflect new phase numbers
  - [ ] Ensure 6 phase items (0-5) instead of 8+
- [ ] Update checkpoint variable names:
  - [ ] `CHECKPOINT_PHASE_5_*` → `CHECKPOINT_PHASE_3_*`
  - [ ] `CHECKPOINT_PHASE_6_*` → `CHECKPOINT_PHASE_4_*`
  - [ ] `CHECKPOINT_PHASE_7_*` → `CHECKPOINT_PHASE_5_*`
- [ ] Update PROGRESS markers:
  - [ ] Find: `PROGRESS: Phase 5` → Replace: `PROGRESS: Phase 3`
  - [ ] Find: `PROGRESS: Phase 6` → Replace: `PROGRESS: Phase 4`
  - [ ] Find: `PROGRESS: Phase 7` → Replace: `PROGRESS: Phase 5`
- [ ] Update error messages and logging:
  - [ ] Search for all phase number references in error strings
  - [ ] Update conditional logic branches
  - [ ] Update phase completion checkpoints
- [ ] Update workflow state variables:
  - [ ] `current_phase` values (use new phase names/numbers)
  - [ ] `completed_phases` array tracking
- [ ] Update cross-references in documentation sections:
  - [ ] Command description (lines 40-55)
  - [ ] Reference files section
  - [ ] Example workflows
  - [ ] Dry-run output examples

**Testing**:
```bash
# Verify no references to old phase numbers for removed phases
! grep -q "Phase 2\.5" .claude/commands/orchestrate.md
! grep -q "Phase 4:" .claude/commands/orchestrate.md  # Old Phase 4 (expansion)
! grep -q "Phase 5:" .claude/commands/orchestrate.md  # Old Phase 5 (implementation)
! grep -q "Phase 6:" .claude/commands/orchestrate.md  # Old Phase 6 (testing)
! grep -q "Phase 7:" .claude/commands/orchestrate.md  # Old Phase 7 (debugging)

# Verify new phase numbering (sequential 0-5 or 0-6)
grep -q "## Phase 0:" .claude/commands/orchestrate.md
grep -q "## Phase 1:" .claude/commands/orchestrate.md
grep -q "## Phase 2:" .claude/commands/orchestrate.md
grep -q "## Phase 3:" .claude/commands/orchestrate.md
grep -q "## Phase 4:" .claude/commands/orchestrate.md
grep -q "## Phase 5:" .claude/commands/orchestrate.md

# Verify TodoWrite has 6 items (not 8+)
grep -A 50 "TodoWrite" .claude/commands/orchestrate.md | grep -c '"content":' | grep -q "6"

# Check for orphaned phase references
! grep -E "Phase [789]:" .claude/commands/orchestrate.md
```

**Git Commit**: `feat(070): Phase 4 - renumber phases and update cross-references`

---

### Phase 5: Content Extraction and Size Reduction
**Objective**: Extract supplemental (non-execution-critical) content to reference files to achieve 30-40% file size reduction while maintaining command independence.

**Complexity**: Medium

**Tasks**:
- [ ] Identify extraction candidates (following 80/20 rule):
  - [ ] Extended background explanations (keep inline summary, extract deep dive)
  - [ ] Historical design decisions (extract to orchestration-history.md)
  - [ ] Alternative orchestration strategies (extract to orchestration-alternatives.md)
  - [ ] Advanced troubleshooting scenarios (extract to orchestration-troubleshooting.md)
  - [ ] Performance optimization deep dives (extract to orchestration-performance.md)
  - [ ] Redundant examples (keep 1-2 inline, extract additional)
- [ ] Extract content section by section:
  - [ ] For each extraction candidate:
    - [ ] Copy content to appropriate shared/ file
    - [ ] Replace with concise inline summary (1-2 sentences)
    - [ ] Add reference: "For extended details: See .claude/commands/shared/[file].md#[section]"
  - [ ] Ensure all execution-critical content stays inline (80%)
  - [ ] Ensure extracted content is supplemental only (20%)
- [ ] Create/populate shared reference files:
  - [ ] `complexity-evaluation-details.md` - Complexity formula deep dive, threshold examples
  - [ ] `orchestration-alternatives.md` - Sequential mode, custom workflows, advanced patterns
  - [ ] `orchestration-history.md` - Design rationale, architecture evolution, refactoring history
  - [ ] `orchestration-troubleshooting.md` - Edge cases, known issues, workarounds
  - [ ] `orchestration-performance.md` - Parallelization strategies, context optimization
- [ ] Validate extraction quality:
  - [ ] Test command execution WITHOUT shared/ directory (must still work)
  - [ ] Verify all CRITICAL/IMPORTANT warnings remain inline
  - [ ] Verify all Task invocation templates complete (no truncation)
  - [ ] Verify all numbered step procedures remain inline
  - [ ] Verify all bash code blocks for execution remain inline
- [ ] Measure file size reduction:
  - [ ] Count lines before extraction
  - [ ] Count lines after extraction
  - [ ] Verify 30-40% reduction achieved (target: 3,600-4,200 lines)
  - [ ] Verify token count reduced proportionally

**Testing**:
```bash
# Verify file size target achieved
FINAL_LINES=$(wc -l < .claude/commands/orchestrate.md)
echo "Final line count: $FINAL_LINES"
[ "$FINAL_LINES" -ge 3600 ] && [ "$FINAL_LINES" -le 4200 ]

# Verify execution independence (critical test)
mv .claude/commands/shared .claude/commands/shared.backup
# Run orchestrate command (should succeed without shared/ directory)
# If fails: Over-extracted execution-critical content (revert extraction)
mv .claude/commands/shared.backup .claude/commands/shared

# Verify critical content remains inline
grep -c "CRITICAL:" .claude/commands/orchestrate.md  # Should be ≥8
grep -c "EXECUTE NOW" .claude/commands/orchestrate.md  # Should be ≥12
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

**Git Commit**: `feat(070): Phase 5 - content extraction and size reduction (${REDUCTION}% reduction)`

---

### Phase 6: Comprehensive Testing and Validation
**Objective**: Execute comprehensive tests to validate refactored command functionality, user control, standards compliance, and backward compatibility.

**Complexity**: Medium-High

**Tasks**:
- [ ] Run validation tests from command architecture standards:
  - [ ] `grep -c "Step [0-9]:" orchestrate.md` ≥ 20 (numbered steps)
  - [ ] `grep -c "CRITICAL:" orchestrate.md` ≥ 8 (critical warnings)
  - [ ] `grep -c "```bash" orchestrate.md` ≥ 15 (bash execution blocks)
  - [ ] `grep -c "Task {" orchestrate.md` ≥ 5 (agent invocations)
  - [ ] `grep -c "EXECUTE NOW" orchestrate.md` ≥ 12 (imperative enforcement)
- [ ] Test Phase Execution (End-to-End):
  - [ ] Create test feature: "Add test feature for orchestrate validation"
  - [ ] Execute: `/orchestrate "Add test feature for orchestrate validation" --dry-run`
  - [ ] Verify dry-run shows 6 phases (0-5), not 8+
  - [ ] Execute actual workflow (not dry-run)
  - [ ] Verify phases execute in correct order: 0→1→2→(optional expand)→3→4→5
  - [ ] Verify no Phase 2.5 or old Phase 4 execution
  - [ ] Verify implementation, testing, debugging phases work correctly
- [ ] Test User Control (Expansion Prompt):
  - [ ] Execute workflow, wait for Phase 2 completion
  - [ ] Verify AskUserQuestion appears with expansion options
  - [ ] Test "Yes - expand now" path:
    - [ ] Verify /expand command invoked
    - [ ] Verify plan expansion occurs
    - [ ] Verify workflow resumes at Phase 3 after expansion
  - [ ] Test "No - proceed to implementation" path:
    - [ ] Verify workflow skips expansion
    - [ ] Verify proceeds directly to Phase 3 (Implementation)
  - [ ] Test "Review plan first" path (if implemented):
    - [ ] Verify plan summary displayed
    - [ ] Verify re-prompt occurs
- [ ] Test Standards Compliance:
  - [ ] Execution Independence Test:
    - [ ] Temporarily rename `.claude/commands/shared/` directory
    - [ ] Execute /orchestrate command
    - [ ] Verify command completes successfully (proves independence)
    - [ ] Restore shared/ directory
  - [ ] Imperative Language Verification:
    - [ ] Verify all critical operations use MUST/WILL/SHALL language
    - [ ] Verify all agent prompts use "EXECUTE NOW" or "YOU MUST" patterns
    - [ ] Verify all verification checkpoints use "MANDATORY" enforcement
  - [ ] Behavioral Injection Verification:
    - [ ] Verify all agent invocations use Task tool (not SlashCommand)
    - [ ] Verify agent prompts inject complete behavioral instructions
    - [ ] Verify no truncated templates or "See [file]" replacements
- [ ] Test Backward Compatibility:
  - [ ] Execute /orchestrate with existing plan (from specs/)
  - [ ] Verify plan executes despite phase renumbering
  - [ ] Verify checkpoint save/restore works
  - [ ] Verify error recovery patterns work
- [ ] Test /expand Command Integration:
  - [ ] Invoke /expand standalone with test plan
  - [ ] Verify Phase 0 (Complexity Evaluation) executes
  - [ ] Verify expansion logic works (from transferred Phase 4 code)
  - [ ] Verify recursive expansion capability
- [ ] Performance Validation:
  - [ ] Measure file size: verify 3,600-4,200 lines
  - [ ] Measure token count: verify ~35,000-40,000 tokens
  - [ ] Verify 30-40% reduction from original (6,051 lines, 56,849 tokens)
- [ ] Documentation Validation:
  - [ ] Verify all phase references updated in README
  - [ ] Verify command description reflects simplified architecture
  - [ ] Verify examples show 6-phase workflow
  - [ ] Verify reference files have proper structure and content

**Testing**:
```bash
# Run all validation tests
cd .claude/tests
./test_orchestrate_refactor.sh

# Expected output:
# ✓ Validation tests passed (5/5)
# ✓ Phase execution test passed
# ✓ User control test passed (3/3 paths)
# ✓ Standards compliance test passed (3/3)
# ✓ Backward compatibility test passed
# ✓ /expand integration test passed
# ✓ Performance validation passed
# ✓ Documentation validation passed
#
# Overall: ALL TESTS PASSED (8/8 test suites)

# Manual verification checklist
echo "Manual Verification Checklist:"
echo "- [ ] /orchestrate executes 6 phases (not 8+)"
echo "- [ ] Expansion prompt appears after planning"
echo "- [ ] Expansion is optional (user control)"
echo "- [ ] /expand command works standalone"
echo "- [ ] File size reduced 30-40%"
echo "- [ ] All critical content inline"
echo "- [ ] Command executes without shared/ directory"
echo "- [ ] Phase numbering sequential 0-5"
```

**Git Commit**: `feat(070): Phase 6 - comprehensive testing and validation complete`

---

## Testing Strategy

### Unit Tests

**Test File**: `.claude/tests/test_orchestrate_refactor.sh`

```bash
#!/bin/bash
# Test suite for orchestrate refactor

set -e

ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

echo "=== Orchestrate Refactor Test Suite ==="
echo ""

# Test 1: Validation tests
echo "Test 1: Validation tests..."
STEP_COUNT=$(grep -c "Step [0-9]:" "$ORCHESTRATE_FILE")
CRITICAL_COUNT=$(grep -c "CRITICAL:" "$ORCHESTRATE_FILE")
BASH_COUNT=$(grep -c "\`\`\`bash" "$ORCHESTRATE_FILE")
TASK_COUNT=$(grep -c "Task {" "$ORCHESTRATE_FILE")
EXECUTE_COUNT=$(grep -c "EXECUTE NOW" "$ORCHESTRATE_FILE")

[ "$STEP_COUNT" -ge 20 ] || { echo "FAIL: Step count too low ($STEP_COUNT < 20)"; exit 1; }
[ "$CRITICAL_COUNT" -ge 8 ] || { echo "FAIL: Critical count too low ($CRITICAL_COUNT < 8)"; exit 1; }
[ "$BASH_COUNT" -ge 15 ] || { echo "FAIL: Bash block count too low ($BASH_COUNT < 15)"; exit 1; }
[ "$TASK_COUNT" -ge 5 ] || { echo "FAIL: Task count too low ($TASK_COUNT < 5)"; exit 1; }
[ "$EXECUTE_COUNT" -ge 12 ] || { echo "FAIL: Execute count too low ($EXECUTE_COUNT < 12)"; exit 1; }
echo "✓ Validation tests passed (5/5)"
echo ""

# Test 2: Phase removal verification
echo "Test 2: Phase removal verification..."
! grep -q "Phase 2\.5" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 2.5 still present"; exit 1; }
! grep -q "complexity-estimator" "$ORCHESTRATE_FILE" || { echo "FAIL: complexity-estimator still in orchestrate"; exit 1; }
grep -q "Phase 4:" "$ORCHESTRATE_FILE" && {
  # If "Phase 4:" exists, verify it's the NEW Phase 4 (Testing), not old Phase 4 (Expansion)
  grep -A 5 "Phase 4:" "$ORCHESTRATE_FILE" | grep -q "Testing" || { echo "FAIL: Old Phase 4 (Expansion) still present"; exit 1; }
}
echo "✓ Phase removal verified"
echo ""

# Test 3: Phase renumbering verification
echo "Test 3: Phase renumbering verification..."
grep -q "## Phase 0:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 0 missing"; exit 1; }
grep -q "## Phase 1:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 1 missing"; exit 1; }
grep -q "## Phase 2:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 2 missing"; exit 1; }
grep -q "## Phase 3:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 3 missing"; exit 1; }
grep -q "## Phase 4:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 4 missing"; exit 1; }
grep -q "## Phase 5:" "$ORCHESTRATE_FILE" || { echo "FAIL: Phase 5 missing"; exit 1; }
! grep -E "Phase [789]:" "$ORCHESTRATE_FILE" || { echo "FAIL: Old phase numbers still present"; exit 1; }
echo "✓ Phase renumbering verified"
echo ""

# Test 4: User control verification
echo "Test 4: User control verification..."
grep -q "AskUserQuestion" "$ORCHESTRATE_FILE" || { echo "FAIL: AskUserQuestion not found"; exit 1; }
grep -A 20 "Planning Phase Complete" "$ORCHESTRATE_FILE" | grep -q "expand" || { echo "FAIL: Expansion option not offered"; exit 1; }
echo "✓ User control verified"
echo ""

# Test 5: File size verification
echo "Test 5: File size verification..."
LINE_COUNT=$(wc -l < "$ORCHESTRATE_FILE")
echo "Current line count: $LINE_COUNT"
[ "$LINE_COUNT" -ge 3600 ] || { echo "FAIL: Line count too low ($LINE_COUNT < 3600)"; exit 1; }
[ "$LINE_COUNT" -le 4200 ] || { echo "FAIL: Line count too high ($LINE_COUNT > 4200)"; exit 1; }

ORIGINAL_LINES=6051
REDUCTION=$(echo "scale=2; (($ORIGINAL_LINES - $LINE_COUNT) / $ORIGINAL_LINES) * 100" | bc)
echo "Size reduction: ${REDUCTION}%"
[ $(echo "$REDUCTION >= 30" | bc) -eq 1 ] || { echo "FAIL: Reduction too low (${REDUCTION}% < 30%)"; exit 1; }
[ $(echo "$REDUCTION <= 40" | bc) -eq 1 ] || { echo "FAIL: Reduction too high (${REDUCTION}% > 40%)"; exit 1; }
echo "✓ File size verified (${REDUCTION}% reduction)"
echo ""

# Test 6: Execution independence
echo "Test 6: Execution independence..."
if [ -d ".claude/commands/shared" ]; then
  mv .claude/commands/shared .claude/commands/shared.backup
  echo "✓ Shared directory temporarily moved"
  # Note: Full execution test would require running /orchestrate
  # For now, verify command file can be read
  [ -f "$ORCHESTRATE_FILE" ] || { echo "FAIL: Command file not readable"; exit 1; }
  mv .claude/commands/shared.backup .claude/commands/shared
  echo "✓ Execution independence verified (basic)"
else
  echo "⚠  Shared directory not found (already independent or not created)"
fi
echo ""

echo "=== All Tests Passed ==="
```

### Integration Tests

1. **Full Workflow Test**:
   - Execute /orchestrate with real feature
   - Verify 6-phase execution
   - Verify expansion prompt
   - Verify both expansion paths work

2. **Backward Compatibility Test**:
   - Use existing plan from specs/
   - Verify execution completes
   - Verify checkpoint compatibility

3. **Standards Compliance Test**:
   - Verify command executes without shared/ directory
   - Verify imperative language patterns
   - Verify behavioral injection patterns

### Manual Validation

1. **Phase Execution Flow**:
   - Verify phases execute in order: 0→1→2→(prompt)→3→4→5
   - Verify no automatic expansion
   - Verify user prompt appears

2. **User Experience**:
   - Verify expansion prompt is clear
   - Verify both "yes" and "no" paths work
   - Verify workflow is intuitive

3. **Performance**:
   - Verify file loads faster (30-40% smaller)
   - Verify execution time unchanged
   - Verify context usage similar

## Documentation Requirements

### Update Files

1. **orchestrate.md**:
   - Update command description (lines 40-55)
   - Update phase list to show 6 phases
   - Remove Phase 2.5 and old Phase 4 documentation
   - Add AskUserQuestion documentation
   - Update examples to show new workflow

2. **CLAUDE.md**:
   - Update /orchestrate description in project commands section
   - Update phase count (8+ → 6)
   - Add note about user-controlled expansion
   - Update workflow diagrams if present

3. **expand.md**:
   - Add Phase 0: Complexity Evaluation
   - Document transferred expansion logic
   - Add recursive expansion capability
   - Update examples

4. **Shared Reference Files** (NEW):
   - `complexity-evaluation-details.md` - Complexity analysis deep dive
   - `orchestration-alternatives.md` - Alternative workflow patterns
   - `orchestration-history.md` - Design evolution and rationale
   - `orchestration-troubleshooting.md` - Advanced troubleshooting
   - `orchestration-performance.md` - Performance optimization

5. **.claude/commands/README.md**:
   - Update /orchestrate description
   - Update phase count
   - Add note about /expand integration

### Documentation Standards

- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams (no ASCII art)
- No emojis in file content
- Maintain timeless writing (no "previously" or "new" markers)
- Update modification dates
- Cross-reference related commands

## Dependencies

### Internal Dependencies
- `.claude/commands/expand.md` - MUST be enhanced to accept complexity evaluation
- `.claude/agents/complexity-estimator.md` - Used by /expand (not /orchestrate)
- `.claude/agents/expansion-specialist.md` - Used by /expand (not /orchestrate)
- `.claude/lib/complexity-thresholds.sh` - Utility library (unchanged)

### External Dependencies
None

### Breaking Changes
- Workflows expecting automatic expansion now require explicit user approval
- Phase numbers changed: 5→3 (Implementation), 6→4 (Testing), 7→5 (Debugging)
- Checkpoint files with old phase numbers may need regeneration
- Phase 2.5 and old Phase 4 no longer exist

## Migration Guide

### For Users
1. **Automatic Expansion Removed**: After plan creation, you'll be prompted to expand. Choose "Yes" if you want detailed phase organization, or "No" to proceed directly to implementation.

2. **Phase Numbers Changed**: If you reference specific phase numbers in your workflows:
   - Old Phase 5 (Implementation) → New Phase 3
   - Old Phase 6 (Testing) → New Phase 4
   - Old Phase 7 (Debugging) → New Phase 5

3. **No Functional Changes**: The actual workflow capabilities remain the same, just simpler and with more user control.

### For Developers
1. **Checkpoint Files**: If you have custom checkpoint parsing, update phase number mappings.

2. **Phase References**: Update any code that references phase numbers:
   ```bash
   # OLD
   if [ "$PHASE" == "5" ]; then  # Implementation

   # NEW
   if [ "$PHASE" == "3" ]; then  # Implementation
   ```

3. **Expansion Logic**: If you extended /orchestrate's expansion logic, migrate to /expand command instead.

## Notes

### Design Rationale

**Why Remove Automatic Expansion?**
- **User Agency**: Users should control when plans are expanded, not the system
- **Simplicity**: Automatic complexity evaluation adds 817 lines of complexity
- **Separation of Concerns**: Expansion is a separate operation from orchestration
- **Standards Compliance**: Automatic expansion violates command architecture standards

**Why Transfer to /expand?**
- **Single Responsibility**: /expand is specifically for plan expansion
- **Reusability**: Expansion logic can be used standalone or from /orchestrate
- **Recursive Capability**: /expand can recursively expand generated phase files
- **Complexity Analysis**: /expand begins with complexity evaluation (per TODO3.md)

**Why 30-40% Reduction Target?**
- **Maintainability**: Smaller files are easier to maintain and update
- **Performance**: Faster loading, lower context usage
- **Standards Compliance**: Target aligns with command architecture guidelines
- **Critical Mass**: Preserves all execution-critical content (80/20 rule)

### Implementation Considerations

**Phase Renumbering Impact**:
- Low risk: Most references are in orchestrate.md itself (now updated)
- Medium risk: Checkpoint files from old workflows (regenerate if needed)
- Low risk: External references rare (mostly in CLAUDE.md, now updated)

**Content Extraction Risk**:
- Mitigated by 80/20 rule: execution-critical content stays inline
- Validated by independence test: command must work without shared/ directory
- Protected by grep tests: minimum counts for critical patterns

**User Experience**:
- Improved: Clear expansion choice instead of automatic decision
- Simplified: 6 phases instead of 8+ phases with conditional branches
- Empowered: User controls workflow, not automated heuristics

### Future Enhancements

**Potential Improvements** (out of scope for this refactor):
1. **Smart Expansion Hints**: Show inline complexity indicators to help user decide
2. **Expansion Presets**: "Always expand", "Never expand", "Ask each time" user preferences
3. **Plan Templates**: Pre-expanded plan templates for common workflows
4. **Progressive Disclosure**: Expand only high-complexity phases, not entire plan

**Monitoring**:
- Track user expansion choices (yes/no ratio)
- Measure impact on workflow completion time
- Gather feedback on new user prompt
- Evaluate whether automatic expansion is ever requested again

---

**Plan Status**: Ready for implementation
**Estimated Total Time**: 12-18 hours
**Risk Level**: Medium (significant refactoring, but well-scoped)
**Success Probability**: High (clear requirements, comprehensive testing)
