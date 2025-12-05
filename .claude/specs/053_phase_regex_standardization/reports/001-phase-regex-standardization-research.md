# Phase Counting Regex Standardization Research Report

## Metadata
- **Date**: 2025-12-04
- **Agent**: research-specialist
- **Topic**: Phase counting regex standardization across .claude/ codebase
- **Report Type**: codebase analysis

## Executive Summary

Analysis of 50+ files reveals 4 active code files using buggy phase counting regex (`^### Phase` without digit requirement), causing false positives from template examples and summary sections. The recommended fix is to standardize on `^### Phase [0-9]` pattern (already proven in checkbox-utils.sh library and 6 other files). Additionally, 1 standards document requires updates to enforce this pattern going forward.

## Findings

### Current State Analysis

#### Buggy Pattern Files (REQUIRE UPDATE)

**Active Code Files - Phase Counting (grep -c)**:

| File | Lines | Pattern | Issue |
|------|-------|---------|-------|
| `.claude/commands/implement.md` | 1160, 1165 | `^### Phase` and `^### Phase.*\[COMPLETE\]` | No digit requirement - counts false positives |
| `.claude/commands/lean-build.md` | 682, 683 | `^### Phase` and `^### Phase.*\[COMPLETE\]` | No digit requirement - counts false positives |
| `.claude/commands/lean-implement.md` | 1024, 1025 | `^### Phase` and `^### Phase.*\[COMPLETE\]` | No digit requirement - counts false positives |
| `.claude/agents/cleanup-plan-architect.md` | 504 | `^### Phase` (existence check) | No digit requirement - may match template examples |

**False Positive Examples**:
- `### Phase Routing Summary` (matches `^### Phase` but not `^### Phase [0-9]`)
- `### Phase N:` (template example, matches `^### Phase` but not `^### Phase [0-9]`)
- `### Phase Dependencies` (hypothetical header, matches buggy pattern)

**Impact**:
- Block 1d in implement.md counted 6 phases instead of 3 in recent execution
- Recovery loop attempted to process non-existent phases 4-6
- Plan status update never executed due to early exit on error

#### Correct Pattern Files (NO CHANGE NEEDED)

**Files Already Using Recommended Pattern `^### Phase [0-9]`**:

| File | Lines | Pattern | Status |
|------|-------|---------|--------|
| `.claude/lib/plan/checkbox-utils.sh` | 672, 684 | `^##+ Phase [0-9]` | CORRECT (authoritative library) |
| `.claude/agents/plan-architect.md` | 1188, 1199, 1200 | `^### Phase [0-9]` | CORRECT |
| `.claude/lib/todo/todo-functions.sh` | 206, 207 | `^### Phase [0-9]` | CORRECT |
| `.claude/commands/lean-plan.md` | 1803 | `^### Phase [0-9]` | CORRECT |
| `.claude/commands/create-plan.md` | 1541 | `^### Phase [0-9]` | CORRECT |
| `.claude/lib/lean/phase-classifier.sh` | 92 | `^### Phase [0-9]` | CORRECT |
| `.claude/commands/revise.md` | 1204 | `^### Phase [0-9]` | CORRECT |

**Note**: checkbox-utils.sh uses `^##+ Phase [0-9]` which is even more robust (supports both h2 and h3 headings), but current standardization focuses on h3 format (`^### Phase [0-9]`) since all plans use h3.

#### Test Files Analysis

**Test Files Using Correct Pattern** (verification only, no updates needed):
- `.claude/tests/unit/test_parsing_utilities.sh` (lines 119, 310)
- `.claude/tests/progressive/test_progressive_roundtrip.sh` (line 212)

**Test Files Using Buggy Pattern** (require updates for consistency):
- `.claude/tests/agents/test_plan_architect_revision_mode.sh` (line 162)
- `.claude/tests/commands/test_revise_small_plan.sh` (lines 134, 286, 328)

### Standards Documentation Analysis

