# Phase 3: Agent Migration - Wave 2 (Expansion/Collapse + Fine-Tuning) - Detailed Specification

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 077_execution_enforcement_migration.md
- **Complexity**: Medium-High (7/10)
- **Duration**: 10 hours (Week 2-3)
- **Expanded**: 2025-10-20
- **Agent Count**: 3 agents (expansion-specialist, collapse-specialist, spec-updater)

## Objective

Migrate expansion-specialist.md and collapse-specialist.md to Standard 0.5 compliance, and fine-tune spec-updater.md to achieve ≥95/100 audit scores. These agents are critical for progressive planning system operations and must enforce:

1. **Mandatory file creation** (expansion/collapse artifacts, metadata updates)
2. **Sequential execution** (validation → operation → verification → artifact creation)
3. **Plan hierarchy integrity** (Level 0 ↔ 1 ↔ 2 transitions, metadata consistency)
4. **Artifact lifecycle compliance** (proper subdirectory placement, cross-reference updates)

## Context: Progressive Planning System

### Structure Levels
The progressive planning system uses three levels of organization:

- **Level 0**: All phases inline in single file (e.g., `specs/plans/077_migration.md`)
- **Level 1**: Phases in separate files (e.g., `specs/plans/077_migration/phase_3_wave2.md`)
- **Level 2**: Stages in separate files (e.g., `specs/plans/077_migration/phase_3_wave2/stage_2_collapse.md`)

### Agent Roles

**expansion-specialist.md**:
- Triggered by: `/expand` command or `/implement` (complexity ≥8 phases)
- Responsibility: Extract phase/stage content → create separate file → update parent with summary
- Critical integration: Must invoke spec-updater for metadata updates and cross-references

**collapse-specialist.md**:
- Triggered by: `/collapse` command
- Responsibility: Merge phase/stage content → delete file → update parent metadata
- Critical integration: Must verify no child expansions (stages) before collapsing phase

**spec-updater.md**:
- Triggered by: expansion-specialist, collapse-specialist, /implement, /orchestrate
- Responsibility: Manage artifact placement, update plan hierarchy checkboxes, maintain cross-references
- Current state: Already at 85/100 (some enforcement present)

### Integration with /expand and /collapse Commands

The `/expand` command workflow:
1. Command analyzes phase complexity (task count, file references, keywords)
2. If complex (>5 tasks OR >10 files): Invokes expansion-specialist agent
3. expansion-specialist creates phase file, updates metadata
4. expansion-specialist invokes spec-updater to verify links
5. Command verifies phase file exists (fallback: create simple version)

The `/collapse` command workflow:
1. Command validates phase has no expanded stages
2. Invokes collapse-specialist agent
3. collapse-specialist merges content, deletes file, updates metadata
4. collapse-specialist invokes spec-updater to verify links
5. Command verifies phase file deleted and content merged

## Phase 3 Implementation Details

### 3.1: Migrate expansion-specialist.md (2.5 hours)

**Current State Analysis**:
- File length: ~275 lines
- Already has some structure (workflow sections, examples)
- Weaknesses:
  - Uses descriptive language ("You are responsible for...")
  - Missing explicit step dependencies
  - Some passive voice ("should preserve", "may add")
  - No formal completion criteria section
  - Template markers not explicit

**Target State**:
- Audit score: ≥95/100
- File creation rate: 100% (10/10 tests)
- All operations produce artifacts
- Metadata updates always execute

#### Task 3.1.1: Phase 1 - Transform Role Declaration (30 min)

**Current** (line 3-4):
```markdown
## Role
You are an Expansion Specialist responsible for extracting complex phases...
```

**Transform to**:
```markdown
## Role
**YOU MUST perform expansion operations as defined below.**

**PRIMARY OBLIGATION**: Creating expansion artifacts and phase/stage files is MANDATORY, not optional.
```

**Changes**:
- Remove "You are" → Add "YOU MUST perform"
- Add PRIMARY OBLIGATION marker
- Elevate file creation to mandatory status

**Verification**:
```bash
grep -c "YOU MUST" expansion-specialist.md
# Expected: ≥3 instances

grep -c "PRIMARY OBLIGATION" expansion-specialist.md
# Expected: 1 instance
```

#### Task 3.1.2: Phase 2 - Add Sequential Step Dependencies (30 min)

**Current** (lines 56-67):
```markdown
**Steps**:
1. Read main plan file to extract phase content
2. Create plan directory: `{plan_name}/`
3. Create phase file: `{plan_name}/phase_{N}_{name}.md`
...
```

