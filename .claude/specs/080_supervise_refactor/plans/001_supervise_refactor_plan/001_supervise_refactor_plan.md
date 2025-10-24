# Implementation Plan: /supervise Command Refactor

## Metadata

- **Plan Type**: Refactoring (code quality improvement)
- **Complexity**: 6/10 (systematic refactoring with standards compliance)
- **Estimated Total Time**: 8-10 hours
- **Risk Level**: Medium (active command, must maintain functionality)
- **Dependencies**: Research report 001_supervise_bloat_analysis.md
- **Created**: 2025-10-23

## Objective

Reduce `/supervise` command bloat from 2,526 lines to 1,800-2,000 lines (~30% reduction) while improving standards conformance from 57% to 90%+ imperative language ratio and achieving full Command Architecture Standards compliance.

**Success Criteria**:
- [ ] File size: 1,800-2,000 lines (target: 1,900)
- [ ] Imperative language ratio: ≥90%
- [ ] All Standard 0 and 0.5 enforcement patterns applied
- [ ] All utility functions sourced from libraries (not inline)
- [ ] All tests pass with refactored command
- [ ] Execution behavior unchanged (functional equivalence)

## Plan Structure

- **Level**: 1 (main plan with expanded phases)
- **Phases**: 7 (Phases 0-6)
- **Expanded Phases**: [1, 4]
- **Parallel Opportunities**: Phases 1-2 can run in parallel (library extraction + doc reduction)
- **Critical Path**: Phase 3 → Phase 4 → Phase 5 (imperative → templates → validation)

## Phases

### Phase 0: Pre-Refactor Preparation [COMPLETED]

**Objective**: Create backup, establish baseline metrics, and prepare test cases.

**Duration**: 1 hour

**Tasks**:
1. Create backup of current supervise.md
   ```bash
   cp .claude/commands/supervise.md .claude/commands/supervise.md.backup-pre-refactor
   ```

2. Run baseline audit for imperative language ratio
   ```bash
   bash .claude/lib/audit-imperative-language.sh .claude/commands/supervise.md > baseline_audit.txt
   ```

3. Create test workflow scripts for validation:
   - `test_research_only.sh` - Test "research authentication patterns"
   - `test_research_and_plan.sh` - Test "research...to create plan"
   - `test_full_implementation.sh` - Test "implement oauth feature"
   - `test_debug_only.sh` - Test "fix token refresh bug"

4. Document current execution behavior (reference output)
   ```bash
   # Run each test and capture output for comparison
   /supervise "research authentication patterns" > test_research_only_baseline.txt
   ```

**Verification**:
- [x] Backup file exists with 2,168 lines (current size)
- [x] Baseline audit shows 90/100 score (90% imperative ratio - better than expected!)
- [x] 4 test scripts created (manual execution required via Claude Code)
- [x] Baseline metrics established

**Complexity**: 2/10 (straightforward preparation)

---

### Phase 1: Library Extraction and Sourcing [COMPLETED]

**Objective**: Extract 750 lines of inline bash utility functions to library files and replace with source statements.

**Status**: COMPLETED

**Complexity**: 6/10 (actual complexity lower than estimated)

**Summary**: Successfully extracted workflow detection functions to workflow-detection.sh library (130 lines), added backward compatibility aliases to error-handling.sh, added emit_progress() to unified-logger.sh, and replaced 465 lines of inline functions with source statements and reference tables. Achieved 309-line reduction (14.2%) with 100% test pass rate.

**Completion Summary**: See [Phase 1 Completion Summary](../../phase_1_completion_summary.md)

For detailed tasks and implementation, see [Phase 1 Details](phase_1_library_extraction.md)

---

### Phase 2: Documentation Reduction and Referencing [COMPLETED]

**Objective**: Replace 400 lines of redundant documentation with concise references to pattern docs.

**Duration**: 1.5 hours (Actual: ~1 hour)

**Tasks**:

1. **Condense Auto-Recovery section** (lines 40-140 → 20-40):
   ```markdown
   # Before (100 lines):
   ## Auto-Recovery

   This command includes minimal auto-recovery capabilities...

   ### Recovery Philosophy

   **Auto-recover from transient failures**:
   - Network timeouts
   - Temporary file locks
   ...
   [90 more lines of detailed explanation]

   # After (20 lines):
   ## Auto-Recovery

   This command implements verification-fallback pattern with single-retry for transient errors.

   **Key Behaviors**:
   - Transient errors (timeouts, file locks): Single retry after 1s delay
   - Permanent errors (syntax, dependencies): Fail-fast with diagnostics
   - Partial research failure: Continue if ≥50% agents succeed

   **See**: [Verification-Fallback Pattern](../docs/concepts/patterns/verification-fallback.md)
   **See**: [Error Handling Library](../lib/error-handling.sh) - Implementation details
   ```
   **Savings**: ~80 lines

2. **Condense Enhanced Error Reporting** (lines 140-240 → 20-30):
   ```markdown
   # Before (100 lines):
   ## Enhanced Error Reporting

   When workflow failures occur, the command provides detailed diagnostic information:

   ### Error Location Extraction
   [detailed explanation]

   ### Specific Error Types
   [detailed categorization]

   ### Recovery Suggestions
   [detailed suggestion generation]

   # After (10 lines):
   ## Enhanced Error Reporting

   Failed operations receive enhanced diagnostics via error-handling.sh:
   - Error location extraction (file:line parsing)
   - Error type categorization (timeout, syntax, dependency, unknown)
   - Context-specific recovery suggestions

   **See**: [Error Handling Library](../lib/error-handling.sh) - Complete error reporting implementation
   ```
   **Savings**: ~90 lines

3. **Condense Progress Markers** (lines 240-340 → 20-30):
   ```markdown
   # Before (100 lines):
   ## Progress Markers

   ### Format

   ```
   PROGRESS: [Phase N] - [action]
   ```

   ### Examples
   [20 examples]

   ### Purpose
   [detailed explanation]

   # After (10 lines):
   ## Progress Markers

   Emit silent progress markers at phase boundaries:
   ```
   PROGRESS: [Phase N] - [action]
   ```

   Example: `PROGRESS: [Phase 1] - Research complete (4/4 succeeded)`
   ```
   **Savings**: ~90 lines

4. **Condense Orchestrate Comparison** (lines 30-40 → 10-15):
   ```markdown
   # Before (200 lines):
   ### Relationship with /orchestrate

   This command (`/supervise`) and `/orchestrate` serve different purposes...
   [extensive comparison]

   # After (50 lines):
   ### Relationship with /orchestrate

   Complementary to `/orchestrate`:
   - `/supervise`: Research-and-plan workflows (15-25% faster, minimal scope)
   - `/orchestrate`: Full implementation (recursive supervision, wave-based)

   **See**: [Command Comparison](../docs/reference/command-comparison.md)
   ```
   **Savings**: ~150 lines

5. **Create referenced documentation** (new files):
   - `.claude/docs/reference/command-comparison.md` - Full supervise vs orchestrate analysis

**Verification**:
- [x] Auto-recovery reduced to ~11 lines with pattern reference (from 29 lines, saved 18)
- [x] Error reporting reduced to ~8 lines with library reference (from 54 lines, saved 46)
- [x] Progress markers reduced to ~8 lines with example (from 22 lines, saved 14)
- [x] Checkpoint Resume condensed with pattern reference (from 43 lines, saved 36)
- [x] Partial Failure Handling condensed (from 17 lines, saved 14)
- [x] All referenced pattern docs verified to exist (verification-fallback.md, checkpoint-recovery.md, error-handling.sh)
- [ ] Test scripts pass (requires manual execution - tests created in Phase 0)

**Note**: Orchestrate comparison section was not found in current file (may have been removed in earlier work or not present as expected).

**Complexity**: 3/10 (mostly text editing and referencing)

**Actual Lines Saved**: ~125 lines (1859 → 1734)

---

### Phase 3: Imperative Language Strengthening

**Objective**: Transform weak language to imperative language, achieving 90%+ imperative ratio.

**Duration**: 2 hours

**Tasks**:

1. **Audit current imperative ratio** (baseline):
   ```bash
   bash .claude/lib/audit-imperative-language.sh .claude/commands/supervise.md
   # Expected: ~57% imperative ratio
   ```