#### Documentation Files Requiring Updates

**Primary Standards File**:

| File | Current Content | Required Update |
|------|----------------|-----------------|
| `.claude/docs/reference/standards/plan-progress.md` | Lines 218-219 show correct pattern in example, but no explicit standard documented | Add section on phase counting regex standard |

**Current Example in plan-progress.md (lines 218-219)**:
```bash
if grep -qE "^### Phase [0-9]+:" "$PLAN_FILE" && \
   ! grep -qE "^### Phase.*\[(NOT STARTED|IN PROGRESS|COMPLETE)\]" "$PLAN_FILE"; then
```

This example already uses the correct pattern but:
1. No explicit standard documented stating this is the required pattern
2. No explanation of why digit requirement is necessary
3. No enforcement guidance for command authors

**Documentation Gap**: Standards file should explicitly state:
- Phase counting MUST use `^### Phase [0-9]` pattern
- Digit requirement prevents false positives from template examples
- Examples of what gets matched/excluded

#### Secondary Documentation Files

**Files with Phase Counting Examples** (review and update if needed):

| File | Context | Assessment |
|------|---------|------------|
| `.claude/docs/reference/command-patterns-quick-reference.md` | May contain phase counting examples | Review for pattern consistency |
| `.claude/docs/guides/patterns/standards-integration.md` | Line 91 shows `^### Phase 0: Standards Revision` (correct) | Already correct, no update needed |
| `.claude/docs/reference/workflows/phases-planning.md` | Line 96 shows `^## Phase\|^### Phase` | Supports both h2/h3 but lacks digit requirement |

### Pattern Comparison Matrix

| Pattern | Example Matches | False Positives | Recommended |
|---------|----------------|-----------------|-------------|
| `^### Phase` | `### Phase 1:`, `### Phase Routing Summary`, `### Phase N:` | YES (any text after "Phase") | NO |
| `^### Phase [0-9]` | `### Phase 1:`, `### Phase 2:` | NO (requires digit) | YES (current standard) |
| `^##+ Phase [0-9]` | `## Phase 1:`, `### Phase 1:` | NO (supports both h2/h3) | IDEAL (future consideration) |

**Note**: `^##+ Phase [0-9]` pattern from checkbox-utils.sh is more flexible (supports both h2 and h3 headings), but since all current plans use h3 format, standardizing on `^### Phase [0-9]` is sufficient.

### Code Location Details

#### implement.md - Lines 1160, 1165

**Block 1d: Phase Marker Validation and Recovery**

Context (lines 1157-1168):
```bash
# Count total phases and phases with [COMPLETE] marker
# Apply defensive sanitization pattern to prevent bash conditional syntax errors
# from grep output containing embedded newlines (Pattern from complexity-utils.sh)
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
TOTAL_PHASES=$(echo "$TOTAL_PHASES" | tr -d '\n' | tr -d ' ')
TOTAL_PHASES=${TOTAL_PHASES:-0}
[[ "$TOTAL_PHASES" =~ ^[0-9]+$ ]] || TOTAL_PHASES=0

PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(echo "$PHASES_WITH_MARKER" | tr -d '\n' | tr -d ' ')
PHASES_WITH_MARKER=${PHASES_WITH_MARKER:-0}
[[ "$PHASES_WITH_MARKER" =~ ^[0-9]+$ ]] || PHASES_WITH_MARKER=0
```

**Required Changes**:
- Line 1160: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"`
- Line 1165: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"`

#### lean-build.md - Lines 682, 683

**Block 1d: Phase Marker Validation**

Context (lines 681-686):
```bash
# Count total phases and phases with [COMPLETE] marker
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

echo "Plan File: $(basename "$PLAN_FILE")"
echo "Total phases: $TOTAL_PHASES"
```

**Required Changes**:
- Line 682: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"`
- Line 683: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"`

#### lean-implement.md - Lines 1024, 1025

**Block: Phase Marker Validation and Recovery**