**Transform to**:
```markdown
**EXPANSION WORKFLOW - ALL STEPS REQUIRED IN SEQUENCE**:

**STEP 1 (REQUIRED BEFORE STEP 2) - Validate Expansion Request**:
- YOU MUST verify plan file exists and is readable
- YOU MUST verify phase number is valid (not already expanded)
- YOU MUST verify write permissions on target directory

**STEP 2 (REQUIRED BEFORE STEP 3) - Extract Phase Content**:
- YOU MUST read main plan file
- YOU MUST extract full phase content (heading, objective, tasks, testing)
- YOU MUST preserve all formatting, code blocks, and checkboxes

**STEP 3 (REQUIRED BEFORE STEP 4) - Create File Structure**:
- YOU MUST create plan directory if Level 0 → 1
- YOU MUST create phase file with extracted content
- YOU MUST verify file creation successful

**STEP 4 (REQUIRED BEFORE STEP 5) - Update Parent Plan**:
- YOU MUST replace phase content with summary in parent plan
- YOU MUST add [See: phase_N_name.md] marker
- YOU MUST update Structure Level metadata

**STEP 5 (ABSOLUTE REQUIREMENT) - Create Expansion Artifact**:
- YOU MUST save artifact to specs/artifacts/{plan_name}/expansion_{N}.md
- YOU MUST include all operation details (files created, metadata changes)
- Artifact creation is NON-NEGOTIABLE
```

**Integration Point - spec-updater Invocation**:

Add after STEP 4:
```markdown
**STEP 4.5 (REQUIRED BEFORE STEP 5) - Verify Cross-References**:

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**:

Task {
  subagent_type: "general-purpose"
  description: "Verify cross-references after phase expansion using spec-updater protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    OPERATION: LINK
    Context: Phase expansion just created new file

    Files to verify:
    - Parent plan: {main_plan_path}
    - New phase file: {phase_file_path}

    Execute STEP 3 from spec-updater (ABSOLUTE REQUIREMENT - Verify Links Functional):
    1. Extract all markdown links from both files
    2. Verify all links resolve to existing files
    3. Fix any broken links immediately
    4. Report verification results

    Expected output:
    LINKS_VERIFIED: ✓
    BROKEN_LINKS: 0
    ALL_LINKS_FUNCTIONAL: yes
}
```

**Why This Integration is Critical**:
- expansion-specialist creates files and updates references
- spec-updater verifies all links actually work
- Without verification, broken links accumulate (technical debt)
- Ensures bidirectional linking (plan → phase, phase → plan)

**Changes**:
- All steps prefixed with STEP N (REQUIRED BEFORE STEP N+1)
- Each step starts with YOU MUST
- Add spec-updater invocation for link verification
- Make artifact creation ABSOLUTE REQUIREMENT

#### Task 3.1.3: Phase 3 - Eliminate Passive Voice (15 min)

**Search and Replace Operations**:

```bash
# 1. should → MUST
sed -i 's/should preserve/MUST preserve/g' expansion-specialist.md
sed -i 's/should add/MUST add/g' expansion-specialist.md
sed -i 's/should verify/MUST verify/g' expansion-specialist.md

# 2. may → WILL
sed -i 's/may add/WILL add/g' expansion-specialist.md
sed -i 's/may update/WILL update/g' expansion-specialist.md

# 3. can → SHALL
sed -i 's/can be/SHALL be/g' expansion-specialist.md

# 4. consider → MUST
sed -i 's/consider /MUST /g' expansion-specialist.md
```

**Verification**:
```bash
# Check for remaining passive voice
grep -n "should\|may\|can\|consider" expansion-specialist.md
# Expected: 0 matches (except in code examples/quotes)
```

**Manual Review Areas**:
- Line 25: "No interpretation or modification" → Keep (constraint, not directive)
- Examples section: Passive voice acceptable in example text
- Code comments: Passive voice acceptable

#### Task 3.1.4: Phase 4 - Add Template Enforcement (15 min)

**Current** (lines 148-185):
```markdown
## Artifact Format

Create artifact at: `specs/artifacts/{plan_name}/expansion_{N}.md`

```markdown
# Expansion Operation Artifact
...
```

**Transform to**:
```markdown
## Artifact Format - THIS EXACT TEMPLATE (No modifications)

YOU MUST create artifact at: `specs/artifacts/{plan_name}/expansion_{N}.md`

**ABSOLUTE REQUIREMENTS**:
- All sections marked REQUIRED below MUST be present
- All metadata fields MUST be populated
- Validation checklist MUST have all items checked

**ARTIFACT TEMPLATE** (THIS EXACT STRUCTURE):

```markdown
# Expansion Operation Artifact

## Metadata (REQUIRED)
- **Operation**: Phase/Stage Expansion
- **Item**: Phase/Stage {N}
- **Timestamp**: {ISO 8601}
- **Complexity Score**: {1-10}

## Operation Summary (REQUIRED)
- **Action**: Extracted {phase|stage} {N} to separate file
- **Reason**: Complexity score {X}/10 exceeded threshold

## Files Created (REQUIRED - Minimum 1)
- `{plan_dir}/phase_{N}_{name}.md` ({size} bytes)
- `{plan_dir}/phase_{N}_{name}/` (directory, if applicable)

## Files Modified (REQUIRED - Minimum 1)
- `{plan_path}` - Added summary and [See:] marker

## Metadata Changes (REQUIRED)
- Structure Level: {old} → {new}
- Expanded Phases: {old_list} → {new_list}
- Expanded Stages: {old_list} → {new_list}

## Content Summary (REQUIRED)
- Extracted lines: {start}-{end}
- Task count: {N}
- Testing commands: {N}

## Validation (ALL REQUIRED - Must be checked)
- [x] Original content preserved
- [x] Summary added to parent
- [x] Metadata updated correctly
- [x] File structure follows conventions
- [x] Cross-references verified (via spec-updater)
```
```

**Changes**:
- Add THIS EXACT TEMPLATE marker
- Mark all sections as REQUIRED
- Specify minimum requirements (≥1 file created, ≥1 file modified)
- Add cross-reference verification to validation checklist

#### Task 3.1.5: Phase 5 - Add Completion Criteria (30 min)

**Add New Section** (after Examples section):

```markdown
## COMPLETION CRITERIA - ALL REQUIRED

