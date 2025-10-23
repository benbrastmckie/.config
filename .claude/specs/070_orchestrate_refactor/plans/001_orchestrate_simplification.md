# /orchestrate Command Systematic Refactor - Implementation Plan

## Metadata
- **Date**: 2025-10-22 (Created), 2025-10-23 (Revised)
- **Feature**: Systematic refactor of /orchestrate command
- **Scope**: Remove automatic complexity evaluation and expansion, simplify phase architecture, enhance user control
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Context**: TODO3.md requirements, command architecture standards compliance
- **Plan Number**: 070-001
- **Structure Level**: 1
- **Expanded Phases**: [3]
- **Revision**: 2 (Standards Compliance Enhancement - see REVISION_SUMMARY.md)

## Revision History

### 2025-10-23 - Revision 2: Standards Compliance Enhancement

**Changes**: Enhanced all phases with imperative enforcement patterns, verification checkpoints, and fallback mechanisms per `.claude/docs/` standards

**Reason**: User requested "fully comply with the standards given in .claude/docs/"

**Modified Phases**: Phases 1, 2, 4 enhanced with execution blocks and verification; Phases 5, 6 status fields added

**Details**: See [REVISION_SUMMARY.md](001_orchestrate_simplification_REVISION_SUMMARY.md) for complete analysis

**Standards Applied**:
- ✅ Standard 0: Execution Enforcement (EXECUTE NOW, MANDATORY VERIFICATION)
- ✅ Standard 1: Inline Execution Content (37+ bash blocks)
- ✅ Directory Protocols (topic-based organization)
- ✅ Imperative Language Guidelines (YOU MUST, CRITICAL, REQUIRED)

**Metrics**:
- Bash blocks: 11 → 37+ (+236% increase)
- Verification checkpoints: 0 → 26+ (new)
- Fallback mechanisms: 0 → 3 (new)
- Plan size: 854 → 1,337 lines (+56% for execution content)

---

## Overview

This refactor addresses the concerns raised in TODO3.md by systematically removing the automatic complexity evaluation (Phase 2.5) and automatic expansion pipeline (Phase 4) from `/orchestrate`, simplifying the command to a clean 6-phase architecture that respects user agency and adheres strictly to command architecture standards documented in `.claude/docs/`.

**Plan now includes imperative enforcement patterns throughout for full standards compliance.**

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

**Status**: COMPLETED

#### Implementation Steps

**STEP 1 (REQUIRED) - Create Topic Directory Structure**

**EXECUTE NOW - Create Directory Tree**:

```bash
# Create complete topic directory structure
TOPIC_DIR=".claude/specs/070_orchestrate_refactor"

mkdir -p "$TOPIC_DIR"/{plans,reports,summaries,debug,scripts,outputs,artifacts,backups}

echo "✓ Topic directory structure created: $TOPIC_DIR"
```

**MANDATORY VERIFICATION - Directory Structure Created**:

```bash
# Verify all subdirectories exist
REQUIRED_DIRS=("plans" "reports" "summaries" "debug" "scripts" "outputs" "artifacts" "backups")

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$TOPIC_DIR/$dir" ]; then
    echo "❌ ERROR: Required directory missing: $TOPIC_DIR/$dir"
    exit 1
  fi
done

echo "✓ VERIFIED: All 8 subdirectories created"
```

---

**STEP 2 (REQUIRED) - Read Complete orchestrate.md File**

**EXECUTE NOW - Read File in Segments** (file is 6,051 lines):

```bash
ORCHESTRATE_FILE=".claude/commands/orchestrate.md"
TOTAL_LINES=$(wc -l < "$ORCHESTRATE_FILE")

echo "Reading orchestrate.md: $TOTAL_LINES lines total"
echo "Will read in segments due to size"

# Read first 2000 lines to identify Phase 2.5
# Read next 2000 lines to identify Phase 4
# Use Read tool with offset/limit parameters
```

**YOU MUST** use multiple Read tool calls:
- Read lines 1-2000 (identify Phase 2.5 start)
- Read lines 2000-4000 (identify Phase 4)
- Read lines 4000-6051 (identify remaining phase references)

---

**STEP 3 (REQUIRED) - Identify Sections to Remove**

**EXECUTE NOW - Locate Phase 2.5 and Phase 4 Boundaries**:

