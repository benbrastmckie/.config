# Orchestrate Research Phase Enhancement Implementation Plan

## Metadata
- **Date**: 2025-10-13
- **Feature**: Enhanced /orchestrate research phase with improved visibility, progress tracking, error recovery, and documentation
- **Scope**: /orchestrate command research phase workflow improvements
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - .claude/specs/reports/orchestrate_improvements/001_alternative_approaches_analysis.md
  - .claude/specs/reports/orchestrate_improvements/002_current_implementation_analysis.md
  - .claude/specs/reports/orchestrate_improvements/003_best_practices_research.md
  - .claude/specs/reports/orchestrate_improvements/004_path_inconsistency_finding.md (CRITICAL FINDING)
- **Plan Number**: 046
- **Estimated Effort**: 6-9 hours

## Overview

The /orchestrate command currently implements a subagent-per-report research phase pattern where each research-specialist agent creates an individual report file. The orchestrator collects file paths (not content) and passes them to the planning phase. This implementation already follows 2025 best practices for multi-agent workflows with artifact-based communication.

However, a **critical empirical finding** (Report 004) revealed that when /orchestrate executed to research its own improvements, the three parallel research agents created reports in inconsistent directory locations (2 at project root, 1 in .claude/). This demonstrates the current implementation has critical gaps in:

1. **CRITICAL - Absolute Path Specification**: Orchestrator provides relative paths, agents interpret inconsistently
2. **CRITICAL - Path Verification**: No validation that reports exist at expected locations
3. **Documentation clarity**: Not explicitly stated that subagents create individual files
4. **Progress visibility**: Limited real-time feedback about which agent is doing what
5. **Error recovery**: Basic verification without robust retry mechanisms
6. **Path tracking**: No agent-to-report mapping for debugging

This plan enhances the existing workflow with improved visibility, documentation, and error recovery while **prioritizing absolute path specification as a critical fix** to prevent report location inconsistencies. The plan preserves the efficient parallel execution pattern that provides ~66% time savings.

## Success Criteria

- [ ] Documentation clearly explains subagent report creation pattern
- [ ] Per-agent progress markers provide real-time visibility
- [ ] Report creation verification with automatic retry capability
- [ ] Agent-to-report mapping stored in checkpoints for debugging
- [ ] All enhancements preserve parallel execution performance
- [ ] Comprehensive test coverage for new verification and retry logic
- [ ] No breaking changes to existing /orchestrate workflows

## Technical Design

### Architecture Decisions

**1. Preserve Parallel Execution**
- Verification happens AFTER all agents complete (batch verification)
- Retry logic targets only failed agents, not all agents
- Maintains ~66% time savings from parallel execution

**2. Enhanced State Management**
- Extend workflow_state.research_reports from array of strings to array of objects
- Each object contains: agent_index, topic, report_path, created_at, verified
- Checkpoint includes full agent-to-report mapping for recovery

**3. Progressive Visibility**
- Per-agent progress markers emitted during research phase
- REPORT_CREATED: markers when files successfully written
- Verification summary displayed after research phase completes

**4. Error Classification and Recovery**
- Use existing error-utils.sh for error classification
- Single retry attempt for missing reports (max 1 per agent)
- Store agent prompts in checkpoint for retry operations
- Escalate to user after retry failures

### Component Interactions

```
Research Phase Flow (Enhanced):
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Identify Research Topics                             │
│ - Extract 2-4 topics from workflow description               │
│ - Calculate thinking mode (complexity scoring)               │
│ - Store agent prompts in checkpoint for retry                │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│ Step 2: Launch Parallel Research Agents                      │
│ - Invoke all agents in single message (parallel)             │
│ - Each agent creates individual report file                  │
│ - Emit PROGRESS: markers for user visibility                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│ Step 3a: Monitor Research Agent Execution (NEW)              │
│ - Display per-agent progress: [Agent N/M: topic] Status...   │
│ - Watch for REPORT_CREATED: markers                          │
│ - Show report paths as they're created                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│ Step 4: Collect Report Paths (ENHANCED)                      │
│ - Extract REPORT_PATH: from each agent output                │
│ - Store in workflow_state.research_reports array             │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│ Step 4.5: Verify Report Files (NEW)                          │
│ - Batch verification of all reports                          │
│ - Check file exists, readable, valid metadata                │
│ - Build agent-to-report mapping                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                  ┌───────┴────────┐
                  │ All reports OK?│
                  └───────┬────────┘
                          │
              ┌───────────┴──────────────┐
              │ YES                      │ NO
              │                          │
┌─────────────▼────────────┐  ┌─────────▼─────────────────────┐
│ Proceed to Planning Phase│  │ Step 4.6: Retry Failed Reports│
│                          │  │ - Identify failed agents       │
│                          │  │ - Retrieve stored prompts      │
│                          │  │ - Retry with error-utils.sh    │
│                          │  │ - Max 1 retry per agent        │
└──────────────────────────┘  └────────────┬──────────────────┘
                                           │
                              ┌────────────▼───────────────┐
                              │ Retry successful?          │
                              └────────────┬───────────────┘
                                           │
                                   ┌───────┴────────┐
                                   │ YES            │ NO
                                   │                │
                         ┌─────────▼──────┐  ┌─────▼─────────┐
                         │ Proceed to     │  │ Escalate to   │
                         │ Planning Phase │  │ User          │
                         └────────────────┘  └───────────────┘
```

