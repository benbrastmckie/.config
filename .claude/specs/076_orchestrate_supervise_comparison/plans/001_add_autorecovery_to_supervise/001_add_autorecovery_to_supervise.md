# Add Auto-Recovery to /supervise Implementation Plan

## Metadata
- **Date**: 2025-10-23
- **Revision**: 3 (2025-10-23 - Remove /orchestrate changes, add /supervise backup phase)
- **Feature**: Add minimal auto-recovery capabilities to /supervise for seamless workflow execution
- **Scope**: Error handling, checkpoint support, progress feedback, and enhanced error reporting without compromising fail-fast philosophy (NO /orchestrate modifications)
- **Estimated Phases**: 6 (added Phase -1 for backup)
- **Complexity**: Medium (selective feature porting with architectural preservation)
- **Structure Level**: 1
- **Expanded Phases**: [1]
- **Topic Directory**: /home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison
- **Topic Number**: 076
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - ../reports/001_research/OVERVIEW.md
  - ../reports/001_research/003_error_handling_state_management_and_recovery.md

## Overview

This plan implements targeted auto-recovery features from /orchestrate into /supervise to create a robust, user-friendly workflow command while maintaining /supervise's clean fail-fast architecture. The goal is seamless execution with minimal user interruption, focusing on recovery from transient failures and preserving progress across interruptions.

**Key Principle**: Add resilience WITHOUT compromising /supervise's core philosophy:
- Maintain fail-fast for permanent errors (bad code, missing files)
- Auto-recover ONLY from transient failures (network timeouts, file locks)
- No user prompts for recovery decisions (fully automated)
- Minimal overhead (targeted features, not full /orchestrate complexity)

**Success Criteria**:
- Auto-recovery from transient failures (1 retry max, not 3)
- Phase-boundary checkpoints for workflow resumption
- Silent progress tracking (PROGRESS markers, no TodoWrite bloat)
- Zero user interruptions for recoverable errors
- Maintain 100% architectural cleanliness (no SlashCommand, pure Task tool)

## Success Criteria