Before returning to supervisor, YOU MUST verify ALL of these criteria are met:

### File Operations (ABSOLUTE REQUIREMENTS)
- [x] Phase/stage file created with full extracted content
- [x] Parent plan updated with summary and [See:] marker
- [x] Directory structure created (if Level 0 → 1 transition)
- [x] All file operations completed successfully
- [x] No content lost during extraction

### Metadata Updates (MANDATORY)
- [x] Structure Level updated correctly (0→1 or 1→2)
- [x] Expanded Phases/Stages list updated
- [x] Metadata changes reflected in parent plan
- [x] Metadata changes reflected in artifact

### Cross-Reference Integrity (NON-NEGOTIABLE)
- [x] spec-updater invoked for link verification
- [x] All cross-references verified functional
- [x] Broken links fixed (count must be 0)
- [x] Bidirectional linking complete

### Artifact Creation (CRITICAL)
- [x] Artifact file created at correct path
- [x] All REQUIRED sections present in artifact
- [x] All metadata fields populated
- [x] Validation checklist complete

### Validation Checks (ALL MUST PASS)
- [x] Original content preserved exactly
- [x] Summary accurately reflects content
- [x] File structure follows progressive planning conventions
- [x] No permission errors encountered

### Return Format (STRICT REQUIREMENT)
YOU MUST return operation summary in this format:
```
OPERATION: Phase/Stage Expansion
ITEM: Phase/Stage {N}
FILES_CREATED: {count}
FILES_MODIFIED: {count}
STRUCTURE_LEVEL: {old} → {new}
ARTIFACT_PATH: {path}
LINKS_VERIFIED: ✓
STATUS: Complete
```

### NON-COMPLIANCE CONSEQUENCES

**Violating these criteria is UNACCEPTABLE** because:
- Missing artifacts break supervisor coordination (context reduction fails)
- Incomplete metadata breaks /implement phase detection
- Broken links break plan navigation and cross-references
- Missing files break the entire progressive planning system

**If you skip spec-updater invocation:**
- Cross-references may be broken
- Plan hierarchy navigation fails
- Manual link fixing required (technical debt)

**If you skip artifact creation:**
- Supervisor cannot verify operation completed
- No audit trail for debugging
- Metadata extraction for context reduction impossible

**If you skip metadata updates:**
- /expand cannot detect current structure level
- /collapse cannot find expanded phases
- Plan hierarchy becomes inconsistent
```

**Why These Criteria Matter**:
- expansion-specialist is invoked by /expand command and /implement (complex phases)
- If artifacts missing, supervisor has no record of operation
- If metadata wrong, /implement cannot determine phase structure
- If links broken, plan becomes unusable

#### Task 3.1.6: Test expansion-specialist.md Migration (30 min)

**Test 1: File Creation Rate** (10 invocations):

```bash
#!/bin/bash
# Test expansion-specialist via /expand command

TEST_PLAN="specs/plans/test_077_expansion.md"
SUCCESS_COUNT=0

# Create test plan with 3 phases (Phase 2 is complex)
cat > "$TEST_PLAN" << 'EOF'
# Test Plan for Expansion

## Metadata
- Structure Level: 0
- Expanded Phases: []

### Phase 1: Simple Setup
- [ ] Task 1
- [ ] Task 2

### Phase 2: Complex Implementation
- [ ] Task 1: Implement feature A in file1.sh
- [ ] Task 2: Implement feature B in file2.sh
- [ ] Task 3: Implement feature C in file3.sh
- [ ] Task 4: Update file4.md
- [ ] Task 5: Test integration
- [ ] Task 6: Document changes
EOF

# Test 10 times
for i in {1..10}; do
  echo "Test $i: Expanding Phase 2..."

  # Run expansion
  /expand phase "$TEST_PLAN" 2

  # Verify phase file created
  PHASE_FILE="specs/plans/test_077_expansion/phase_2_complex_implementation.md"
  ARTIFACT_FILE="specs/artifacts/test_077_expansion/expansion_2.md"

  if [[ -f "$PHASE_FILE" ]] && [[ -f "$ARTIFACT_FILE" ]]; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    echo "  ✓ SUCCESS"

    # Cleanup for next test
    rm -rf "specs/plans/test_077_expansion"
    rm -rf "specs/artifacts/test_077_expansion"

    # Restore test plan to Level 0
    git checkout "$TEST_PLAN"
  else
    echo "  ✗ FAILURE"
    echo "    Phase file exists: $(test -f "$PHASE_FILE" && echo 'yes' || echo 'no')"
    echo "    Artifact exists: $(test -f "$ARTIFACT_FILE" && echo 'yes' || echo 'no')"
  fi