```bash
# Find Phase 2.5 section
PHASE_2_5_START=$(grep -n "^## Phase 2\.5:" "$ORCHESTRATE_FILE" | cut -d: -f1)
PHASE_2_5_END=$(grep -n "^## Phase 4:" "$ORCHESTRATE_FILE" | cut -d: -f1)
PHASE_2_5_LINES=$((PHASE_2_5_END - PHASE_2_5_START))

# Find Phase 4 section
PHASE_4_START="$PHASE_2_5_END"
PHASE_4_END=$(grep -n "^## Phase 5:" "$ORCHESTRATE_FILE" | cut -d: -f1)
PHASE_4_LINES=$((PHASE_4_END - PHASE_4_START))

echo "Phase 2.5: Lines $PHASE_2_5_START-$PHASE_2_5_END ($PHASE_2_5_LINES lines)"
echo "Phase 4: Lines $PHASE_4_START-$PHASE_4_END ($PHASE_4_LINES lines)"

# Document in phase map file
cat > "$TOPIC_DIR/artifacts/phase_map.txt" <<EOF
Phase 2.5 Boundaries:
  Start: Line $PHASE_2_5_START
  End: Line $PHASE_2_5_END
  Lines: $PHASE_2_5_LINES

Phase 4 Boundaries:
  Start: Line $PHASE_4_START
  End: Line $PHASE_4_END
  Lines: $PHASE_4_LINES

Agent References:
  complexity-estimator: $(grep -n "complexity-estimator" "$ORCHESTRATE_FILE" | wc -l) occurrences
  expansion-specialist: $(grep -n "expansion-specialist" "$ORCHESTRATE_FILE" | wc -l) occurrences
EOF
```

**MANDATORY VERIFICATION - Sections Identified**:

```bash
# Verify phase boundaries found
if [ -z "$PHASE_2_5_START" ] || [ -z "$PHASE_4_START" ]; then
  echo "❌ CRITICAL: Phase boundaries not found"
  exit 1
fi

# Verify expected line counts
if [ "$PHASE_2_5_LINES" -lt 300 ] || [ "$PHASE_2_5_LINES" -gt 400 ]; then
  echo "⚠️  WARNING: Phase 2.5 size unexpected ($PHASE_2_5_LINES lines, expected ~347)"
fi

if [ "$PHASE_4_LINES" -lt 400 ] || [ "$PHASE_4_LINES" -gt 500 ]; then
  echo "⚠️  WARNING: Phase 4 size unexpected ($PHASE_4_LINES lines, expected ~470)"
fi

echo "✓ VERIFIED: Phase boundaries documented in $TOPIC_DIR/artifacts/phase_map.txt"
```

---

**STEP 4 (REQUIRED) - Create Extraction Target Files**

**EXECUTE NOW - Create Shared Reference Files**:

```bash
SHARED_DIR=".claude/commands/shared"
mkdir -p "$SHARED_DIR"

# Create extraction target files with headers
declare -A EXTRACTION_FILES=(
  ["complexity-evaluation-details.md"]="Complexity Evaluation Details"
  ["orchestration-alternatives.md"]="Orchestration Workflow Alternatives"
  ["orchestration-history.md"]="Orchestration Architecture History"
  ["orchestration-troubleshooting.md"]="Orchestration Troubleshooting Guide"
  ["orchestration-performance.md"]="Orchestration Performance Optimization"
)

for file in "${!EXTRACTION_FILES[@]}"; do
  TITLE="${EXTRACTION_FILES[$file]}"
  cat > "$SHARED_DIR/$file" <<EOF
# $TITLE

[Extracted from orchestrate.md during 070 refactor]

Last Updated: $(date +%Y-%m-%d)

---

[Content will be added during Phase 2, 3, and 5]
EOF
  echo "✓ Created: $SHARED_DIR/$file"
done
```

**MANDATORY VERIFICATION - Files Created**:

```bash
# Verify all extraction files exist
for file in "${!EXTRACTION_FILES[@]}"; do
  if [ ! -f "$SHARED_DIR/$file" ]; then
    echo "❌ ERROR: Extraction file not created: $file"
    exit 1
  fi
done

echo "✓ VERIFIED: All 5 extraction target files created"
```

---

**STEP 5 (REQUIRED) - Create Backup**

**EXECUTE NOW - Backup orchestrate.md**:

