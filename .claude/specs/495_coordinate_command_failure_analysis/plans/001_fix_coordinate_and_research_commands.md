# Implementation Plan: Fix /coordinate and /research Command Agent Delegation

## Plan Metadata

- **Plan ID**: 001
- **Topic**: 495_coordinate_command_failure_analysis
- **Type**: Bug Fix
- **Complexity**: 7/10
- **Estimated Total Time**: 4-6 hours
- **Dependencies**: None (spec 438 resolution pattern already proven)
- **Related Reports**:
  - `001_coordinate_failure_diagnostic.md` - /coordinate failure analysis
  - `002_research_command_failure.md` - /research failure analysis
- **Related Specs**:
  - Spec 438 - /supervise command agent delegation fix (proven pattern)

## Problem Statement

Both `/coordinate` and `/research` commands have **0% agent delegation rate** due to YAML-style Task invocations wrapped in markdown code fences, causing Claude to interpret them as documentation rather than executable instructions. This is the exact anti-pattern identified and fixed in spec 438 for the `/supervise` command, but the fix was never propagated to these commands.

**Impact**: Complete failure of multi-agent orchestration and research workflows.

**Evidence**:
- `/coordinate` writes output to `TODO1.md` instead of invoking agents
- `/research` displays entire command prompt instead of executing workflow
- Both confirmed with 0% agent delegation rate

## Success Criteria

1. **Agent Delegation Rate**: >90% for both commands (verified via `/analyze agents`)
2. **File Creation**: Reports/artifacts created in correct locations (`.claude/specs/NNN_topic/`)
3. **No TODO Output**: No output written to `.claude/TODO*.md` files
4. **Progress Markers**: `PROGRESS:` markers emitted during execution
5. **Working Workflows**: Complete end-to-end test of research and orchestration workflows
6. **Pattern Consistency**: Both commands use identical imperative bullet-point pattern as `/supervise`

## Implementation Strategy

**Approach**: Apply proven spec 438 resolution pattern to both commands systematically.

**Key Changes**:
1. Replace all YAML-style Task blocks with imperative bullet-point invocations
2. Remove all markdown code fences (` ```yaml `, ` ```bash `) around Task invocations
3. Convert template variables to actual value injection instructions
4. Add explicit imperative phrasing: "USE the Task tool NOW with these parameters"
5. Ensure all agent prompts contain pre-calculated absolute paths (no placeholders)

**Risk Mitigation**:
- Create backups before editing (`.backup-YYYYMMDD-HHMMSS` suffix)
- Fix `/coordinate` first (more critical), then `/research`
- Test each command individually after fixes
- Keep `/supervise` as working reference throughout

---

## Phase 1: Preparation and Backup

**Objective**: Create backups and validate current state before modifications.

**Tasks**:
1. Create timestamped backups of both command files
2. Verify `/supervise` command working state (reference pattern)
3. Document current failure modes with test invocations
4. Verify test environment ready (`.claude/specs/` directory accessible)

**Acceptance Criteria**:
- [ ] Backup files created with timestamp suffix
- [ ] `/supervise` verified working (delegation rate >90%)
- [ ] Test invocations documented showing current failures
- [ ] Git status clean or changes committed before starting

**Estimated Time**: 30 minutes

**Commands**:
```bash
# Create backups
cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)
cp .claude/commands/research.md .claude/commands/research.md.backup-$(date +%Y%m%d-%H%M%S)

# Verify supervise working
/supervise "research test topic" --dry-run

# Document current failures
/coordinate "test coordinate" 2>&1 | head -50 > /tmp/coordinate_before.log
/research "test research" 2>&1 | head -50 > /tmp/research_before.log
```

---

## Phase 2: Fix /coordinate Command (Critical Priority)

**Objective**: Apply spec 438 resolution pattern to all agent invocations in coordinate.md.

**Failure Points to Fix**: 9 agent invocations across 6 phases

### Task 2.1: Fix Research Phase Agent Invocation (Lines 1042-1082)

**Current Pattern** (BROKEN):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]}
    ...
  "
}
```

**New Pattern** (FIXED):
```markdown
**STEP 2: Invoke Research Agents in Parallel**

For each research complexity level (1-4 topics), YOU MUST invoke research-specialist agents.

