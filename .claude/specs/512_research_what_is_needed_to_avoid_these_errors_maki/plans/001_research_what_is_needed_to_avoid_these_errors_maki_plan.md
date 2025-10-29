# /research Command Reliability Fix - Implementation Plan

## Metadata
- **Date**: 2025-10-28
- **Last Revised**: 2025-10-28
- **Feature**: Fix /research command bash syntax error and achieve full .claude/docs/ standards compliance
- **Scope**: Minimal changes to fix bash error + MANDATORY standards compliance (Standard 11, Verification-Fallback, Standard 0)
- **Estimated Phases**: 4
- **Estimated Hours**: 5.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 45.0
- **Research Reports**:
  - [001_bash_syntax_error_analysis.md](../reports/001_bash_syntax_error_analysis.md)
  - [002_research_command_architecture_analysis.md](../reports/002_research_command_architecture_analysis.md)
  - [003_documentation_standards_review.md](../reports/003_documentation_standards_review.md)

## Overview

The /research command currently fails with bash associative array syntax errors when attempting to iterate over subtopic arrays (Report 001). Additionally, it violates MANDATORY command architecture standards (Standard 11, Verification-Fallback Pattern, Standard 0) that are required per `.claude/docs/` specifications (Report 003). This plan implements the MINIMAL COMPLIANT set of changes to fix the bash error and achieve mandatory standards compliance without unnecessary complexity.

**Core Issues**:
1. **Bash syntax error** in STEP 2 (lines 155-196 of research.md) due to array iteration in single code block
2. **Standard 0 violation**: Missing "EXECUTE NOW" directives causing bash blocks to be interpreted as documentation
3. **Standard 11 violation**: Current delegation rate 0% (should be >90% per standards)
4. **Verification-Fallback violation**: Missing fallback file creation mechanism (only 33% of required pattern implemented)

**Revised Approach**: Fix bash error + achieve MANDATORY standards compliance. These are not optional improvements but required per active documentation standards (.claude/docs/reference/command_architecture_standards.md, last updated 2025-10-27). Focus on: fix bash error → enforce Standard 11 → implement full Verification-Fallback → validate compliance.

## Research Summary

**Key Findings from Research Reports**:

From **001_bash_syntax_error_analysis.md**:
- Root cause: Bash tool cannot handle `"${SUBTOPICS[@]}"` array iteration in single large code block
- Tool attempts to expand arrays during eval construction, resulting in malformed syntax
- Solution: Split code block at array iteration boundary (proven successful in second attempt)
- Minimal fix: Split lines 155-196 into two sequential bash invocations

From **002_research_command_architecture_analysis.md**:
- Missing STEP 0 library sourcing with verification (80+ line gap vs /coordinate)
- Path calculation redundancy (47 lines could be 10 lines via utility)
- NO recommendation to adopt complex patterns from /coordinate (904 vs 1836 lines)
- Focus on adding verification helpers only, not restructuring

From **003_documentation_standards_review.md**:
- Current compliance: 0/5 standards (0%)
- Critical violations: Standard 11 (agent invocation), Standard 0 (execution enforcement)
- Verification-Fallback pattern completely missing
- Fix priority: Standard 11 → Verification → Bash directives → Error messages
- Expected improvement: 0% → >90% delegation rate, 0% → 100% file creation

**Revised Approach Based on Standards Analysis**:
User requested "minimal changes" to ensure "full compliance with .claude/docs/ standards". Analysis reveals that several originally-deferred improvements are actually MANDATORY per active standards:
- Phase 1: Fix immediate bash syntax error + add EXECUTE NOW directives (Standard 0 compliance)
- Phase 2: Implement full Verification-Fallback pattern (MANDATORY for file-creation commands)
- Phase 3: Add path pre-calculation validation + error handling (Standard 0 completion)
- Phase 4: Validate Standard 11 compliance + test delegation rate (>90% target)
- DEFERRED (truly optional): Library consolidation, helper functions (these are optimizations, not compliance requirements)