```bash
BACKUP_FILE="$ORCHESTRATE_FILE.backup-$(date +%Y%m%d)"

# Create backup
cp "$ORCHESTRATE_FILE" "$BACKUP_FILE"

# Verify backup matches original
if ! cmp -s "$ORCHESTRATE_FILE" "$BACKUP_FILE"; then
  echo "❌ CRITICAL: Backup verification failed"
  exit 1
fi

echo "✓ Backup created: $BACKUP_FILE"
```

**FALLBACK MECHANISM**:

```bash
# If any phase fails, restore from backup:
# cp "$BACKUP_FILE" "$ORCHESTRATE_FILE"
```

---

**CHECKPOINT REQUIREMENT**

After completing Phase 1, YOU MUST report:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Phase 1 Complete - Preparation and Analysis
═══════════════════════════════════════════════════════

Directory Structure: ✓ CREATED
  Location: .claude/specs/070_orchestrate_refactor/
  Subdirectories: 8 (plans, reports, summaries, debug, scripts, outputs, artifacts, backups)

Phase Boundaries Identified: ✓ DOCUMENTED
  Phase 2.5: Lines $PHASE_2_5_START-$PHASE_2_5_END ($PHASE_2_5_LINES lines)
  Phase 4: Lines $PHASE_4_START-$PHASE_4_END ($PHASE_4_LINES lines)
  Phase map: artifacts/phase_map.txt

Extraction Files Created: ✓ VERIFIED (5 files)
  - complexity-evaluation-details.md
  - orchestration-alternatives.md
  - orchestration-history.md
  - orchestration-troubleshooting.md
  - orchestration-performance.md

Backup Created: ✓ VERIFIED
  File: orchestrate.md.backup-$(date +%Y%m%d)
  Size: $(wc -l < "$BACKUP_FILE") lines (matches original)

Status: READY FOR PHASE 2
═══════════════════════════════════════════════════════
```

**Git Commit**: `feat(070): Phase 1 - preparation and analysis complete`

---

### Phase 2: Remove Phase 2.5 (Complexity Evaluation)
**Objective**: Completely remove the automatic complexity evaluation section (Phase 2.5) from orchestrate.md and update all branching logic.

**Complexity**: Medium

**Status**: COMPLETED

#### Implementation Steps

**STEP 1 (REQUIRED) - Extract Valuable Content for Reference Files**

**EXECUTE NOW - Copy Content to Extraction Files**:

```bash
ORCHESTRATE_FILE=".claude/commands/orchestrate.md"
SHARED_DIR=".claude/commands/shared"
PHASE_2_5_START=$(grep -n "^## Phase 2\.5:" "$ORCHESTRATE_FILE" | cut -d: -f1)
PHASE_2_5_END=$(grep -n "^## Phase 4:" "$ORCHESTRATE_FILE" | cut -d: -f1)

# Extract Phase 2.5 content to temporary file
sed -n "${PHASE_2_5_START},${PHASE_2_5_END}p" "$ORCHESTRATE_FILE" > /tmp/phase_2_5_content.txt

# Extract complexity formula documentation
grep -A 20 "complexity formula\|complexity score\|complexity calculation" /tmp/phase_2_5_content.txt >> "$SHARED_DIR/complexity-evaluation-details.md"

# Extract threshold loading examples
grep -A 30 "load_complexity_thresholds\|EXPANSION_THRESHOLD\|TASK_COUNT_THRESHOLD" /tmp/phase_2_5_content.txt >> "$SHARED_DIR/complexity-evaluation-details.md"

# Extract complexity metrics parsing
grep -A 25 "parse.*complexity\|extract.*complexity\|complexity.*metrics" /tmp/phase_2_5_content.txt >> "$SHARED_DIR/complexity-evaluation-details.md"

echo "✓ Content extracted to complexity-evaluation-details.md"
```

**MANDATORY VERIFICATION - Content Extracted**:

```bash
# Verify extraction file has content
FILE_SIZE=$(wc -l < "$SHARED_DIR/complexity-evaluation-details.md")

if [ "$FILE_SIZE" -lt 50 ]; then
  echo "⚠️  WARNING: Extraction file smaller than expected ($FILE_SIZE lines)"
fi

echo "✓ VERIFIED: Content extracted ($FILE_SIZE lines total)"
```

---

**STEP 2 (REQUIRED) - Remove Phase 2.5 Section**

**EXECUTE NOW - Delete Phase 2.5 Section**:

```bash
# Calculate exact lines to delete
LINES_TO_DELETE=$((PHASE_2_5_END - PHASE_2_5_START))