**CRITICAL**: Calculate report paths BEFORE agent invocation:

USE the Bash tool to calculate report paths:
```bash
# Calculate absolute paths for all research reports
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${TOPIC_PATH}/reports/$(printf '%03d' $i)_research_topic_${i}.md"
  echo "REPORT_PATH_${i}=${REPORT_PATH}"
done
```

**AGENT INVOCATION - Research Topic 1**

USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research primary topic with mandatory file creation"
- prompt: "Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Research Topic: [INSERT ACTUAL TOPIC FROM WORKFLOW DESCRIPTION]
- Report Path: [INSERT ABSOLUTE PATH FROM CALCULATION ABOVE]
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Complexity Level: [INSERT RESEARCH_COMPLEXITY VALUE]

**YOUR ROLE**: You are a SUBAGENT executing research for ONE topic.
- The ORCHESTRATOR calculated your report path (injected above)
- DO NOT use Task tool to orchestrate other agents
- STAY IN YOUR LANE: Research YOUR topic only

**CRITICAL**: Before writing report, ensure parent directory exists:
Use Bash tool: mkdir -p \"$(dirname \"[REPORT_PATH]\")\"

Execute research following all guidelines in behavioral file.
Return: REPORT_CREATED: [ABSOLUTE_PATH]"

**Repeat for each research topic (1-4 invocations based on complexity)**
```

**Changes Made**:
1. Removed YAML-style `Task { }` block
2. Changed to imperative bullet-point pattern with "USE the Task tool NOW"
3. Added explicit path calculation using Bash tool BEFORE agent invocation
4. Replaced template variables (`${VAR}`) with instructions to insert actual values
5. Added clarity on orchestrator vs subagent roles
6. Removed code fence around Task invocation

**Acceptance Criteria**:
- [ ] YAML-style Task block removed
- [ ] Imperative bullet-point pattern implemented
- [ ] Path calculation uses explicit Bash tool invocation
- [ ] No template variables in final agent prompt
- [ ] Pattern matches `/supervise` reference implementation

### Task 2.2: Fix Planning Phase Agent Invocation (Lines 1323-1346)

**Apply same pattern transformation**:
- Remove YAML-style `Task { }` block
- Use imperative bullet-point pattern
- Add explicit plan path calculation
- Ensure no template variables in agent prompt

**New Pattern**:
```markdown
**STEP 2: Invoke Plan-Architect Agent**

USE the Bash tool to calculate plan path:
```bash
PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"
echo "PLAN_PATH=${PLAN_PATH}"
mkdir -p "$(dirname "$PLAN_PATH")"
```

**AGENT INVOCATION - Plan Creation**

USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Create implementation plan with mandatory file creation"
- prompt: "Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

**Workflow-Specific Context**:
- Workflow Description: [INSERT ACTUAL WORKFLOW DESCRIPTION]
- Plan File Path: [INSERT ABSOLUTE PATH FROM CALCULATION ABOVE]
- Project Standards: /home/benjamin/.config/CLAUDE.md
- Research Reports: [LIST VERIFIED REPORT PATHS FROM PHASE 1]
- Research Report Count: [INSERT SUCCESSFUL_REPORT_COUNT]

**CRITICAL**: Before writing plan file, ensure parent directory exists (already created above).

Execute planning following all guidelines in behavioral file.
Return: PLAN_CREATED: [ABSOLUTE_PATH]"
```

### Task 2.3: Fix Implementation Phase Agent Invocation (Lines 1579-1620)

**Apply same pattern transformation** for implementer-coordinator agent.

### Task 2.4: Fix Testing Phase Agent Invocation (Lines 1761-1800)

**Apply same pattern transformation** for test-specialist agent.

### Task 2.5: Fix Debug Phase Agent Invocations (Lines 1896-2066)

**Apply same pattern transformation** for:
- debug-analyst agent
- code-writer agent (fix application)
- test-specialist agent (re-run)

**Note**: Debug phase has **3 agent invocations in a loop**, all need fixing.

### Task 2.6: Fix Documentation Phase Agent Invocation (Lines 2101-2140)

**Apply same pattern transformation** for doc-writer agent.

**Acceptance Criteria for Phase 2**:
- [ ] All 9 agent invocations converted to imperative bullet-point pattern
- [ ] All YAML-style blocks removed
- [ ] All template variables replaced with value injection instructions
- [ ] All bash code blocks converted to explicit Bash tool invocations
- [ ] Pattern consistency verified against `/supervise` reference

**Estimated Time**: 2.5-3 hours

**Files Modified**:
- `.claude/commands/coordinate.md` (9 locations)

---

## Phase 3: Fix /research Command

**Objective**: Apply identical pattern to research.md agent invocations.

**Failure Points to Fix**: 3 agent invocations (research-specialist, research-synthesizer, spec-updater)

### Task 3.1: Fix Research-Specialist Invocation (STEP 3)

**Current Pattern** (BROKEN):
````markdown
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [SUBTOPIC_DISPLAY_NAME]
    - Report Path: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]
    ...
  "
}
```
````

