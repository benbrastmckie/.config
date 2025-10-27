# Agents Directory Cleanup and Consolidation Implementation Plan

## Metadata
- **Date**: 2025-10-26
- **Feature**: .claude/agents/ Directory Cleanup and Consolidation
- **Scope**: Consolidate 3-4 overlapping agents, archive 2-3 orphaned agents, update registry for 6 missing agents, refactor 1 agent to utility library
- **Estimated Phases**: 8
- **Estimated Hours**: 20-24 hours
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Agent Directory Overview](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/OVERVIEW.md)
  - [Agent Command Reference Mapping](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/001_agent_command_reference_mapping.md)
  - [Agent Functional Overlap Analysis](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/002_agent_functional_overlap_analysis.md)
  - [Agent Consolidation Opportunities](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/003_agent_consolidation_opportunities.md)
  - [Deprecated Agent Identification](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/004_deprecated_agent_identification.md)

## Overview

This plan implements comprehensive cleanup and consolidation of the .claude/agents/ directory based on detailed research findings. The work addresses 77% active agent usage (17/22 agents), identifies consolidation opportunities saving 1,168+ lines of code, eliminates 3-4 agents (14-19% reduction), and resolves documentation gaps for 6 missing registry entries.

**Primary Objectives**:
1. Update agent registry for 6 missing agents (git-commit-helper, implementation-executor, implementer-coordinator, research-synthesizer, doc-converter-usage.md, +1 unidentified)
2. Investigate and archive 5 orphaned agents (collapse-specialist, git-commit-helper, doc-converter-usage.md, metrics-specialist, debug-specialist)
3. Consolidate expansion-specialist + collapse-specialist → plan-structure-manager (95% overlap, 506 lines saved)
4. Eliminate plan-expander wrapper agent (562 lines saved)
5. Refactor git-commit-helper to utility library (100 lines saved, zero agent invocation overhead)

**Key Research Findings**:
- 95% code overlap between expansion-specialist and collapse-specialist (consolidation opportunity)
- plan-expander is pure coordination wrapper with no expansion logic (elimination candidate)
- git-commit-helper has no behavioral logic, purely deterministic (refactor to library)
- 5 orphaned agents requiring investigation (23% of agent ecosystem)
- 6 agents missing from registry (documentation gap)

## Research Summary

The comprehensive research identified:

1. **Usage Analysis** (Report 001): 77% active usage (17/22 agents), 5 orphaned agents, 80+ command invocations across 15 command files
2. **Overlap Analysis** (Report 002): 95% overlap expansion/collapse, 80% overlap debug agents, intentional hierarchical patterns preserved
3. **Consolidation Opportunities** (Report 003): 3 high-priority consolidations (1,168 lines saved), timeline 1-2 weeks, complexity 8/10
4. **Deprecation Status** (Report 004): 1 confirmed deprecated (location-specialist archived 2025-10-26), 3 at risk, 6 missing from registry

**Recommended Approach**: Phased implementation starting with registry updates and investigation (low risk), followed by high-impact consolidations (expansion/collapse, plan-expander elimination, git-commit-helper refactoring), then comprehensive testing and documentation updates.

## Success Criteria

- [ ] Agent registry updated with all 6 missing agents
- [ ] All 5 orphaned agents investigated with clear disposition (archive or document usage)
- [ ] expansion-specialist + collapse-specialist consolidated into plan-structure-manager
- [ ] plan-expander wrapper eliminated, commands updated to invoke plan-structure-manager directly
- [ ] git-commit-helper refactored to .claude/lib/git-commit-utils.sh
- [ ] All affected commands updated and tested with new agent structure
- [ ] All tests passing (.claude/tests/test_*.sh)
- [ ] Documentation updated (README.md, agent-registry.json, CHANGELOG.md)
- [ ] Agent count reduced from 21 to 18 active agents (14% reduction)
- [ ] Codebase reduced by 1,168+ lines across consolidated agents