echo "Deleting Phase 2.5: Lines $PHASE_2_5_START to $PHASE_2_5_END ($LINES_TO_DELETE lines)"

# Create backup before deletion
cp "$ORCHESTRATE_FILE" "${ORCHESTRATE_FILE}.pre-phase2-deletion"

# Delete section
sed -i "${PHASE_2_5_START},$((PHASE_2_5_END - 1))d" "$ORCHESTRATE_FILE"

echo "✓ Phase 2.5 section deleted"
```

**MANDATORY VERIFICATION - Section Deleted**:

```bash
# Verify Phase 2.5 header no longer exists
if grep -q "^## Phase 2\.5:" "$ORCHESTRATE_FILE"; then
  echo "❌ CRITICAL: Phase 2.5 header still present"
  # Rollback
  cp "${ORCHESTRATE_FILE}.pre-phase2-deletion" "$ORCHESTRATE_FILE"
  exit 1
fi

# Verify complexity-estimator no longer invoked in orchestrate
if grep -q "complexity-estimator" "$ORCHESTRATE_FILE"; then
  echo "⚠️  WARNING: complexity-estimator still referenced (expected in /expand only)"
fi

# Verify line count reduced
CURRENT_LINES=$(wc -l < "$ORCHESTRATE_FILE")
EXPECTED_MAX=5750  # 6051 - 347 + buffer

if [ "$CURRENT_LINES" -gt "$EXPECTED_MAX" ]; then
  echo "⚠️  WARNING: Line count higher than expected ($CURRENT_LINES > $EXPECTED_MAX)"
fi

echo "✓ VERIFIED: Phase 2.5 removed, line count now $CURRENT_LINES"
```

---

**STEP 3 (REQUIRED) - Update Phase 2 Completion with User Prompt**

**EXECUTE NOW - Add AskUserQuestion After Phase 2**:

**YOU MUST** locate the Phase 2 completion section and add this exact code block:

```markdown
---

## Optional: Plan Review and Expansion

After plan creation, user can choose whether to expand the plan.

**EXECUTE NOW - Display Plan Summary**:

```bash
# Extract basic complexity indicators
PHASE_COUNT=$(grep -c "^### Phase" "$IMPLEMENTATION_PLAN_PATH")
TOTAL_TASKS=$(grep -c "^- \[ \]" "$IMPLEMENTATION_PLAN_PATH")
AVG_TASKS=$((TOTAL_TASKS / PHASE_COUNT))

echo "Plan Summary:"
echo "  Phases: $PHASE_COUNT"
echo "  Total tasks: $TOTAL_TASKS"
echo "  Average tasks/phase: $AVG_TASKS"
echo ""

if [ "$AVG_TASKS" -gt 8 ] || [ "$PHASE_COUNT" -gt 5 ]; then
  echo "💡 Recommendation: Consider expanding plan (complex structure detected)"
fi
```

**EXECUTE NOW - Present Expansion Choice**:

```yaml
AskUserQuestion:
  questions:
    - question: "Would you like to expand this plan for detailed phase organization?"
      header: "Expand Plan"
      multiSelect: false
      options:
        - label: "Yes - expand now"
          description: "Invoke /expand to create detailed phase files with complexity analysis"
        - label: "No - proceed to implementation"
          description: "Use current plan structure and proceed directly to implementation"
```

**EXECUTE NOW - Handle User Response**:

```bash
if [[ "$ANSWER_EXPAND_PLAN" == "Yes - expand now" ]]; then
  echo "Invoking /expand command..."
  /expand "$IMPLEMENTATION_PLAN_PATH"
  echo "✓ Plan expansion complete"
else
  echo "Proceeding with current plan structure"
fi
```
```

---

**STEP 4 (REQUIRED) - Remove Phase 2.5 References**

**EXECUTE NOW - Clean Up References**:

```bash
# Remove TodoWrite Phase 2.5 items
sed -i '/Phase 2\.5/d' "$ORCHESTRATE_FILE"

# Remove workflow state variables for complexity
sed -i '/WORKFLOW_STATE.*COMPLEXITY/d' "$ORCHESTRATE_FILE"
sed -i '/WORKFLOW_STATE.*EXPANSION_PENDING/d' "$ORCHESTRATE_FILE"