## Success Criteria

**Functional Requirements**:
- [ ] Bash syntax error eliminated (no "syntax error near unexpected token" errors)
- [ ] /research command executes without fatal errors on test topics
- [ ] Path calculation completes successfully with absolute paths
- [ ] Manual testing confirms workflow completes end-to-end
- [ ] No regression in existing functionality

**Standards Compliance Requirements** (MANDATORY):
- [ ] Standard 0 compliance: All bash blocks have `**EXECUTE NOW**` directives (100% execution rate)
- [ ] Standard 11 compliance: Agent delegation rate >90% (measured via file creation success)
- [ ] Verification-Fallback compliance: 100% file creation via verification + fallback mechanism
- [ ] Path validation: All paths verified absolute before agent invocation
- [ ] Error handling: 5-component error messages for all failure modes

## Technical Design

**Architecture Preservation**:
- Keep existing 7-step structure (STEP 1-7)
- Keep existing inline path calculation (defer library consolidation)
- Keep existing agent invocation structure
- Keep existing metadata extraction pattern

**Minimal Changes**:

1. **Bash Code Block Split** (Phase 1)
   - Split STEP 2 bash block at array iteration boundary
   - First block: Directory creation + for loop iteration
   - Second block: Path verification
   - Pattern: Mirrors successful recovery pattern from lines 82-89 of error output

2. **Execution Enforcement** (Phase 2)
   - Add `**EXECUTE NOW**: USE the Bash tool` before each bash code block
   - Target: STEP 2 path calculation block (now 2 blocks after split)
   - No other directive changes (minimize scope)

3. **Basic Verification** (Phase 3)
   - Add simple file existence check after path calculation
   - Echo verification success message
   - Exit on failure (no complex fallback yet)
   - Pattern: Lightweight checkpoint, not full Verification-Fallback pattern

**What to Defer** (truly optional optimizations):
- Library consolidation for path calculation (Report 002 Rec 3 - optimization, not compliance)
- Verification helper function (Report 002 Rec 4 - DRY improvement, not compliance)
- STEP 0 library sourcing (Report 002 Rec 2 - fail-fast improvement, not critical)

**Rationale**: User requested "full compliance with .claude/docs/ standards" which means implementing MANDATORY requirements (Standard 11, Verification-Fallback, Standard 0, Error Handling) while deferring true optimizations (library consolidation, helper functions) that don't affect compliance.

## Implementation Phases

### Phase 1: Fix Bash Syntax Error + Add Standard 0 Enforcement
dependencies: []

**Objective**: Split the problematic bash code block to eliminate syntax error AND add EXECUTE NOW directives for Standard 0 compliance

**Complexity**: Low

**Tasks**:
- [x] Read current /research command file (file: /home/benjamin/.config/.claude/commands/research.md, lines 155-213)
- [x] Identify exact split point (after for loop completes, before verification loop)
- [x] Use Edit tool to split single bash block into two sequential blocks
  - First block ends after: `echo "RESEARCH_SUBDIR='$RESEARCH_SUBDIR'"`
  - Add closing ``` and new bash block opening ```bash
  - Second block starts with: `# Verify all paths are absolute`
- [x] Add EXECUTE NOW directive before first bash block:
  ```markdown
  **EXECUTE NOW**: USE the Bash tool to calculate report paths:
  ```
- [x] Add EXECUTE NOW directive before second bash block:
  ```markdown
  **EXECUTE NOW**: USE the Bash tool to verify all paths:
  ```
- [x] Add path validation after second bash block executes:
  ```bash
  # Verify all paths are absolute
  [[ "$RESEARCH_SUBDIR" = /* ]] || { echo "ERROR: Path not absolute: $RESEARCH_SUBDIR"; exit 1; }
  [ -d "$RESEARCH_SUBDIR" ] || { echo "ERROR: Directory missing: $RESEARCH_SUBDIR"; exit 1; }
  ```
- [x] Verify edit syntax is correct (read back edited section)
- [x] Preserve all existing logic (no functionality changes)