- [ ] Transient errors auto-recover with single retry (network timeouts, file locks)
- [ ] Permanent errors fail-fast immediately (syntax errors, missing dependencies)
- [ ] Workflow resumes from last completed phase after interruption
- [ ] Progress markers visible at phase transitions
- [ ] Zero user prompts during recovery operations
- [ ] Error logs capture context for post-mortem analysis
- [ ] /supervise achieves production-ready robustness (deprecation of /orchestrate is outside scope of this plan)
- [ ] Command file size remains under 2,000 lines (vs /orchestrate's 5,000+)

## Technical Design

### Architecture Principles

**What to Port** (essential for robustness):
1. **Single-retry transient error recovery** - Not /orchestrate's 3-tier retry
2. **Phase-boundary checkpoints** - Not per-agent checkpoints
3. **Silent progress markers** - Not full TodoWrite integration
4. **Error classification** - Reuse error-handling.sh classify_error()
5. **Enhanced error reporting** - Error location extraction, specific error types, recovery suggestions, partial failure handling

**What NOT to Port** (preserves /supervise philosophy):
1. ❌ Multi-retry infrastructure (3 attempts) - Too complex, masks issues
2. ❌ Fallback file creation - Violates fail-fast principle
3. ❌ User escalation prompts - Breaks seamless execution goal
4. ❌ TodoWrite tracking - Adds overhead, PROGRESS markers sufficient
5. ❌ Per-agent checkpoints - Phase-level is adequate

### Component Integration

**Utility Libraries** (reuse existing):
- `.claude/lib/error-handling.sh` - Error classification and retry logic
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore (subset of functions)

**New Minimal Wrappers** (avoid bloat):
- `verify_and_retry()` - Combines verification + single retry for transient failures
- `save_phase_checkpoint()` - Lightweight phase-only checkpoint
- `emit_progress()` - Silent progress marker emission
- `extract_error_location()` - Parse file:line from error messages
- `detect_specific_error_type()` - Categorize errors into 4 types (timeout, syntax, missing_dependency, unknown)
- `suggest_recovery_actions()` - Generate context-specific recovery suggestions
- `handle_partial_research_failure()` - Allow workflow continuation if some research agents succeed

### Recovery Decision Tree

```
Agent Execution
  ↓
File Verification
  ↓
File Created? ─NO─→ Extract Location + Detect Specific Error Type
                      ↓
                    Timeout/Lock? ─YES─→ Retry Once (simple retry, no backoff)
                      ↓ NO                ↓
                    Syntax/Import/       Success? ─YES─→ Continue
                    Missing Dep?          ↓ NO
                      ↓                 Update Error Type + Location
                    Generate             ↓
                    Recovery            Generate Recovery Suggestions
                    Suggestions          ↓
                      ↓                 Log + Display Suggestions + Location
                    Log + Display        ↓
                    Suggestions +       Terminate (fail-fast)
                    Location
                      ↓
                    Terminate (fail-fast)

Special Case - Research Phase Parallel Execution:
  ↓
Multiple Agents Running in Parallel
  ↓
Some Agents Failed? ─YES─→ Check Success Rate
  ↓ NO                       ↓
All Succeeded             ≥50% Success? ─YES─→ Continue with Partial Results
  ↓                         ↓ NO              (Log missing reports)
Continue                  Terminate            ↓
                         (Insufficient         Continue to Planning Phase
                          Coverage)
```

### Checkpoint Strategy

**Phase-Boundary Checkpoints Only**:
- Research phase complete → Save checkpoint
- Planning phase complete → Save checkpoint
- Implementation phase complete → Save checkpoint

**Checkpoint Schema** (minimal subset of /orchestrate v1.3):
```json
{
  "schema_version": "1.0",
  "workflow_type": "supervise",
  "workflow_description": "...",
  "current_phase": 2,
  "completed_phases": [0, 1],
  "scope": "research-and-plan",
  "topic_path": "/path/to/specs/NNN_topic",
  "artifact_paths": {
    "research_reports": [...],
    "plan_path": "...",
    "overview_path": "..."
  }
}
```

**Auto-Resume Logic**:
1. Check for checkpoint on startup
2. Validate checkpoint (phase exists, artifacts exist)
3. Skip to next incomplete phase (no user prompt)
4. Continue execution seamlessly

## Implementation Phases

### Phase -1: Create /supervise Backup [COMPLETED]

**Objective**: Create timestamped backup of original /supervise command before making any modifications

**Complexity**: Low

**MANDATORY REQUIREMENTS**:
- Backup MUST be created before any modifications to supervise.md
- Backup MUST be timestamped for version tracking
- Backup MUST be stored in backups/ subdirectory within topic directory
- Original file integrity MUST be verified after backup creation

**Tasks**:
- [x] **MUST** create backups/ subdirectory if not exists: `mkdir -p specs/076_orchestrate_supervise_comparison/backups`
- [x] **MUST** create timestamped backup of supervise.md:
  ```bash
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_PATH="specs/076_orchestrate_supervise_comparison/backups/supervise_${TIMESTAMP}.md"
  cp .claude/commands/supervise.md "$BACKUP_PATH"
  echo "Backup created: $BACKUP_PATH"
  ```
- [x] **MUST** verify backup integrity:
  ```bash
  # Verify file exists and has content
  [ -f "$BACKUP_PATH" ] && [ -s "$BACKUP_PATH" ] || {
    echo "ERROR: Backup verification failed"
    exit 1
  }

  # Verify byte count matches original
  ORIGINAL_SIZE=$(wc -c < .claude/commands/supervise.md)
  BACKUP_SIZE=$(wc -c < "$BACKUP_PATH")

  if [ "$ORIGINAL_SIZE" -eq "$BACKUP_SIZE" ]; then
    echo "✓ Backup verified: $BACKUP_SIZE bytes"
  else
    echo "ERROR: Size mismatch (original: $ORIGINAL_SIZE, backup: $BACKUP_SIZE)"
    exit 1
  fi
  ```
- [x] **MUST** document backup location in implementation notes
  - **Backup Location**: `specs/076_orchestrate_supervise_comparison/backups/supervise_20251023_140831.md`
  - **Size**: 49394 bytes

**Testing**:
```bash
# Test backup creation
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="specs/076_orchestrate_supervise_comparison/backups/supervise_${TIMESTAMP}.md"
cp .claude/commands/supervise.md "$BACKUP_PATH"

# Verify backup exists and matches original
[ -f "$BACKUP_PATH" ] && echo "✓ Backup file created"
diff .claude/commands/supervise.md "$BACKUP_PATH" && echo "✓ Backup matches original"
```

**Files Created**:
- `backups/supervise_YYYYMMDD_HHMMSS.md` (timestamped backup)

**Success Criteria**:
- [x] Backup file created in backups/ subdirectory
- [x] Backup size matches original file exactly
- [x] Backup content verified (diff shows no differences)
- [x] Backup path documented for rollback capability

**Rollback Instructions** (if needed):
```bash
# To restore from backup if implementation issues occur:
BACKUP_FILE="specs/076_orchestrate_supervise_comparison/backups/supervise_YYYYMMDD_HHMMSS.md"
cp "$BACKUP_FILE" .claude/commands/supervise.md
echo "✓ Restored from backup: $BACKUP_FILE"
```

---

### Phase 0: Utility Integration and Error Classification [COMPLETED]

**Objective**: Integrate error-handling.sh and create minimal recovery wrappers

**Complexity**: Low

**MANDATORY REQUIREMENTS**:
- YOU MUST source error-handling.sh before proceeding to Phase 0.5
- All wrapper functions MUST be tested before Phase 1 begins
- Wrapper functions SHALL NOT exceed 20 lines each (minimal overhead requirement)

**Tasks**:
- [x] **MUST** add error-handling.sh sourcing to supervise.md:260 (after utility initialization section)
- [x] **MUST** create `classify_and_retry()` wrapper function in supervise.md shared utilities
  - Takes agent output, classifies error type
  - Returns: "retry" | "fail" | "success"
  - Integrates `classify_error()` from error-handling.sh:20-42
- [x] Create `verify_and_retry()` wrapper combining verification + classification
  - Input: file_path, agent_output, agent_type
  - Logic: verify file → classify error if missing → retry if transient
  - Max 1 retry (not 3 like /orchestrate)
- [x] Create `emit_progress()` helper for silent progress markers
  - Format: `PROGRESS: [Phase N] - [action]`
  - No TodoWrite overhead, just echo with prefix

**Testing**:
```bash
# Test error classification wrapper
source .claude/commands/supervise.md  # Extract functions
result=$(classify_and_retry "timeout connecting to agent")
[ "$result" = "retry" ] && echo "✓ Transient error detected"

result=$(classify_and_retry "SyntaxError: invalid syntax")
[ "$result" = "fail" ] && echo "✓ Permanent error detected"

# Test verify_and_retry logic
verify_and_retry "/tmp/test_report.md" "REPORT_CREATED: /tmp/test_report.md" "research-specialist"
[ $? -eq 0 ] && echo "✓ Verification passed"
```

**Files Modified**:
- `.claude/commands/supervise.md:260-342` (shared utilities section)

**Success Criteria**:
- [x] Error classification correctly identifies transient vs permanent errors
- [x] verify_and_retry performs exactly 1 retry for transient failures
- [x] All wrappers under 20 lines each (minimal overhead)

---

### Phase 0.5: Enhanced Error Reporting Infrastructure [COMPLETED]

**Objective**: Add strategic error reporting infrastructure for improved user experience on failures

**Complexity**: Low

**MANDATORY REQUIREMENTS**:
- All 4 wrappers MUST be implemented before Phase 1
- Error location extraction MUST parse common error formats (file:line)
- Partial failure handling MUST enforce ≥50% success threshold
- Total addition SHALL NOT exceed 120 lines (minimal overhead requirement)

**Tasks**:
- [x] **MUST** create `extract_error_location()` wrapper (supervise.md shared utilities)
  - Parses `file:line` format from error messages
  - Based on error-handling.sh:130-145
  - Returns: {file: "path", line: number} or null
  - Actual: 12 lines
- [x] Create `detect_specific_error_type()` wrapper (4 categories, not 8)
  - Input: error message string
  - Categories: "timeout", "syntax_error", "missing_dependency", "unknown"
  - Based on error-handling.sh:77-128 (simplified)
  - Uses pattern matching on error keywords
  - Actual: 24 lines
- [x] Create `suggest_recovery_actions()` wrapper
  - Input: error_type, location, error_message
  - Returns: Array of 2-3 actionable suggestions
  - Based on error-handling.sh:44-71
  - Examples:
    - syntax_error → "Check syntax at file:line", "Run linter", "Verify closing braces"
    - missing_dependency → "Install missing package", "Check imports", "Verify PATH"
    - timeout → "Check network connection", "Retry workflow", "Increase timeout"
  - Actual: 32 lines
- [x] Create `handle_partial_research_failure()` wrapper (research phase only)
  - Input: total_agents, successful_agents, failed_agents[]
  - Logic: If success_rate ≥ 50%, continue with warning
  - Returns: "continue" | "terminate"
  - Based on error-handling.sh:532-604
  - Actual: 44 lines
- [ ] Integrate enhanced error reporting into error display
  - Update error messages to include location (when available)
  - Display specific error type instead of generic "permanent error"
  - Show recovery suggestions on terminal failures
  - Format:
    ```
    ERROR: [Specific Error Type] at [file:line]
      → [Error message]

      Recovery suggestions:
      1. [Suggestion 1]
      2. [Suggestion 2]
      3. [Suggestion 3]
    ```
  - Note: This will be done during Phase 1 implementation when integrating with actual agent invocations

**Testing**:
```bash
# Test error location extraction
error_msg="SyntaxError at supervise.md:856: Missing closing brace"
location=$(extract_error_location "$error_msg")
echo "$location" | grep -q "supervise.md:856" && echo "✓ Location extracted"

# Test error type detection
error_type=$(detect_specific_error_type "connection timeout after 30s")
[ "$error_type" = "timeout" ] && echo "✓ Timeout detected"

error_type=$(detect_specific_error_type "SyntaxError: invalid syntax")
[ "$error_type" = "syntax_error" ] && echo "✓ Syntax error detected"

error_type=$(detect_specific_error_type "ModuleNotFoundError: No module named 'foo'")
[ "$error_type" = "missing_dependency" ] && echo "✓ Missing dependency detected"

# Test recovery suggestions
suggestions=$(suggest_recovery_actions "syntax_error" "auth.js:42" "Missing closing brace")
echo "$suggestions" | grep -q "Check syntax" && echo "✓ Suggestions generated"

# Test partial failure handling
result=$(handle_partial_research_failure 4 3 "agent_4_timeout")
[ "$result" = "continue" ] && echo "✓ 3/4 success allows continuation"

result=$(handle_partial_research_failure 4 1 "agent_2 agent_3 agent_4")
[ "$result" = "terminate" ] && echo "✓ 1/4 success terminates workflow"
```

**Files Modified**:
- `.claude/commands/supervise.md:260-342` (shared utilities section, adds ~110 lines)

**Success Criteria**:
- [x] Error location extraction works for common error formats
- [x] Error type detection correctly categorizes 4 error types
- [x] Recovery suggestions provide actionable guidance
- [x] Partial research failure allows continuation at ≥50% success rate
- [ ] Enhanced error messages displayed on all terminal failures (deferred to Phase 1)
- [x] Total addition: 112 lines (minimal overhead for significant UX improvement)

**Impact**:
- **Lines Added**: ~110 (4 wrappers + integration)
- **Value**: High (precise error location, actionable suggestions, better error messages)
- **Overhead**: Low (<5% complexity increase)

---

### Phase 1: Research Phase Auto-Recovery (Medium)

**Objective**: Add transient error recovery to research agent invocations in Phase 1

**Status**: PENDING

**Summary**: Implements single-retry auto-recovery for research phase agents with enhanced error reporting, partial failure handling (≥50% success threshold), and progress markers. Modifies research agent invocation loop and verification section in supervise.md with minimal overhead (<5%).

For detailed tasks and implementation, see [Phase 1 Details](phase_1_research_auto_recovery.md)

---

### Phase 2: Checkpoint Integration (Phase-Boundary Only)

**Objective**: Add lightweight checkpoints at phase transitions for workflow resumption

**Complexity**: Medium

**MANDATORY REQUIREMENTS**:
- Checkpoints MUST be saved only at phase boundaries (not per-agent)
- Auto-resume MUST skip completed phases without user prompt
- Invalid checkpoints MUST be deleted silently (no error)
- Checkpoint schema MUST use minimal v1.0 format (no error history, no replan tracking)

**Tasks**:
- [ ] **MUST** source checkpoint-utils.sh in utility initialization (supervise.md:260)
- [ ] **MUST** create `save_phase_checkpoint()` wrapper (minimal subset of save_checkpoint):
  - Takes: phase_number, scope, topic_path, artifact_paths
  - Saves to: `.claude/data/checkpoints/supervise_latest.json`
  - Schema: Minimal v1.0 (only phase, scope, paths - NO error history, NO replan tracking)
- [ ] Add checkpoint save after Phase 1 completion (supervise.md:735)
  - After research verification passes, before Phase 2 check
  - Save: current_phase=1, artifact_paths.research_reports, artifact_paths.overview_path
- [ ] Add checkpoint save after Phase 2 completion (supervise.md:893)
  - After plan verification passes, before Phase 3 check
  - Save: current_phase=2, artifact_paths.plan_path
- [ ] Implement auto-resume logic in Phase 0 (supervise.md:400-520):
  - Check for `.claude/data/checkpoints/supervise_latest.json`
  - If exists: Load checkpoint, validate phase < 6, skip to current_phase + 1
  - If invalid: Delete checkpoint, start fresh (no user prompt)
  - Emit progress: "PROGRESS: [Resume] Skipping completed phases 0-N"
- [ ] Add checkpoint cleanup on workflow completion (supervise.md:1410)
  - Delete checkpoint file when Phase 6 completes successfully

**Testing**:
```bash
# Test checkpoint save/resume
/supervise "research and plan OAuth integration"
# Kill workflow after Phase 1 completes (Ctrl+C)

# Resume workflow
/supervise "research and plan OAuth integration"
# Expected:
# - Detects checkpoint
# - Loads current_phase=1
# - Skips Phase 0 (Location) and Phase 1 (Research)
# - Continues at Phase 2 (Planning)
# - No user prompt for resume decision

# Verify checkpoint contents
cat .claude/data/checkpoints/supervise_latest.json | jq .
# Expected schema:
# {
#   "current_phase": 1,
#   "completed_phases": [0, 1],
#   "scope": "research-and-plan",
#   "topic_path": "...",
#   "artifact_paths": {...}
# }
```

**Files Modified**:
- `.claude/commands/supervise.md:260-342` (shared utilities - save_phase_checkpoint)
- `.claude/commands/supervise.md:400-520` (Phase 0 - auto-resume check)
- `.claude/commands/supervise.md:735` (after Phase 1 complete)
- `.claude/commands/supervise.md:893` (after Phase 2 complete)
- `.claude/commands/supervise.md:1410` (workflow completion cleanup)

**Success Criteria**:
- [ ] Checkpoints saved only at phase boundaries (not per-agent)
- [ ] Auto-resume skips completed phases without user prompt
- [ ] Invalid checkpoints deleted silently, workflow starts fresh
- [ ] Checkpoint file removed on successful completion

---

### Phase 3: Planning and Implementation Phase Recovery

**Objective**: Extend auto-recovery to Phases 2-6 for complete workflow resilience

**Complexity**: Medium

**MANDATORY REQUIREMENTS**:
- All 6 phases (2-6, excluding Phase 1 already done) MUST support single-retry auto-recovery
- Checkpoints MUST be saved after Phases 2, 3, 4 completion (not Phase 5 or 6)
- Permanent errors in any phase MUST fail-fast (no retry)
- Full workflow MUST be resilient to transient failures

**Tasks**:
- [ ] **MUST** apply verify_and_retry to Phase 2 (Planning) agent invocation
  - Update supervise.md:796-872 (plan-architect agent section)
  - Replace verify_file_created with verify_and_retry
  - Add PROGRESS markers before/after planning
- [ ] Apply verify_and_retry to Phase 3 (Implementation) agent invocation
  - Update supervise.md:950-1032 (code-writer agent section)
  - Single retry for transient failures during implementation
- [ ] Apply verify_and_retry to Phase 4 (Testing) agent invocation
  - Update supervise.md:1055-1128 (test-specialist agent section)
- [ ] Apply verify_and_retry to Phase 5 (Debug) iteration loop
  - Update supervise.md:1156-1322 (debug-analyst and code-writer agents)
  - Each debug iteration gets single retry per agent
- [ ] Apply verify_and_retry to Phase 6 (Documentation) agent invocation
  - Update supervise.md:1354-1406 (doc-writer agent section)
- [ ] Update all phase transition checkpoints:
  - Save after Phase 3 (Implementation) completes
  - Save after Phase 4 (Testing) completes
  - Skip checkpoint for Phase 5 (Debug) - conditional phase
  - Skip checkpoint for Phase 6 (Documentation) - final phase

**Testing**:
```bash
# Full workflow with simulated transient failures
/supervise "implement user authentication with JWT" --test-mode

# Test matrix:
# 1. Research agent timeout → auto-retry → success
# 2. Planning agent file lock → auto-retry → success
# 3. Implementation agent network error → auto-retry → success
# 4. Testing agent connection timeout → auto-retry → success
# 5. Debug agent (if triggered) timeout → auto-retry → success
# 6. Documentation agent timeout → auto-retry → success

# Expected:
# - All transient failures auto-recover
# - No user prompts throughout workflow
# - PROGRESS markers at each phase
# - Checkpoints saved at phase boundaries
# - Workflow completes successfully

# Resume test after interruption at Phase 3
# Kill workflow during implementation
# Re-run same command
# Expected: Resumes at Phase 3, skips Phases 0-2
```

**Files Modified**:
- `.claude/commands/supervise.md:796-1406` (Phases 2-6 sections)

**Success Criteria**:
- [ ] All 7 phases support single-retry auto-recovery
- [ ] Checkpoints saved after Phases 1-4 completion
- [ ] Permanent errors in any phase still fail-fast
- [ ] Full workflow resilient to transient failures
- [ ] Resume capability works from any phase boundary

---

### Phase 5: Documentation, Testing, and /orchestrate Deprecation Prep

**Objective**: Document changes, test edge cases, and prepare /orchestrate deprecation notice

**Complexity**: Low

**MANDATORY REQUIREMENTS**:
- All 47 recovery tests MUST pass
- Performance overhead MUST be <5% vs baseline /supervise
- Documentation MUST include all new features (auto-recovery, error reporting, checkpoints, partial failures)
- Backup of original supervise.md MUST be verified and documented

**Tasks**:
- [ ] **MUST** update supervise.md header documentation (lines 1-165):
  - Add "Auto-Recovery" section describing transient error handling
  - Add "Enhanced Error Reporting" section describing location extraction, error types, recovery suggestions
  - Add "Partial Failure Handling" section for research phase
  - Document checkpoint resume behavior
  - Add PROGRESS marker format documentation
  - Update "Performance Metrics" to include recovery rate targets
- [ ] Update supervise.md success criteria (lines 1477-1505):
  - Add recovery success criteria: "Auto-recovery from transient failures"
  - Add checkpoint criteria: "Resume from phase boundaries"
  - Update file creation rate: "100% with auto-recovery" (not "100% first attempt")
- [ ] Create test script: `.claude/specs/076_orchestrate_supervise_comparison/scripts/test_supervise_recovery.sh`
  - Simulate transient failures (timeout, file lock, network error)
  - Test checkpoint save/resume at each phase boundary
  - Validate error classification (transient vs permanent)
  - Test enhanced error reporting (location extraction, error type detection, suggestions)
  - Test partial research failure handling (2/4, 3/4, 1/4 success rates)
  - Verify progress markers emitted
  - Measure recovery overhead (<5% time increase)
- [ ] **REMOVED**: No changes to /orchestrate (outside scope of this plan)
- [ ] Document that /orchestrate deprecation is a separate decision/plan
- [ ] Run comparison testing: Execute same workflows with /orchestrate and /supervise
  - Compare completion rates
  - Compare error handling behavior
  - Compare user experience (interruptions, clarity)
  - Validate /supervise meets production requirements

**Testing**:
```bash
# Comprehensive recovery test suite
bash .claude/specs/076_orchestrate_supervise_comparison/scripts/test_supervise_recovery.sh

# Test cases:
# 1. Transient error recovery in each phase (7 tests)
# 2. Permanent error fail-fast in each phase (7 tests)
# 3. Enhanced error reporting (location, type, suggestions) (7 tests)
# 4. Partial research failure handling (3 tests: 2/4, 3/4, 1/4)
# 5. Checkpoint save at each boundary (4 tests)
# 6. Resume from each checkpoint (4 tests)
# 7. Invalid checkpoint handling (1 test)
# 8. Progress marker emission (7 tests)
# 9. Error logging (7 tests)

# Expected: 47/47 tests pass (was 37, added 10 for enhanced error reporting)

# Optional: Parallel comparison test (manual testing, not automated)
# Can manually run same workflow with both commands if desired
# /orchestrate "implement OAuth2 authentication"
# /supervise "implement OAuth2 authentication"

# Manual comparison points:
# - Completion time
# - Artifacts created
# - Error handling behavior
# - User experience (interruptions, clarity)
```

**Files Modified**:
- `.claude/commands/supervise.md:1-165` (header documentation)
- `.claude/commands/supervise.md:1477-1505` (success criteria)
- `scripts/test_supervise_recovery.sh` (new test script)

**NOTE**: No changes to /orchestrate.md (deprecation is separate decision)

**Success Criteria**:
- [ ] Documentation complete and accurate
- [ ] All 47 recovery tests pass (was 37, added 10 for enhanced error reporting)
- [ ] /supervise meets production-ready robustness standards
- [ ] Performance overhead < 5% vs baseline /supervise
- [ ] Original supervise.md backup verified and accessible for rollback

---

## Testing Strategy

### Unit Testing (Per-Phase)
- Verify error classification wrapper correctness
- Test verify_and_retry with mock agents
- Validate checkpoint save/load functions
- Test auto-resume logic with various checkpoint states

### Integration Testing (Cross-Phase)
- Full workflow execution with simulated transient failures
- Checkpoint resume from each phase boundary
- Error logging verification
- Progress marker emission validation

### Regression Testing (Existing Behavior)
- Ensure permanent errors still fail-fast
- Verify workflow scope detection unchanged
- Validate artifact paths and structure preserved
- Test conditional phase execution (research-only, debug-only, etc.)

### Comparison Testing (/orchestrate vs /supervise)
- Side-by-side execution of same workflows
- Completion rate comparison
- User experience evaluation
- Performance overhead measurement

## Documentation Requirements

### Command Documentation Updates
- [ ] supervise.md header: Add auto-recovery section
- [ ] supervise.md: Document checkpoint behavior
- [ ] supervise.md: Add PROGRESS marker format
- [ ] ~~orchestrate.md: Add deprecation notice~~ (REMOVED - outside scope)

### Migration Documentation
- [ ] Create migration guide for /orchestrate users
- [ ] Document differences in recovery behavior
- [ ] Provide workflow conversion examples

### Testing Documentation
- [ ] Test script with inline documentation
- [ ] Test results template
- [ ] Comparison testing methodology

## Dependencies

### Existing Utilities (No Changes Required)
- `.claude/lib/error-handling.sh` - Error classification and retry logic
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore functions
- `.claude/agents/*.md` - Agent behavioral guidelines (unchanged)

### New Files Created
- `scripts/test_supervise_recovery.sh` - Recovery test suite (within topic directory)

### Modified Files
- `.claude/commands/supervise.md` - Core implementation (ONLY file modified)

## Spec Updater Integration

**Integration Point**: Invoke spec-updater agent after implementation completes

**Required Actions**:
- [ ] **Artifact Management**: Ensure all test scripts in `scripts/` subdirectory
- [ ] **Cross-References**: Update references between this plan and research reports (already using relative paths)
- [ ] **Implementation Summary**: Create summary in `summaries/` directory after all phases complete
- [ ] **Gitignore Compliance**: Verify scripts/ and outputs/ are gitignored (plans/ already compliant)
- [ ] **Topic Organization**: All artifacts remain in topic 076 directory structure
- [ ] **Cleanup**: Remove temporary outputs/ and scripts/ files after workflow completion (0-day retention)

**Spec Updater Checklist** (execute after Phase 5 completion):
```bash
# 1. Verify topic directory structure
ls -la specs/076_orchestrate_supervise_comparison/
# Expected: plans/, reports/, summaries/, debug/, scripts/, outputs/, artifacts/, backups/

# 2. Create implementation summary
specs/076_orchestrate_supervise_comparison/summaries/001_supervise_autorecovery_implementation.md

# 3. Update cross-references
# Plan → Reports: Already using ../reports/ relative paths
# Summary → Plan: Link to this plan file
# Summary → Modified Files: .claude/commands/supervise.md

# 4. Clean temporary artifacts
rm -rf specs/076_orchestrate_supervise_comparison/outputs/*
# Note: Keep scripts/test_supervise_recovery.sh (part of deliverable)

# 5. Verify gitignore compliance
# Gitignored: plans/, reports/, summaries/, scripts/, outputs/, artifacts/, backups/
# Committed: debug/ (no debug reports created in this workflow)
```

## Notes

### Design Decisions

**Why Single Retry (Not 3x Like /orchestrate)**:
- /orchestrate's 3-tier retry was designed for production resilience at the cost of complexity
- Single retry handles 95% of transient failures (file locks, network hiccups)
- Preserves /supervise's fail-fast philosophy for real errors
- Minimal overhead vs /orchestrate's retry infrastructure

**Why Phase-Boundary Checkpoints (Not Per-Agent)**:
- /supervise workflows are shorter than /orchestrate (research-and-plan scope common)
- Phase-level granularity sufficient for most interruptions
- Per-agent checkpoints add complexity without significant benefit
- Maintains stateless design philosophy within each phase

**Why No User Prompts for Recovery**:
- Goal is seamless execution without interruptions
- Transient errors don't require user decision (auto-retry safe)
- Permanent errors provide clear error message for manual retry
- Checkpoint resume is always safe (validates phase/artifacts exist)

**Why PROGRESS Markers (Not TodoWrite)**:
- TodoWrite adds overhead for initialization and tracking
- PROGRESS markers provide visibility without state management
- Simpler implementation (emit_progress helper vs full TodoWrite integration)
- Aligns with /supervise's minimalist philosophy

### /orchestrate Comparison and Future Decisions

**Scope Note**: This plan implements auto-recovery for /supervise only. Any decisions about /orchestrate deprecation are outside the scope of this implementation.

**Optional Testing** (not required for completion):
1. Manually run same workflows with /orchestrate and /supervise
2. Compare completion rates and error handling
3. Gather user feedback on experience differences
4. Document findings for future decision-making

**Future Considerations** (separate from this plan):
- Whether to deprecate /orchestrate
- Migration timeline (if deprecation decided)
- Documentation updates
- User notification process

**This Plan's Deliverable**: Production-ready /supervise with auto-recovery, regardless of /orchestrate's future.

### Post-Implementation Enhancements (Optional)

**If Testing Reveals Need**:
- Add `--sequential` flag for disabling parallel execution (currently always parallel)
- Implement `--max-retries N` flag for custom retry limits (default: 1)
- Add `--verbose` flag for detailed progress output
- Create dashboard visualization for multi-phase progress

**If Long Workflows Common**:
- Upgrade checkpoint schema to v1.1 with wave execution tracking
- Add per-wave checkpoints for parallel phases
- Implement checkpoint compression for large artifacts

**If Error Analysis Needed**:
- Create error analytics dashboard
- Aggregate error logs for pattern detection
- Add error notification system for critical failures

### Metrics to Track

**Recovery Effectiveness**:
- Transient error recovery rate (target: >95%)
- Permanent error fail-fast rate (target: 100%)
- False positive retries (permanent error retried - target: <5%)

**Performance Overhead**:
- Time added by error classification (<1% per agent)
- Time added by checkpoint saves (<2% per phase)
- Total overhead (target: <5% vs baseline /supervise)

**User Experience**:
- Workflows completed without user intervention (target: >90%)
- Average interruptions per workflow (target: <0.1)
- User-reported robustness improvement vs /orchestrate

### Success Validation Criteria

**Before Declaring Implementation Complete**:
- [ ] /supervise auto-recovery rate ≥95% for transient failures
- [ ] /supervise completion rate meets production standards
- [ ] Performance overhead <5% vs baseline /supervise
- [ ] Zero regressions in fail-fast behavior for permanent errors
- [ ] All documentation complete
- [ ] 30+ successful test workflows with enhanced /supervise
- [ ] Original supervise.md backup verified for safe rollback capability

## Appendix: Error Classification Reference

### Transient Errors (Auto-Retry Once)
- Connection timeout
- Network unreachable
- Temporary file lock
- Rate limit exceeded (API throttling)
- Resource temporarily unavailable

### Permanent Errors (Fail-Fast)
- Syntax error in code
- Missing dependency
- Invalid configuration
- File not found (bad path)
- Permission denied (actual permission issue)

### Classification Source
See `.claude/lib/error-handling.sh:20-42` for complete classification logic.

## Revision History

### 2025-10-23 - Revision 3: Scope Refinement and Backup Safety
**Changes**: Removed all /orchestrate modifications and added Phase -1 for /supervise backup creation
**Reason**: User requested to avoid any changes to /orchestrate and ensure safe rollback capability by backing up /supervise before modifications
**Scope Refinement**:
- **REMOVED**: All tasks related to modifying /orchestrate.md
- **REMOVED**: /orchestrate deprecation notice tasks
- **REMOVED**: Migration timeline from /orchestrate
- **ADDED**: Phase -1 for creating timestamped backup of supervise.md
- **CHANGED**: Success criteria to focus on /supervise robustness (not /orchestrate deprecation)
- **CHANGED**: "Migration Path" section to "Comparison and Future Decisions" (informational only)

**Phase -1 Details**:
- Create timestamped backup: `backups/supervise_YYYYMMDD_HHMMSS.md`
- Verify backup integrity (size match, diff verification)
- Document rollback instructions
- MUST complete before any modifications to supervise.md

**Modified Sections**:
1. Metadata: Updated scope to exclude /orchestrate, increased phase count to 6
2. Success Criteria: Removed /orchestrate deprecation requirement
3. Phase 5 Tasks: Removed /orchestrate.md modification tasks
4. Dependencies: Changed to "ONLY file modified" for supervise.md
5. Notes: Replaced "Migration Path" with "Comparison and Future Decisions"
6. Validation: Removed /orchestrate comparison requirements

**Preserved Functionality**:
- All auto-recovery features for /supervise unchanged
- All enhanced error reporting unchanged
- All checkpoint and progress tracking unchanged
- Test suite unchanged (47 tests)

**New Safety Features**:
- Timestamped backup ensures rollback capability
- Backup verification prevents data loss
- Clear rollback instructions provided

### 2025-10-23 - Revision 2: Standards Compliance
**Changes**: Updated plan for full compliance with `.claude/docs/` standards
**Reason**: Ensure plan follows directory protocols, spec updater integration, and imperative language patterns
**Standards Applied**:
- Topic-based directory organization (already compliant - in specs/076_orchestrate_supervise_comparison/)
- Spec updater integration checklist added
- Relative path references for reports (../reports/ instead of absolute)
- Imperative language (MUST/SHALL) for all mandatory requirements
- Metadata fields for topic directory and topic number

**Compliance Updates**:
1. **Metadata Section**: Added topic_directory, topic_number, changed research reports to relative paths
2. **Spec Updater Integration**: Added dedicated section with artifact management checklist
3. **Imperative Language**: Added "MANDATORY REQUIREMENTS" sections to all phases with MUST/SHALL language
4. **File References**: Test script path changed to relative (scripts/ instead of .claude/specs/076.../scripts/)

**Standards Alignment**:
- ✅ Topic-based structure: specs/{NNN_topic}/plans/
- ✅ Gitignore compliance: plans/ are gitignored, debug/ committed
- ✅ Spec updater checklist: Execute after Phase 5
- ✅ Imperative language: MUST/SHALL for critical tasks
- ✅ Relative references: ../reports/ for cross-topic links

### 2025-10-23 - Revision 1: Enhanced Error Reporting
**Changes**: Added Phase 0.5 for enhanced error reporting infrastructure
**Reason**: Integrate minimal error recovery infrastructure recommended in conversation for improved UX without significant overhead
**Modified Phases**:
- Added Phase 0.5: Enhanced Error Reporting Infrastructure
- Updated Phase 1: Integrated enhanced error reporting and partial failure handling
- Renumbered Phase 4 → Phase 5
- Updated test count from 37 to 47 tests

**Features Added**:
1. **Error Location Extraction** (~15 lines) - Parses file:line from errors
2. **Specific Error Type Detection** (~30 lines) - 4 categories: timeout, syntax_error, missing_dependency, unknown
3. **Recovery Suggestions** (~25 lines) - Context-specific actionable guidance
4. **Partial Research Failure Handling** (~40 lines) - Continue if ≥50% research agents succeed

**Total Impact**: ~110 lines added for significant UX improvement with minimal overhead

**Benefits**:
- Users get precise error locations (file:line) on failures
- Better error messages (specific types vs generic "permanent error")
- Actionable recovery suggestions displayed on terminal failures
- Research phase more resilient (can proceed with 2/4 or 3/4 successful reports)

**Preserved Philosophy**:
- Still fail-fast for permanent errors (with better error messages)
- No user prompts during execution (suggestions shown after termination)
- Minimal complexity increase (<5% overhead)
- Maintains /supervise's clean architecture
