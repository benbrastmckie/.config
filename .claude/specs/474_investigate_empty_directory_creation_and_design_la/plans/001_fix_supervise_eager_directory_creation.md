# Fix /supervise Eager Directory Creation - Implementation Plan

## Metadata
- Complexity: 4/10
- Estimated Time: 2-3 hours
- Phases: 3
- Dependencies: None

## Overview

The `/supervise` command creates all 6 subdirectories (reports/, plans/, summaries/, debug/, scripts/, outputs/) upfront in Phase 0, resulting in empty directories for workflows that don't use all artifact types. This plan implements lazy directory creation to align with system-wide standards.

**Target**: Create only topic root during Phase 0; subdirectories created on-demand when files written.

## Phases

### Phase 1: Modify create_topic_structure() for Lazy Creation [COMPLETED]

**Objective**: Update `create_topic_structure()` to only create topic root directory

**Tasks**:
1. [x] Read `.claude/lib/topic-utils.sh` and locate `create_topic_structure()` function
2. [x] Modify function to only create topic root: `mkdir -p "$topic_path"`
3. [x] Remove subdirectory creation loop and verification checkpoint for all 6 subdirectories
4. [x] Update function documentation to reflect lazy creation pattern
5. [x] Verify function returns 0 on success, 1 on failure (preserve interface)

**Verification**:
- [x] Function creates only topic root directory
- [x] No subdirectories created after function call
- [x] Return values unchanged (backward compatibility)

**Complexity**: 2/10
**Dependencies**: None

---

### Phase 2: Update /supervise Command Phase 0

**Objective**: Remove eager subdirectory creation from `/supervise` command

**Tasks**:
1. Read `.claude/commands/supervise.md` Phase 0 section (STEP 5 - Create topic directory structure)
2. Remove eager subdirectory creation from fallback mechanism
3. Update fallback to only create topic root: `mkdir -p "$TOPIC_PATH"`
4. Update verification checkpoint to only check topic root exists
5. Remove "All 6 subdirectories verified" message
6. Add inline comment explaining subdirectories created on-demand

**Verification**:
- [ ] Phase 0 only creates topic root
- [ ] Fallback mechanism only creates topic root
- [ ] Verification checkpoints updated
- [ ] All workflow types tested (research-only, research-and-plan, full-implementation, debug-only)

**Complexity**: 4/10
**Dependencies**: Phase 1

---

### Phase 3: Add Directory Creation to Agent Templates

**Objective**: Ensure agent templates create parent directories before writing files

**Tasks**:
1. Identify all Write tool invocations in `.claude/commands/supervise.md` agent templates
2. Add `mkdir -p "$(dirname "$FILE_PATH")"` before each Write tool usage
3. Update verification checkpoints to confirm directory creation
4. Test all workflow types to ensure subdirectories created when needed

**Verification**:
- [ ] Research agents create reports/ when writing files
- [ ] Plan-architect creates plans/ when writing files
- [ ] Debug-analyst creates debug/ when writing files
- [ ] No empty directories remain after workflow completion

**Complexity**: 5/10
**Dependencies**: Phase 2

---

## Success Criteria

- [ ] `create_topic_structure()` creates only topic root
- [ ] `/supervise` Phase 0 creates only topic root
- [ ] Subdirectories created on-demand when files written
- [ ] No empty directories after workflow completion
- [ ] All workflow types functional (research-only, research-and-plan, full-implementation, debug-only)
- [ ] Backward compatibility maintained

## Risk Assessment

**Risk 1: Missing Directory Creation**
Agents fail to write files if parent directories not created.

**Mitigation**: Phase 3 adds `mkdir -p` before all Write tool invocations; comprehensive testing across all workflow types.

**Risk 2: Verification Checkpoint Failures**
Phase 0 verification may fail if expecting all 6 subdirectories.

**Mitigation**: Phase 2 updates all verification checkpoints to only check topic root existence.

---

## Revision History

### 2025-10-24 - Revision 1
**Changes**: Reduced from 4 phases to 3 phases; removed bloat from task descriptions; simplified testing sections; streamlined risk assessment; eliminated Phase 4 (documentation/testing) as unnecessary overhead.

**Rationale**: Original plan contained excessive detail (repeated line numbers), redundant testing sections per phase, and verbose risk assessments. Phase 4 (documentation and tests) was overly prescriptive for a small refactor. Lean implementation focuses on core changes with verification criteria built into each phase.

**Standards Compliance**:
- Removed temporal language (no "currently", "previously", "updated")
- Eliminated redundant detail that added no value
- Focused on "what to do" not "how it evolved"
- Reduced complexity score from 5/10 to 4/10 to reflect actual implementation effort
- Reduced time estimate from 3-4 hours to 2-3 hours (more realistic for 3 focused phases)