2. **Apply systematic transformations** per Imperative Language Guide:

   **Pattern A: Descriptive → Imperative (Phase sections)**
   ```markdown
   # Before:
   "Invoke multiple research-specialist agents for parallel research"

   # After:
   "**YOU MUST invoke** multiple research-specialist agents in parallel"
   ```

   **Pattern B: Add EXECUTE NOW markers** (bash blocks)
   ```markdown
   # Before:
   ```bash
   WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
   ```

   # After:
   **EXECUTE NOW - Detect Workflow Scope**

   ```bash
   WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
   ```
   ```

   **Pattern C: Add MANDATORY VERIFICATION markers**
   ```markdown
   # Before:
   "Verify report file created successfully"

   # After:
   **MANDATORY VERIFICATION - Report File Existence**

   **YOU MUST verify** report file exists using this exact verification:

   ```bash
   if [ ! -f "$REPORT_PATH" ]; then
     echo "❌ CRITICAL ERROR: File not created"
     exit 1
   fi
   ```
   ```

3. **Target sections for transformation**:
   - Phase 0: Project Location (15 instances)
   - Phase 1: Research (25 instances)
   - Phase 2: Planning (20 instances)
   - Phase 3: Implementation (15 instances)
   - Phase 4: Testing (10 instances)
   - Phase 5: Debug (15 instances)
   - Phase 6: Documentation (10 instances)

4. **Re-audit imperative ratio** (target verification):
   ```bash
   bash .claude/lib/audit-imperative-language.sh .claude/commands/supervise.md
   # Expected: ≥90% imperative ratio
   ```

**Verification**:
- [ ] Imperative ratio ≥90% (audit tool confirms)
- [ ] All critical bash blocks have "EXECUTE NOW" markers
- [ ] All file verifications have "MANDATORY VERIFICATION" markers
- [ ] All agent invocations use "YOU MUST" language
- [ ] Test scripts pass (no functional change)

**Complexity**: 5/10 (systematic but requires careful judgment)

**Estimated Lines Added**: ~100 lines (markers and enforcement language)

---

### Phase 4: Agent Prompt Template Enhancement (Standard 0.5) (Very High Complexity)

**Objective**: Apply Standard 0.5 enforcement patterns to all 6 agent prompt templates.

**Status**: PENDING

**Complexity**: 8/10 (very high complexity due to deep Standard 0.5 understanding and agent behavior impact)

**Summary**: Systematically enhance all 6 embedded agent templates (research, planning, implementation, testing, debug, documentation) with Standard 0.5 enforcement patterns including PRIMARY OBLIGATION language, sequential step dependencies, consequence statements, and fallback mechanisms. Each template receives 7 enforcement markers totaling ~180 lines of additions with architectural impact on agent contract enforcement.

For detailed tasks and implementation, see [Phase 4 Details](phase_4_agent_template_enhancement.md)

---

### Phase 5: Structural Annotations and Verification Consistency

**Objective**: Add structural annotations and ensure consistent verification checkpoint format.

**Duration**: 1 hour

**Tasks**:

1. **Add structural annotations** to all major sections:
   ```markdown
   ## Shared Utility Functions
   [EXECUTION-CRITICAL: Source statements for required libraries - cannot be moved to external files]

   ## Phase 0: Project Location and Path Pre-Calculation
   [EXECUTION-CRITICAL: Path calculation before agent invocations - inline bash required]

   ## Phase 1: Research
   [EXECUTION-CRITICAL: Agent invocation patterns and verification - templates must be inline]

   ## Workflow Overview
   [REFERENCE-OK: Can be supplemented with external orchestration pattern docs]
   ```

2. **Standardize verification checkpoint format** across all phases:
   ```markdown
   **MANDATORY VERIFICATION - [Artifact Type] File Existence**

   **YOU MUST verify** [artifact] exists using this exact verification:

   ```bash
   if [ ! -f "$FILE_PATH" ]; then
     echo "❌ CRITICAL ERROR: [Artifact] not created at $FILE_PATH"

     # FALLBACK MECHANISM
     echo "Executing fallback creation..."
     [fallback code]

     # Re-verification
     if [ ! -f "$FILE_PATH" ]; then
       echo "❌ FATAL: Fallback failed"
       exit 1
     fi
   fi

   echo "✅ VERIFIED: [Artifact] exists at $FILE_PATH"
   ```

   **YOU MUST NOT** proceed until verification passes.
   ```