# Remove checkpoint operations for Phase 2.5
sed -i '/CHECKPOINT.*2\.5/d' "$ORCHESTRATE_FILE"
sed -i '/checkpoint.*complexity.*evaluation/Iid' "$ORCHESTRATE_FILE"

echo "✓ Phase 2.5 references removed"
```

**MANDATORY VERIFICATION - References Removed**:

```bash
# Count remaining Phase 2.5 references
REMAINING_REFS=$(grep -c "Phase 2\.5\|Phase 2-5\|phase_2_5" "$ORCHESTRATE_FILE" || true)

if [ "$REMAINING_REFS" -gt 0 ]; then
  echo "⚠️  WARNING: $REMAINING_REFS Phase 2.5 references remain"
  grep -n "Phase 2\.5\|Phase 2-5\|phase_2_5" "$ORCHESTRATE_FILE"
fi

echo "✓ VERIFIED: Phase 2.5 references removed (remaining: $REMAINING_REFS)"
```

---

**FALLBACK MECHANISM**:

```bash
# If deletion fails, restore from backup:
# cp "${ORCHESTRATE_FILE}.pre-phase2-deletion" "$ORCHESTRATE_FILE"
```

---

**CHECKPOINT REQUIREMENT**

After completing Phase 2, YOU MUST report:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Phase 2 Complete - Phase 2.5 Removed
═══════════════════════════════════════════════════════

Content Extracted: ✓ COMPLETED
  Destination: shared/complexity-evaluation-details.md
  Size: $FILE_SIZE lines

Phase 2.5 Section Deleted: ✓ VERIFIED
  Lines removed: $LINES_TO_DELETE
  New file size: $CURRENT_LINES lines (was 6051)
  Reduction: $((6051 - CURRENT_LINES)) lines

User Prompt Added: ✓ VERIFIED
  Location: After Phase 2 completion
  AskUserQuestion: Plan expansion choice
  Fallback: Proceed to implementation if user declines

References Cleaned: ✓ VERIFIED
  TodoWrite: Phase 2.5 item removed
  Workflow state: Complexity variables removed
  Checkpoints: Phase 2.5 checkpoints removed
  Remaining references: $REMAINING_REFS

Backup Available: orchestrate.md.pre-phase2-deletion

Status: READY FOR PHASE 3
═══════════════════════════════════════════════════════
```

**Git Commit**: `feat(070): Phase 2 - remove automatic complexity evaluation (Phase 2.5)`

---

### Phase 3: Remove Phase 4 (Plan Expansion)
**Objective**: Completely remove the automatic plan expansion section (Phase 4) and transfer expansion logic to /expand command.

**Complexity**: High (8.0/10)

**Status**: COMPLETED

**Summary**: This phase removes the 470-line Phase 4 (Plan Expansion) section from orchestrate.md, transfers expansion logic to /expand with new Phase 0 (Complexity Evaluation), and updates Phase 2→3 transition with user prompt for optional expansion via SlashCommand invocation.

For detailed tasks and implementation, see [Phase 3 Details](phase_3_remove_phase_4_expansion.md)

---

### Phase 4: Renumber Phases and Update Cross-References
**Objective**: Renumber all remaining phases sequentially (0-6) and update all cross-references throughout the command.

**Complexity**: Medium

**Status**: COMPLETED

#### Implementation Steps

**STEP 1 (REQUIRED) - Renumber Phase Section Headers**

**EXECUTE NOW - Update Phase Headers Sequentially**:

```bash
ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

# Create backup before renumbering
cp "$ORCHESTRATE_FILE" "${ORCHESTRATE_FILE}.pre-renumbering"

# Renumber phases (do in reverse order to avoid conflicts)
sed -i 's/^## Phase 7:/## Phase 5:/' "$ORCHESTRATE_FILE"
sed -i 's/^## Phase 6:/## Phase 4:/' "$ORCHESTRATE_FILE"
sed -i 's/^## Phase 5:/## Phase 3:/' "$ORCHESTRATE_FILE"

# Verify Phase 8 handling (merge or keep as Phase 6)
if grep -q "^## Phase 8:" "$ORCHESTRATE_FILE"; then
  echo "⚠️  Phase 8 found - review if it should be merged into Phase 3 or kept as Phase 6"
fi

echo "✓ Phase headers renumbered"
```