### Data Flow and State Management

**Workflow State Structure (Enhanced)**:
```json
{
  "workflow_state": {
    "thinking_mode": "think hard",
    "current_phase": "research",
    "research_reports": [
      {
        "agent_index": 1,
        "topic": "existing_patterns",
        "topic_slug": "existing_patterns",
        "report_path": "specs/reports/existing_patterns/001_auth_patterns.md",
        "created_at": "2025-10-13T14:30:22Z",
        "verified": true,
        "retry_count": 0
      },
      {
        "agent_index": 2,
        "topic": "security_practices",
        "topic_slug": "security_practices",
        "report_path": "specs/reports/security_practices/001_best_practices.md",
        "created_at": "2025-10-13T14:31:15Z",
        "verified": true,
        "retry_count": 0
      }
    ],
    "research_phase_data": {
      "agent_prompts": {
        "existing_patterns": "[full prompt text for agent 1]",
        "security_practices": "[full prompt text for agent 2]"
      },
      "failed_agents": [],
      "verification_attempts": 1
    }
  }
}
```

## Implementation Phases

### Phase 1: Documentation Enhancement and Absolute Path Specification (CRITICAL) [COMPLETED]
**Objective**: Document absolute path requirements and clarify subagent report creation pattern
**Complexity**: Low-Medium
**Estimated Time**: 2-3 hours
**Priority**: CRITICAL (addresses Report 004 finding)

Tasks:
- [x] **CRITICAL**: Document that orchestrator MUST provide absolute paths to research agents (not relative)
- [x] **CRITICAL**: Add path determination logic showing how to construct absolute report paths
- [x] **CRITICAL**: Document directory convention (.claude/specs/reports/ for Claude Code features)
- [x] Update orchestrate.md Research Phase section to explicitly state subagents create individual files
- [x] Add clear documentation that orchestrator collects paths, not content
- [x] Document expected REPORT_PATH: output format from research agents (must be absolute path)
- [x] Add examples showing per-agent file creation workflow with absolute paths
- [x] Create troubleshooting section for path inconsistency issues
- [x] Add section explaining agent-to-report mapping
- [x] Update Research Agent Prompt Template with absolute REPORT_PATH: requirement
- [x] Add visual diagram showing file-based artifact communication with path specification

Files Modified:
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (lines 610-1131)

Absolute Path Determination Pattern (CRITICAL):
```bash
# Orchestrator determines absolute paths BEFORE invoking agents
PROJECT_ROOT="/home/benjamin/.config"
CLAUDE_DIR="${PROJECT_ROOT}/.claude"
SPECS_DIR="${CLAUDE_DIR}/specs/reports"
TOPIC_SLUG="orchestrate_improvements"  # Derived from topic
REPORT_DIR="${SPECS_DIR}/${TOPIC_SLUG}"

# Ensure directory exists
mkdir -p "${REPORT_DIR}"

# Calculate next report number for this topic
NEXT_NUM=$(find "${REPORT_DIR}" -name "*.md" 2>/dev/null | wc -l)
NEXT_NUM=$((NEXT_NUM + 1))
REPORT_NUM=$(printf "%03d" ${NEXT_NUM})

# Construct ABSOLUTE path for agent
REPORT_PATH="${REPORT_DIR}/${REPORT_NUM}_${report_name}.md"

# Pass absolute path to research agent in prompt:
# "Create a research report at: ${REPORT_PATH}"
# NOT: "Create a research report at: specs/reports/..."
```