**Testing**:
```bash
# Verify syntax of edited file
bash -n .claude/commands/research.md 2>&1 | grep -i "syntax error"
# Should return no errors

# Check split was applied correctly
grep -A2 "RESEARCH_SUBDIR=" .claude/commands/research.md | grep '```'
# Should show closing fence after variable echo

# Check EXECUTE NOW directives present
grep -c "EXECUTE NOW.*USE the Bash tool" .claude/commands/research.md
# Should find 2 matches in STEP 2

# Check path validation present
grep -c "ERROR: Path not absolute" .claude/commands/research.md
# Should find 1 match
```

**Expected Duration**: 45 minutes (was 30 min, +15 for Standard 0 additions)

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Bash syntax error eliminated in edited file
- [ ] EXECUTE NOW directives added (Standard 0 compliance)
- [ ] Path validation added with error messages
- [ ] Split point preserves all existing logic
- [ ] No unintended changes to other sections
- [ ] Git commit created: `feat(512): complete Phase 1 - Fix Bash Syntax + Standard 0`
- [ ] Update this plan file with phase completion status

### Phase 2: Implement Full Verification-Fallback Pattern
dependencies: [1]

**Objective**: Implement MANDATORY Verification-Fallback pattern for 100% file creation reliability (required per .claude/docs/concepts/patterns/verification-fallback.md)

**Complexity**: Medium

**Context**: Report 003 identified that current plan implements only 33% of the Verification-Fallback pattern (verification only, no fallback mechanism). Full pattern is MANDATORY for all file-creation commands per standards.

**Tasks**:
- [x] Locate STEP 4 section (after agent invocations complete) in /research command
- [x] Add concise verification checkpoint after each agent completes:
  ```bash
  # Verify research report (concise format: single line on success)
  echo -n "Verifying report ${i}/${RESEARCH_COMPLEXITY}: "

  REPORT_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    echo "✓ ($FILE_SIZE bytes)"
  else
    echo ""
    echo "✗ VERIFICATION FAILED: Report missing at $REPORT_PATH"
    echo "   Proceeding to FALLBACK MECHANISM..."
  fi
  ```
- [x] Add FALLBACK MECHANISM after verification failure:
  ```bash
  # FALLBACK MECHANISM - Create report from agent output
  if [ ! -f "$REPORT_PATH" ] || [ ! -s "$REPORT_PATH" ]; then
    mkdir -p "$(dirname "$REPORT_PATH")"

    cat > "$REPORT_PATH" <<EOF
  # Research Report: ${subtopic}

  ## Status
  This report was created via fallback mechanism after agent failed to create file.

  ## Agent Output Summary
  $(echo "$AGENT_OUTPUT" | head -100)

  ## Next Steps
  - Review agent output for research findings
  - Manually enhance this report if needed
  - Re-run research agent if output insufficient
  EOF

    echo "✓ FALLBACK: Created report at $REPORT_PATH"
  fi
  ```
- [x] Add RE-VERIFICATION after fallback (concise format):
  ```bash
  # RE-VERIFICATION - Confirm fallback successful (concise)
  if [ ! -f "$REPORT_PATH" ] || [ ! -s "$REPORT_PATH" ]; then
    echo ""
    echo "✗ CRITICAL ERROR: Fallback creation failed"
    echo "   Expected: File exists at $REPORT_PATH"
    echo "   Found: File still missing after fallback"
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -la $(dirname "$REPORT_PATH")"
    echo "  cat $REPORT_PATH"
    echo ""
    echo "Workflow terminated"
    exit 1
  fi

  echo -n " (fallback)"  # Append to verification line
  ```
- [x] Apply pattern to all 4 agent invocations in STEP 3 (research agents)
- [x] Apply pattern to overview synthesis in STEP 5 (if applicable)

**Testing**:
```bash
# Check concise verification format present
grep -c "echo -n \"Verifying report" .claude/commands/research.md
# Should find 4-5 matches (one per research agent + overview)