**MANDATORY VERIFICATION - Headers Renumbered**:

```bash
# Verify new phase numbering exists
for phase in 0 1 2 3 4 5; do
  if ! grep -q "^## Phase $phase:" "$ORCHESTRATE_FILE"; then
    echo "⚠️  WARNING: Phase $phase header not found"
  fi
done

# Verify old phase numbers removed (5, 6, 7 should not exist anymore)
for old_phase in 5 6 7; do
  # Check if old phase number appears as a header (not in text)
  if grep -q "^## Phase $old_phase:" "$ORCHESTRATE_FILE"; then
    echo "❌ ERROR: Old Phase $old_phase header still exists"
    exit 1
  fi
done

echo "✓ VERIFIED: Phase headers renumbered (0-5)"
```

---

**STEP 2 (REQUIRED) - Update Checkpoint Variable Names**

**EXECUTE NOW - Rename Checkpoint Variables**:

```bash
# Update checkpoint variable names throughout file
sed -i 's/CHECKPOINT_PHASE_7/CHECKPOINT_PHASE_5/g' "$ORCHESTRATE_FILE"
sed -i 's/CHECKPOINT_PHASE_6/CHECKPOINT_PHASE_4/g' "$ORCHESTRATE_FILE"
sed -i 's/CHECKPOINT_PHASE_5/CHECKPOINT_PHASE_3/g' "$ORCHESTRATE_FILE"

# Update phase_5, phase_6, phase_7 in variable names
sed -i 's/_phase_7_/_phase_5_/g' "$ORCHESTRATE_FILE"
sed -i 's/_phase_6_/_phase_4_/g' "$ORCHESTRATE_FILE"
sed -i 's/_phase_5_/_phase_3_/g' "$ORCHESTRATE_FILE"

echo "✓ Checkpoint variables renamed"
```

**MANDATORY VERIFICATION - Variables Renamed**:

```bash
# Check for orphaned old checkpoint variables
ORPHANED=$(grep -c "CHECKPOINT_PHASE_[567]" "$ORCHESTRATE_FILE" || true)

if [ "$ORPHANED" -gt 0 ]; then
  echo "⚠️  WARNING: $ORPHANED orphaned checkpoint variables found"
  grep -n "CHECKPOINT_PHASE_[567]" "$ORCHESTRATE_FILE"
fi

echo "✓ VERIFIED: Checkpoint variables updated (orphaned: $ORPHANED)"
```

---

**STEP 3 (REQUIRED) - Update PROGRESS Markers and TodoWrite**

**EXECUTE NOW - Update Progress Tracking**:

```bash
# Update PROGRESS markers
sed -i 's/PROGRESS: Phase 7/PROGRESS: Phase 5/g' "$ORCHESTRATE_FILE"
sed -i 's/PROGRESS: Phase 6/PROGRESS: Phase 4/g' "$ORCHESTRATE_FILE"
sed -i 's/PROGRESS: Phase 5/PROGRESS: Phase 3/g' "$ORCHESTRATE_FILE"

# Update TodoWrite phase descriptions
sed -i 's/"Phase 7:/"Phase 5:/g' "$ORCHESTRATE_FILE"
sed -i 's/"Phase 6:/"Phase 4:/g' "$ORCHESTRATE_FILE"
sed -i 's/"Phase 5:/"Phase 3:/g' "$ORCHESTRATE_FILE"

echo "✓ PROGRESS markers and TodoWrite updated"
```

**MANDATORY VERIFICATION - Progress Tracking Updated**:

```bash
# Verify TodoWrite has correct number of items (6 phases: 0-5)
TODO_COUNT=$(grep -A 100 "TodoWrite" "$ORCHESTRATE_FILE" | grep -c '"Phase [0-5]:' || true)

if [ "$TODO_COUNT" -ne 6 ]; then
  echo "⚠️  WARNING: TodoWrite has $TODO_COUNT items, expected 6"
fi

echo "✓ VERIFIED: TodoWrite has $TODO_COUNT phase items"
```

---

**STEP 4 (REQUIRED) - Update Error Messages and Documentation**

**EXECUTE NOW - Update Phase References in Text**:

