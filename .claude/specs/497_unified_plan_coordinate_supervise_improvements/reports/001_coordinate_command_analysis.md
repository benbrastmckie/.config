# /coordinate Command Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: /coordinate command implementation plan analysis (spec 495)
- **Report Type**: Implementation plan analysis
- **Source Plan**: /home/benjamin/.config/.claude/specs/495_coordinate_command_failure_analysis/plans/001_fix_coordinate_and_research_commands.md

## Executive Summary

The implementation plan addresses a critical bug in both `/coordinate` and `/research` commands where 0% agent delegation occurs due to YAML-style Task invocations wrapped in markdown code fences. The plan systematically applies a proven resolution pattern from spec 438 (/supervise fix) to convert 9 agent invocations in /coordinate and 3 in /research to imperative bullet-point format. The plan includes comprehensive validation, testing strategy, and prevention measures with an estimated 4-6 hour completion time across 5 phases.

## Findings

### Plan Overview and Structure

**Plan Metadata**:
- **Plan ID**: 001
- **Topic**: 495_coordinate_command_failure_analysis
- **Type**: Bug Fix
- **Complexity**: 7/10
- **Estimated Total Time**: 4-6 hours
- **Dependencies**: None (spec 438 resolution pattern already proven)
- **Related Specs**: Spec 438 - /supervise command agent delegation fix

The plan uses spec 438's proven resolution pattern as a template, minimizing implementation risk since the pattern has been validated in the /supervise command.

**Problem Statement** (lines 17-27):
- Both `/coordinate` and `/research` have 0% agent delegation rate
- Root cause: YAML-style Task invocations wrapped in markdown code fences (````yaml`)
- Commands interpret Task blocks as documentation instead of executable instructions
- Impact: Complete failure of multi-agent orchestration and research workflows
- Evidence: `/coordinate` writes to TODO1.md files instead of invoking agents

**Success Criteria** (lines 29-36):
1. Agent delegation rate >90% (verified via `/analyze agents`)
2. Files created in correct locations (`.claude/specs/NNN_topic/`)
3. No TODO output files created
4. PROGRESS: markers emitted during execution
5. Complete end-to-end workflow testing
6. Pattern consistency with /supervise command

**Implementation Strategy** (lines 38-53):
- Apply spec 438 resolution systematically
- Key changes: Remove YAML blocks, use imperative phrasing, replace template variables
- Risk mitigation: Create backups, fix /coordinate first, keep /supervise as reference

### Phase Breakdown

#### Phase 1: Preparation and Backup (30 minutes)

**Objective**: Create backups and validate current state before modifications (lines 56-94)

**Tasks**:
1. Create timestamped backups of both command files
2. Verify /supervise command working state (reference pattern)
3. Read /supervise command file (`.claude/commands/supervise.md`)
4. Document current failure modes with test invocations
5. Verify test environment ready

**Acceptance Criteria**:
- Backup files created with timestamp suffix
- /supervise verified working (delegation rate >90%)
- /supervise command file reviewed as working reference
- Test invocations documented showing current failures
- Git status clean or changes committed

**Key Commands**:
```bash
# Create backups
cp .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)
cp .claude/commands/research.md .claude/commands/research.md.backup-$(date +%Y%m%d-%H%M%S)