# Check fallback mechanism present
grep -c "FALLBACK MECHANISM" .claude/commands/research.md
# Should find 4-5 matches

# Verify NO verbose box-drawing format
grep -c "═══" .claude/commands/research.md
# Should find 0 matches in verification sections

# Integration test - verify concise success output
/research "test topic" 2>&1 | grep "Verifying report"
# Expected output: "Verifying report 1/4: ✓ (15KB)"

# Integration test - force agent failure to test fallback
# (Manual test: modify agent to not create file, verify fallback triggers)
```

**Expected Duration**: 60 minutes (implements complete 3-component pattern)

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Concise verification format implemented (1 line on success)
- [ ] Verification checkpoints added after each agent (4-5 total)
- [ ] Fallback file creation mechanism added for each agent
- [ ] Re-verification added after each fallback (appends to verification line)
- [ ] All 3 components of Verification-Fallback pattern implemented
- [ ] No verbose box-drawing (═══) in verification sections
- [ ] Manual test confirms concise output: "Verifying report 1/4: ✓ (15KB)"
- [ ] Manual test confirms fallback creates files when agents fail
- [ ] Git commit created: `feat(512): complete Phase 2 - Concise Verification-Fallback Pattern`
- [ ] Update this plan file with phase completion status

### Phase 3: Add Concise Error Messages + Diagnostic Commands
dependencies: [1, 2]

**Objective**: Add clear error handling with concise diagnostic messages (avoiding verbose formatting)

**Complexity**: Low

**Context**: Standards require error messages with: (1) What failed, (2) Expected vs found state, (3) Diagnostic commands. Apply formatting principles from plan 510-002 to avoid overly verbose error messages while maintaining diagnostic utility.

**Tasks**:
- [x] Update all error messages in STEP 2 (path calculation) to concise diagnostic format:
  ```bash
  echo ""
  echo "✗ ERROR: Path calculation failed"
  echo "   Expected: RESEARCH_SUBDIR='[absolute path]'"
  echo "   Found: RESEARCH_SUBDIR='$RESEARCH_SUBDIR'"
  echo ""
  echo "Diagnostic commands:"
  echo "  echo \$RESEARCH_SUBDIR"
  echo "  ls -la \$(dirname \"\$RESEARCH_SUBDIR\")"
  echo ""
  echo "Workflow terminated"
  exit 1
  ```
- [x] Update error messages in Verification-Fallback blocks (from Phase 2) to 5-component format
- [x] Add diagnostic commands for each failure mode:
  - Path not absolute
  - Directory missing
  - Report file missing
  - Fallback creation failed
- [x] Test error messages by intentionally triggering each failure mode

**Testing**:
```bash
# Check concise error format (lowercase headers)
grep -A8 "✗ ERROR:" .claude/commands/research.md | grep "Diagnostic commands:"
# Should find matches (lowercase, concise)

# Verify NO verbose uppercase headers
grep -c "DIAGNOSTIC COMMANDS:" .claude/commands/research.md
# Should find 0 matches

# Check diagnostic commands present
grep -c "Diagnostic commands:" .claude/commands/research.md
# Should find 3-4 matches