**New Pattern** (FIXED):
```markdown
**STEP 3: Invoke Research-Specialist Agents in Parallel**

**CRITICAL**: All report paths MUST be calculated in STEP 2 before this step.

For EACH subtopic in SUBTOPICS array, YOU MUST invoke a research-specialist agent.

**Example for Subtopic 1**: "authentication_patterns"

USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research authentication_patterns with mandatory artifact creation"
- timeout: 300000
- prompt: "Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/research-specialist.md

**Workflow-Specific Context**:
- Research Topic: authentication_patterns
- Report Path: [INSERT ABSOLUTE PATH CALCULATED IN STEP 2]
- Project Standards: /home/benjamin/.config/CLAUDE.md

**YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
- The ORCHESTRATOR calculated your report path (injected above)
- DO NOT use Task tool to orchestrate other agents
- STAY IN YOUR LANE: Research YOUR subtopic only

**CRITICAL**: Create report file at EXACT path provided above.

Execute research following all guidelines in behavioral file.
Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]"

**Repeat this invocation for EACH subtopic** (2-4 times based on complexity).

**Monitor agent execution**:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths
```

**Changes Made**:
1. Removed markdown code fence (` ```yaml `)
2. Removed YAML-style `Task { }` block
3. Changed to imperative bullet-point pattern
4. Replaced placeholders `[SUBTOPIC]`, `[ABSOLUTE_PATH]` with instructions to insert actual values
5. Added concrete example showing how to invoke for one subtopic
6. Made orchestrator responsibilities explicit

### Task 3.2: Fix Research-Synthesizer Invocation (STEP 5)

**Apply same pattern transformation**:
- Remove code fence
- Remove YAML-style block
- Use imperative bullet-point pattern
- Replace template variables with actual value instructions

**New Pattern**:
```markdown
**STEP 5: Invoke Research-Synthesizer Agent**

USE the Bash tool to calculate overview path:
```bash
OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"
echo "OVERVIEW_PATH=${OVERVIEW_PATH}"
```

**AGENT INVOCATION - Synthesis**

USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Synthesize research findings into overview report"
- timeout: 180000
- prompt: "Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/research-synthesizer.md

**Workflow-Specific Context**:
- Overview Report Path: [INSERT ABSOLUTE PATH FROM CALCULATION ABOVE]
- Research Topic: [INSERT ACTUAL RESEARCH TOPIC]
- Subtopic Report Paths:
  [LIST ALL VERIFIED REPORT PATHS FROM STEP 4]

**YOUR ROLE**: You are a SUBAGENT synthesizing research findings.
- The ORCHESTRATOR created all subtopic reports (paths injected above)
- DO NOT use Task tool to orchestrate other agents
- STAY IN YOUR LANE: Synthesize findings only

**IMPORTANT**: Create overview file with filename OVERVIEW.md (ALL CAPS).

Execute synthesis following all guidelines in behavioral file.
Return: OVERVIEW_CREATED: [ABSOLUTE_PATH]
        OVERVIEW_SUMMARY: [100-word summary]
        METADATA: [structured metadata]"
```

### Task 3.3: Fix Spec-Updater Invocation (STEP 6)

**Apply same pattern transformation** for spec-updater agent.

### Task 3.4: Remove Bash Code Block Pseudo-Instructions

**Problem**: research.md has extensive bash code blocks in STEPs 1-2 that appear as documentation rather than executable instructions.

**Example** (STEP 2 - lines ~150-250):
````markdown
```bash
# Source unified location detection utilities
source .claude/lib/topic-utils.sh
source .claude/lib/detect-project-dir.sh

# Get project root (from environment or git)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
...
```
````

**Fix**: Convert to explicit Bash tool invocations:
```markdown
**STEP 2: Calculate Topic Directory and Report Paths**

**EXECUTE NOW**: USE the Bash tool to calculate topic directory:

Command:
```bash
# Source utilities and calculate paths
source .claude/lib/topic-utils.sh
source .claude/lib/detect-project-dir.sh

PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: CLAUDE_PROJECT_DIR not set"
  exit 1
fi

# Determine specs directory
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
else
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  mkdir -p "$SPECS_ROOT"
fi

# Calculate topic metadata
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$RESEARCH_TOPIC")
TOPIC_DIR="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

# Create topic root directory
mkdir -p "$TOPIC_DIR"

echo "TOPIC_DIR=${TOPIC_DIR}"
echo "TOPIC_NUM=${TOPIC_NUM}"
echo "TOPIC_NAME=${TOPIC_NAME}"
```

Description: Calculate topic directory path and create directory structure

**VERIFY**: Check that TOPIC_DIR was created successfully:
```bash
if [ ! -d "$TOPIC_DIR" ]; then
  echo "ERROR: Topic directory creation failed: $TOPIC_DIR"
  exit 1
fi
```
```

**Key Changes**:
1. Added "**EXECUTE NOW**: USE the Bash tool" prefix
2. Kept bash code block but made clear it should be executed, not just read
3. Added explicit description of what the command does
4. Added verification step after execution

**Acceptance Criteria for Phase 3**:
- [ ] All 3 agent invocations converted to imperative bullet-point pattern
- [ ] All markdown code fences removed from Task invocations
- [ ] All template placeholders replaced with value injection instructions
- [ ] All bash code blocks converted to explicit Bash tool invocations
- [ ] Pattern consistency verified against `/supervise` and fixed `/coordinate`

**Estimated Time**: 1.5-2 hours

**Files Modified**:
- `.claude/commands/research.md` (3 agent invocations + ~10 bash code blocks)

---

## Phase 4: Validation Testing

**Objective**: Verify both commands work correctly with >90% agent delegation rate.

### Task 4.1: Test /coordinate Command

**Test 1: Simple Research Workflow**
```bash
/coordinate "research authentication patterns for REST APIs"
```

**Expected Results**:
- [ ] 2-4 research-specialist agents invoked (check for PROGRESS: markers)
- [ ] Report files created in `.claude/specs/NNN_topic/reports/`
- [ ] No output in `.claude/TODO*.md` files
- [ ] Summary displayed with artifact paths
- [ ] Delegation rate >90% (verify with `/analyze agents`)

**Test 2: Research-and-Plan Workflow**
```bash
/coordinate "research authentication to create implementation plan"
```

**Expected Results**:
- [ ] Research phase completes successfully
- [ ] plan-architect agent invoked
- [ ] Plan file created in `.claude/specs/NNN_topic/plans/`
- [ ] No output in TODO files
- [ ] Delegation rate >90%

### Task 4.2: Test /research Command

**Test 1: Basic Research**
```bash
/research "API authentication patterns and best practices"
```

**Expected Results**:
- [ ] Topic decomposed into 2-4 subtopics
- [ ] Research-specialist agents invoked in parallel
- [ ] Subtopic reports created
- [ ] research-synthesizer agent invoked
- [ ] OVERVIEW.md created
- [ ] spec-updater agent invoked
- [ ] Cross-references updated
- [ ] Summary displayed to user
- [ ] No output in TODO files
- [ ] Delegation rate >90%

### Task 4.3: Delegation Rate Analysis

```bash
# Check agent delegation metrics
/analyze agents

# Expected output should show:
# - /coordinate: >90% delegation rate, multiple agent invocations
# - /research: >90% delegation rate, multiple agent invocations
# - Recent invocations logged with timestamps
```

### Task 4.4: File Creation Verification

**Verify correct artifact locations**:
```bash
# Check that reports created in correct locations
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/

# Verify NO TODO output
ls -la .claude/TODO*.md
# Should show: TODO.md (project tracking, expected)
#              NO TODO1.md, TODO2.md (command output, unexpected)
```

**Acceptance Criteria for Phase 4**:
- [ ] Both commands invoke agents successfully (PROGRESS: markers visible)
- [ ] Files created in correct locations (specs/NNN_topic/)
- [ ] No command output written to TODO*.md
- [ ] Delegation rate >90% for both commands
- [ ] All test workflows complete end-to-end
- [ ] Summary displays correctly to user

**Estimated Time**: 45 minutes - 1 hour

---

## Phase 5: Documentation and Cleanup

**Objective**: Document fixes, update anti-pattern documentation, clean up backup files.

### Task 5.1: Update Anti-Pattern Documentation

**File**: `.claude/docs/concepts/patterns/behavioral-injection.md`

**Add section**:
```markdown
## Anti-Pattern Case Study: /coordinate and /research (Spec 495)

**Problem**: Both commands used YAML-style Task blocks wrapped in markdown code fences, causing 0% agent delegation rate.

**Example of Broken Pattern**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "..."
}
```

**Why It Failed**:
- Markdown code fence made Task invocation appear as documentation
- Template variables like ${TOPIC} were never substituted
- Claude interpreted as "here's what a Task invocation looks like" not "execute this Task invocation"

**Fix Applied** (from spec 438 resolution):
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "general-purpose"
- description: "Research authentication patterns"  # Actual value
- prompt: "[complete prompt with pre-calculated values]"
```