# Verify supervise working
/supervise "research test topic" --dry-run
```

**Critical Insight**: Phase explicitly requires reading /supervise command file as working reference (line 87-89), ensuring developers can compare patterns side-by-side.

#### Phase 2: Fix /coordinate Command (2.5-3 hours)

**Objective**: Apply spec 438 resolution pattern to all agent invocations in coordinate.md (lines 98-258)

**Scope**: 9 agent invocations across 6 phases of /coordinate command

**Task 2.1: Fix Research Phase Agent Invocation** (lines 104-184):

**Current Pattern** (BROKEN) - lines 108-124:
- Uses `Task { }` YAML-style block
- Wrapped in markdown code fence
- Contains template variables: `${TOPIC_NAME}`, `${WORKFLOW_DESCRIPTION}`, `${REPORT_PATHS[i]}`
- Agent prompt includes placeholder syntax

**New Pattern** (FIXED) - lines 126-168:
- Imperative bullet-point format: "USE the Task tool NOW with these parameters"
- No code fences around Task invocation
- Explicit path calculation using Bash tool BEFORE agent invocation
- Template variables replaced with instructions to insert actual values
- Clear orchestrator vs subagent role definition

**Changes Made** (lines 170-176):
1. Removed YAML-style `Task { }` block
2. Changed to imperative bullet-point pattern with "USE the Task tool NOW"
3. Added explicit path calculation using Bash tool BEFORE agent invocation
4. Replaced template variables with instructions to insert actual values
5. Added clarity on orchestrator vs subagent roles
6. Removed code fence around Task invocation

**Remaining Tasks** (lines 185-258):
- Task 2.2: Fix Planning Phase Agent Invocation (plan-architect)
- Task 2.3: Fix Implementation Phase Agent Invocation (implementer-coordinator)
- Task 2.4: Fix Testing Phase Agent Invocation (test-specialist)
- Task 2.5: Fix Debug Phase Agent Invocations (3 invocations: debug-analyst, code-writer, test-specialist re-run)
- Task 2.6: Fix Documentation Phase Agent Invocation (doc-writer)

**Acceptance Criteria for Phase 2** (lines 247-253):
- All 9 agent invocations converted to imperative bullet-point pattern
- All YAML-style blocks removed
- All template variables replaced with value injection instructions
- All bash code blocks converted to explicit Bash tool invocations
- Pattern consistency verified against /supervise reference

**Files Modified**: `.claude/commands/coordinate.md` (9 locations)

#### Phase 3: Fix /research Command (1.5-2 hours)

**Objective**: Apply identical pattern to research.md agent invocations (lines 261-473)

**Scope**: 3 agent invocations (research-specialist, research-synthesizer, spec-updater)

**Task 3.1: Fix Research-Specialist Invocation** (lines 267-336):

**Current Pattern** (BROKEN) - lines 269-287:
- YAML-style `Task { }` block wrapped in markdown code fence (`````markdown` + ` ```yaml `)
- Template placeholders: `[SUBTOPIC]`, `[ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]`

**New Pattern** (FIXED) - lines 289-327:
- Removed markdown code fence and YAML-style block
- Imperative bullet-point pattern
- Concrete example showing invocation for one subtopic
- Explicit orchestrator responsibilities
- Instructions to repeat for each subtopic (2-4 times based on complexity)

**Task 3.2: Fix Research-Synthesizer Invocation** (lines 338-381):
- Apply same transformation pattern
- Calculate overview path using Bash tool
- Provide list of verified report paths from previous step

**Task 3.3: Fix Spec-Updater Invocation** (line 383-386):
- Apply same pattern transformation

**Task 3.4: Remove Bash Code Block Pseudo-Instructions** (lines 388-454):

**Problem** (lines 388-391):
- research.md has extensive bash code blocks in STEPs 1-2
- Appear as documentation rather than executable instructions

**Fix** (lines 405-454):
- Convert to explicit Bash tool invocations
- Add "**EXECUTE NOW**: USE the Bash tool" prefix
- Keep bash code block but make clear it should be executed
- Add explicit description and verification steps

**Acceptance Criteria for Phase 3** (lines 462-468):
- All 3 agent invocations converted to imperative bullet-point pattern
- All markdown code fences removed from Task invocations
- All template placeholders replaced with value injection instructions
- All bash code blocks (~10) converted to explicit Bash tool invocations
- Pattern consistency verified against /supervise and fixed /coordinate

**Files Modified**: `.claude/commands/research.md` (3 agent invocations + ~10 bash code blocks)

#### Phase 4: Validation Testing (45 minutes - 1 hour)

**Objective**: Verify both commands work correctly with >90% agent delegation rate (lines 476-566)

**Comparison Baseline**: /supervise command (verified >90% delegation rate)

**Task 4.1: Test /coordinate Command** (lines 483-506):

**Test 1: Simple Research Workflow**:
```bash
/coordinate "research authentication patterns for REST APIs"
```

**Expected Results**:
- 2-4 research-specialist agents invoked (PROGRESS: markers visible)
- Report files created in `.claude/specs/NNN_topic/reports/`
- No output in `.claude/TODO*.md` files
- Summary displayed with artifact paths
- Delegation rate >90%

**Test 2: Research-and-Plan Workflow**:
```bash
/coordinate "research authentication to create implementation plan"
```

**Expected Results**:
- Research phase completes successfully
- plan-architect agent invoked
- Plan file created in `.claude/specs/NNN_topic/plans/`
- No TODO file output
- Delegation rate >90%

**Task 4.2: Test /research Command** (lines 508-525):

**Test: Basic Research**:
```bash
/research "API authentication patterns and best practices"
```

**Expected Results**:
- Topic decomposed into 2-4 subtopics
- Research-specialist agents invoked in parallel
- Subtopic reports created
- research-synthesizer agent invoked
- OVERVIEW.md created
- spec-updater agent invoked
- Cross-references updated
- No TODO file output
- Delegation rate >90%