3. **Apply consistent format** to 7 verification checkpoints:
   - Phase 0: Topic directory creation verification
   - Phase 1: Research reports verification (4 agents)
   - Phase 1: Research overview verification
   - Phase 2: Plan file verification
   - Phase 3: Implementation artifacts verification
   - Phase 5: Debug report verification
   - Phase 6: Summary file verification

4. **Add defensive verification markers**:
   ```markdown
   **VERIFICATION REQUIRED**: [specific check]
   **GUARANTEE REQUIRED**: [specific outcome]
   **CHECKPOINT REQUIREMENT**: [status reporting]
   ```

**Verification**:
- [ ] All major sections have structural annotations
- [ ] All 7 verification checkpoints use consistent format
- [ ] All verification blocks include fallback mechanisms
- [ ] All verification blocks include re-verification after fallback
- [ ] Test scripts pass with enhanced verifications

**Complexity**: 3/10 (systematic application of consistent format)

**Estimated Lines Added**: ~50 lines (annotations and verification consistency)

---

### Phase 6: Validation and Metrics

**Objective**: Verify refactored command meets all success criteria and maintains functional equivalence.

**Duration**: 1.5 hours

**Tasks**:

1. **Run all test scripts and compare outputs**:
   ```bash
   # Test research-only workflow
   /supervise "research authentication patterns" > test_research_only_refactored.txt
   diff test_research_only_baseline.txt test_research_only_refactored.txt

   # Test research-and-plan workflow
   /supervise "research oauth to create plan" > test_research_plan_refactored.txt
   diff test_research_plan_baseline.txt test_research_plan_refactored.txt

   # Test full-implementation workflow
   /supervise "implement oauth feature" > test_implement_refactored.txt
   diff test_implement_baseline.txt test_implement_refactored.txt

   # Test debug-only workflow
   /supervise "fix token refresh bug" > test_debug_refactored.txt
   diff test_debug_baseline.txt test_debug_refactored.txt
   ```

2. **Measure success criteria**:
   ```bash
   # File size
   wc -l .claude/commands/supervise.md
   # Expected: 1,800-2,000 lines (target: 1,900)

   # Imperative language ratio
   bash .claude/lib/audit-imperative-language.sh .claude/commands/supervise.md
   # Expected: ≥90%

   # Standard 0 compliance (manual checklist)
   # Expected: All items checked

   # Standard 0.5 compliance (agent scoring rubric)
   # Expected: 95+/100 for all 6 agent templates
   ```

3. **Run comprehensive validation suite**:
   ```bash
   # Standard validation
   bash .claude/tests/validate_behavioral_injection.sh .claude/commands/supervise.md
   bash .claude/tests/validate_verification_fallback.sh .claude/commands/supervise.md
   bash .claude/tests/validate_forward_message.sh .claude/commands/supervise.md

   # Custom supervise validation
   bash .claude/tests/test_supervise_workflow_detection.sh
   bash .claude/tests/test_supervise_auto_recovery.sh
   ```

4. **Create refactor summary document**:
   ```markdown
   # /supervise Refactor Summary

   ## Metrics

   | Metric | Before | After | Change |
   |--------|--------|-------|--------|
   | File size (lines) | 2,526 | 1,XXX | -XX% |
   | Imperative ratio | 57% | XX% | +XX% |
   | Inline bash (lines) | 800 | 50 | -94% |
   | Documentation (lines) | 500 | 100 | -80% |

   ## Standards Compliance

   | Standard | Before | After |
   |----------|--------|-------|
   | Standard 0 | Partial | ✅ Full |
   | Standard 0.5 | Missing | ✅ Full |
   | Standard 1 | Violated | ✅ Compliant |
   | Standard 2 | Violated | ✅ Compliant |

   ## Test Results

   - [x] All 4 workflow tests pass
   - [x] Functional equivalence confirmed (diff analysis)
   - [x] File creation rate: 100% (10/10 test runs)
   - [x] Auto-recovery working (simulated transient failures)
   ```