**Result**: 0% → >90% delegation rate after applying imperative bullet-point pattern.

**Prevention**: All Task invocations in command files must use imperative phrasing with explicit tool usage instructions.
```

### Task 5.2: Update Command Architecture Standards

**File**: `.claude/docs/reference/command_architecture_standards.md`

**Update Standard 11** with /coordinate and /research examples:
```markdown
## Standard 11: Imperative Agent Invocation Pattern

**Requirement**: All agent invocations MUST use imperative bullet-point pattern.

**Verified Commands**:
- ✅ /supervise (fixed in spec 438)
- ✅ /coordinate (fixed in spec 495)
- ✅ /research (fixed in spec 495)

**Pattern Template**:
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "[type]"
- description: "[actual description, no placeholders]"
- prompt: "[complete prompt with pre-calculated values]"
```

**Anti-Patterns Detected and Fixed**:
1. YAML-style Task blocks (spec 438, 495)
2. Template variables in agent prompts (spec 495)
3. Bash code blocks as documentation (spec 495)
```

### Task 5.3: Create Validation Script

**File**: `.claude/lib/validate-agent-invocation-pattern.sh`

**Purpose**: Detect YAML-style Task blocks and code fences in command files.

```bash
#!/bin/bash
# Validation script to detect agent invocation anti-patterns

COMMAND_DIR="${1:-.claude/commands}"
FAILED=0

echo "Validating agent invocation patterns in: $COMMAND_DIR"
echo ""

# Check for YAML-style Task blocks
echo "Checking for YAML-style Task blocks..."
if grep -rn "^Task {" "$COMMAND_DIR"/*.md; then
  echo "❌ FAILED: Found YAML-style Task blocks"
  echo "   These should use imperative bullet-point pattern"
  FAILED=1
else
  echo "✅ PASSED: No YAML-style Task blocks found"
fi

# Check for code fences around Task invocations
echo ""
echo "Checking for code fences around Task invocations..."
if grep -B2 "^Task {" "$COMMAND_DIR"/*.md | grep "^\`\`\`"; then
  echo "❌ FAILED: Found code fences around Task invocations"
  echo "   Remove markdown code fences from Task blocks"
  FAILED=1
else
  echo "✅ PASSED: No code fences around Task invocations"
fi

# Check for template variables in agent prompts
echo ""
echo "Checking for unsubstituted template variables..."
if grep -rn '\${[A-Z_]*}' "$COMMAND_DIR"/*.md | grep -v "example\|Example"; then
  echo "⚠️  WARNING: Found template variables that may not be substituted"
  echo "   Verify these are in documentation sections, not agent prompts"
fi

echo ""
if [ $FAILED -eq 1 ]; then
  echo "❌ VALIDATION FAILED"
  exit 1
else
  echo "✅ ALL VALIDATIONS PASSED"
  exit 0
fi
```

