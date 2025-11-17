# Implementation Plan: Fix Plan Command Execution Failures

## Metadata
- **Date**: 2025-11-16
- **Feature**: Fix plan command errors from shell context isolation and missing Task invocations
- **Scope**: Refactor plan.md to combine library sourcing with execution and add explicit Task invocations
- **Estimated Phases**: 4
- **Estimated Hours**: 6-8 hours
- **Structure Level**: 0
- **Complexity Score**: 6.5/10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_topic1.md)
  - [Optimize-Claude Success Patterns](../reports/002_topic2.md)
  - [Standards Drift Analysis](../reports/003_topic3.md)

## Overview

The plan command fails due to bash shell context isolation where library functions sourced in one Bash tool invocation are not available in subsequent invocations. Additionally, the command uses imperative comments ("EXECUTE NOW: USE the Task tool") instead of actual Task invocations, resulting in agents never being invoked. This plan fixes both issues by:

1. Combining library sourcing with function execution in single bash blocks
2. Replacing imperative comments with explicit Task tool invocations (following optimize-claude pattern)
3. Removing placeholder fallbacks that mask agent failures
4. Adding fail-fast verification checkpoints

## Research Summary

### Root Cause Analysis (Report 001)
- **Primary Issue**: Each Bash tool call creates fresh shell - functions sourced in one call unavailable in next
- **Secondary Issue**: Array syntax `${!ARRAY[@]}` requires `set +H` to prevent history expansion errors
- **Evidence**: Lines 162-174 of plan_output.md show "command not found" errors for sourced functions
- **Solution Pattern**: Combine sourcing + execution in single bash block (successful at line 178)

### Optimize-Claude Success Patterns (Report 002)
- **Key Difference**: optimize-claude has explicit Task blocks embedded in markdown, not just comments
- **Verification**: Mandatory checkpoints after each agent wave with fail-fast behavior
- **No Placeholders**: Never creates fallback files - failures terminate with clear errors
- **Simple Dependencies**: Only 1 library (unified-location-detection.sh) vs 7 in plan command
- **Path Pre-Calculation**: All paths calculated before agent invocation using simple bash string concatenation

### Standards Compliance Analysis (Report 003)
- **No Drift Found**: Plan command correctly implements Standard 11 (imperative invocation) and Standard 15 (library sourcing order)
- **Timeline**: Plan command created Oct-Nov 2024 DURING standards formalization period
- **Compliance**: Standards were incorporated from inception, not retrofitted
- **Conclusion**: Standards are not the problem - execution model mismatch is the issue

## Success Criteria

- [ ] Plan command executes without "command not found" errors
- [ ] Plan command executes without "bad substitution" errors
- [ ] Research agents are actually invoked (not just commented about)
- [ ] Plan-architect agent is actually invoked (not just commented about)
- [ ] Agent failures result in clear error messages (no placeholder files created)
- [ ] All verification checkpoints execute and fail-fast on errors
- [ ] Test execution completes successfully with existing test cases
- [ ] Command maintains Standard 11 and Standard 15 compliance

## Technical Design

### Architecture Changes

**Current Architecture (Broken)**:
```
Phase 0 bash block: Source libraries
Phase 1 bash block: Use functions → ERROR: functions not found
Phase 1.5 bash comment: "EXECUTE NOW: USE Task tool" → No actual invocation
Phase 3 bash comment: "EXECUTE NOW: USE Task tool" → No actual invocation
```

**New Architecture (Fixed)**:
```
Phase 0 bash block: Source essential libraries + initialize state
Phase 0.1 Task: Haiku subagent analyzes feature complexity → returns JSON classification
Phase 0.2 bash block: Parse classification JSON + generate semantic filenames + calculate paths
Phase 1.5: Explicit Task invocations for research agents (parallel) using semantic report paths
  → VERIFICATION CHECKPOINT (mandatory)
Phase 3: Explicit Task invocation for plan-architect agent using semantic plan path
  → VERIFICATION CHECKPOINT (mandatory)
```

### Key Design Decisions

1. **Use Haiku Subagent for Complexity Analysis**: Delegate complexity estimation to Haiku classifier (following coordinate pattern) instead of bash heuristics for:
   - Accurate semantic topic identification
   - Descriptive filename slug generation
   - Confidence scoring and reasoning
   - JSON-structured output matching coordinate command format