5. **Commit refactored command**:
   ```bash
   git add .claude/commands/supervise.md
   git add .claude/lib/workflow-detection.sh
   git add .claude/docs/reference/command-comparison.md
   git commit -m "refactor(supervise): Reduce bloat and improve standards conformance

   - Reduce from 2,526 to ~1,900 lines (25% reduction)
   - Extract 750 lines of bash utilities to libraries
   - Replace 400 lines of docs with pattern references
   - Improve imperative ratio from 57% to 95%
   - Apply Standard 0.5 enforcement to all agent templates
   - Achieve full Command Architecture Standards compliance

   Tests: All workflow tests pass with functional equivalence
   Standards: 95%+ imperative ratio, Standard 0/0.5 compliant"
   ```

**Verification**:
- [ ] All 4 workflow tests pass
- [ ] File size: 1,800-2,000 lines (target: 1,900)
- [ ] Imperative ratio: ≥90%
- [ ] All utility functions sourced (not inline)
- [ ] All standards validation scripts pass
- [ ] Functional equivalence confirmed (diff analysis)
- [ ] Refactor summary document created
- [ ] Commit created with descriptive message

**Complexity**: 4/10 (comprehensive testing and validation)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking functional behavior | Medium | High | Comprehensive test suite, diff comparison, backup |
| Library functions missing features | Low | Medium | Verify libraries before extraction, add if needed |
| Over-reduction of inline examples | Low | Medium | Retain minimal examples for clarity |
| Test scripts incomplete coverage | Medium | Low | Create 4 workflow-type tests covering all scopes |
| Imperative language too aggressive | Low | Low | Follow guide transformation rules strictly |

## Testing Strategy

### Unit Testing
- Test each library function extracted (workflow-detection.sh)
- Verify source statements load correctly
- Test error classification and retry logic

### Integration Testing
- Test complete workflows with refactored command:
  - Research-only workflow
  - Research-and-plan workflow
  - Full-implementation workflow
  - Debug-only workflow

### Regression Testing
- Compare outputs before/after refactor (diff analysis)
- Verify file creation rates unchanged (100%)
- Confirm auto-recovery still functions

### Standards Validation
- Run all pattern validation scripts
- Audit imperative language ratio
- Check Standard 0/0.5 compliance

## Rollback Plan

If refactor introduces breaking changes:

1. **Immediate rollback**:
   ```bash
   cp .claude/commands/supervise.md.backup-pre-refactor .claude/commands/supervise.md
   git checkout HEAD -- .claude/commands/supervise.md
   ```

2. **Identify broken phase**:
   - Review test outputs to find first failure
   - Isolate phase causing regression

3. **Incremental fix**:
   - Restore only problematic section from backup
   - Re-apply refactor to that section more conservatively
   - Re-test

4. **Document issues**:
   - Add to refactor summary: "Rollback required for Phase X"
   - Create follow-up issue for safe incremental fix

## Success Metrics

### Quantitative
- [ ] File size reduced by 25-30%: 2,526 → 1,800-2,000 lines
- [ ] Imperative ratio increased to ≥90% (from 57%)
- [ ] Inline bash reduced by 94%: 800 → 50 lines
- [ ] Documentation reduced by 80%: 500 → 100 lines
- [ ] All 4 workflow tests pass (100% success rate)

### Qualitative
- [ ] Command Architecture Standards fully compliant
- [ ] Standard 0.5 agent templates score 95+/100
- [ ] Code readability improved (subjective assessment)
- [ ] Maintainability improved (less duplication)
- [ ] Execution clarity improved (stronger enforcement)

## Follow-Up Tasks

After refactor completion:

1. Update related documentation:
   - `.claude/docs/reference/command-reference.md` - Update supervise entry
   - `CLAUDE.md` - Update project commands section if needed

2. Create example usage guide:
   - `.claude/docs/guides/supervise-usage-guide.md`
   - Include 4 workflow type examples

3. Share refactor patterns:
   - Document library extraction pattern for other commands
   - Share imperative language transformation approach

4. Consider applying same refactor to `/orchestrate`:
   - Analyze orchestrate.md for similar bloat
   - Create follow-up refactor plan if warranted

## Notes

- This refactor prioritizes **bloat removal** over feature addition
- Focus is on **standards conformance** without changing functionality
- **Functional equivalence** is critical success criterion
- **Testing coverage** ensures no regressions introduced
- **Rollback plan** provides safety net for production command