Context (lines 1023-1028):
```bash
# Count total phases and phases with [COMPLETE] marker
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

echo "Total phases: $TOTAL_PHASES"
echo "Phases with [COMPLETE] marker: $PHASES_WITH_MARKER"
```

**Required Changes**:
- Line 1024: Change `grep -c "^### Phase"` to `grep -c "^### Phase [0-9]"`
- Line 1025: Change `grep -c "^### Phase.*\[COMPLETE\]"` to `grep -c "^### Phase [0-9].*\[COMPLETE\]"`

**Note**: lean-implement.md also has CORRECT pattern at lines 464 (`^### Phase [0-9]`) - this should remain unchanged.

#### cleanup-plan-architect.md - Line 504

**Block: /implement Compatibility Validation**

Context (lines 503-507):
```bash
# Verify /implement compatibility (has phases with checkboxes)
if ! grep -q "^### Phase" "$PLAN_PATH"; then
  echo "ERROR: No phases found - plan not /implement-compatible"
  exit 1
fi
```

**Required Change**:
- Line 504: Change `grep -q "^### Phase"` to `grep -q "^### Phase [0-9]"`

**Rationale**: Ensures validation only passes for real numbered phases, not template examples or summary sections.

### Additional Occurrences (Documentation/Historical)

**Documentation Files** (examples in docs, no code changes needed but should verify accuracy):
- `.claude/specs/052_phase_counting_regex_fix/reports/001-phase-counting-regex-research.md` (multiple examples)
- `.claude/docs/concepts/patterns/defensive-programming.md` (lines 393, 424, 430)
- `.claude/specs/021_plan_progress_tracking_fix/reports/001-progress-tracking-analysis.md` (multiple examples)

**Historical/Archive** (no updates needed):
- Various spec files in `.claude/specs/` (historical examples)
- Test plan files (examples only)

## Recommendations

### 1. Update Active Code Files (Priority: CRITICAL)

Update 4 files with buggy patterns to use recommended `^### Phase [0-9]` pattern:

**Commands**:
1. `.claude/commands/implement.md` (lines 1160, 1165)
2. `.claude/commands/lean-build.md` (lines 682, 683)
3. `.claude/commands/lean-implement.md` (lines 1024, 1025)

**Agents**:
4. `.claude/agents/cleanup-plan-architect.md` (line 504)

**Change Pattern**:
```bash
# BEFORE
grep -c "^### Phase" "$PLAN_FILE"

# AFTER
grep -c "^### Phase [0-9]" "$PLAN_FILE"
```

### 2. Document Standard in plan-progress.md (Priority: HIGH)

Add explicit section to `.claude/docs/reference/standards/plan-progress.md` documenting the phase counting regex standard.

**Recommended New Section** (add after line 240):

```markdown
## Phase Counting Standard

### Required Regex Pattern

**CRITICAL**: All phase counting operations MUST use the digit-required pattern to prevent false positives.

#### Standard Pattern

```bash
# Phase counting (total phases)
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")

# Phase counting with status marker
COMPLETE_PHASES=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
```

#### Pattern Explanation

| Component | Purpose | Example Match | Example Non-Match |
|-----------|---------|---------------|-------------------|
| `^` | Line start anchor | `### Phase 1:` | `  ### Phase 1:` (indented) |
| `### Phase ` | Exact heading format | `### Phase 1:` | `## Phase 1:` (h2), `#### Phase 1:` (h4) |
| `[0-9]` | **REQUIRED** digit | `### Phase 1:`, `### Phase 2:` | `### Phase Routing Summary`, `### Phase N:` |

#### Why Digit Requirement is Critical

The `[0-9]` digit requirement prevents false positives from:

1. **Template Examples**: `### Phase N: [Example Template]` (used in documentation)
2. **Summary Sections**: `### Phase Routing Summary` (metadata tables)
3. **Dependency Sections**: `### Phase Dependencies` (hypothetical)