### Task 5.4: Add to Test Suite

**File**: `.claude/tests/test_command_agent_invocations.sh`

```bash
#!/bin/bash
# Test agent invocation patterns in orchestration commands

source "$(dirname "$0")/../lib/validate-agent-invocation-pattern.sh"

test_coordinate_agent_invocations() {
  echo "Testing /coordinate agent invocations..."

  # Test that coordinate uses imperative pattern
  if grep -q "USE the Task tool NOW" .claude/commands/coordinate.md; then
    echo "✓ /coordinate uses imperative pattern"
  else
    echo "✗ /coordinate missing imperative pattern"
    return 1
  fi

  # Test no YAML blocks
  if grep -q "^Task {" .claude/commands/coordinate.md; then
    echo "✗ /coordinate has YAML-style Task blocks"
    return 1
  else
    echo "✓ /coordinate has no YAML-style blocks"
  fi

  return 0
}

test_research_agent_invocations() {
  echo "Testing /research agent invocations..."

  # Similar tests for research command
  if grep -q "USE the Task tool NOW" .claude/commands/research.md; then
    echo "✓ /research uses imperative pattern"
  else
    echo "✗ /research missing imperative pattern"
    return 1
  fi

  if grep -q "^Task {" .claude/commands/research.md; then
    echo "✗ /research has YAML-style Task blocks"
    return 1
  else
    echo "✓ /research has no YAML-style blocks"
  fi

  return 0
}

# Run tests
test_coordinate_agent_invocations
test_research_agent_invocations

echo ""
echo "Agent invocation pattern tests complete"
```

