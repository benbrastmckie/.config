# Refactor /coordinate Command to Reduce Bash Complexity

## Metadata
- **Date**: 2025-11-05 (Revised: 2025-11-05)
- **Feature**: Simplify /coordinate command bash orchestration
- **Scope**: Eliminate ~95 lines (4%) of workaround overhead by consolidating with existing workflow-initialization.sh library patterns
- **Estimated Phases**: 4
- **Complexity**: Medium (5/10)
- **Estimated Total Time**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: Internal research (agent analysis of bash issues), existing infrastructure review
- **Integration Strategy**: Consolidate with existing workflow-initialization.sh patterns, maintain clean-break philosophy
- **Structure Level**: 1
- **Expanded Phases**: [4]

## Overview

**Revised Analysis After Infrastructure Review**:

The `/coordinate` command contains bash workaround code, but much of this is **already addressed by existing infrastructure** (`workflow-initialization.sh`). The real opportunity is **consolidation and consistency** with project patterns, not building new infrastructure.

### Key Discovery
- **workflow-initialization.sh already exports all paths**: The `initialize_workflow_paths()` function already handles CLAUDE_PROJECT_DIR detection, topic calculation, and path exports
- **`REPORT_PATH_N` pattern is a design choice**: Used to work around bash array export limitations (cannot export arrays directly)
- **Re-sourcing is necessary**: Due to Bash tool invocation isolation (GitHub #334, #2508)
- **Real complexity**: ~95 lines of actual workaround overhead (not 195)

### Current Impact (Revised)
- **CLAUDE_PROJECT_DIR recalculated**: 3 times in coordinate.md (30 lines per block = 90 lines total)
- **Library re-sourcing**: Necessary due to Bash tool limitation, but can be simplified (~5 lines needed)
- **Already handled by workflow-initialization.sh**: Topic detection, path calculation, directory creation

### Revised Goals
1. **Consolidate patterns**: Use workflow-initialization.sh consistently across all phase blocks
2. **Eliminate redundant recalculation**: CLAUDE_PROJECT_DIR detection can be simplified to match Standard 13 pattern
3. **Maintain functionality**: Zero regressions in workflow behavior
4. **Document accepted trade-offs**: Make Bash tool limitations explicit
5. **Follow clean-break philosophy**: Remove workarounds, don't add compatibility layers

## Success Criteria
- [ ] Bash workaround overhead reduced from ~95 lines to ~50 lines (~47% reduction)
- [ ] No functional regressions (all 4 workflow types work identically)
- [ ] Consistency with workflow-initialization.sh patterns (consolidated approach)
- [ ] Compliance with Standard 13 (CLAUDE_PROJECT_DIR detection pattern)
- [ ] Better documentation (Bash tool limitations explicitly documented)
- [ ] All tests pass (existing test suite + validation of phase transitions)
- [ ] Clean-break principle maintained (no compatibility layers or shims)

## Risk Assessment

### High Risks
- **Breaking existing workflows**: Many users depend on /coordinate
  - *Mitigation*: Comprehensive testing, all 4 workflow types validated

- **Introducing subtle bugs**: State management changes
  - *Mitigation*: No state management changes - only simplification of existing patterns

### Medium Risks
- **Documentation accuracy**: New docs may not match implementation
  - *Mitigation*: Write docs after implementation, validate with tests

### Low Risks
- **Performance regression**: Simpler code unlikely to be slower
  - *Mitigation*: Benchmark before/after, accept ±100ms variance

## Technical Design

### Revised Problem Analysis

The core issue is not architectural mismatch, but **inconsistent application of existing patterns**. The project already has `workflow-initialization.sh` which handles path calculation and exports, but `/coordinate` has redundant recalculation code.

#### Current Architecture (Actually Works, Just Redundant)
```
┌─────────────────────────────────────────────────────┐
│ /coordinate command                                  │
│                                                      │
│  Phase 0 Block 3: initialize_workflow_paths()       │
│  ↓ (exports CLAUDE_PROJECT_DIR, TOPIC_PATH, etc.)  │
│                                                      │
│  Phase 1 Block: (exports lost)                      │
│  ↓ Recalculates CLAUDE_PROJECT_DIR (30 lines)      │
│  ↓ Re-sources libraries (5 lines)                   │
│                                                      │
│  Phase 2 Block: (exports lost again)                │
│  ↓ Recalculates CLAUDE_PROJECT_DIR (30 lines)      │
│  ↓ Re-sources libraries (5 lines)                   │
│                                                      │
│  ...similar pattern in Phases 3-6                   │
└─────────────────────────────────────────────────────┘
```

**Opportunity**: Consolidate CLAUDE_PROJECT_DIR detection to Standard 13 pattern (10 lines), re-use workflow-initialization.sh exports via `reconstruct_report_paths_array()`

#### Constraint Analysis (Revised)

| Constraint | Type | Can Change? | Impact | Strategy |
|------------|------|-------------|---------|----------|
| Export persistence | Tool limitation | No (Anthropic) | Must recalculate minimal state | Accept, use Standard 13 pattern |
| Array export | Bash limitation | No (language) | Use REPORT_PATH_N pattern | Already solved by workflow-initialization.sh |
| 400-line threshold | Tool behavior | No (Anthropic) | Split blocks | Already compliant (blocks <350 lines) |
| Re-sourcing needed | Tool isolation | No (Anthropic) | Re-source libraries per block | Accept, simplify to 2-3 lines |

### Recommended Approach: Infrastructure Consolidation

**Strategy**: Leverage existing `workflow-initialization.sh` patterns, consolidate CLAUDE_PROJECT_DIR recalculation to Standard 13 pattern, and document accepted Bash tool limitations.

#### Key Changes

**1. Standardize CLAUDE_PROJECT_DIR Detection (60 lines savings)**

Replace verbose detection with Standard 13 pattern across 3 bash blocks.

**Current Pattern** (30 lines):
```bash
# Bash tool limitation (GitHub #334, #2508): exports don't persist
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
```

**Standard 13 Pattern** (10 lines):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Savings**: 20 lines per block × 3 blocks = 60 lines

**2. Simplify Library Sourcing (35 lines savings)**

Current pattern has verbose fallbacks that violate fail-fast principle. Simplify to match other orchestration commands.

**Current** (10 lines per block):
```bash
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries || exit 1

if command -v emit_progress &>/dev/null; then
  emit_progress "1" "Phase 1 starting"
else
  echo "PROGRESS: [Phase 1] - Phase 1 starting"
fi
```

**Simplified** (5 lines):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1
```

**Savings**: 5 lines per block × 7 blocks = 35 lines

**3. Document Bash Tool Limitations**

Add explicit documentation explaining accepted trade-offs.

#### Implementation Summary

| Phase | Change | Lines Saved | Rationale |
|-------|--------|-------------|-----------|
| 1 | Standardize CLAUDE_PROJECT_DIR | 60 | Apply Standard 13 consistently |
| 2 | Simplify library sourcing | 35 | Remove fallbacks (fail-fast) |
| 3 | Document limitations | +30 | Explicit trade-offs |
| 4 | Testing | 0 | Validation only |

**Total**: ~95 lines removed, ~30 documentation added = **~65 net reduction (-3%)**

#### Benefits

1. **Consistency**: All blocks use Standard 13 pattern
2. **Maintainability**: Simpler code, clearer purpose
3. **Documentation**: Limitations explicitly documented
4. **Clean-break**: No compatibility layers
5. **Integration**: Leverages workflow-initialization.sh

#### Accepted Trade-offs

These limitations are **inherent to Bash tool** and cannot be eliminated:

1. **CLAUDE_PROJECT_DIR recalculation**: 10 lines per block (necessary)
2. **Library re-sourcing**: 2-3 lines per block (necessary)
3. **REPORT_PATH_N pattern**: Already solved by workflow-initialization.sh

## Implementation Phases

### Phase 1: Standardize CLAUDE_PROJECT_DIR Detection
**Objective**: Replace verbose git detection with Standard 13 pattern across all bash blocks
**Complexity**: Low (2/10)
**Estimated Time**: 1-2 hours
**Dependencies**: []

**Tasks**:
- [ ] Identify all CLAUDE_PROJECT_DIR detection blocks in coordinate.md (expected: 3 blocks)
- [ ] Replace each 30-line detection block with 10-line Standard 13 pattern
- [ ] Verify `export CLAUDE_PROJECT_DIR` is present in each block
- [ ] Test phase transitions work correctly (exports don't persist, but recalculation works)
- [ ] Validate all 4 workflow types complete successfully

**Pattern**:
```bash
# Before (30 lines - verbose comments and error handling)
# Bash tool limitation (GitHub #334, #2508): exports from Block 1 don't
# persist to Block 2. Recalculate using same git-based detection pattern.

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi

# After (10 lines - Standard 13)
# Standard 13: CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Testing**:
```bash
# Test each workflow type
/coordinate "research bash patterns"  # research-only
/coordinate "research auth to create plan"  # research-and-plan
/coordinate "implement test feature"  # full-implementation (stub)

# Verify CLAUDE_PROJECT_DIR available in each phase
# (add debug echo to each block temporarily)
```

**Files Modified**:
- `.claude/commands/coordinate.md` (3 bash blocks updated)

**Success Criteria**:
- [ ] All 3 CLAUDE_PROJECT_DIR blocks use Standard 13 pattern
- [ ] All tests pass
- [ ] 60 lines removed (20 per block × 3)

---

### Phase 2: Simplify Library Sourcing
**Objective**: Remove verbose fallback patterns, use fail-fast library sourcing
**Complexity**: Low (3/10)
**Estimated Time**: 1-2 hours
**Dependencies**: [1]

**Tasks**:
- [ ] Identify all library sourcing blocks in coordinate.md (expected: 6-7 blocks)
- [ ] Replace verbose pattern with 2-line fail-fast sourcing
- [ ] Remove emit_progress fallback patterns (function availability guaranteed by library-sourcing.sh)
- [ ] Test library sourcing failures produce clear errors
- [ ] Validate all functions available after sourcing

**Pattern**:
```bash
# Before (10 lines - verbose with fallbacks)
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "$LIB_DIR/library-sourcing.sh"
source_required_libraries || exit 1

# Emit progress with fallback if function unavailable
if command -v emit_progress &>/dev/null; then
  emit_progress "1" "Phase 1: Research"
else
  echo "PROGRESS: [Phase 1] - Phase 1: Research"
fi

# After (2 lines - fail-fast)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries || exit 1
```

**Rationale**:
- `library-sourcing.sh` already handles error messages
- Fallback patterns violate fail-fast principle
- `emit_progress` guaranteed available after source_required_libraries

**Testing**:
```bash
# Test library sourcing failure
mv .claude/lib/library-sourcing.sh .claude/lib/library-sourcing.sh.bak
/coordinate "test workflow"
# Expected: Clear error message, immediate exit
mv .claude/lib/library-sourcing.sh.bak .claude/lib/library-sourcing.sh

# Test function availability
# (all emit_progress calls should work without fallback)
```

**Files Modified**:
- `.claude/commands/coordinate.md` (6-7 blocks simplified)

**Success Criteria**:
- [ ] All library sourcing uses 2-line pattern
- [ ] No emit_progress fallbacks remain
- [ ] All tests pass
- [ ] 35-40 lines removed (5 per block × 7)

---

### Phase 3: Documentation - Bash Tool Limitations
**Objective**: Document accepted trade-offs and Bash tool limitations
**Complexity**: Low (2/10)
**Estimated Time**: 1 hour
**Dependencies**: [1, 2]

**Tasks**:
- [ ] Add "Bash Tool Limitations" section to coordinate.md or separate doc
- [ ] Explain export persistence limitation (GitHub #334, #2508)
- [ ] Explain array export limitation and REPORT_PATH_N pattern
- [ ] Explain why recalculation is necessary (not a workaround, but correct approach)
- [ ] Link to Standard 13 for CLAUDE_PROJECT_DIR pattern
- [ ] Link to workflow-initialization.sh for array handling

**Documentation Structure**:
```markdown
## Bash Tool Limitations

### Export Persistence (GitHub #334, #2508)
**Limitation**: Exports from one Bash invocation don't persist to the next.

**Impact**: CLAUDE_PROJECT_DIR must be recalculated in each phase block.

**Solution**: Use Standard 13 pattern (10 lines per block). This is not a workaround—it's the correct approach given the tool's execution model.

### Array Export
**Limitation**: Bash arrays cannot be exported across process boundaries.

**Solution**: workflow-initialization.sh exports arrays using REPORT_PATH_N variables. Use reconstruct_report_paths_array() to rebuild in subsequent blocks.

**Example**:
[code example]

### Performance Impact
- CLAUDE_PROJECT_DIR detection: <1ms per block
- Library sourcing: ~5ms per block
- Total overhead: <50ms for entire workflow

**Accepted**: Small overhead is acceptable for correct operation.
```

**Files Modified**:
- `.claude/commands/coordinate.md` or `.claude/docs/troubleshooting/bash-tool-limitations.md`

**Success Criteria**:
- [ ] Limitations clearly documented
- [ ] Examples provided
- [ ] Links to relevant standards/libraries
- [ ] ~30 lines documentation added

---

### Phase 4: Testing and Validation (Medium)
**Objective**: Comprehensive testing of all changes, validate no regressions
**Status**: PENDING

**Summary**: Multi-dimensional testing across workflow types, state management, error handling, performance benchmarking, regression testing, and documentation validation. Includes 8 detailed tasks covering baseline establishment, 4 workflow type scenarios, state transition verification, fail-fast error handling, performance comparison, existing test suite integration, documentation accuracy checks, and real-world integration testing.

For detailed tasks and implementation, see [Phase 4 Details](phase_4_testing_and_validation.md)

---

## Testing Strategy

### Validation Tests
1. **Workflow Types**: All 4 types complete successfully
2. **File Creation**: 100% reliability (no failures)
3. **Phase Transitions**: CLAUDE_PROJECT_DIR available in each block
4. **Library Functions**: All functions available after sourcing
5. **Performance**: Within ±100ms of baseline

### Regression Prevention
- Run existing test suite: `.claude/tests/test_orchestration_commands.sh --command coordinate`
- Verify no new failures introduced
- Validate error messages remain clear and actionable

---

## Rollback Plan

If issues discovered:

**Phase 1-2 Rollback**:
```bash
git revert HEAD~2..HEAD  # Revert Phase 1 and 2 commits
```

**Phase 3 Rollback**:
```bash
# Documentation-only, just remove the new section
```

**Phase 4**:
```bash
# Testing-only, no rollback needed
```

---

## Estimated Time Summary
- Phase 1: 1-2 hours (CLAUDE_PROJECT_DIR standardization)
- Phase 2: 1-2 hours (Library sourcing simplification)
- Phase 3: 1 hour (Documentation)
- Phase 4: 2-3 hours (Testing and validation)

**Total**: 6-8 hours

---

## Revision History

### 2025-11-05 - Initial Revision
**Changes**: Simplified approach based on infrastructure review
**Reason**: Discovered workflow-initialization.sh already addresses most complexity
**Modified Phases**: Reduced from 6 phases to 4 phases
**Scope Change**: 195 lines → 95 lines (realistic assessment)
**Key Insight**: Integration with existing infrastructure, not building new state file patterns
**Alignment**: Maintains clean-break philosophy, follows Standard 13, leverages workflow-initialization.sh