**Real-World Bug**: Without digit requirement, implement.md Block 1d counted 6 "phases" instead of 3:
- 3 real phases: `### Phase 1:`, `### Phase 2:`, `### Phase 3:`
- 2 false positives: `### Phase Routing Summary` (appeared twice)
- 1 false positive: `### Phase N:` (template example)

#### Enforcement

All command authors MUST:
- Use `^### Phase [0-9]` for phase counting operations
- Never use `^### Phase` without digit requirement
- Test with plans containing `### Phase Routing Summary` sections
- Verify regex with test cases before committing

#### Alternative Patterns (Advanced)

For commands that need to support both h2 and h3 formats:

```bash
# Supports both ## Phase and ### Phase
grep -c "^##+ Phase [0-9]" "$PLAN_FILE"
```

**Note**: Current standard is h3 only (`^### Phase [0-9]`) since all plans use h3 format. The h2/h3 flexible pattern is used in checkbox-utils.sh library but not required for command-level phase counting.
```

### 3. Update Test Files for Consistency (Priority: MEDIUM)

Update test files using buggy pattern to match production code standard:

**Test Files to Update**:
1. `.claude/tests/agents/test_plan_architect_revision_mode.sh` (line 162)
2. `.claude/tests/commands/test_revise_small_plan.sh` (lines 134, 286, 328)

**Rationale**: Tests should demonstrate correct patterns for future reference.

### 4. Add Validation to Pre-Commit Hooks (Priority: LOW)

Consider adding linter check to prevent future regressions:

```bash
# .claude/scripts/lint-phase-counting-regex.sh
# Detect buggy phase counting patterns in commands/agents

find .claude/commands .claude/agents -name "*.md" -exec grep -Hn 'grep -c.*"\^###.*Phase[^[]*"' {} \; | \
  grep -v 'Phase \[0-9\]' && {
  echo "ERROR: Phase counting without digit requirement detected"
  echo "Use: grep -c '^### Phase [0-9]' instead of grep -c '^### Phase'"
  exit 1
}
```

### 5. Review docs/reference/workflows/phases-planning.md (Priority: MEDIUM)

File `.claude/docs/reference/workflows/phases-planning.md` line 96 uses:
```bash
PHASE_COUNT=$(grep -c "^## Phase\|^### Phase" "$PLAN_PATH")
```

This pattern supports both h2/h3 but lacks digit requirement. Review and update if needed.

## Implementation Checklist

### Phase 1: Active Code Updates (CRITICAL - Execute First)

- [ ] Update `.claude/commands/implement.md` line 1160: `grep -c "^### Phase [0-9]"`
- [ ] Update `.claude/commands/implement.md` line 1165: `grep -c "^### Phase [0-9].*\[COMPLETE\]"`
- [ ] Update `.claude/commands/lean-build.md` line 682: `grep -c "^### Phase [0-9]"`
- [ ] Update `.claude/commands/lean-build.md` line 683: `grep -c "^### Phase [0-9].*\[COMPLETE\]"`
- [ ] Update `.claude/commands/lean-implement.md` line 1024: `grep -c "^### Phase [0-9]"`
- [ ] Update `.claude/commands/lean-implement.md` line 1025: `grep -c "^### Phase [0-9].*\[COMPLETE\]"`
- [ ] Update `.claude/agents/cleanup-plan-architect.md` line 504: `grep -q "^### Phase [0-9]"`

### Phase 2: Standards Documentation (HIGH - Execute Second)

- [ ] Add "Phase Counting Standard" section to `.claude/docs/reference/standards/plan-progress.md`
- [ ] Include pattern explanation table
- [ ] Include false positive examples
- [ ] Include enforcement requirements
- [ ] Include real-world bug example

### Phase 3: Test File Updates (MEDIUM - Execute Third)

- [ ] Update `.claude/tests/agents/test_plan_architect_revision_mode.sh` line 162
- [ ] Update `.claude/tests/commands/test_revise_small_plan.sh` line 134
- [ ] Update `.claude/tests/commands/test_revise_small_plan.sh` line 286
- [ ] Update `.claude/tests/commands/test_revise_small_plan.sh` line 328

### Phase 4: Documentation Review (MEDIUM - Execute Fourth)

- [ ] Review `.claude/docs/reference/command-patterns-quick-reference.md` for phase counting examples
- [ ] Review `.claude/docs/reference/workflows/phases-planning.md` line 96 (add digit requirement if needed)
- [ ] Update any other documentation files with phase counting examples

### Phase 5: Validation Infrastructure (LOW - Execute Last)

- [ ] Create `.claude/scripts/lint-phase-counting-regex.sh` validator
- [ ] Add validator to `.claude/scripts/validate-all-standards.sh`
- [ ] Test validator against known buggy patterns
- [ ] Add validator to pre-commit hook

## Testing Strategy

### Validation Test Case

Create test plan with mixed content to verify fix:

```bash
cat > /tmp/test_phase_counting.md << 'EOF'
## Metadata
- **Status**: [IN PROGRESS]