# Integration test - trigger path error
RESEARCH_SUBDIR="relative/path" /research "test" 2>&1 | tee error_test.log
grep "Diagnostic commands:" error_test.log
# Should show concise error format
```

**Expected Duration**: 30 minutes (simplified)

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] All error messages follow concise diagnostic format
- [ ] No verbose uppercase headers (DIAGNOSTIC COMMANDS, DIAGNOSTIC INFORMATION, etc.)
- [ ] Diagnostic commands provided for each failure mode
- [ ] Manual testing confirms error messages clear but not overly verbose
- [ ] Git commit created: `feat(512): complete Phase 3 - Add Concise Error Messages`
- [ ] Update this plan file with phase completion status

### Phase 4: Validate Standard 11 Compliance + Test Delegation Rate
dependencies: [1, 2, 3]

**Objective**: Validate that /research command achieves >90% agent delegation rate and full Standard 11 compliance

**Complexity**: Low

**Context**: Standard 11 requires imperative agent invocation with no code fence wrappers. Current /research uses documentation-only YAML blocks (0% delegation). This phase validates that previous phases achieved compliance.

**Tasks**:
- [ ] Review all Task tool invocations in /research command (STEP 3, STEP 5)
- [ ] Verify each Task invocation follows Standard 11 pattern:
  - Has `**EXECUTE NOW**: USE the Task tool` directive before invocation
  - References agent behavioral file: `.claude/agents/research-specialist.md`
  - No markdown code fences wrapping Task invocation
  - Includes completion signal requirement: `Return: REPORT_CREATED: ${REPORT_PATH}`
- [ ] Run validation script (if available):
  ```bash
  .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/research.md
  # Should pass all checks
  ```
- [ ] Perform end-to-end test to measure delegation rate:
  ```bash
  /research "test research topic with 3 subtopics" 2>&1 | tee delegation_test.log

  # Count total agent invocations
  TOTAL=$(grep -c "Task invocation" delegation_test.log)

  # Count successful file creations
  SUCCESS=$(grep -c "✅ VERIFIED: Report exists" delegation_test.log)

  # Calculate delegation rate
  RATE=$((SUCCESS * 100 / TOTAL))
  echo "Delegation Rate: $RATE%"
  # Should be >90%
  ```
- [ ] If delegation rate < 90%, review Standard 11 implementation and iterate
- [ ] Document final delegation rate in plan completion notes

**Testing**:
```bash
# Check imperative directives present for Task invocations
grep -B2 "Task {" .claude/commands/research.md | grep "EXECUTE NOW"
# Should find matches for all Task invocations

# Check no code fences wrap Task invocations
grep -B2 "^Task {" .claude/commands/research.md | grep '```'
# Should return 0 matches

# Check agent behavioral file references
grep "\.claude/agents/research-specialist.md" .claude/commands/research.md
# Should find references in Task prompts

# Run end-to-end test
/research "validate Standard 11 compliance" 2>&1 | tee standard11_test.log

# Verify >90% delegation rate
SUCCESS=$(grep -c "✅ VERIFIED" standard11_test.log)
EXPECTED=4  # 4 research agents
RATE=$((SUCCESS * 100 / EXPECTED))
echo "Delegation Rate: $RATE%"
[ $RATE -ge 90 ] && echo "✅ PASSED" || echo "❌ FAILED"
```

**Expected Duration**: 35 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] All Task invocations follow Standard 11 pattern
- [ ] Validation script passes (if available)
- [ ] End-to-end test shows delegation rate >90%
- [ ] Documentation updated with final delegation rate
- [ ] Git commit created: `feat(512): complete Phase 4 - Validate Standard 11 Compliance`
- [ ] Update this plan file with phase completion status

## Testing Strategy

**Unit Testing** (per-phase):
- Phase 1: Bash syntax validation + EXECUTE NOW directive presence + path validation
- Phase 2: Verification-Fallback pattern completeness (3 components × 4-5 agents)
- Phase 3: 5-component error message format validation
- Phase 4: Standard 11 compliance validation + delegation rate measurement

**Integration Testing** (after Phase 4):
- Run /research command with simple test topic (3 subtopics)
- Verify no bash syntax errors in output
- Verify path calculation completes with absolute paths
- Verify MANDATORY VERIFICATION messages appear (4-5 times)
- Verify delegation rate >90% (measured via file creation success)
- Compare output structure to expected (correct directory structure, all files created)

**Fallback Testing**:
- Intentionally cause agent failure (e.g., invalid agent prompt)
- Verify FALLBACK MECHANISM triggers
- Verify fallback creates file with agent output
- Verify RE-VERIFICATION passes
- Confirm workflow continues after fallback

**Error Handling Testing**:
- Trigger each error condition intentionally:
  - Path not absolute
  - Directory missing
  - Report file missing after fallback
- Verify 5-component error messages appear
- Verify diagnostic commands are actionable
- Verify workflow terminates with clear guidance

**Regression Testing**:
- Test with same query that originally failed (bash syntax error)
- Verify error no longer appears
- Confirm file creation in correct locations
- Verify no performance degradation

**Success Metrics**:
- Bash syntax error: 100% eliminated
- Path calculation: 100% success rate with validation
- Standard 0 compliance: 100% (all bash blocks have EXECUTE NOW)
- Standard 11 compliance: >90% delegation rate
- Verification-Fallback: 100% file creation rate (via fallback if needed)
- Error handling: 100% compliance with 5-component format
- Manual workflow: 100% completion rate (no fatal errors)

**Testing Commands**:
```bash
# Quick syntax check
bash -n .claude/commands/research.md