Testing:
```bash
# Verify absolute path documentation
cd /home/benjamin/.config
grep -A 10 "Research Phase (Parallel Execution)" .claude/commands/orchestrate.md
grep -A 5 "REPORT_PATH:" .claude/commands/orchestrate.md
grep "absolute path" .claude/commands/orchestrate.md

# Verify path determination logic documented
grep -A 20 "Path Determination" .claude/commands/orchestrate.md
```

Expected Outcomes:
- **CRITICAL**: Documentation mandates absolute paths for all research agents
- **CRITICAL**: Path determination logic clearly documented with examples
- **CRITICAL**: Directory convention established (.claude/specs/reports/ for Claude Code)
- Documentation clearly explains subagent report creation
- Examples show REPORT_PATH: format expectations (absolute paths)
- Troubleshooting section addresses path inconsistency issues
- Visual diagram clarifies artifact-based communication with path flow

### Phase 2: Progress Visibility Enhancement [COMPLETED]
**Objective**: Add per-agent progress markers and report creation visibility
**Complexity**: Medium
**Estimated Time**: 2-3 hours

Tasks:
- [x] Add per-agent progress marker format to orchestrate.md Step 3a
- [x] Document REPORT_CREATED: marker format
- [x] Add examples of progress output during research phase
- [x] Create progress display template showing agent index, topic, and status
- [x] Update TodoWrite integration to show per-agent subtasks
- [x] Add verification summary output format after research phase
- [x] Document expected timeline for progress markers
- [x] Add error progress markers for failed agents

Files Modified:
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (lines 1032-1069)

Progress Marker Format:
```
PROGRESS: Starting Research Phase (3 agents, parallel execution)
PROGRESS: [Agent 1/3: existing_patterns] Analyzing codebase...
PROGRESS: [Agent 2/3: security_practices] Searching best practices...
PROGRESS: [Agent 3/3: framework_implementations] Comparing libraries...
PROGRESS: [Agent 1/3: existing_patterns] Report created ✓
REPORT_CREATED: specs/reports/existing_patterns/001_auth_patterns.md
PROGRESS: [Agent 2/3: security_practices] Report created ✓
REPORT_CREATED: specs/reports/security_practices/001_best_practices.md
PROGRESS: [Agent 3/3: framework_implementations] Report created ✓
REPORT_CREATED: specs/reports/framework_implementations/001_lua_auth.md
PROGRESS: Research Phase complete - 3/3 reports verified (0 retries needed)
```

Testing:
```bash
# Verify progress marker documentation
cd /home/benjamin/.config
grep -A 20 "Step 3a: Monitor Research Agent Execution" .claude/commands/orchestrate.md
grep "REPORT_CREATED:" .claude/commands/orchestrate.md
```

Expected Outcomes:
- Clear per-agent progress visibility
- Report paths displayed as created
- Verification summary shows success/retry counts
- User can track which agent is working on what

### Phase 3: Report Verification Enhancement (includes path validation) [COMPLETED]
**Objective**: Add batch verification with absolute path validation and detailed error reporting
**Complexity**: Medium
**Estimated Time**: 2-3 hours
**Addresses**: Report 004 finding (path inconsistency detection)

Tasks:
- [x] Create new Step 4.5 in orchestrate.md for report verification
- [x] **CRITICAL**: Add path consistency verification (reports at expected absolute paths)
- [x] **CRITICAL**: Document path mismatch detection (agent created report elsewhere)
- [x] Document batch verification process (verify all reports after collection)
- [x] Add report validation checklist (exists at expected path, readable, valid metadata)
- [x] Document agent-to-report mapping storage in checkpoint (includes expected vs. actual paths)
- [x] Add verification failure classification (file_not_found, path_mismatch, invalid_metadata, permission_denied)
- [x] Create verification summary output format
- [x] Document when to proceed vs. retry vs. escalate
- [x] Add examples of verification output for success and failure cases
- [x] Add path mismatch troubleshooting guidance

Files Modified:
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (new Step 4.5, after line 1131)