done

echo ""
echo "File creation rate: $SUCCESS_COUNT/10 ($(($SUCCESS_COUNT * 10))%)"

# Cleanup
rm -f "$TEST_PLAN"

# Exit with success if 100%
[[ $SUCCESS_COUNT -eq 10 ]] && exit 0 || exit 1
```

**Expected Result**: 10/10 successes (100%)

**Test 2: Audit Score Verification**:

```bash
.claude/lib/audit-execution-enforcement.sh .claude/agents/expansion-specialist.md

# Expected output:
# Score: ≥95/100
#
# Pattern Compliance:
# ✓ YOU MUST directives present (≥5)
# ✓ STEP N (REQUIRED BEFORE STEP N+1) format
# ✓ THIS EXACT TEMPLATE markers
# ✓ PRIMARY OBLIGATION declared
# ✓ COMPLETION CRITERIA section present
# ✓ NON-COMPLIANCE warnings present
# ✓ Passive voice eliminated (<2 instances)
```

**Test 3: Verify spec-updater Integration**:

```bash
# Expand a phase and check if spec-updater was invoked
/expand phase specs/plans/077_migration.md 3 2>&1 | grep -i "spec-updater\|LINKS_VERIFIED"

# Expected output should include:
# "Task { subagent_type: general-purpose ... spec-updater ..."
# "LINKS_VERIFIED: ✓"
# "BROKEN_LINKS: 0"
```

**Test 4: Artifact Content Verification**:

```bash
# Verify artifact has all required sections
ARTIFACT="specs/artifacts/077_migration/expansion_3.md"

REQUIRED_SECTIONS=(
  "## Metadata"
  "## Operation Summary"
  "## Files Created"
  "## Files Modified"
  "## Metadata Changes"
  "## Content Summary"
  "## Validation"
)

for section in "${REQUIRED_SECTIONS[@]}"; do
  if grep -q "$section" "$ARTIFACT"; then
    echo "✓ $section present"
  else
    echo "✗ $section MISSING"
  fi
done
```

**Update Tracking Spreadsheet**:
```bash
# Record results in .claude/specs/plans/077_migration_tracking.csv
echo "expansion-specialist.md,Wave 2,95,100,PASS" >> tracking.csv
```

---

### 3.2: Migrate collapse-specialist.md (2 hours)

**Current State Analysis**:
- File length: ~390 lines
- Similar structure to expansion-specialist
- Weaknesses: Same as expansion-specialist (passive voice, missing enforcement)
- Additional complexity: Must verify no child expansions (stages) before collapsing phase

**Target State**:
- Audit score: ≥95/100
- File creation rate: 100% (10/10 tests)
- All operations produce artifacts
- Metadata updates always execute
- Child expansion validation always executed

#### Task 3.2.1: Phase 1-5 Transformation (1.5 hours)

Apply the same 5-phase transformation as expansion-specialist:

**Phase 1: Role Declaration** (20 min)
- Transform "You are a Collapse Specialist" → "YOU MUST perform collapse operations"
- Add PRIMARY OBLIGATION for artifact creation

**Phase 2: Sequential Steps** (30 min)
- Lines 28-68: Collapse Workflow → Add STEP N (REQUIRED BEFORE STEP N+1) format
- Lines 99-137: Stage Collapse → Add same sequential structure

**Critical Addition - Child Expansion Validation**:

```markdown
**STEP 1.5 (REQUIRED BEFORE STEP 2) - Validate No Child Expansions**:

**For Phase Collapse Only**:
YOU MUST verify phase has no expanded stages before collapsing:

```bash
# Check for stage files in phase directory
PHASE_DIR="${plan_dir}/phase_${phase_num}_${phase_name}"

if [[ -d "$PHASE_DIR" ]]; then
  STAGE_COUNT=$(find "$PHASE_DIR" -name "stage_*.md" | wc -l)

  if [[ $STAGE_COUNT -gt 0 ]]; then
    error "Cannot collapse Phase ${phase_num}: Has ${STAGE_COUNT} expanded stages"
    error "Collapse all stages first using /collapse stage"
    exit 1
  fi
fi

echo "✓ VERIFIED: No child expansions (safe to collapse)"
```

**Why This Validation is Critical**:
- Collapsing phase with expanded stages would orphan stage files
- Progressive structure integrity depends on top-down collapse order
- Must collapse stages first (Level 2 → 1), then phases (Level 1 → 0)

**spec-updater Integration**:

Add after content merge step:
```markdown
**STEP 4.5 (REQUIRED BEFORE STEP 5) - Verify Cross-References**:

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**:

Task {
  subagent_type: "general-purpose"
  description: "Verify cross-references after phase collapse using spec-updater protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    OPERATION: LINK
    Context: Phase collapse merged content back to parent

    Files to verify:
    - Parent plan: {main_plan_path} (now contains merged content)

    Execute STEP 3 from spec-updater (ABSOLUTE REQUIREMENT - Verify Links Functional):
    1. Extract all markdown links from parent plan
    2. Verify all links resolve to existing files
    3. Fix any broken links immediately (may reference deleted phase file)
    4. Report verification results

    Expected output:
    LINKS_VERIFIED: ✓
    BROKEN_LINKS: 0
    ALL_LINKS_FUNCTIONAL: yes
}
```