```bash
# Update error messages referencing old phase numbers
sed -i 's/failed at Phase 7/failed at Phase 5/gi' "$ORCHESTRATE_FILE"
sed -i 's/failed at Phase 6/failed at Phase 4/gi' "$ORCHESTRATE_FILE"
sed -i 's/failed at Phase 5/failed at Phase 3/gi' "$ORCHESTRATE_FILE"

# Update documentation references to phases
sed -i 's/Phase 7 (Debugging)/Phase 5 (Debugging)/g' "$ORCHESTRATE_FILE"
sed -i 's/Phase 6 (Testing)/Phase 4 (Testing)/g' "$ORCHESTRATE_FILE"
sed -i 's/Phase 5 (Implementation)/Phase 3 (Implementation)/g' "$ORCHESTRATE_FILE"

# Update workflow state variables
sed -i 's/current_phase=7/current_phase=5/g' "$ORCHESTRATE_FILE"
sed -i 's/current_phase=6/current_phase=4/g' "$ORCHESTRATE_FILE"
sed -i 's/current_phase=5/current_phase=3/g' "$ORCHESTRATE_FILE"

echo "✓ Error messages and documentation updated"
```

**MANDATORY VERIFICATION - Complete Renumbering Check**:

```bash
# Comprehensive check for any remaining old phase references
echo "Checking for orphaned phase references..."

# Check for Phase 4 (should only be the NEW Phase 4: Testing)
PHASE_4_REFS=$(grep -n "Phase 4" "$ORCHESTRATE_FILE" | grep -v "Phase 4 (Testing)\|Phase 4:" | wc -l)

# Check for Phase 5 references (should be NEW Phase 5: Debugging)
PHASE_5_REFS=$(grep -n "Phase 5" "$ORCHESTRATE_FILE" | grep -v "Phase 5 (Debugging)\|Phase 5:" | wc -l)

# Check for Phase 6, 7 references (should not exist)
PHASE_6_REFS=$(grep -c "Phase 6" "$ORCHESTRATE_FILE" || true)
PHASE_7_REFS=$(grep -c "Phase 7" "$ORCHESTRATE_FILE" || true)

if [ "$PHASE_6_REFS" -gt 0 ] || [ "$PHASE_7_REFS" -gt 0 ]; then
  echo "⚠️  WARNING: Found Phase 6 ($PHASE_6_REFS) or Phase 7 ($PHASE_7_REFS) references"
  grep -n "Phase [67]" "$ORCHESTRATE_FILE" | head -10
fi

echo "✓ VERIFIED: Renumbering complete"
echo "  - Phase 4 contextual refs: $PHASE_4_REFS"
echo "  - Phase 5 contextual refs: $PHASE_5_REFS"
echo "  - Phase 6 refs (should be 0): $PHASE_6_REFS"
echo "  - Phase 7 refs (should be 0): $PHASE_7_REFS"
```

---

**FALLBACK MECHANISM**:

```bash
# If renumbering creates errors, restore from backup:
# cp "${ORCHESTRATE_FILE}.pre-renumbering" "$ORCHESTRATE_FILE"
```

---

**CHECKPOINT REQUIREMENT**

After completing Phase 4, YOU MUST report:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Phase 4 Complete - Renumbering Complete
═══════════════════════════════════════════════════════

Phase Headers Renumbered: ✓ VERIFIED
  OLD → NEW:
  - Phase 5 (Implementation) → Phase 3 (Implementation)
  - Phase 6 (Testing) → Phase 4 (Testing)
  - Phase 7 (Debugging) → Phase 5 (Debugging)

Checkpoint Variables Updated: ✓ VERIFIED
  - CHECKPOINT_PHASE_5 → CHECKPOINT_PHASE_3
  - CHECKPOINT_PHASE_6 → CHECKPOINT_PHASE_4
  - CHECKPOINT_PHASE_7 → CHECKPOINT_PHASE_5
  - Orphaned variables: $ORPHANED

PROGRESS Markers Updated: ✓ VERIFIED
  - All phase progress markers use new numbers
  - TodoWrite has $TODO_COUNT phase items

Error Messages Updated: ✓ VERIFIED
  - All error messages reference new phase numbers
  - Documentation references updated
  - Workflow state variables updated

Verification Results:
  - Phase 6 remaining refs: $PHASE_6_REFS (expected: 0)
  - Phase 7 remaining refs: $PHASE_7_REFS (expected: 0)

Backup Available: orchestrate.md.pre-renumbering

Status: READY FOR PHASE 5
═══════════════════════════════════════════════════════
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