## Technical Design

### Architecture Overview

The cleanup follows a **phased consolidation pattern** with three strategic approaches:

1. **Similar Operations Consolidation**: Merge agents with 90%+ structural similarity (expansion/collapse → plan-structure-manager)
2. **Wrapper Elimination**: Remove pure coordination wrappers with no behavioral logic (plan-expander)
3. **Agent-to-Library Refactoring**: Convert deterministic agents to utility libraries (git-commit-helper → git-commit-utils.sh)

### Component Interactions

**Before Consolidation**:
```
/expand command → plan-expander → expansion-specialist → file operations
/collapse command → (inline logic?) → collapse-specialist → file operations
implementation-executor → git-commit-helper → commit message
```

**After Consolidation**:
```
/expand command → plan-structure-manager(operation=expand) → file operations
/collapse command → plan-structure-manager(operation=collapse) → file operations
implementation-executor → lib/git-commit-utils.sh::generate_commit_message() → commit message
```

### Consolidation Strategy: plan-structure-manager

**Unified Workflow Pattern**:
- **STEP 1**: Validate operation request (expand/collapse)
- **STEP 2**: Extract/merge content based on operation
- **STEP 3**: Update parent plan metadata
- **STEP 4**: Create/delete files as needed
- **STEP 5**: Save operation artifact

**Operation Parameter**:
```yaml
operation: "expand" | "collapse"
target_type: "phase" | "stage"
target_number: N
plan_path: /absolute/path/to/plan.md
```

**Behavioral Logic Merge**:
- Expansion logic from expansion-specialist (lines 1-300)
- Collapse logic from collapse-specialist (lines 1-300)
- Shared validation utilities (95% overlap extracted to common section)
- Operation dispatch based on operation parameter

### Refactoring Strategy: git-commit-utils.sh

**Function Signature**:
```bash
generate_commit_message() {
  local topic_number="$1"
  local completion_type="$2"  # phase|stage|plan
  local phase_number="$3"     # optional
  local stage_number="$4"     # optional
  local name="$5"
  local feature_name="$6"     # optional for plan completion

  # Returns: feat(NNN): complete Phase N - Name
}
```

**Integration Pattern**:
```bash
# In implementation-executor.md or commands
source "$(dirname "$0")/../lib/git-commit-utils.sh"
COMMIT_MSG=$(generate_commit_message "027" "phase" 2 "" "Backend Implementation")
git commit -m "$COMMIT_MSG"
```

### Registry Update Strategy

**Auto-Detection Approach**:
```bash
# Use existing .claude/lib/register-all-agents.sh
cd /home/benjamin/.config/.claude/agents/
for agent in *.md; do
  if ! grep -q "\"$agent\"" agent-registry.json; then
    echo "Missing: $agent"
  fi
done
```

**Manual Registration** (if auto-detection insufficient):
- Extract frontmatter from each missing agent
- Add entry to agent-registry.json with proper metadata
- Verify tools, category, description match agent behavioral file

## Implementation Phases

### Phase 1: Registry Update and Verification [COMPLETED]
dependencies: []

**Objective**: Update agent registry to include all 6 missing agents and verify registry accuracy

**Complexity**: Low

**Tasks**:
- [x] Run agent registry auto-detection: `.claude/lib/register-all-agents.sh` (if exists) - Script not found, used manual process
- [x] Manually identify 6 missing agents by comparing directory listing to registry - Found 5 missing (doc-converter-usage, git-commit-helper, implementation-executor, implementer-coordinator, research-synthesizer)
- [x] Extract frontmatter metadata from each missing agent (tools, description, category)
- [x] Add registry entries for: git-commit-helper, implementation-executor, implementer-coordinator, research-synthesizer, doc-converter-usage.md
- [x] Verify registry count matches actual agent files (should be 22 entries) - Verified: 22 files, 22 registry entries ✓
- [x] Update .claude/agents/README.md agent count (updated to 22 specialized agents + 1 documentation file)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify registry completeness
cd /home/benjamin/.config/.claude/agents/
AGENT_COUNT=$(ls -1 *.md | wc -l)
REGISTRY_COUNT=$(jq '.agents | length' agent-registry.json)
echo "Agent files: $AGENT_COUNT, Registry entries: $REGISTRY_COUNT"
[ "$AGENT_COUNT" -eq "$REGISTRY_COUNT" ] && echo "✓ Registry complete" || echo "✗ Registry incomplete"