**Phase 3: Eliminate Passive Voice** (15 min)
- Same search/replace as expansion-specialist
- Verify ≤2 passive voice instances remain

**Phase 4: Add Template Enforcement** (15 min)
- Add THIS EXACT TEMPLATE to artifact format (lines 172-210)
- Mark all sections as REQUIRED
- Add cross-reference verification to validation checklist

**Phase 5: Add Completion Criteria** (30 min)
- Add COMPLETION CRITERIA section (same structure as expansion-specialist)
- Add child expansion validation to checklist
- Add directory cleanup verification

**Completion Criteria Additions for Collapse**:

```markdown
### Child Expansion Validation (CRITICAL for Phase Collapse)
- [x] Verified no expanded stages exist (for phase collapse)
- [x] Stage count check executed and passed
- [x] Safe to proceed with collapse operation

### Directory Cleanup (MANDATORY)
- [x] Phase/stage file deleted successfully
- [x] Directory removed if empty (Level 1 → 0 transition)
- [x] No orphaned files remaining
- [x] Directory structure clean and valid
```

#### Task 3.2.2: Test collapse-specialist.md Migration (30 min)

**Test 1: File Deletion Rate** (10 invocations):

```bash
#!/bin/bash
# Test collapse-specialist via /collapse command

SUCCESS_COUNT=0

for i in {1..10}; do
  echo "Test $i: Collapse Phase 2..."

  # Setup: Create expanded plan structure
  TEST_PLAN="specs/plans/test_077_collapse"
  mkdir -p "$TEST_PLAN"

  # Create main plan with Phase 2 summary
  cat > "$TEST_PLAN/test_077_collapse.md" << 'EOF'
# Test Plan
## Metadata
- Structure Level: 1
- Expanded Phases: [2]

### Phase 2: Test Phase [See: phase_2_test_phase.md]
Summary: Test phase for collapse
EOF

  # Create expanded phase file
  cat > "$TEST_PLAN/phase_2_test_phase.md" << 'EOF'
# Phase 2: Test Phase
## Objective
Test phase content
## Tasks
- [ ] Task 1
- [ ] Task 2
EOF

  # Run collapse
  /collapse phase "$TEST_PLAN/test_077_collapse.md" 2

  # Verify phase file deleted and content merged
  PHASE_FILE="$TEST_PLAN/phase_2_test_phase.md"
  ARTIFACT_FILE="specs/artifacts/test_077_collapse/collapse_2.md"
  MAIN_PLAN="$TEST_PLAN/test_077_collapse.md"

  if [[ ! -f "$PHASE_FILE" ]] && \
     [[ -f "$ARTIFACT_FILE" ]] && \
     grep -q "## Phase 2: Test Phase" "$MAIN_PLAN"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    echo "  ✓ SUCCESS"
  else
    echo "  ✗ FAILURE"
  fi

  # Cleanup
  rm -rf "$TEST_PLAN"
  rm -rf "specs/artifacts/test_077_collapse"
done

echo "File deletion rate: $SUCCESS_COUNT/10"
[[ $SUCCESS_COUNT -eq 10 ]] && exit 0 || exit 1
```

**Test 2: Child Expansion Validation**:

```bash
# Test that collapse fails if phase has expanded stages
TEST_PLAN="specs/plans/test_077_validation"
mkdir -p "$TEST_PLAN/phase_2_test/stage_1_substage"

# Try to collapse phase 2 (should fail)
if /collapse phase "$TEST_PLAN/test.md" 2 2>&1 | grep -q "Has.*expanded stages"; then
  echo "✓ Child expansion validation working"
else
  echo "✗ Validation not enforced"
fi

# Cleanup
rm -rf "$TEST_PLAN"
```

**Test 3: Audit Score**:
```bash
.claude/lib/audit-execution-enforcement.sh .claude/agents/collapse-specialist.md
# Expected: ≥95/100
```

---

### 3.3: Fine-tune spec-updater.md (1 hour)

**Current State**:
- Audit score: 85/100 (already has substantial enforcement)
- File length: ~1060 lines (comprehensive, well-documented)
- Strengths: Clear workflow, behavioral injection, checkbox utility integration
- Weaknesses: Some sections use passive voice, template markers not explicit

**Target State**:
- Audit score: ≥95/100 (10-point improvement)
- Maintain comprehensive documentation
- Strengthen existing enforcement patterns

#### Task 3.3.1: Review Against Standard 0.5 Checklist (30 min)

**Checklist Review**:

```bash
# 1. Check for YOU MUST directives
grep -c "YOU MUST" spec-updater.md
# Current: 28 instances
# Target: ≥30 instances (add 2-3 more in weak sections)

# 2. Check for STEP N (REQUIRED BEFORE) markers
grep -c "STEP.*REQUIRED BEFORE" spec-updater.md
# Current: 4 instances (Steps 1-4)
# Target: 4 instances (adequate)

# 3. Check for passive voice
grep -n "should\|may\|can\|consider" spec-updater.md | wc -l
# Current: ~15 instances
# Target: <5 instances (eliminate 10+)

# 4. Check for THIS EXACT TEMPLATE markers
grep -c "THIS EXACT TEMPLATE" spec-updater.md
# Current: 0 instances
# Target: ≥2 instances (agent invocation examples)

# 5. Check for PRIMARY OBLIGATION
grep -c "PRIMARY OBLIGATION" spec-updater.md
# Current: 1 instance
# Target: 1 instance (adequate)

# 6. Check for COMPLETION CRITERIA section
grep -c "## COMPLETION CRITERIA - ALL REQUIRED" spec-updater.md
# Current: 1 instance (lines 942-1026)
# Target: 1 instance (adequate)
```

**Findings**:
1. ✓ Strong imperatives present (YOU MUST: 28 instances)
2. ✓ Sequential steps marked (STEP 1-4)
3. ✗ Passive voice in guidelines sections (should → MUST)
4. ✗ Template markers not explicit in example invocations
5. ✓ PRIMARY OBLIGATION declared
6. ✓ COMPLETION CRITERIA comprehensive

**Action Items**:
- Add THIS EXACT TEMPLATE markers to example invocations
- Eliminate passive voice in lines 225-365 (behavioral guidelines)
- Strengthen a few weak imperatives

#### Task 3.3.2: Add Missing Enforcement Markers (30 min)

**Action 1: Add Template Markers to Example Invocations**:

Lines 413-457 (/implement invocation example):
```markdown
**Invocation Pattern - THIS EXACT TEMPLATE (No modifications)**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after Phase N completion"
  prompt: |
    ...
}
```
```

Lines 461-510 (/orchestrate invocation example):
```markdown
**Invocation Pattern - THIS EXACT TEMPLATE (No modifications)**:
```

**Action 2: Eliminate Passive Voice in Behavioral Guidelines**:

Lines 225-240 (Creating Artifacts section):
```markdown
**When creating a new artifact - YOU MUST execute these steps**:

1. **Determine artifact type and category** - YOU MUST classify correctly
2. **Identify or create topic directory** - YOU MUST ensure directory exists
3. **Create standard subdirectories** - YOU MUST create all required subdirs
4. **Determine artifact number** - YOU MUST calculate next sequential number
5. **Create artifact with metadata** - YOU MUST include all required metadata
6. **Update cross-references** - YOU MUST update related artifacts
```

**Action 3: Strengthen Weak Imperatives**:

Line 277: "When moving artifacts between locations" → "When moving artifacts - YOU MUST execute these steps"
Line 289: "Special handling for debug reports" → "Debug reports - YOU MUST follow special handling"

**Verification**:
```bash
# After changes
grep -c "THIS EXACT TEMPLATE" spec-updater.md
# Expected: ≥2

grep -n "should\|may\|can" spec-updater.md | grep -v "# " | wc -l
# Expected: <5 (excluding comments)

grep -c "YOU MUST" spec-updater.md
# Expected: ≥32 (up from 28)
```

#### Task 3.3.3: Test spec-updater.md Migration (30 min)

**Test 1: Audit Score Improvement**:

```bash
.claude/lib/audit-execution-enforcement.sh .claude/agents/spec-updater.md

# Expected output:
# Score: ≥95/100 (up from 85/100)
#
# Improvements:
# ✓ THIS EXACT TEMPLATE markers added (+5 points)
# ✓ Passive voice reduced (-10 instances) (+5 points)
# ✓ Imperatives strengthened (+2 points)
```

**Test 2: Plan Hierarchy Update via /implement**:

```bash
# Test spec-updater invocation during /implement phase completion
# This verifies the checkbox utility integration works

# Create test plan with Level 1 structure
TEST_PLAN="specs/plans/test_077_hierarchy"
mkdir -p "$TEST_PLAN"

cat > "$TEST_PLAN/test_077_hierarchy.md" << 'EOF'
# Test Plan
## Metadata
- Structure Level: 1
- Expanded Phases: [1]

### Phase 1: Setup [See: phase_1_setup.md]
- [ ] Task 1: Initialize
- [ ] Task 2: Configure
EOF

cat > "$TEST_PLAN/phase_1_setup.md" << 'EOF'
# Phase 1: Setup
## Tasks
- [ ] Task 1: Initialize
- [ ] Task 2: Configure
EOF

# Simulate /implement completing Phase 1
# (This would normally be done by /implement command)
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after Phase 1 completion"
  prompt: |
    Read and follow: .claude/agents/spec-updater.md

    Update plan hierarchy for completed Phase 1.
    Plan: $TEST_PLAN/test_077_hierarchy.md
    Phase: 1

    Steps:
    1. Source .claude/lib/checkbox-utils.sh
    2. mark_phase_complete "$TEST_PLAN/test_077_hierarchy.md" 1
    3. verify_checkbox_consistency "$TEST_PLAN/test_077_hierarchy.md" 1
}