2. **Replace Comments with Task Blocks**: Convert imperative comments to actual Task invocations following optimize-claude pattern:
   ```markdown
   Task {
     subagent_type: "general-purpose"
     description: "Research [topic]"
     prompt: "
       Read and follow ALL behavioral guidelines from:
       ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

       **CRITICAL**: Create report file at EXACT path provided above.
     "
   }
   ```

3. **Remove Placeholder Fallbacks**: Delete placeholder creation blocks (lines 411-449, 619-696) that mask agent failures

4. **Add Verification Checkpoints**: After each agent wave, verify files exist and fail-fast with diagnostic messages

5. **Generate Semantic Filenames**: Use Haiku-provided `filename_slug` fields to create descriptive report names:
   - Instead of: `001_topic1.md`, `002_topic2.md`
   - Generate: `001_root_cause_analysis.md`, `002_success_patterns.md`
   - Improves readability and matches coordinate command's filename generation

6. **Simplify Dependencies**: Reduce library dependencies by using Haiku for complexity analysis (removes need for complexity-utils.sh)

## Implementation Phases

### Phase 1: Replace Bash Complexity Analysis with Haiku Subagent
dependencies: []

**Objective**: Replace bash-based complexity estimation with Haiku subagent classifier (following coordinate command pattern) to provide accurate topic analysis with semantic filenames

**Complexity**: Medium-High

**Tasks**:
- [x] Read coordinate command's workflow-classifier invocation pattern (coordinate.md Phase 0.1)
- [x] Create new agent behavioral file: /.claude/agents/plan-complexity-classifier.md
- [x] Agent should analyze feature description and return JSON with:
  - `research_complexity`: integer 0-3 (0=no research, 1=simple, 2=moderate, 3=complex)
  - `research_topics`: array of topic objects with `short_name`, `detailed_description`, `filename_slug`, `research_focus`
  - `plan_complexity`: integer 1-10 for plan difficulty estimation
  - `confidence`: float 0.0-1.0
  - `reasoning`: explanation of classification
- [x] Replace plan.md Phase 1 bash complexity logic with Task invocation:
  ```
  Task {
    subagent_type: "general-purpose"
    description: "Classify feature complexity"
    model: "haiku"
    prompt: "
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-complexity-classifier.md

      **Feature Description**: $FEATURE_DESCRIPTION

      Return: CLASSIFICATION_COMPLETE: {JSON classification object}
    "
  }
  ```
- [x] Update Phase 0 bash block to:
  - Source only essential libraries (state-persistence.sh, error-handling.sh, verification-helpers.sh)
  - Save feature description to state
  - Initialize workflow state
  - NOT perform complexity analysis (delegated to agent)
- [x] Add post-classification bash block to:
  - Parse JSON classification from agent response
  - Validate JSON structure (verify all required fields present)
  - Extract research_complexity, research_topics, plan_complexity
  - Generate semantic report filenames from `filename_slug` fields (e.g., `001_root_cause_analysis.md`)
  - Calculate REPORT_PATHS array with descriptive names
  - Save classification results to state
- [x] Ensure research topic objects contain all fields used in coordinate command
- [x] Test that filename slugs are valid (^[a-z0-9_]{1,50}$)
- [x] Verify Standard 15 library sourcing order maintained

**Testing**:
```bash
# Test Haiku classification with simple feature
/plan "add login button"
# Verify classification returns complexity=0 or 1, no research needed

# Test Haiku classification with complex feature
/plan "implement distributed tracing with OpenTelemetry integration"
# Verify classification returns complexity=2-3, multiple research topics
# Verify topic filenames are semantic (not generic "topic1", "topic2")
# Verify JSON structure matches coordinate command pattern
```

**Expected Duration**: 2-3 hours