**Task 4.3: Delegation Rate Analysis** (lines 527-541):
```bash
/analyze agents
```
- All three commands (/supervise, /coordinate, /research) should show >90% delegation rate

**Task 4.4: File Creation Verification** (lines 543-554):
- Verify reports created in correct locations
- Verify NO TODO*.md output files

**Acceptance Criteria for Phase 4** (lines 556-563):
- Both commands invoke agents successfully
- Files created in correct locations
- No command output written to TODO*.md
- Delegation rate >90% for both commands
- All test workflows complete end-to-end
- Summary displays correctly to user

#### Phase 5: Documentation and Cleanup (45 minutes - 1 hour)

**Objective**: Document fixes, update anti-pattern documentation, clean up backup files (lines 568-810)

**Task 5.1: Update Anti-Pattern Documentation** (lines 573-607):
- File: `.claude/docs/concepts/patterns/behavioral-injection.md`
- Add case study section for /coordinate and /research (spec 495)
- Document broken pattern, why it failed, fix applied, results

**Task 5.2: Update Command Architecture Standards** (lines 609-636):
- File: `.claude/docs/reference/command_architecture_standards.md`
- Update Standard 11 with /coordinate and /research examples
- List verified commands (supervise, coordinate, research)
- Document anti-patterns detected and fixed

**Task 5.3: Create Validation Script** (lines 638-691):
- File: `.claude/lib/validate-agent-invocation-pattern.sh`
- Purpose: Detect YAML-style Task blocks and code fences in command files
- Checks: YAML-style Task blocks, code fences around invocations, template variables
- Exit codes: 0 for pass, 1 for failure

**Task 5.4: Add to Test Suite** (lines 693-752):
- File: `.claude/tests/test_command_agent_invocations.sh`
- Test /coordinate agent invocations (imperative pattern, no YAML blocks)
- Test /research agent invocations (same checks)

**Task 5.5: Clean Up Backup Files** (lines 754-765):
- List backups
- Optionally remove if satisfied with fixes

**Task 5.6: Update Diagnostic Reports** (lines 767-800):
- Add "RESOLVED" status to both diagnostic reports
- Document date fixed, spec number, plan file
- List changes applied, verification results, prevention measures

**Acceptance Criteria for Phase 5** (lines 802-808):
- Anti-pattern documentation updated with case studies
- Command architecture standards updated
- Validation script created and tested
- Test suite updated with new tests
- Backup files cleaned up (or retained)
- Diagnostic reports marked as resolved

### Technical Requirements