### Phase Routing Summary
| Phase | Type | Dependencies |
|-------|------|--------------|
| 1 | software | [] |
| 2 | software | [1] |

### Phase 1: Setup [COMPLETE]
- [x] Task 1
- [x] Task 2

### Phase 2: Implementation [IN PROGRESS]
- [x] Task 1
- [ ] Task 2

### Phase N: [Example Template]
This is a template example showing phase structure.
- [ ] Example task

### Phase Dependencies
No external dependencies.
EOF

# Test buggy pattern (WRONG - counts 6)
grep -c "^### Phase" /tmp/test_phase_counting.md
# Expected: 6 (includes false positives)

# Test fixed pattern (CORRECT - counts 2)
grep -c "^### Phase [0-9]" /tmp/test_phase_counting.md
# Expected: 2 (only real phases)

# Test with status marker (CORRECT - counts 1)
grep -c "^### Phase [0-9].*\[COMPLETE\]" /tmp/test_phase_counting.md
# Expected: 1 (Phase 1 only)
```

### Expected Results

| Pattern | Count | Explanation |
|---------|-------|-------------|
| `^### Phase` | 6 | Matches all 6 headers starting with "### Phase" |
| `^### Phase [0-9]` | 2 | Matches only Phase 1 and Phase 2 (real phases) |
| `^### Phase [0-9].*\[COMPLETE\]` | 1 | Matches only Phase 1 (complete) |

## References

### Primary Source Files

**Buggy Pattern Files**:
- `/home/benjamin/.config/.claude/commands/implement.md:1160` (phase counting)
- `/home/benjamin/.config/.claude/commands/implement.md:1165` (complete phase counting)
- `/home/benjamin/.config/.claude/commands/lean-build.md:682` (phase counting)
- `/home/benjamin/.config/.claude/commands/lean-build.md:683` (complete phase counting)
- `/home/benjamin/.config/.claude/commands/lean-implement.md:1024` (phase counting)
- `/home/benjamin/.config/.claude/commands/lean-implement.md:1025` (complete phase counting)
- `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md:504` (phase existence check)

**Correct Pattern Files** (authoritative examples):
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:672` (authoritative library)
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:684` (authoritative library)
- `/home/benjamin/.config/.claude/agents/plan-architect.md:1188` (phase counting)
- `/home/benjamin/.config/.claude/agents/plan-architect.md:1199` (phase headers)
- `/home/benjamin/.config/.claude/agents/plan-architect.md:1200` (status markers)

**Standards Documentation**:
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md` (requires new section)
- `/home/benjamin/.config/.claude/docs/reference/workflows/phases-planning.md:96` (review needed)

**Research Foundation**:
- `/home/benjamin/.config/.claude/specs/052_phase_counting_regex_fix/reports/001-phase-counting-regex-research.md` (Option 1 recommendation)