# Verify no duplicate entries
jq '.agents | keys' agent-registry.json | sort | uniq -d
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 1 - Registry Update and Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Orphaned Agents Investigation [COMPLETED]
dependencies: [1]

**Objective**: Investigate 5 orphaned agents to determine if they should be archived, documented, or retained

**Complexity**: Medium

**Tasks**:
- [x] Search codebase for collapse-specialist references: `grep -r "collapse-specialist" .claude/commands/` - Found 4 references in /collapse command
- [x] Verify /collapse command implementation (inline logic vs agent invocation) - Uses Task tool to invoke collapse-specialist agent
- [x] Search codebase for metrics-specialist references: `grep -r "metrics-specialist" .claude/commands/` - Found 0 references
- [x] Verify /analyze command integration with metrics-specialist - No integration, /analyze uses inline logic
- [x] Search codebase for debug-specialist references: `grep -r "debug-specialist" .claude/commands/` - Found 23 references (heavily used)
- [x] Compare debug-specialist vs debug-analyst usage patterns (line-by-line if needed) - debug-specialist actively used in /debug, /orchestrate, /implement
- [x] Verify doc-converter-usage.md is documentation (not executable agent) - Confirmed: documentation file
- [x] Move doc-converter-usage.md to .claude/docs/ if confirmed documentation - Moved successfully ✓
- [x] Document investigation findings in specs/480_*/investigation_findings.md - Created comprehensive findings document
- [x] Create disposition list: [archive | retain | document-usage] for each orphaned agent - See investigation_findings.md

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify doc-converter-usage.md moved to docs/
test -f /home/benjamin/.config/.claude/docs/doc-converter-usage.md && echo "✓ File moved" || echo "✗ File not moved"

# Verify investigation findings document created
test -f /home/benjamin/.config/.claude/specs/480_*/investigation_findings.md && echo "✓ Findings documented" || echo "✗ Findings missing"

# Check grep results for each orphaned agent
for agent in collapse-specialist metrics-specialist debug-specialist; do
  echo "Checking $agent..."
  grep -r "$agent" /home/benjamin/.config/.claude/commands/ | wc -l
done
```

**Expected Duration**: 4-6 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 2 - Orphaned Agents Investigation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Create plan-structure-manager Agent
dependencies: [2]

**Objective**: Consolidate expansion-specialist and collapse-specialist into unified plan-structure-manager agent

**Complexity**: High

**Tasks**:
- [x] Read expansion-specialist.md full content (file: /home/benjamin/.config/.claude/agents/expansion-specialist.md)
- [x] Read collapse-specialist.md full content (file: /home/benjamin/.config/.claude/agents/collapse-specialist.md)
- [x] Identify common sections (95% overlap): STEP 1-5 workflow, validation, metadata updates, artifact creation
- [x] Create .claude/agents/plan-structure-manager.md with unified frontmatter (tools: Read, Write, Edit, Bash, Task)
- [x] Add operation parameter to behavioral guidelines: `operation: "expand" | "collapse"`
- [x] Merge STEP 1 (validation) with conditional logic for expand vs collapse
- [x] Merge STEP 2 (extract/merge) with operation dispatch
- [x] Merge STEP 3 (parent plan update) preserving both expand and collapse patterns
- [x] Merge STEP 4 (file operations) with conditional create/delete logic
- [x] Merge STEP 5 (artifact creation) with unified artifact format
- [x] Add operation examples for both expand and collapse in agent documentation
- [x] Verify total agent file size reduced by 21% (9,996 bytes saved - actual reduction vs 36% estimate)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify new agent file created
test -f /home/benjamin/.config/.claude/agents/plan-structure-manager.md && echo "✓ Agent created" || echo "✗ Agent missing"

# Verify file size reduction
OLD_SIZE=$(($(wc -c < /home/benjamin/.config/.claude/agents/expansion-specialist.md) + $(wc -c < /home/benjamin/.config/.claude/agents/collapse-specialist.md)))
NEW_SIZE=$(wc -c < /home/benjamin/.config/.claude/agents/plan-structure-manager.md)
REDUCTION=$(echo "scale=2; (($OLD_SIZE - $NEW_SIZE) / $OLD_SIZE) * 100" | bc)
echo "Size reduction: $REDUCTION% (target: 36%)"

# Verify operation parameter exists
grep -q "operation.*expand.*collapse" /home/benjamin/.config/.claude/agents/plan-structure-manager.md && echo "✓ Operation parameter present" || echo "✗ Operation parameter missing"
```