### Task 5.5: Clean Up Backup Files

```bash
# After validation passes, optionally remove backup files
# (or keep for historical reference)

# List backups
ls -lh .claude/commands/*.backup-*

# Optional: Remove if satisfied with fixes
# rm .claude/commands/*.backup-*
```

### Task 5.6: Update Diagnostic Reports

Update both diagnostic reports with "RESOLVED" status:

**Add to 001_coordinate_failure_diagnostic.md**:
```markdown
---

## Resolution Status: FIXED

**Date Fixed**: [INSERT DATE]
**Spec**: 495_coordinate_command_failure_analysis
**Plan**: 001_fix_coordinate_and_research_commands.md

**Changes Applied**:
- All 9 agent invocations converted to imperative bullet-point pattern
- All YAML-style blocks removed
- All template variables replaced with value injection instructions
- Delegation rate improved: 0% → >90%

**Verification**:
- Test workflows completed successfully
- Files created in correct locations
- No TODO.md output
- Agent delegation metrics confirmed >90%

**Prevention Measures**:
- Validation script added: `.claude/lib/validate-agent-invocation-pattern.sh`
- Test suite updated: `.claude/tests/test_command_agent_invocations.sh`
- Anti-pattern documentation updated
```

**Add same resolution section to 002_research_command_failure.md**

**Acceptance Criteria for Phase 5**:
- [ ] Anti-pattern documentation updated with case studies
- [ ] Command architecture standards updated
- [ ] Validation script created and tested
- [ ] Test suite updated with new tests
- [ ] Backup files cleaned up (or retained for reference)
- [ ] Diagnostic reports marked as resolved

**Estimated Time**: 45 minutes - 1 hour

---

## Risk Assessment

### Low Risk
- **Pattern already proven**: Spec 438 resolution pattern has been validated in `/supervise` command
- **No new functionality**: Only fixing existing broken pattern, not adding features
- **Clear rollback**: Backup files enable easy rollback if issues arise

### Medium Risk
- **Multiple large files**: Both commands are 60-86KB, requires careful editing
- **Testing coverage**: Need comprehensive testing to verify all agent invocations work

### Mitigation Strategies
1. **Create backups** before any edits (Phase 1)
2. **Fix one command at a time** (/coordinate first as more critical)
3. **Test after each command** before proceeding to next
4. **Keep `/supervise` as working reference** throughout
5. **Validation script** catches regression if pattern accidentally reintroduced

---

## Dependencies