**Core Requirements**:
1. **Pattern Transformation**: Convert YAML-style `Task { }` blocks to imperative bullet-point pattern
2. **Code Fence Removal**: Remove all markdown code fences (````yaml`, ```` ```bash ```) around Task invocations
3. **Template Variable Replacement**: Replace `${VAR}` placeholders with instructions to insert actual values
4. **Path Pre-Calculation**: Add explicit Bash tool invocations to calculate paths BEFORE agent invocation
5. **Imperative Phrasing**: Use "USE the Task tool NOW with these parameters"
6. **Role Clarity**: Explicitly define orchestrator vs subagent responsibilities
7. **Pattern Consistency**: Match /supervise command's working pattern exactly

**Agent Invocation Pattern Template** (from lines 625-630):
```markdown
USE the Task tool NOW with these parameters:
- subagent_type: "[type]"
- description: "[actual description, no placeholders]"
- prompt: "[complete prompt with pre-calculated values]"
```

**Anti-Patterns to Eliminate**:
1. YAML-style Task blocks (lines 655-657)
2. Template variables in agent prompts (line 678)
3. Bash code blocks as documentation (spec 495 specific)

### File Modifications

**Files to Modify**:
1. `.claude/commands/coordinate.md` - 9 agent invocations
2. `.claude/commands/research.md` - 3 agent invocations + ~10 bash code blocks
3. `.claude/docs/concepts/patterns/behavioral-injection.md` - Add case study
4. `.claude/docs/reference/command_architecture_standards.md` - Update Standard 11

**Files to Create**:
1. `.claude/lib/validate-agent-invocation-pattern.sh` - Validation script
2. `.claude/tests/test_command_agent_invocations.sh` - Test suite
3. Backup files: `coordinate.md.backup-[TIMESTAMP]`, `research.md.backup-[TIMESTAMP]`

**Files to Update**:
1. `001_coordinate_failure_diagnostic.md` - Mark as RESOLVED
2. `002_research_command_failure.md` - Mark as RESOLVED

### Testing Strategy

**Unit Testing** (lines 857-859):
- Validation script tests each command file for anti-patterns
- Test suite verifies imperative pattern present
- Test suite verifies no YAML-style blocks

**Integration Testing** (lines 861-866):
- End-to-end test of /coordinate research workflow
- End-to-end test of /coordinate research-and-plan workflow
- End-to-end test of /research hierarchical pattern
- Verify files created in correct locations

**Performance Testing** (lines 868-870):
- Measure delegation rate via `/analyze agents`
- Verify >90% target met for both commands
- Compare before/after metrics

**Regression Testing** (lines 872-876):
- Verify /supervise still works after adding validation
- Ensure no impact on other commands
- Confirm /orchestrate if already working

**Test Commands**:
```bash
# Coordinate tests
/coordinate "research authentication patterns for REST APIs"
/coordinate "research authentication to create implementation plan"

# Research test
/research "API authentication patterns and best practices"

# Delegation analysis
/analyze agents

# File verification
ls -la .claude/specs/*/reports/
ls -la .claude/specs/*/plans/
ls -la .claude/TODO*.md  # Should show no TODO1.md, TODO2.md
```

### Risks and Challenges

**Low Risk** (lines 816-819):
- Pattern already proven in spec 438
- No new functionality (only fixing broken pattern)
- Clear rollback via backup files

**Medium Risk** (lines 821-822):
- Multiple large files (60-86KB) require careful editing
- Testing coverage needs to be comprehensive

**Mitigation Strategies** (lines 824-829):
1. Create backups before any edits
2. Fix one command at a time (/coordinate first as more critical)
3. Test after each command before proceeding
4. Keep /supervise as working reference throughout
5. Validation script catches regression

**Rollback Plan** (lines 881-900):
```bash
# Immediate rollback
cp .claude/commands/coordinate.md.backup-[TIMESTAMP] .claude/commands/coordinate.md
cp .claude/commands/research.md.backup-[TIMESTAMP] .claude/commands/research.md

# Verify rollback
diff .claude/commands/coordinate.md .claude/commands/coordinate.md.backup-[TIMESTAMP]
```

### Key Insights

**1. Proven Pattern Reduces Risk**:
The plan leverages spec 438's proven resolution pattern, which has already been validated in the /supervise command. This minimizes implementation risk and provides a clear template. Phase 1 explicitly requires reading /supervise command file as a working reference (lines 63, 87-89).

**2. Systematic Approach**:
The plan follows a clear progression: prepare → fix coordinate → fix research → test → document. Fixing /coordinate first (more critical) with testing before proceeding to /research reduces risk.

**3. Comprehensive Testing Strategy**:
Phase 4 includes multiple test types (unit, integration, performance, regression) with specific commands and expected results. Delegation rate analysis provides quantitative verification of success.

**4. Prevention Measures**:
Phase 5 creates automated validation (validate-agent-invocation-pattern.sh) and test suite additions to prevent regression. This ensures the anti-pattern cannot be accidentally reintroduced.

**5. Clear Acceptance Criteria**:
Each phase has specific, measurable acceptance criteria. Phase 2 acceptance criteria (lines 247-253) require all 9 invocations converted, all YAML blocks removed, pattern consistency verified.

**6. Template Variable Problem**:
The plan identifies a critical issue: template variables like `${TOPIC_NAME}` in agent prompts are never substituted (lines 170-176). The fix replaces these with instructions to insert actual values.

**7. Bash Code Block Documentation**:
Task 3.4 addresses a /research-specific issue: extensive bash code blocks appearing as documentation rather than executable instructions. The fix adds "**EXECUTE NOW**: USE the Bash tool" prefix (lines 405-454).

**8. Comprehensive Documentation Updates**:
Phase 5 updates anti-pattern documentation, command architecture standards, and diagnostic reports. This creates a complete audit trail and knowledge base for future developers.

**9. Timeline Realism**:
Total estimate of 4-6 hours across 5 phases with recommended 3-session schedule (lines 906-919). Session 1: 2-2.5 hours (phases 1-2), Session 2: 1.5-2 hours (phase 3), Session 3: 1.5 hours (phases 4-5).

**10. Success Metrics**:
Quantitative metrics provide clear success criteria: 0% → >90% delegation rate, 0% → 100% file creation rate, 100% → 0% TODO output, 0% → 100% test pass rate (lines 924-928).

**11. Dependencies Satisfied**:
The plan documents all internal dependencies (8 agents, libraries, spec 438 pattern) as satisfied with no blockers (lines 833-851).

**12. /supervise as Reference Pattern**:
The plan explicitly references /supervise throughout (lines 63, 69, 87-89, 106, 185, 252, 467, 480, 533-540, 823, 873), treating it as the proven implementation template. This is critical for developers to compare working patterns side-by-side with broken patterns during fixes.

## Recommendations

### For Unified Plan Creation (spec 497)

**1. Extract Common Pattern Transformation Logic**:
Both /coordinate and /research use the same pattern transformation:
- Remove YAML-style `Task { }` blocks
- Remove markdown code fences
- Use imperative bullet-point format
- Replace template variables
- Add explicit path calculation

The unified plan should create a shared "Pattern Transformation Template" that can be applied to both commands, reducing duplication and ensuring consistency.

**2. Standardize Testing Approach**:
Create a unified testing framework for all orchestration commands (/supervise, /coordinate, /research, /orchestrate):
- Standard test workflows for each command type
- Shared delegation rate analysis script
- Common file verification checks
- Unified regression test suite

This ensures all orchestration commands are tested consistently.

**3. Generalize Validation Script**:
The validate-agent-invocation-pattern.sh script (Task 5.3) should be expanded to:
- Validate ALL orchestration commands, not just /coordinate and /research
- Include /supervise and /orchestrate in validation
- Run automatically as part of CI/CD or pre-commit hooks
- Generate detailed reports on anti-pattern detection

**4. Create Agent Invocation Best Practices Guide**:
Document the proven pattern in a standalone guide:
- When to use imperative bullet-point format
- How to calculate paths before agent invocation
- Template for agent prompts
- Orchestrator vs subagent role definitions
- Common anti-patterns to avoid

This prevents future developers from reintroducing the same anti-pattern.

**5. Consolidate /supervise References**:
The plan references /supervise 12 times as the working pattern. The unified plan should:
- Create a single comprehensive reference document comparing all three commands
- Document which pattern each command uses
- Provide side-by-side examples of broken vs fixed patterns
- Make /supervise the canonical reference implementation

**6. Automate Backup and Rollback**:
Create a standardized backup/rollback utility:
- Automatically create timestamped backups before any command file edits
- Provide easy rollback commands
- Verify rollback success
- Log all backup/rollback operations

This reduces manual effort and ensures safety during edits.

**7. Enhance Delegation Rate Monitoring**:
Extend `/analyze agents` command to:
- Track delegation rate over time (historical data)
- Alert when delegation rate drops below 90%
- Compare all orchestration commands side-by-side
- Identify specific agent invocations that fail

This provides ongoing monitoring and early warning of regressions.

**8. Create Interactive Validation Tool**:
Build an interactive tool that:
- Analyzes command files for anti-patterns
- Suggests specific fixes at each location
- Provides before/after preview
- Validates fixes before applying
- Generates test commands for verification

This reduces implementation time and increases accuracy.

**9. Document Template Variable Handling**:
Create clear guidelines for when to use:
- Template variables that will be substituted (and how)
- Instructions to insert actual values (and when)
- Pre-calculated values passed as parameters
- Dynamic calculation during execution

This prevents confusion about template variable usage.

**10. Standardize PROGRESS: Marker Usage**:
Define standard PROGRESS: marker patterns for all agents:
- Required markers for each workflow phase
- Format and frequency standards
- How orchestrators should monitor progress
- Error handling when markers are missing

This ensures consistent visibility across all workflows.

## References

- Source plan: `/home/benjamin/.config/.claude/specs/495_coordinate_command_failure_analysis/plans/001_fix_coordinate_and_research_commands.md` (lines 1-972)
- Related spec 438: /supervise command agent delegation fix (referenced throughout plan)
- Diagnostic reports:
  - `001_coordinate_failure_diagnostic.md` (line 12)
  - `002_research_command_failure.md` (line 13)
- Command files to be modified:
  - `.claude/commands/coordinate.md` (lines 257, 677-678)
  - `.claude/commands/research.md` (lines 472, 678)
- Documentation files to update:
  - `.claude/docs/concepts/patterns/behavioral-injection.md` (line 574)
  - `.claude/docs/reference/command_architecture_standards.md` (line 612)
- Scripts to create:
  - `.claude/lib/validate-agent-invocation-pattern.sh` (line 640)
  - `.claude/tests/test_command_agent_invocations.sh` (line 695)
- Agents referenced:
  - research-specialist (lines 267-336)
  - research-synthesizer (lines 338-381)
  - spec-updater (lines 383-386)
  - plan-architect (lines 185-224)
  - implementer-coordinator (line 228)
  - test-specialist (lines 230, 236)
  - debug-analyst (line 234)
  - code-writer (line 235)
  - doc-writer (line 246)