**Expected Duration**: 8-10 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 3 - Create plan-structure-manager Agent`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Update Commands for plan-structure-manager
dependencies: [3]

**Objective**: Update /expand and /collapse commands to invoke plan-structure-manager instead of old agents

**Complexity**: Medium

**Tasks**:
- [x] Read /expand command: .claude/commands/expand.md
- [x] Update /expand to invoke plan-structure-manager with operation=expand
- [x] Remove plan-expander invocation from /expand (if present) - Updated integration section to reference plan-structure-manager
- [x] Update Task invocation to use .claude/agents/plan-structure-manager.md
- [x] Add operation parameter to invocation: `operation: expand`
- [x] Read /collapse command: .claude/commands/collapse.md
- [x] Update /collapse to invoke plan-structure-manager with operation=collapse
- [x] Remove collapse-specialist invocation from /collapse (if present) - No removal needed, updated references
- [x] Update Task invocation to use .claude/agents/plan-structure-manager.md
- [x] Add operation parameter to invocation: `operation: collapse`
- [x] Update /orchestrate command if it invokes plan-expander (file: .claude/commands/orchestrate.md) - No updates needed, no references found
- [x] Replace plan-expander with direct plan-structure-manager invocation - N/A, /orchestrate has no plan-expander references

**Testing**:
```bash
# Test /expand command with plan-structure-manager
# Note: This requires a test plan with unexpanded phases
cd /home/benjamin/.config
# Create test plan if needed, then run:
# /expand phase test_plan.md 1

# Test /collapse command with plan-structure-manager
# Note: This requires a test plan with expanded phases
# /collapse phase test_plan.md 1

# Verify commands reference new agent
grep -q "plan-structure-manager" .claude/commands/expand.md && echo "✓ /expand updated" || echo "✗ /expand not updated"
grep -q "plan-structure-manager" .claude/commands/collapse.md && echo "✓ /collapse updated" || echo "✗ /collapse not updated"
```

**Expected Duration**: 2-3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 4 - Update Commands for plan-structure-manager`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Refactor git-commit-helper to Utility Library
dependencies: [2]

**Objective**: Convert git-commit-helper agent to .claude/lib/git-commit-utils.sh utility library

**Complexity**: Low

**Tasks**:
- [ ] Read git-commit-helper.md behavioral logic (file: /home/benjamin/.config/.claude/agents/git-commit-helper.md)
- [ ] Create .claude/lib/git-commit-utils.sh with bash function structure
- [ ] Implement generate_commit_message() function with 6 parameters (topic_number, completion_type, phase_number, stage_number, name, feature_name)
- [ ] Add input validation: topic_number 3-digit format (001-999)
- [ ] Add input validation: completion_type must be phase|stage|plan
- [ ] Implement stage completion format: `feat(NNN): complete Phase N Stage M - [Name]`
- [ ] Implement phase completion format: `feat(NNN): complete Phase N - [Name]`
- [ ] Implement plan completion format: `feat(NNN): complete [feature name]`
- [ ] Add error handling for missing required inputs
- [ ] Add unit tests in .claude/tests/test_git_commit_utils.sh
- [ ] Test all three completion types (stage, phase, plan)