Verification Process (with path validation):
```yaml
For EACH report in workflow_state.research_reports:
  1. CRITICAL: Verify file exists at EXPECTED absolute path (not just anywhere)
  2. Check if file is readable (not empty, not corrupted)
  3. Validate metadata section exists (Date, Research Focus, etc.)
  4. If file not at expected path: Search for report in other locations (path mismatch detection)
  5. Record verification result in workflow_state with expected_path and actual_path

If ALL reports verified at expected paths:
  - Display success summary
  - Proceed to Planning Phase

If ANY reports failed or at wrong paths:
  - Classify error types using error-utils.sh
  - file_not_found: No file at expected path, not found elsewhere
  - path_mismatch: File exists but at different location than expected
  - invalid_metadata: File at correct path but metadata incomplete
  - permission_denied: Cannot read file at expected path
  - Proceed to Step 4.6 (Retry Failed Reports)
```

Testing:
```bash
# Verify Step 4.5 documentation added
cd /home/benjamin/.config
grep -A 30 "Step 4.5: Verify Report Files" .claude/commands/orchestrate.md
```

Expected Outcomes:
- Comprehensive verification of all reports
- Clear error classification for failures
- Agent-to-report mapping stored for debugging
- Verification results tracked in workflow_state

### Phase 4: Error Recovery Enhancement (includes path correction) [COMPLETED]
**Objective**: Add retry logic with error classification, prompt preservation, and absolute path enforcement
**Complexity**: Medium-High
**Estimated Time**: 3-4 hours
**Addresses**: Report 004 finding (path inconsistency recovery)

Tasks:
- [x] Create new Step 4.6 in orchestrate.md for retry logic
- [x] **CRITICAL**: Add path mismatch recovery (move report to correct location OR retry with clarified absolute path)
- [x] **CRITICAL**: Document how absolute paths are re-emphasized in retry prompts
- [x] Document how agent prompts are stored in checkpoint before invocation
- [x] Add error classification integration using error-utils.sh (including path_mismatch)
- [x] Document retry strategy (single retry per agent, max 1 attempt)
- [x] Add retry invocation pattern (retrieve prompt from checkpoint, reinvoke agent with ABSOLUTE path emphasis)
- [x] Document loop prevention (max 1 retry tracked in workflow_state)
- [x] Add escalation criteria (retry failures, all agents failed, timeout, persistent path issues)
- [x] Create retry output format showing which agents are being retried and why (include path issues)
- [x] Document preservation of parallel execution during retry (only retry failed agents)

Files Modified:
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (new Step 4.6, after Step 4.5)

Retry Logic:
```yaml
Step 4.6: Retry Failed Reports

For EACH failed report from Step 4.5:
  1. IDENTIFY which agent failed (using agent_index from mapping)
  2. CLASSIFY error type using error-utils.sh:
     - file_not_found: Report file missing after agent completion
     - path_mismatch: Report created but at wrong location (CRITICAL - Report 004 issue)
     - invalid_metadata: Report exists but metadata incomplete
     - permission_denied: Cannot write to specs directory
     - agent_crashed: Agent output indicates failure

  3. DETERMINE if error is retryable:
     - file_not_found: YES (retry agent invocation with absolute path)
     - path_mismatch: YES (move file to correct location OR retry with emphasized absolute path)
     - invalid_metadata: PARTIAL (attempt metadata fix, then retry if fails)
     - permission_denied: NO (escalate - system issue)
     - agent_crashed: YES (retry with same prompt)

  4. RETRIEVE agent prompt from checkpoint:
     prompt = workflow_state.research_phase_data.agent_prompts[topic_slug]

  5. RETRY agent invocation if retryable and retry_count < 1:
     - Invoke agent using Task tool with stored prompt
     - Increment retry_count in workflow_state
     - Emit PROGRESS: marker showing retry attempt

  6. VERIFY retry result:
     - If successful: Update workflow_state, mark verified=true
     - If failed again: Add to workflow_state.research_phase_data.failed_agents

After all retries complete:
  - If all reports now verified: Proceed to Planning Phase
  - If any still failed: Escalate to user with detailed error report
```