# Integration test
/research "research best practices for command reliability"

# Check for expected output patterns
grep "CHECKPOINT" <output>
grep "✓ VERIFIED" <output>
! grep "syntax error" <output>  # Should NOT appear
```

## Documentation Requirements

**Inline Documentation** (in /research command file):
- Add comment at STEP 2 explaining why code block is split
- Reference Report 001 (bash syntax error analysis) for context
- Note that future optimization may consolidate to library utilities

**No New Documentation Files**:
- User requested minimal changes
- Defer comprehensive documentation to future iteration
- Existing standards in CLAUDE.md are sufficient

**Plan Update**:
- Mark phases complete as work progresses
- Update estimated hours if actual time differs significantly
- Note any deviations from plan in implementation summary

## Dependencies

**External Dependencies**:
- None (changes are isolated to research.md command file)

**Library Dependencies** (existing, no new ones):
- `.claude/lib/topic-decomposition.sh` (already sourced in STEP 1)
- `.claude/lib/artifact-creation.sh` (already sourced in STEP 1)
- `.claude/lib/metadata-extraction.sh` (already sourced in STEP 1)

**File Dependencies**:
- `/home/benjamin/.config/.claude/commands/research.md` (modification target)
- Research reports in `../reports/` (informational only)

**No New Files Created**:
- All changes are edits to existing research.md file
- No new library utilities
- No new helper functions
- No new documentation files

## Future Improvements (Deferred)

**Not in Scope for This Plan** (defer to future iterations):

1. **STEP 0 Library Sourcing** (Report 002 Rec 2)
   - Estimated effort: 30 minutes
   - Benefit: Fail-fast on missing libraries
   - Rationale for deferral: Not causing current failures

2. **Path Calculation Consolidation** (Report 002 Rec 3)
   - Estimated effort: 1 hour
   - Benefit: 47 → 10 lines (80% reduction)
   - Rationale for deferral: Requires testing, not a bug fix

3. **Verification Helper Function** (Report 002 Rec 4)
   - Estimated effort: 1.5 hours
   - Benefit: Consistent error messages
   - Rationale for deferral: Cosmetic improvement

4. **Standard 11 Compliance** (Report 003 Priority 1)
   - Estimated effort: 2 hours
   - Benefit: >90% delegation rate improvement
   - Rationale for deferral: Requires restructuring agent invocations

5. **5-Component Error Messages** (Report 003 Priority 4)
   - Estimated effort: 30 minutes
   - Benefit: Better debugging experience
   - Rationale for deferral: User requested minimal changes

**When to Apply Deferred Improvements**:
- After baseline reliability established (this plan)
- When user requests optimization (not just bug fixes)
- During comprehensive refactoring effort
- When similar patterns needed across multiple commands

## Notes

**Design Philosophy**:
This plan follows the user's REVISED guidance: "Ensure full compliance with .claude/docs/ standards while making minimal changes." The key insight is that several originally-deferred improvements are actually MANDATORY per active standards, not optional optimizations. Therefore, we:
- Fix critical bash syntax error (functional requirement)
- Implement Standard 11 compliance (MANDATORY per command_architecture_standards.md)
- Implement full Verification-Fallback pattern (MANDATORY for file-creation commands)
- Implement Standard 0 enforcement (MANDATORY execution directives)
- Add 5-component error messages (MANDATORY per orchestration troubleshooting guide)
- Defer true optimizations (library consolidation, helper functions - not compliance-related)

**Why This Approach**:
1. User explicitly requested "full compliance with .claude/docs/ standards"
2. Standards analysis revealed that originally-deferred items are MANDATORY, not optional
3. "Minimal changes" means minimal COMPLIANT changes (not minimal non-compliant changes)
4. Standards are active and enforced (last updated 2025-10-27, Spec 497)
5. Historical evidence (Specs 438, 495) shows 0% → >90% delegation rate improvement from Standard 11

**Alignment with Research Recommendations**:
- Report 003 recommends full Standard 11 compliance → **NOW INCLUDED** (Phase 1 + Phase 4)
- Report 003 recommends comprehensive Verification-Fallback → **NOW INCLUDED** (Phase 2)
- Report 003 recommends 5-component error messages → **NOW INCLUDED** (Phase 3)
- Report 002 recommends library consolidation → **STILL DEFERRED** (optimization, not compliance)
- Report 002 recommends verification helper function → **STILL DEFERRED** (DRY, not compliance)

**Success Criteria** (revised):
This plan succeeds if the /research command:
1. Executes without bash syntax errors (functional)
2. Achieves >90% delegation rate (Standard 11 compliance)
3. Achieves 100% file creation rate via Verification-Fallback (pattern compliance)
4. All bash blocks have EXECUTE NOW directives (Standard 0 compliance)
5. All error messages follow 5-component format (error handling compliance)
6. Runs end-to-end without fatal errors (functional)

**Compliance vs Optimization**:
The revised plan distinguishes between:
- **Compliance** (MANDATORY): Standard 11, Verification-Fallback, Standard 0, Error Handling → MUST implement
- **Optimization** (OPTIONAL): Library consolidation, helper functions, STEP 0 sourcing → CAN defer

This distinction was not clear in the original plan, which incorrectly classified compliance requirements as optional improvements.

## Revision History

### 2025-10-28 - Revision 1: Full Standards Compliance

**Trigger**: User requested: "ensure that the refactor it produces is in full compliance with .claude/docs/ standards, making any necessary changes to the plan"

**Changes Made**:
1. **Phases expanded from 3 to 4** to achieve MANDATORY standards compliance
2. **Phase 1 enhanced**: Added Standard 0 enforcement (EXECUTE NOW directives + path validation) beyond just bash syntax fix
3. **Phase 2 completely rewritten**: Changed from "basic verification checkpoints" to "full Verification-Fallback pattern" (all 3 components: verification + fallback + re-verification)
4. **Phase 3 redefined**: Changed from generic verification to "5-component error messages" per Orchestration Troubleshooting Guide
5. **Phase 4 added (new)**: Standard 11 validation + delegation rate testing (>90% target)
6. **Estimated hours**: Increased from 3.5 to 5.0 hours to reflect additional mandatory work
7. **Complexity score**: Increased from 35.0 to 45.0 to reflect additional phases
8. **Success criteria**: Expanded to include standards compliance metrics (delegation rate, file creation rate, error message format)

**Reason for Revision**:
Standards analysis revealed that several items originally classified as "deferred improvements" are actually MANDATORY per active .claude/docs/ standards:
- **Standard 11 (Imperative Agent Invocation)**: MANDATORY per command_architecture_standards.md (lines 1128-1307), last updated 2025-10-27
- **Verification-Fallback Pattern**: MANDATORY for all file-creation commands per verification-fallback.md (line 3: "[Used by: all file creation commands]")
- **5-Component Error Messages**: MANDATORY per orchestration-troubleshooting.md requirements
- **Standard 0 (Execution Enforcement)**: MANDATORY for bash block execution

Historical evidence from Specs 438, 495, 057, 497 shows these are enforced standards, not optional improvements:
- /supervise: 0% → >90% delegation after Standard 11 fix (Spec 438)
- /coordinate, /research: 0% delegation before fixes (Spec 495)
- All orchestration commands validated for compliance (Spec 497)

**Reports Used**:
- 001_bash_syntax_error_analysis.md (bash fix guidance)
- 002_research_command_architecture_analysis.md (architecture analysis)
- 003_documentation_standards_review.md (compliance gap identification - critical for this revision)

**Modified Phases**:
- Phase 1: Enhanced with Standard 0 enforcement
- Phase 2: Completely rewritten (basic verification → full Verification-Fallback)
- Phase 3: Redefined (generic checkpoints → 5-component error messages)
- Phase 4: Added (new - Standard 11 validation)

**Key Insight**:
Original plan interpreted "minimal changes" as "minimal non-compliant changes" but user clarification revealed intent was "minimal COMPLIANT changes." Standards compliance is non-negotiable per active documentation, so plan revised to implement MANDATORY standards while still deferring true optimizations (library consolidation, helper functions).

**Backup Created**: 001_research_what_is_needed_to_avoid_these_errors_maki_plan.md.backup-20251028_222649

### 2025-10-28 - Revision 2: Formatting Improvements

**Trigger**: User requested: "follow similar aims as described in /home/benjamin/.config/.claude/specs/510_coordinate_error_and_formatting_improvements/plans/002_coordinate_remaining_formatting_improvements.md to avoid poor formatting (for instance 'MANDATORY VERIFICATION' sections do not show up great and could be simplified to improve user experience)"

**Changes Made**:
1. **Phase 2 verification format**: Changed from verbose "MANDATORY VERIFICATION" boxes with box-drawing (═══) to concise 1-line format
   - Success: `Verifying report 1/4: ✓ (15KB)` instead of 6-line box
   - Fallback: Appends " (fallback)" to verification line
   - Verbose diagnostics only on failure

2. **Phase 3 error messages**: Simplified from 5-component uppercase headers to concise lowercase format
   - Changed: "DIAGNOSTIC COMMANDS:" → "Diagnostic commands:"
   - Removed: "DIAGNOSTIC INFORMATION:" verbose header
   - Removed: "CONTEXT:" and "ACTION:" sections (implicit in error message)
   - Duration reduced: 40min → 30min

3. **Testing sections**: Updated to verify concise format adoption
   - Added checks for NO box-drawing characters (═══)
   - Added checks for NO uppercase verbose headers
   - Verify concise output examples in tests

4. **Completion requirements**: Added concise formatting validation
   - Phase 2: "No verbose box-drawing (═══) in verification sections"
   - Phase 3: "No verbose uppercase headers (DIAGNOSTIC COMMANDS, etc.)"
   - Success criteria include format verification tests

**Reason for Revision**:
Plan 510-002 demonstrates that verbose "MANDATORY VERIFICATION" boxes with box-drawing characters create poor user experience:
- Hard to scan quickly (50+ lines of verification per workflow)
- Token-heavy (3,500+ tokens for verification sections alone)
- Overwhelming for users (everything looks equally important)

Best practice from 510-002:
- **Success path**: Single line with ✓ marker (scannable)
- **Failure path**: Verbose diagnostics (when needed)
- **Format**: Lowercase headers, no box-drawing, no excessive whitespace

**Reference Plan**: specs/510_coordinate_error_and_formatting_improvements/plans/002_coordinate_remaining_formatting_improvements.md

**Examples of Improvement**:

Before (verbose):
```
════════════════════════════════════════════════════════
  MANDATORY VERIFICATION - Research Report 1
════════════════════════════════════════════════════════

Verifying Report 1: report_001.md

  ✅ PASSED: Report created successfully (15384 bytes)

════════════════════════════════════════════════════════
```

After (concise):
```
Verifying report 1/4: ✓ (15KB)
```

**Token Reduction**: ~90% in verification sections (following 510-002 pattern)

**Backup Created**: 001_research_what_is_needed_to_avoid_these_errors_maki_plan.md.backup-formatting-20251028_223230