**Testing**:
```bash
# Source the library
source /home/benjamin/.config/.claude/lib/git-commit-utils.sh

# Test stage completion
MSG=$(generate_commit_message "027" "stage" 2 1 "Database Schema" "")
echo "Stage: $MSG"
[[ "$MSG" == "feat(027): complete Phase 2 Stage 1 - Database Schema" ]] && echo "✓ Stage format correct" || echo "✗ Stage format incorrect"

# Test phase completion
MSG=$(generate_commit_message "042" "phase" 3 "" "Backend Implementation" "")
echo "Phase: $MSG"
[[ "$MSG" == "feat(042): complete Phase 3 - Backend Implementation" ]] && echo "✓ Phase format correct" || echo "✗ Phase format incorrect"

# Test plan completion
MSG=$(generate_commit_message "080" "plan" "" "" "" "authentication system")
echo "Plan: $MSG"
[[ "$MSG" == "feat(080): complete authentication system" ]] && echo "✓ Plan format correct" || echo "✗ Plan format incorrect"

# Run unit tests
bash /home/benjamin/.config/.claude/tests/test_git_commit_utils.sh
```

**Expected Duration**: 2-3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 5 - Refactor git-commit-helper to Utility Library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Update Commands to Use git-commit-utils Library
dependencies: [5]

**Objective**: Update all commands that previously invoked git-commit-helper to source git-commit-utils.sh library

**Complexity**: Medium

**Tasks**:
- [ ] Search for git-commit-helper invocations: `grep -r "git-commit-helper" .claude/commands/`
- [ ] Read implementation-executor.md (if it invokes git-commit-helper)
- [ ] Update implementation-executor to source git-commit-utils.sh
- [ ] Replace agent invocation with direct function call: `generate_commit_message()`
- [ ] Update /implement command if it invokes git-commit-helper directly (file: .claude/commands/implement.md)
- [ ] Update /orchestrate command if it invokes git-commit-helper directly (file: .claude/commands/orchestrate.md)
- [ ] Update /commit-phase command if it invokes git-commit-helper directly (file: .claude/commands/commit-phase.md)
- [ ] Verify all git commit operations now use library function
- [ ] Remove any remaining git-commit-helper Task invocations

**Testing**:
```bash
# Verify no remaining git-commit-helper references in commands
grep -r "git-commit-helper" /home/benjamin/.config/.claude/commands/ && echo "✗ References still exist" || echo "✓ All references removed"

# Verify git-commit-utils.sh is sourced in updated files
grep -r "source.*git-commit-utils.sh" /home/benjamin/.config/.claude/commands/ || \
grep -r "source.*git-commit-utils.sh" /home/benjamin/.config/.claude/agents/

# Test implementation-executor with library (if accessible)
# This requires running a phase completion workflow
```

**Expected Duration**: 2-3 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 6 - Update Commands to Use git-commit-utils Library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 7: Archive Deprecated Agents
dependencies: [4, 6]

**Objective**: Archive expansion-specialist, collapse-specialist, plan-expander, and git-commit-helper agents

**Complexity**: Low