Error Classification Examples:
```bash
# file_not_found
ERROR: Report missing for Agent 2/3 (topic: security_practices)
Expected: /home/benjamin/.config/.claude/specs/reports/security_practices/001_best_practices.md
Agent completed successfully but report file not found at expected location.
Retrying agent invocation with absolute path emphasis (attempt 1/1)...

# path_mismatch (CRITICAL - Report 004 finding)
ERROR: Report location mismatch for Agent 1/3 (topic: existing_patterns)
Expected: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_auth_patterns.md
Actual:   /home/benjamin/.config/specs/reports/existing_patterns/001_auth_patterns.md
Report exists but at wrong location (relative path interpretation issue).
Options: (1) Move file to correct location, or (2) Retry with emphasized absolute path
Choosing: Move file to expected location...
SUCCESS: File moved to correct location.

# invalid_metadata
ERROR: Report incomplete for Agent 3/3 (topic: framework_implementations)
Path: /home/benjamin/.config/.claude/specs/reports/framework_implementations/001_lua_auth.md
File exists at correct path but metadata section missing.
Attempting metadata fix...

# agent_crashed
ERROR: Agent failed for topic: alternative_approaches
Agent output indicates crash or error condition.
Retrying agent invocation with same prompt (attempt 1/1)...
```

Testing:
```bash
# Verify Step 4.6 documentation added
cd /home/benjamin/.config
grep -A 50 "Step 4.6: Retry Failed Reports" .claude/commands/orchestrate.md
grep "retry_count" .claude/commands/orchestrate.md
```

Expected Outcomes:
- Automatic retry for recoverable errors
- Error classification provides actionable information
- Loop prevention through retry count limits
- Agent prompts preserved in checkpoint for retry
- Clear escalation path for non-recoverable errors

### Phase 5: Integration Testing and Validation [COMPLETED]
**Objective**: Comprehensive testing of enhanced research phase workflow
**Complexity**: Medium
**Estimated Time**: 2-3 hours

Tasks:
- [x] Create test script for enhanced research phase: test_orchestrate_research_enhancements.sh
- [x] **CRITICAL**: Test absolute path specification (all agents receive absolute paths)
- [x] **CRITICAL**: Test path mismatch detection (report at wrong location detected)
- [x] **CRITICAL**: Test path mismatch recovery (file moved or retry with path emphasis)
- [x] Test successful 3-agent parallel execution with verification
- [x] Test single agent failure scenario with successful retry
- [x] Test multiple agent failures with partial recovery
- [x] Test non-retryable error escalation
- [x] Test progress marker output format
- [x] Test REPORT_CREATED: marker emission
- [x] Test agent-to-report mapping storage in checkpoint (includes expected/actual paths)
- [x] Test retry loop prevention (max 1 retry enforced)
- [x] Test verification summary output
- [x] Test integration with existing planning phase
- [x] Test backward compatibility (existing workflows still work)
- [x] Update run_all_tests.sh to include new test script

Files Created:
- `/home/benjamin/.config/.claude/tests/test_orchestrate_research_enhancements.sh`

Files Modified:
- `/home/benjamin/.config/.claude/tests/run_all_tests.sh`

Test Coverage Areas:
```yaml
Absolute Path Tests (CRITICAL - Report 004):
  - test_absolute_path_specification: Verify all agent prompts contain absolute paths (not relative)
  - test_path_consistency: All agents create reports in same directory
  - test_expected_location: Reports created at exact paths specified by orchestrator

Happy Path Tests:
  - test_parallel_research_success: All 3 agents create reports successfully at correct paths
  - test_progress_markers_displayed: Per-agent progress shown correctly
  - test_report_verification_success: All reports verified in batch at expected paths
  - test_planning_phase_receives_paths: Planning phase gets correct absolute report paths

Error Recovery Tests:
  - test_single_agent_failure_retry: One agent fails, retry succeeds
  - test_multiple_agent_failures: Two agents fail, both retry successfully
  - test_retry_failure_escalation: Agent fails twice, escalates to user
  - test_max_retry_enforcement: Retry count limit enforced (max 1)

Error Classification Tests:
  - test_file_not_found_classification: Missing report file detected
  - test_path_mismatch_classification: Report at wrong location detected (CRITICAL - Report 004)
  - test_path_mismatch_recovery: File moved to correct location successfully
  - test_invalid_metadata_classification: Incomplete metadata detected
  - test_permission_denied_classification: Write permission error detected

State Management Tests:
  - test_agent_to_report_mapping: Mapping stored correctly in checkpoint
  - test_agent_prompt_preservation: Prompts stored for retry
  - test_workflow_state_updates: workflow_state.research_reports structure correct

Integration Tests:
  - test_backward_compatibility: Existing /orchestrate workflows unaffected
  - test_planning_phase_integration: Planning agent receives correct paths
  - test_checkpoint_resume: Can resume after research phase failure
```