**Key Differences from Coordinate**:
- Uses plan-complexity-classifier.md (custom for /plan needs)
- Returns 0-3 research complexity (vs coordinate's 1-4)
- Includes plan_complexity field for plan difficulty estimation
- Generates semantic filenames for both reports AND plan file
- Simpler library dependencies (only 3 vs 9 in coordinate)

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(731): complete Phase 1 - Consolidate bash blocks`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Add Explicit Task Invocations for Research Delegation
dependencies: [1]

**Objective**: Replace Phase 1.5 imperative comments with actual Task tool invocations

**Complexity**: High

**Tasks**:
- [x] Read optimize-claude.md Task invocation pattern (lines 71-113)
- [x] Remove imperative comment at plan.md line 381-382
- [x] Remove placeholder creation block at plan.md lines 411-449
- [x] Add explicit Task invocations for each research topic (following optimize-claude pattern)
- [x] Inject pre-calculated REPORT_PATH variables into Task prompt
- [x] Reference behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
- [x] Ensure Task blocks are NOT wrapped in code fences (Standard 11)
- [x] Add "EXECUTE NOW" marker before Task blocks (Standard 11)
- [x] Keep research topic generation logic in bash block (lines 317-377)
- [x] Add VERIFICATION CHECKPOINT after research agents complete
- [x] Verification should check each REPORT_PATH exists and fail-fast if missing
- [x] Update research delegation section documentation reference

**Testing**:
```bash
# Test research delegation with actual agent invocation
/plan "complex feature requiring research architecture design patterns"
# Verify Task tools are invoked (check agent output)
# Verify research reports are created at pre-calculated paths
# Verify verification checkpoint executes
# Verify failure if agent doesn't create file
```

**Expected Duration**: 2-3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(731): complete Phase 2 - Add research agent Task invocations`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: Add Explicit Task Invocation for Plan-Architect
dependencies: [2]

**Objective**: Replace Phase 3 imperative comment with actual plan-architect Task invocation

**Complexity**: Medium

**Tasks**:
- [x] Read optimize-claude.md plan-architect invocation pattern (lines 235-270)
- [x] Remove imperative comment at plan.md lines 594-595
- [x] Remove placeholder creation block at plan.md lines 619-696
- [x] Add explicit Task invocation for plan-architect agent
- [x] Inject pre-calculated PLAN_PATH into Task prompt
- [x] Inject REPORT_PATHS_JSON for research report integration
- [x] Reference behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
- [x] Ensure Task block is NOT wrapped in code fence (Standard 11)
- [x] Add "EXECUTE NOW" marker before Task block (Standard 11)
- [x] Add VERIFICATION CHECKPOINT after plan-architect completes
- [x] Verification should check PLAN_PATH exists, size ≥2000 bytes, phases ≥3, checkboxes ≥10
- [x] Verification should fail-fast with diagnostic messages if checks fail
- [x] Keep context JSON generation in bash for state caching (lines 596-617)

**Testing**:
```bash
# Test plan-architect invocation
/plan "add user authentication feature"
# Verify Task tool is invoked for plan-architect
# Verify plan file is created at pre-calculated path
# Verify verification checkpoint executes
# Verify file size, phase count, checkbox count checks
# Verify failure if agent doesn't create proper plan
```

**Expected Duration**: 1.5-2 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(731): complete Phase 3 - Add plan-architect Task invocation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 4: Integration Testing and Documentation
dependencies: [3]

**Objective**: Validate complete workflow and update documentation

**Complexity**: Low

**Tasks**:
- [ ] Run integration test: /plan "simple feature" (no research)
- [ ] Run integration test: /plan "complex architecture feature" (with research)
- [ ] Run integration test: /plan "feature" /path/to/existing/report.md (with report paths)
- [ ] Verify all error paths produce clear diagnostic messages
- [ ] Verify no "command not found" errors occur
- [ ] Verify no "bad substitution" errors occur
- [ ] Verify research agents are invoked when complexity ≥7
- [ ] Verify plan-architect is always invoked
- [ ] Verify verification checkpoints fail-fast on errors
- [ ] Update .claude/docs/guides/plan-command-guide.md with architectural changes
- [ ] Document shell context isolation issue and solution in guide
- [ ] Document Task invocation pattern in guide
- [ ] Add troubleshooting section for common errors
- [ ] Update command-reference.md if needed

**Testing**:
```bash
# Comprehensive integration tests
.claude/tests/test-plan-command.sh
# All tests should pass
```

**Expected Duration**: 1-2 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(731): complete Phase 4 - Integration testing and documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test library sourcing in single bash block (no context loss)
- Test complexity analysis function execution
- Test path pre-calculation logic
- Test verification checkpoint logic

### Integration Testing
- Test complete /plan workflow without research delegation
- Test complete /plan workflow with research delegation
- Test complete /plan workflow with provided research reports
- Test error paths (agent failures, missing libraries, invalid paths)

### Regression Testing
- Verify existing test cases still pass
- Verify Standard 11 compliance (imperative invocation)
- Verify Standard 15 compliance (library sourcing order)
- Verify no placeholder files created on agent failure

### Coverage Requirements
- Target: ≥80% coverage per Testing Protocols in CLAUDE.md
- Focus on error handling and verification checkpoints
- Test all failure modes with diagnostic messages

## Documentation Requirements

### Files to Update
1. **/.claude/docs/guides/plan-command-guide.md**
   - Add §2.5 "Shell Context Isolation" explaining the issue
   - Add §2.6 "Agent Invocation Architecture" documenting Task pattern
   - Update §3.1 "Phase 0" to reflect consolidated bash block
   - Update §3.3 "Phase 1.5" to reflect Task invocations
   - Update §3.5 "Phase 3" to reflect Task invocation
   - Add troubleshooting entry for "command not found" errors

2. **/.claude/docs/reference/command-reference.md**
   - Update /plan entry if architectural changes warrant it
   - Add note about Task invocations vs imperative comments

3. **/.claude/docs/troubleshooting/** (if needed)
   - Create entry for shell context isolation issues
   - Document solution pattern

### Documentation Standards
- Follow CommonMark specification
- No emojis in file content
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams
- No historical commentary (clean-break approach)

## Dependencies

### Internal Dependencies
- /.claude/lib/detect-project-dir.sh
- /.claude/lib/workflow-state-machine.sh
- /.claude/lib/state-persistence.sh
- /.claude/lib/error-handling.sh
- /.claude/lib/verification-helpers.sh
- /.claude/lib/unified-location-detection.sh
- /.claude/lib/metadata-extraction.sh
- /.claude/agents/plan-complexity-classifier.md (NEW - created in Phase 1)
- /.claude/agents/research-specialist.md
- /.claude/agents/plan-architect.md
- /.claude/agents/workflow-classifier.md (reference pattern from coordinate command)
- /.claude/commands/optimize-claude.md (reference pattern)
- /.claude/commands/coordinate.md (reference pattern for Haiku classification)

### External Dependencies
- bash (with `set +H` support)
- jq (JSON processing)
- Standard Unix utilities (grep, sed, tr, wc, etc.)

## Rollback Strategy

If issues occur during implementation:
1. Git revert to last known good state
2. Document specific failure mode in issue tracker
3. Re-evaluate architectural approach if fundamental issue discovered
4. Consider phased rollout (Phase 1 → test → Phase 2 → test → etc.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking existing /plan users | Low | High | Maintain backward compatibility; test extensively |
| Task invocations fail in some contexts | Medium | High | Add fallback with clear error messages |
| Library sourcing still fails in consolidated block | Low | Critical | Add diagnostic output; test thoroughly |
| Verification checkpoints too strict | Low | Medium | Make verification messages clear; allow override flag if needed |
| Standards drift during refactor | Low | Medium | Verify Standard 11 and 15 compliance after each phase |

## Notes

### Implementation Approach
- This is a critical fix, not a feature enhancement
- Preserve all existing functionality during refactor
- Focus on execution model, not standards (standards are correct)
- Follow optimize-claude pattern as proven working reference
- Maintain Standard 11 and Standard 15 compliance throughout

### Key Insights from Research
1. Shell context isolation is THE root cause (Report 001)
2. Optimize-claude works because it uses explicit Task invocations (Report 002)
3. Standards are NOT the problem - they're correctly implemented (Report 003)
4. Bash-based complexity heuristics are error-prone - Haiku classifier provides accurate semantic analysis
5. Solution: Use Haiku for classification + add Task invocations + generate semantic filenames + remove placeholders

### Success Metrics
- Zero "command not found" errors
- Zero "bad substitution" errors
- 100% agent invocation rate (research + planning)
- Clear failure messages (no silent placeholder fallbacks)
- Maintained Standard 11 and 15 compliance
- Semantic filenames generated for all artifacts (reports and plans)
- Accurate complexity classification via Haiku subagent

## Revision History

- **2025-11-16**: Revised Phase 1 to use Haiku subagent for complexity analysis (following coordinate command pattern) instead of bash heuristics. Updated architecture to include Phase 0.1 (Haiku classification) and Phase 0.2 (JSON parsing + semantic filename generation). Added plan-complexity-classifier.md agent to dependencies. Improved filename generation to use semantic slugs matching coordinate command behavior.