**Tasks**:
- [ ] Create .claude/archive/agents/ directory if not exists
- [ ] Move expansion-specialist.md to .claude/archive/agents/expansion-specialist.md
- [ ] Move collapse-specialist.md to .claude/archive/agents/collapse-specialist.md
- [ ] Move plan-expander.md to .claude/archive/agents/plan-expander.md
- [ ] Move git-commit-helper.md to .claude/archive/agents/git-commit-helper.md
- [ ] Remove archived agents from agent-registry.json (4 entries)
- [ ] Add plan-structure-manager to agent-registry.json (1 new entry)
- [ ] Update .claude/agents/README.md with new agent count (19 active agents: 21 - 4 archived + 1 new)
- [ ] Update .claude/CHANGELOG.md with deprecation entries (date: 2025-10-26)
- [ ] Add archive reason: "Consolidated into plan-structure-manager" for expansion/collapse specialists
- [ ] Add archive reason: "Eliminated wrapper, functionality in plan-structure-manager" for plan-expander
- [ ] Add archive reason: "Refactored to .claude/lib/git-commit-utils.sh utility library" for git-commit-helper

**Testing**:
```bash
# Verify agents archived
for agent in expansion-specialist collapse-specialist plan-expander git-commit-helper; do
  test -f /home/benjamin/.config/.claude/archive/agents/${agent}.md && echo "✓ $agent archived" || echo "✗ $agent not archived"
done

# Verify agents removed from active directory
for agent in expansion-specialist collapse-specialist plan-expander git-commit-helper; do
  test ! -f /home/benjamin/.config/.claude/agents/${agent}.md && echo "✓ $agent removed" || echo "✗ $agent still present"
done

# Verify registry updated
ACTIVE_COUNT=$(jq '.agents | length' /home/benjamin/.config/.claude/agents/agent-registry.json)
echo "Active agents: $ACTIVE_COUNT (expected: 19)"
jq '.agents | has("plan-structure-manager")' /home/benjamin/.config/.claude/agents/agent-registry.json | grep -q true && echo "✓ plan-structure-manager registered" || echo "✗ plan-structure-manager not registered"
```

**Expected Duration**: 1-2 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 7 - Archive Deprecated Agents`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 8: Integration Testing and Documentation Updates
dependencies: [7]

**Objective**: Comprehensive integration testing and final documentation updates

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite: `cd .claude/tests && ./run_all_tests.sh`
- [ ] Test /expand command with real plan: Create test plan, expand phase, verify plan-structure-manager invoked
- [ ] Test /collapse command with real plan: Use expanded plan from previous test, collapse phase, verify success
- [ ] Test git commit message generation: Run phase completion workflow, verify commit format
- [ ] Verify no broken agent references in commands: `grep -r "expansion-specialist\|collapse-specialist\|plan-expander\|git-commit-helper" .claude/commands/`
- [ ] Update .claude/docs/guides/agent-development-guide.md with consolidation patterns
- [ ] Document plan-structure-manager operation parameter pattern
- [ ] Document agent-to-library refactoring pattern (git-commit-helper example)
- [ ] Update .claude/agents/README.md with hierarchical delegation documentation
- [ ] Add section explaining intentional coordinator/worker patterns (implementation-executor/implementer-coordinator)
- [ ] Create .claude/docs/concepts/patterns/agent-consolidation-patterns.md (optional)
- [ ] Update this implementation plan with completion summary

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Full test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Verify test coverage
TOTAL_TESTS=$(grep -r "test_" . | wc -l)
PASSED_TESTS=$(./run_all_tests.sh 2>&1 | grep -c "✓")
echo "Test coverage: $PASSED_TESTS / $TOTAL_TESTS tests passed"

# Integration smoke tests
# Test 1: /expand command
# Test 2: /collapse command
# Test 3: git commit message generation

# Verify no broken references
BROKEN_REFS=$(grep -r "expansion-specialist\|collapse-specialist\|plan-expander\|git-commit-helper" /home/benjamin/.config/.claude/commands/ | wc -l)
[ "$BROKEN_REFS" -eq 0 ] && echo "✓ No broken references" || echo "✗ $BROKEN_REFS broken references found"

# Verify documentation updates
test -f /home/benjamin/.config/.claude/docs/concepts/patterns/agent-consolidation-patterns.md && echo "✓ Consolidation patterns documented" || echo "✗ Documentation missing"
```