Testing Commands:
```bash
# Run new test suite
cd /home/benjamin/.config
.claude/tests/test_orchestrate_research_enhancements.sh

# Run full test suite to verify no regressions
.claude/tests/run_all_tests.sh

# Test specific scenarios
.claude/tests/test_orchestrate_research_enhancements.sh test_parallel_research_success
.claude/tests/test_orchestrate_research_enhancements.sh test_single_agent_failure_retry
```

Expected Outcomes:
- All tests pass (>80% coverage target)
- No regressions in existing /orchestrate workflows
- Error scenarios handled gracefully
- Progress visibility working as documented
- Verification and retry logic functioning correctly

## Testing Strategy

### Unit Testing
- Test report path extraction from agent output
- Test verification logic (file exists, readable, metadata valid)
- Test error classification using error-utils.sh
- Test retry count enforcement
- Test agent-to-report mapping creation

### Integration Testing
- Test full research phase workflow with 3 agents
- Test interaction with planning phase (report paths passed correctly)
- Test checkpoint integration (state preserved and restored)
- Test error-utils.sh integration for error classification
- Test backward compatibility with existing workflows

### Error Scenario Testing
- Test single agent failure with successful retry
- Test multiple agent failures with partial recovery
- Test non-retryable errors (permission denied)
- Test retry limit enforcement (max 1 retry)
- Test escalation to user after retry failures