### External Dependencies
- None (all required libraries and agents already exist)

### Internal Dependencies
- `.claude/agents/research-specialist.md` (exists)
- `.claude/agents/research-synthesizer.md` (exists)
- `.claude/agents/plan-architect.md` (exists)
- `.claude/agents/implementer-coordinator.md` (exists)
- `.claude/agents/test-specialist.md` (exists)
- `.claude/agents/debug-analyst.md` (exists)
- `.claude/agents/doc-writer.md` (exists)
- `.claude/agents/spec-updater.md` (exists)
- `.claude/lib/unified-location-detection.sh` (exists)
- Spec 438 resolution pattern (documented, proven)

**Status**: All dependencies satisfied, no blockers.

---

## Testing Strategy

### Unit Testing
- Validation script tests each command file for anti-patterns
- Test suite verifies imperative pattern present
- Test suite verifies no YAML-style blocks

### Integration Testing
- End-to-end test of `/coordinate` research workflow
- End-to-end test of `/coordinate` research-and-plan workflow
- End-to-end test of `/research` hierarchical pattern
- Verify files created in correct locations

### Performance Testing
- Measure delegation rate via `/analyze agents`
- Verify >90% target met for both commands
- Compare before/after metrics

### Regression Testing
- Verify `/supervise` still works after adding validation
- Ensure no impact on other commands
- Confirm `/orchestrate` if it was already working

---

## Rollback Plan

If fixes cause issues:

1. **Immediate Rollback**:
   ```bash
   # Restore from backup
   cp .claude/commands/coordinate.md.backup-[TIMESTAMP] .claude/commands/coordinate.md
   cp .claude/commands/research.md.backup-[TIMESTAMP] .claude/commands/research.md
   ```

2. **Verify Rollback**:
   ```bash
   # Confirm files restored
   diff .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-[TIMESTAMP]
   ```

3. **Document Issue**:
   - Add to diagnostic reports under "Attempted Fix - Issues Found"
   - Document specific failure mode
   - Re-assess approach

---

## Timeline

**Total Estimated Time**: 4-6 hours

| Phase | Tasks | Time Estimate | Dependencies |
|-------|-------|--------------|--------------|
| Phase 1 | Preparation and Backup | 30 min | None |
| Phase 2 | Fix /coordinate Command | 2.5-3 hours | Phase 1 complete |
| Phase 3 | Fix /research Command | 1.5-2 hours | Phase 2 complete, tested |
| Phase 4 | Validation Testing | 45 min - 1 hour | Phases 2-3 complete |
| Phase 5 | Documentation and Cleanup | 45 min - 1 hour | Phase 4 passing |

**Recommended Schedule**:
- **Session 1** (2-2.5 hours): Phases 1-2 (fix /coordinate)
- **Session 2** (1.5-2 hours): Phase 3 (fix /research)
- **Session 3** (1.5 hours): Phases 4-5 (testing, documentation)

---

## Success Metrics

### Quantitative Metrics
- **Delegation Rate**: 0% → >90% for both commands
- **File Creation Rate**: 0% → 100% (files created in correct locations)
- **TODO Output**: 100% → 0% (no output to TODO*.md files)
- **Test Pass Rate**: 0% → 100% (all test workflows complete)

### Qualitative Metrics
- Commands execute without displaying command file content
- PROGRESS: markers emitted during execution
- Summary displayed to user at completion
- Agents invoked and visible in logs
- User can successfully run research and orchestration workflows

---

## Conclusion

This plan provides a systematic approach to fixing both `/coordinate` and `/research` commands by applying the proven spec 438 resolution pattern. The pattern has already been validated in `/supervise` command, minimizing risk. With careful execution, comprehensive testing, and validation automation, both commands should achieve >90% agent delegation rate and full functionality restoration.

**Key Success Factors**:
1. **Proven pattern**: Using existing, validated solution from spec 438
2. **Systematic approach**: Fix one command at a time with testing between
3. **Clear acceptance criteria**: Specific, measurable success criteria for each phase
4. **Automated validation**: Prevention measures to catch regression
5. **Comprehensive documentation**: Updated anti-pattern docs and architecture standards

**Estimated Completion**: 4-6 hours over 2-3 work sessions