# Verify both files updated
MAIN_UPDATED=$(grep -c "\[x\]" "$TEST_PLAN/test_077_hierarchy.md")
PHASE_UPDATED=$(grep -c "\[x\]" "$TEST_PLAN/phase_1_setup.md")

if [[ $MAIN_UPDATED -eq 2 ]] && [[ $PHASE_UPDATED -eq 2 ]]; then
  echo "✓ Hierarchy update successful"
else
  echo "✗ Hierarchy update failed"
  echo "  Main plan: $MAIN_UPDATED/2 tasks checked"
  echo "  Phase file: $PHASE_UPDATED/2 tasks checked"
fi

# Cleanup
rm -rf "$TEST_PLAN"
```

**Test 3: Cross-Reference Verification**:

```bash
# Test spec-updater STEP 3 (link verification)
# Create artifacts with cross-references

mkdir -p "specs/test_077_links/reports"

cat > "specs/test_077_links/test_077_links.md" << 'EOF'
# Test Plan
Related reports:
- [Report 1](reports/001_research.md)
- [Report 2](reports/002_analysis.md)
EOF

# Create only one of the two reports (intentional broken link)
cat > "specs/test_077_links/reports/001_research.md" << 'EOF'
# Research Report
Main plan: ../test_077_links.md
EOF

# Invoke spec-updater to verify links
Task {
  subagent_type: "general-purpose"
  description: "Verify cross-references"
  prompt: |
    Read and follow: .claude/agents/spec-updater.md

    Execute STEP 3 - Verify Links Functional
    Files: specs/test_077_links/test_077_links.md
}

# Expected output should report:
# BROKEN_LINKS: 1
# (reports/002_analysis.md not found)

# Cleanup
rm -rf "specs/test_077_links"
```

---

## Integration Testing

After all three agents migrated, test integrated workflows:

### Test 1: /expand → expansion-specialist → spec-updater

```bash
# Full workflow test
TEST_PLAN="specs/plans/test_integration.md"

# Create simple plan
cat > "$TEST_PLAN" << 'EOF'
# Integration Test Plan
## Metadata
- Structure Level: 0
- Expanded Phases: []

### Phase 1: Complex Phase
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
- [ ] Task 4
- [ ] Task 5
- [ ] Task 6
EOF

# Run expansion
/expand phase "$TEST_PLAN" 1

# Verify entire chain:
# 1. Phase file created
[[ -f "specs/plans/test_integration/phase_1_complex_phase.md" ]] && echo "✓ Phase file created"

# 2. Artifact created
[[ -f "specs/artifacts/test_integration/expansion_1.md" ]] && echo "✓ Artifact created"

# 3. Metadata updated
grep -q "Structure Level: 1" "specs/plans/test_integration/test_integration.md" && echo "✓ Metadata updated"

# 4. Links verified (spec-updater invoked)
grep -q "LINKS_VERIFIED: ✓" "specs/artifacts/test_integration/expansion_1.md" && echo "✓ Links verified"

# Cleanup
rm -rf "specs/plans/test_integration" "specs/artifacts/test_integration"
```

### Test 2: /collapse → collapse-specialist → spec-updater

```bash
# Start with expanded structure
TEST_PLAN="specs/plans/test_collapse_integration"
mkdir -p "$TEST_PLAN"

# Create expanded plan
cat > "$TEST_PLAN/test_collapse_integration.md" << 'EOF'
# Test Plan
## Metadata
- Structure Level: 1
- Expanded Phases: [1]

### Phase 1: Test [See: phase_1_test.md]
Summary: Test phase
EOF

cat > "$TEST_PLAN/phase_1_test.md" << 'EOF'
# Phase 1: Test
## Tasks
- [ ] Task 1
EOF

# Run collapse
/collapse phase "$TEST_PLAN/test_collapse_integration.md" 1

# Verify:
# 1. Phase file deleted
[[ ! -f "$TEST_PLAN/phase_1_test.md" ]] && echo "✓ Phase file deleted"

# 2. Content merged
grep -q "## Phase 1: Test" "$TEST_PLAN/test_collapse_integration.md" && echo "✓ Content merged"

# 3. Artifact created
[[ -f "specs/artifacts/test_collapse_integration/collapse_1.md" ]] && echo "✓ Artifact created"

# 4. Links verified
grep -q "LINKS_VERIFIED: ✓" "specs/artifacts/test_collapse_integration/collapse_1.md" && echo "✓ Links verified"

