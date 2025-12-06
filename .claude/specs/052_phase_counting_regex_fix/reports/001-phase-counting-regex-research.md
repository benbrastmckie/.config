# Phase Counting Regex Bug Research Report

## Findings

### Problem Statement

The phase counting regex in implement.md Block 1d uses `^### Phase` which matches false positives like `### Phase Routing Summary` and template examples (`### Phase N:`), causing incorrect phase counts and preventing plan status updates.

### Root Cause Analysis

**Observed Behavior**:
- Block 1d counted 6 "phases" instead of 3 real implementation phases
- 3 false positives: `### Phase Routing Summary` (2x) and `### Phase N:` (template)
- Recovery loop tried to process non-existent phases 4-6
- Block exited with error before reaching `update_plan_status` call

**Pattern Comparison**:

| Pattern | Used In | Behavior |
|---------|---------|----------|
| `^### Phase` | implement.md Block 1d (buggy) | Matches any `### Phase*` |
| `^### Phase [0-9]` | checkbox-utils.sh (correct) | Requires digit after "Phase " |
| `^##+ Phase [0-9]` | checkbox-utils.sh (best) | Handles h2/h3 with digit |

### Code Analysis

**checkbox-utils.sh** (CORRECT - lines 672, 684):
```bash
local total_phases=$(grep -E -c "^##+ Phase [0-9]" "$plan_path" 2>/dev/null || echo "0")
local complete_phases=$(grep -E -c "^##+ Phase [0-9].*\[COMPLETE\]" "$plan_path" 2>/dev/null || echo "0")
```

**implement.md Block 1d** (BUGGY - lines 1160, 1165):
```bash
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
```

### Affected Files (Active Code)

Files with buggy `^### Phase` pattern (no digit requirement):

| File | Lines | Component |
|------|-------|-----------|
| `.claude/commands/implement.md` | 1160, 1165 | Block 1d phase counting |
| `.claude/commands/lean-build.md` | 682, 683 | Block 1d phase counting |
| `.claude/commands/lean-implement.md` | 1024, 1025 | Block 1d phase counting |
| `.claude/agents/cleanup-plan-architect.md` | 504 | Phase existence check |

Files with CORRECT `^### Phase [0-9]` pattern:

| File | Lines | Component |
|------|-------|-----------|
| `.claude/lib/plan/checkbox-utils.sh` | 672, 684 | Library functions |
| `.claude/agents/plan-architect.md` | 1188, 1199, 1200 | Phase validation |
| `.claude/lib/todo/todo-functions.sh` | 206, 207 | TODO tracking |
| `.claude/commands/lean-plan.md` | 1803 | Phase counting |
| `.claude/commands/create-plan.md` | 1541 | Phase counting |
| `.claude/lib/lean/phase-classifier.sh` | 92 | Phase classification |

## Solution Evaluation

### Option 1: More Specific Regex `^### Phase [0-9]+:`

**Implementation**:
```bash
# BEFORE (buggy):
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")

# AFTER (fixed):
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")
```

**Pros**:
- Already proven in checkbox-utils.sh (the authoritative library)
- Simple, minimal change (add ` [0-9]`)
- No new dependencies
- Handles all known edge cases

**Cons**:
- Requires updating 4 files (implement.md, lean-build.md, lean-implement.md, cleanup-plan-architect.md)

**Assessment**: RECOMMENDED - integrates naturally with existing infrastructure

### Option 2: Exclude Lines Inside Code Blocks

**Implementation**: Multi-pass parsing to identify code block boundaries, then filter.

**Pros**: More comprehensive, handles all edge cases

**Cons**:
- Complex implementation requiring line-by-line state tracking
- Overkill for this problem (code blocks are handled by digit requirement)
- No existing infrastructure to leverage

**Assessment**: NOT RECOMMENDED - over-engineering

### Option 3: Use Estimated Phases Metadata Field

**Implementation**: Parse `Estimated Phases: N` from plan metadata.

**Pros**: Uses existing metadata

**Cons**:
- Metadata might be wrong or missing (not always present in older plans)
- Different purpose (estimate vs actual count)
- Requires metadata parsing before phase iteration

**Assessment**: NOT RECOMMENDED - solves different problem

### Option 4: Delegate to checkbox-utils.sh Functions

**Implementation**: Use `check_all_phases_complete()` function instead of inline grep.

**Pros**:
- Functions already exist and are correct
- DRY principle
- Consistent behavior across codebase

**Cons**:
- Block 1d already sources checkbox-utils.sh
- Functions don't return raw counts (return 0/1 for complete/incomplete)
- Would require new function for phase counting

**Assessment**: PARTIAL - good for boolean checks, but raw counts still needed

## Recommended Solution

**Primary Fix**: Update regex pattern from `^### Phase` to `^### Phase [0-9]` in affected files.

This aligns Block 1d with the pattern already proven in checkbox-utils.sh, requiring minimal changes while fixing the root cause.

### Specific Changes

**implement.md** (lines 1160, 1165):
```bash
# Line 1160 - BEFORE:
TOTAL_PHASES=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
# Line 1160 - AFTER:
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")

# Line 1165 - BEFORE:
PHASES_WITH_MARKER=$(grep -c "^### Phase.*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
# Line 1165 - AFTER:
PHASES_WITH_MARKER=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")
```

**lean-build.md** (lines 682, 683):
```bash
# Same pattern change as implement.md
```

**lean-implement.md** (lines 1024, 1025):
```bash
# Same pattern change as implement.md
```

**cleanup-plan-architect.md** (line 504):
```bash
# BEFORE:
if ! grep -q "^### Phase" "$PLAN_PATH"; then
# AFTER:
if ! grep -q "^### Phase [0-9]" "$PLAN_PATH"; then
```

## Testing Strategy

### Validation Tests

1. **False Positive Test**: Plan with `### Phase Routing Summary` should NOT count it as a phase
2. **Template Example Test**: Plan with `### Phase N:` template should NOT count it
3. **Real Phase Test**: Plan with `### Phase 1:`, `### Phase 2:`, `### Phase 3:` should count 3
4. **Mixed Content Test**: Plan with real phases AND Phase Routing Summary should count only real phases

### Test Command

```bash
# Create test plan with mixed content
cat > /tmp/test_plan.md << 'EOF'
## Metadata
- **Status**: [IN PROGRESS]

### Phase Routing Summary
| Phase | Type |
|-------|------|
| 1 | software |

### Phase 1: Setup [COMPLETE]
Tasks here

### Phase 2: Implementation [COMPLETE]
Tasks here

### Phase N: [Example Template]
Example content
EOF

# Test buggy pattern (should return 4 - WRONG)
grep -c "^### Phase" /tmp/test_plan.md

# Test fixed pattern (should return 2 - CORRECT)
grep -c "^### Phase [0-9]" /tmp/test_plan.md
```

## Conclusion

The fix is straightforward: align implement.md Block 1d (and similar code in lean-build.md, lean-implement.md) with the proven pattern in checkbox-utils.sh by adding ` [0-9]` to the grep pattern.

This is a minimal, low-risk change that:
1. Follows existing infrastructure patterns
2. Requires no new dependencies
3. Has been proven in production (checkbox-utils.sh)
4. Fixes the root cause rather than symptoms