**Expected Duration**: 4-5 hours

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(480): complete Phase 8 - Integration Testing and Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Test Levels

**Unit Testing**:
- git-commit-utils.sh function tests (all 3 completion types)
- plan-structure-manager validation logic tests
- Registry update verification tests

**Integration Testing**:
- /expand command with plan-structure-manager
- /collapse command with plan-structure-manager
- git commit generation in phase completion workflow
- agent registry auto-detection

**Regression Testing**:
- Existing .claude/tests/test_*.sh must pass
- No broken agent references in commands
- Commands that previously worked still function correctly

### Test Commands

```bash
# Run full test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Test specific components
bash test_git_commit_utils.sh           # Phase 5
bash test_expansion_collapse.sh         # Phase 3-4 (if exists)
bash test_agent_registry.sh             # Phase 1 (if exists)

# Manual integration tests
# /expand phase [plan-file] 1
# /collapse phase [plan-file] 1
# [run phase completion workflow to test commit generation]
```

### Coverage Requirements

- Unit test coverage: ≥80% for git-commit-utils.sh
- Integration test coverage: All 3 consolidated agents tested
- Regression test coverage: All existing tests must pass
- No broken agent references after consolidation

## Documentation Requirements

### Files to Update

1. **.claude/agents/README.md**:
   - Update agent count (21 → 18 active agents)
   - Add plan-structure-manager entry
   - Remove archived agent entries
   - Add section on hierarchical delegation patterns

2. **.claude/agents/agent-registry.json**:
   - Remove 4 archived agents
   - Add plan-structure-manager entry
   - Verify 6 missing agents added (Phase 1)

3. **.claude/CHANGELOG.md**:
   - Add deprecation entries for 4 archived agents
   - Note consolidation rationale
   - Reference this implementation plan (480/plans/001)

4. **.claude/docs/guides/agent-development-guide.md**:
   - Document operation parameter pattern
   - Document agent-to-library refactoring pattern
   - Add consolidation decision criteria

5. **.claude/commands/expand.md**:
   - Update to invoke plan-structure-manager
   - Remove plan-expander references

6. **.claude/commands/collapse.md**:
   - Update to invoke plan-structure-manager

7. **.claude/docs/concepts/patterns/agent-consolidation-patterns.md** (optional):
   - Document three consolidation strategies
   - Provide examples from this implementation
   - Reference research reports

### Documentation Standards

- Follow CLAUDE.md documentation policy (no emojis, UTF-8 encoding, clear language)
- Use imperative language for agent instructions (MUST/WILL/SHALL per Imperative Language Guide)
- Include code examples with syntax highlighting
- Add cross-references between related documents
- Update modification dates in frontmatter

## Dependencies

### External Dependencies

- Existing .claude/lib/ utility libraries
- .claude/tests/ test framework
- agent-registry.json schema
- Git for commits and archiving

### Prerequisites

- All commands using expansion-specialist, collapse-specialist, plan-expander, git-commit-helper must be identified
- Research reports fully analyzed
- Backup of agents directory before archiving (optional but recommended)

### Integration Points

- /expand command
- /collapse command
- /implement command (uses git-commit-helper via implementation-executor)
- /orchestrate command (may use plan-expander)
- /commit-phase command (may use git-commit-helper)
- implementation-executor agent (uses git-commit-helper)

## Risk Mitigation

### High-Risk Areas

1. **Breaking Command Workflows**: Commands that invoke archived agents will fail
   - **Mitigation**: Comprehensive grep search for all references, update before archiving
   - **Validation**: Integration testing in Phase 8

2. **plan-structure-manager Operation Parameter**: New parameter must be properly dispatched
   - **Mitigation**: Thorough testing of both expand and collapse operations
   - **Validation**: Manual testing with real plans in Phase 4

3. **git-commit-utils.sh Integration**: Library sourcing may fail if path incorrect
   - **Mitigation**: Use absolute paths or `$(dirname "$0")/../lib/` pattern
   - **Validation**: Unit tests in Phase 5, integration tests in Phase 6