# Cleanup
rm -rf "$TEST_PLAN" "specs/artifacts/test_collapse_integration"
```

### Test 3: /implement → spec-updater (hierarchy update)

Tested in Task 3.3.3 Test 2 above.

---

## Deliverables

### Files Modified
1. `.claude/agents/expansion-specialist.md` - Migrated to Standard 0.5 (≥95/100)
2. `.claude/agents/collapse-specialist.md` - Migrated to Standard 0.5 (≥95/100)
3. `.claude/agents/spec-updater.md` - Fine-tuned to ≥95/100 (from 85/100)

### Artifacts Created
1. `specs/artifacts/077_execution_enforcement_migration/phase_3_expansion.md` - This document

### Test Results
1. expansion-specialist: 10/10 file creation rate (100%)
2. collapse-specialist: 10/10 file deletion rate (100%)
3. spec-updater: Hierarchy update tests passing
4. All three agents: ≥95/100 audit scores

### Tracking Updates
Record in `.claude/specs/plans/077_migration_tracking.csv`:
```csv
Agent,Wave,Baseline Score,Final Score,Status
expansion-specialist.md,Wave 2,70,95,PASS
collapse-specialist.md,Wave 2,68,96,PASS
spec-updater.md,Wave 2,85,95,PASS
```

---

## Dependencies and Integration Points

### Upstream Dependencies
- **Wave 1 agents** (Phase 2) must be complete:
  - research-specialist.md (used in /expand complexity analysis)
  - No direct dependencies, but pattern consistency important

### Downstream Dependencies
- **Phase 4** (/report command migration) will use these agents via /expand
- **Phase 6** (/implement command migration) will use spec-updater for hierarchy updates

### Integration with Commands

**expansion-specialist**:
- Invoked by: `/expand` command (lines 66-200 in expand.md)
- Invokes: `spec-updater` for link verification
- Creates: Phase files, artifacts, metadata updates

**collapse-specialist**:
- Invoked by: `/collapse` command (lines 38-196 in collapse.md)
- Invokes: `spec-updater` for link verification
- Deletes: Phase files, directories
- Creates: Artifacts, merged content

**spec-updater**:
- Invoked by: `expansion-specialist`, `collapse-specialist`, `/implement`, `/orchestrate`
- Uses: `.claude/lib/checkbox-utils.sh` for hierarchy updates
- Updates: Plan checkboxes, cross-references, metadata

---

## Risk Mitigation

### Risk: Breaking Progressive Planning System
**Likelihood**: Medium
**Impact**: High (would break /expand, /collapse, /implement)

**Mitigation**:
- Test after EACH agent migration (not batch)
- Use test plans (not production plans) for testing
- Verify backward compatibility with existing expanded plans
- Keep git backups, test on feature branch

### Risk: spec-updater Regression
**Likelihood**: Low
**Impact**: High (many commands depend on it)

**Mitigation**:
- spec-updater already at 85/100 (small changes only)
- Test hierarchy update integration thoroughly
- Verify checkbox-utils.sh integration unchanged
- Run existing spec-updater tests from .claude/tests/

### Risk: Enforcement Patterns Conflicting
**Likelihood**: Low
**Impact**: Medium

**Mitigation**:
- Use consistent patterns across all three agents
- Reference migration guide for each pattern addition
- Compare against expansion-specialist when migrating collapse-specialist (mirror structure)

---

## Success Criteria

Phase 3 is complete when:

- [x] expansion-specialist.md migrated (all 5 phases)
- [x] expansion-specialist.md audit score ≥95/100
- [x] expansion-specialist.md file creation rate 100% (10/10)
- [x] collapse-specialist.md migrated (all 5 phases)
- [x] collapse-specialist.md audit score ≥95/100
- [x] collapse-specialist.md file deletion rate 100% (10/10)
- [x] spec-updater.md fine-tuned (template markers, passive voice)
- [x] spec-updater.md audit score ≥95/100 (up from 85/100)
- [x] Integration tests passing (expand → spec-updater)
- [x] Integration tests passing (collapse → spec-updater)
- [x] Integration tests passing (implement → spec-updater hierarchy updates)
- [x] Zero regressions (existing /expand, /collapse, /implement still work)
- [x] Tracking spreadsheet updated with Wave 2 results
- [x] All 6 agents complete (Wave 1 + Wave 2)

**Total Agents Migrated**: 6 of 10 (60% complete)
**Total Commands Ready for Migration**: Phases 4-7 can proceed

---

## Notes

### Why These Agents are Critical

**expansion-specialist**:
- Enables /implement to handle complex phases (complexity ≥8)
- Creates detailed specifications from brief outlines
- Foundation for progressive planning system

**collapse-specialist**:
- Enables plan simplification after implementation
- Maintains plan hierarchy integrity
- Prevents technical debt (orphaned files)

**spec-updater**:
- Invoked by 12+ commands and agents
- Central artifact management authority
- Ensures plan hierarchy consistency across all operations

### Lessons from Wave 1

Applying patterns from doc-writer, debug-specialist, test-specialist migrations:
1. 5-phase transformation is systematic and repeatable
2. Testing after each agent catches issues early
3. spec-updater integration is critical for all file operations
4. Audit score improvements correlate strongly with file creation rates

### Progressive Planning System Integrity

This phase ensures the foundational agents for plan organization are enforcement-compliant. Without this:
- Plans could become inconsistent (missing metadata, broken links)
- /implement could fail to detect complexity
- Hierarchy updates would be unreliable
- Technical debt would accumulate

With this phase complete, we have:
- ✓ Reliable expansion (always creates files + artifacts)
- ✓ Reliable collapse (always merges + cleans up)
- ✓ Reliable hierarchy updates (always synchronizes checkboxes)
- ✓ Foundation for Phase 4-7 command migrations
