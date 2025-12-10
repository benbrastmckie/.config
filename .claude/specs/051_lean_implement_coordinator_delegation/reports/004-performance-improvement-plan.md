# Research Report: Performance Improvement Implementation Plan

## Metadata
- **Date**: 2025-12-09
- **Topic**: Actionable improvement plan for /lean-implement delegation
- **Source**: Previous research reports in this series

## Executive Summary

This report consolidates findings from the previous three research reports into an actionable implementation plan. The plan addresses three critical issues: (1) primary agent reading agent files, (2) full summary file parsing, and (3) pseudo-code Task blocks. Implementation should reduce primary agent context consumption by 75% and enable 10+ iterations.

## Improvement Categories

### Category A: Remove Agent File Reads (Priority: HIGH)

**Current Behavior**:
- Primary agent reads lean-coordinator.md (1174 lines, ~4000 tokens)
- Primary agent reads implementer-coordinator.md (200 lines, ~700 tokens)
- Total: ~4700 tokens consumed before delegation

**Target Behavior**:
- Primary agent passes only file paths to coordinators
- Coordinators read their own behavioral files
- Primary agent context: 0 tokens for agent files

**Implementation Steps**:
1. Modify Block 1b to NOT read agent files
2. Include "Read and follow: ${path}" instruction in coordinator prompt
3. Remove any prose that describes agent behavior in primary agent

### Category B: Brief Summary Parsing (Priority: HIGH)

**Current Behavior**:
- Primary agent reads entire summary file (~100+ lines)
- Grep patterns search full file content
- Estimated: 2000+ tokens consumed

**Target Behavior**:
- Parse only structured metadata lines (lines 1-8)
- Use `head -8` to limit file read
- Extract only: summary_brief, phases_completed, work_remaining, context_usage_percent
- Target: 80 tokens consumed

**Implementation Steps**:
1. Add `parse_brief_summary()` function to Block 1c
2. Replace full file grep patterns with head-based extraction
3. Remove any full file reads from summary parsing

### Category C: Convert Pseudo-Code to Real Invocations (Priority: MEDIUM)

**Current Behavior**:
- Block 1b ends with pseudo-code: `Task { ... }`
- This is instructional text, not actual Task tool invocation
- Primary agent may interpret this as guidance rather than action

**Target Behavior**:
- Explicit `**EXECUTE NOW**: USE the Task tool` directive
- Clear separation between bash block and Task invocation
- No ambiguity about mandatory delegation

**Implementation Steps**:
1. Replace `Task { }` pseudo-code with explicit invocation directive
2. Add comment explaining mandatory delegation
3. Ensure primary agent cannot bypass Task invocation

### Category D: Context Budget Monitoring (Priority: LOW)

**Current Behavior**:
- No tracking of primary agent context consumption
- Context exhaustion detected only when workflow fails

**Target Behavior**:
- Track estimated context usage after each operation
- Alert when approaching budget threshold
- Enable proactive context management

**Implementation Steps**:
1. Add context budget constants to Block 1a
2. Add tracking function for major operations
3. Log warnings when budget exceeded

## Implementation Phases

### Phase 1: Remove Agent File Reads [NOT STARTED]

**Scope**: Modify lean-implement.md Block 1b to remove agent file reading

**Tasks**:
- [ ] Remove prose instructing primary agent to read agent files
- [ ] Update coordinator prompt to include "Read and follow" instruction
- [ ] Verify coordinator still receives necessary context via paths

**Files Modified**:
- `.claude/commands/lean-implement.md` (Block 1b)

**Validation**:
- Run /lean-implement and verify no Read operations on agent files in output
- Verify coordinator still executes correctly

### Phase 2: Implement Brief Summary Parsing [NOT STARTED]

**Scope**: Modify Block 1c to parse only metadata lines from summary files

**Tasks**:
- [ ] Add `parse_brief_summary()` function
- [ ] Replace grep patterns with head-based extraction
- [ ] Update all variable extraction to use new function

**Files Modified**:
- `.claude/commands/lean-implement.md` (Block 1c)

**Validation**:
- Verify work_remaining, context_usage_percent correctly parsed
- Verify only 80 tokens consumed for summary parsing

### Phase 3: Convert Task Pseudo-Code [NOT STARTED]

**Scope**: Replace pseudo-code Task blocks with actual invocation directives

**Tasks**:
- [ ] Replace `Task { }` pseudo-code at end of Block 1b
- [ ] Add `**EXECUTE NOW**: USE the Task tool` directive
- [ ] Document mandatory delegation in block header

**Files Modified**:
- `.claude/commands/lean-implement.md` (Block 1b)

**Validation**:
- Run /lean-implement and verify Task tool is invoked
- Verify primary agent does not perform implementation work

### Phase 4: Add Context Budget Monitoring [NOT STARTED]

**Scope**: Add optional context tracking to primary agent

**Tasks**:
- [ ] Add PRIMARY_CONTEXT_BUDGET constant to Block 1a
- [ ] Add `track_context_usage()` function
- [ ] Add budget check at end of major blocks
- [ ] Log warnings when budget exceeded

**Files Modified**:
- `.claude/commands/lean-implement.md` (Block 1a, 1c)

**Validation**:
- Verify budget tracking logs appear
- Verify warnings issued when budget exceeded

## Testing Strategy

### Test 1: Agent File Read Elimination

```bash
# Run /lean-implement and check output for agent file reads
/lean-implement plan.md 2>&1 | grep -c "Read.*agents/"
# Expected: 0 (no agent file reads by primary agent)
```

### Test 2: Brief Summary Token Count

```bash
# Extract summary parsing section from output
# Count tokens in parsed content
# Expected: <100 tokens
```

### Test 3: Task Invocation Verification

```bash
# Check output for Task tool invocation
/lean-implement plan.md 2>&1 | grep -c "Task("
# Expected: 1-2 (coordinator invocations only)
```

### Test 4: Iteration Improvement

```bash
# Compare max iterations before and after
# Before: 3-4 iterations before context exhaustion
# After: 10+ iterations
```

## Success Criteria

- [ ] Primary agent context reduced by 75%
- [ ] Max iterations increased from 3-4 to 10+
- [ ] No Read operations on agent files in primary agent output
- [ ] Summary parsing uses only 80 tokens (down from 2000+)
- [ ] Task tool explicitly invoked (not pseudo-code)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Coordinator fails to read behavioral file | Low | High | Test with explicit paths |
| Brief parsing misses critical fields | Medium | Medium | Comprehensive field validation |
| Task invocation syntax incorrect | Low | High | Use proven patterns from /create-plan |
| Context budget too aggressive | Low | Low | Make budget configurable |

## Dependencies

- Existing lean-coordinator.md agent (no changes needed)
- Existing lean-implementer.md agent (no changes needed)
- Block 1a artifact path pre-calculation (already implemented)
- Hard barrier exit pattern (already implemented in Block 1c line 1292)

## Estimated Hours

- Phase 1 (Agent file reads): 1-2 hours
- Phase 2 (Brief summary): 1-2 hours
- Phase 3 (Task pseudo-code): 0.5-1 hour
- Phase 4 (Context budget): 1-2 hours
- Testing: 1-2 hours
- **Total: 5-9 hours**