### Rollback Strategy

If consolidation causes critical failures:
1. Restore archived agents from .claude/archive/agents/
2. Revert command file changes from git history
3. Remove plan-structure-manager and git-commit-utils.sh
4. Restore agent-registry.json from git history

### Validation Checkpoints

- Phase 1: Registry completeness verified
- Phase 2: Orphaned agents disposition documented
- Phase 3: plan-structure-manager file size reduction achieved
- Phase 4: Commands successfully invoke plan-structure-manager
- Phase 5: git-commit-utils.sh unit tests pass
- Phase 6: No broken git-commit-helper references
- Phase 7: All 4 agents archived, registry updated
- Phase 8: Full test suite passes, no regressions

## Timeline Estimates

**Optimistic (Experienced Developer)**: 16-18 hours
- Phase 1: 1.5 hours
- Phase 2: 3 hours
- Phase 3: 6 hours
- Phase 4: 2 hours
- Phase 5: 1.5 hours
- Phase 6: 1.5 hours
- Phase 7: 1 hour
- Phase 8: 3 hours

**Realistic (Average Developer)**: 20-24 hours
- Phase 1: 2 hours
- Phase 2: 5 hours
- Phase 3: 9 hours
- Phase 4: 2.5 hours
- Phase 5: 2.5 hours
- Phase 6: 2.5 hours
- Phase 7: 1.5 hours
- Phase 8: 4.5 hours

**Pessimistic (Learning on the Job)**: 28-32 hours
- Phase 1: 3 hours
- Phase 2: 7 hours
- Phase 3: 12 hours
- Phase 4: 4 hours
- Phase 5: 3 hours
- Phase 6: 3 hours
- Phase 7: 2 hours
- Phase 8: 6 hours

## Notes

### Complexity Score Calculation

```
Score = Base(feature type) + Tasks/2 + Files*3 + Integrations*5

Where:
- Base: refactor=5
- Tasks: 75 tasks (estimated from all phases)
- Files: 23 files to modify/create (agents, commands, docs, tests, lib)
- Integrations: 8 integration points (expand, collapse, implement, orchestrate, commit-phase, implementation-executor, etc.)

Score = 5 + (75/2) + (23*3) + (8*5) = 5 + 37.5 + 69 + 40 = 151.5

Adjusted for high-value consolidation: 142.0 (complexity reduced by proven patterns)
```

### Research Report References

This plan is directly informed by:
1. **Overview Report**: 77% agent usage, 5 orphaned, 3 high-priority consolidations
2. **Command Reference Mapping**: 80+ agent invocations across 15 commands
3. **Overlap Analysis**: 95% overlap expansion/collapse, 80% overlap debug agents
4. **Consolidation Opportunities**: 1,168 lines saved, 3 agents eliminated, 1-2 weeks timeline
5. **Deprecation Status**: 1 agent archived (location-specialist), 6 missing from registry

### Post-Implementation Benefits

**Quantitative**:
- Agent count: 21 → 18 (14% reduction)
- Code reduction: 1,168 lines saved
- Agent invocation overhead: Zero for git-commit-helper (now library function)
- Maintenance burden: 3 fewer agents to maintain

**Qualitative**:
- Clearer architectural patterns (operation parameter for similar operations)
- Reduced code duplication (95% overlap eliminated)
- Better discoverability (6 agents added to registry)
- Improved performance (library function vs agent invocation for deterministic logic)

### Future Consolidation Opportunities

**Medium-Term** (1-2 months):
- Debug-specialist + debug-analyst consolidation (pending line-by-line analysis)
- Implementer-coordinator + implementation-executor (pending production telemetry)

**Long-Term** (ongoing):
- Agent role taxonomy (Coordinators, Workers, Standalone, Dual-Mode)
- Deprecation criteria establishment (library supersession, pattern violations, usage metrics)
- Hierarchical delegation pattern documentation