### Performance Testing
- Verify parallel execution preserved (batch verification doesn't serialize)
- Measure time savings vs. sequential execution (~66% expected)
- Test with 2, 3, and 4 agents to verify scalability

## Documentation Requirements

### Updated Documentation
- `/home/benjamin/.config/.claude/commands/orchestrate.md`:
  - Research Phase section (lines 610-1131) enhanced with clarity
  - New Step 3a examples for progress visibility
  - New Step 4.5 for report verification
  - New Step 4.6 for retry logic
  - Troubleshooting section added

### New Documentation
- Test documentation in test_orchestrate_research_enhancements.sh header
- Inline comments explaining verification and retry algorithms
- Error message format documentation

### CLAUDE.md Updates
- No changes needed - /orchestrate behavior documented in orchestrate.md

## Dependencies

### External Dependencies
- None (all functionality using existing tools and utilities)

### Internal Dependencies
- `.claude/lib/error-utils.sh` - Error classification and handling
- `.claude/lib/checkpoint-utils.sh` - Workflow state persistence
- `.claude/agents/research-specialist.md` - Research agent behavioral guidelines
- Task tool - Agent invocation mechanism
- Read tool - Report file verification
- Write tool - Checkpoint state updates

### Tool Requirements
- Task tool for agent invocation
- Read tool for file verification
- Bash for verification scripts
- Grep for output parsing

## Risk Assessment

### Technical Risks

**Risk 1: Verification Breaks Parallelism**
- **Severity**: Medium
- **Likelihood**: Low
- **Mitigation**: Batch verification after all agents complete (not synchronous per-agent)
- **Contingency**: If performance degrades >10%, make verification optional

**Risk 2: Retry Logic Adds Complexity**
- **Severity**: Medium
- **Likelihood**: Medium
- **Mitigation**: Use existing error-utils.sh patterns, comprehensive testing
- **Contingency**: Limit retry to simple file_not_found cases initially

**Risk 3: Checkpoint State Growth**
- **Severity**: Low
- **Likelihood**: Low
- **Mitigation**: Store only necessary data (paths, not content), compress if >1MB
- **Contingency**: Add checkpoint size warning if >500KB

### Operational Risks

**Risk 1: Breaking Changes to Existing Workflows**
- **Severity**: High
- **Likelihood**: Low
- **Mitigation**: All changes are additive (new steps, enhanced state), backward compatible
- **Contingency**: Feature flag to disable enhancements if issues detected

**Risk 2: Increased Error Messages Confuse Users**
- **Severity**: Low
- **Likelihood**: Medium
- **Mitigation**: Clear, actionable error messages with troubleshooting links
- **Contingency**: Add error message verbosity levels (brief/detailed)

## Notes

### Key Technical Decisions

**Decision 1: Batch Verification vs. Synchronous Verification**
- **Chosen**: Batch verification after all agents complete
- **Rationale**: Preserves parallel execution performance (~66% time savings)
- **Trade-off**: Slight delay in detecting failures, but acceptable given performance benefit

**Decision 2: Single Retry vs. Multiple Retries**
- **Chosen**: Single retry (max retry_count = 1)
- **Rationale**: Most failures are transient (file write timing), single retry sufficient
- **Trade-off**: May not recover from persistent issues, but prevents infinite loops

**Decision 3: Enhanced State vs. Simple Path Array**
- **Chosen**: Enhanced state (array of objects with metadata)
- **Rationale**: Enables debugging, retry, and visibility features
- **Trade-off**: Slightly larger checkpoint files (~500 bytes per report), but worth it for functionality

**Decision 4: Error Classification Integration**
- **Chosen**: Use existing error-utils.sh for consistency
- **Rationale**: Consistent error handling across all commands
- **Trade-off**: Dependency on error-utils.sh, but already widely used

### Implementation Notes

**Note 1: Preserving Existing Behavior**
All enhancements are additive. Existing /orchestrate workflows will continue to work without modification. The enhanced state structure is backward compatible (planning phase still receives report paths array).

**Note 2: Testing Approach**
Focus testing on error scenarios since happy path already works. Use mocking for agent failures to test retry logic without requiring actual agent failures.

**Note 3: Documentation Clarity**
The research report revealed the main issue is documentation, not functionality. Prioritize Phase 1 (Documentation Enhancement) to immediately clarify existing behavior.

**Note 4: Future Enhancements**
Consider for future work (not in this plan):
- Synthesis agent for cross-report insights (Option C-1 from research)
- Configurable retry limits (currently hardcoded to 1)
- Report quality scoring (completeness, depth metrics)
- Real-time streaming progress (requires Task tool enhancement)

### Integration with Existing Systems

**Checkpoint System**: workflow_state structure extended but backward compatible
**Error Handling**: Uses error-utils.sh classification patterns
**Progress Tracking**: Uses existing PROGRESS: marker protocol
**TodoWrite**: Research phase broken into per-agent subtasks for visibility

### Performance Considerations

**Parallel Execution Preserved**: ~66% time savings maintained
**Context Efficiency**: Still passes paths (not content) to planning phase (97% token savings)
**Checkpoint Overhead**: ~500 bytes per report added to checkpoint (acceptable)
**Verification Cost**: <1 second for batch file existence checks (negligible)

## Appendix: Research Report Insights

### CRITICAL Empirical Finding (Report 004: Path Inconsistency)

**Discovery**: When /orchestrate was executed to research its own improvements, the three parallel research agents created reports in **inconsistent directory locations**:
- Agents 1 & 2: `/home/benjamin/.config/specs/reports/orchestrate_improvements/` (project root)
- Agent 3: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/` (.claude subdirectory)

**Root Cause**: Orchestrator provided relative paths (`specs/reports/...`) to research agents. Agents interpreted relative paths from different base directories, resulting in reports scattered across two locations.

**User Impact**: User looked in correct location (`.claude/specs/`) and found only 1 of 3 reports, despite orchestrator claiming all three were created successfully.

**This finding elevated absolute path specification from a documentation improvement to a CRITICAL fix.** The implementation plan now prioritizes:
1. Absolute path specification in Phase 1 (documentation with examples)
2. Path verification in Phase 3 (detect path mismatches)
3. Path recovery in Phase 4 (move files or retry with absolute path)
4. Path testing in Phase 5 (ensure consistency)

### Key Finding from Alternative Approaches Analysis

The research report revealed that the desired subagent-per-report approach is ALREADY IMPLEMENTED. The gaps are in:
1. **CRITICAL**: Absolute path specification (Report 004 finding)
2. **CRITICAL**: Path verification (Report 004 finding)
3. Documentation clarity
4. Progress visibility
5. Error recovery robustness

This plan addresses all gaps, with path specification as highest priority.

### Rejected Alternatives

**Option C-1 (Synthesis Report)**: Adds orchestrator complexity without clear benefit (planning agent already synthesizes)
**Option C-2 (Lazy Creation)**: Violates research artifact persistence principle
**Option C-3 (Streaming Aggregation)**: Requires unavailable streaming features, breaks parallelism

### Recommended Approach Validation

Research report recommends Option B (Enhanced Current Approach) with:
- Documentation clarity (2-3 hours)
- Progress visibility (1-2 hours)
- Verification and recovery (3-4 hours)
- Total: 6-9 hours

This plan follows that recommendation with 5 phases totaling 6-9 hours estimated effort.
