# Standards Conformance Analysis Report

## Metadata
- **Analysis Date**: 2025-11-29
- **Plan Analyzed**: /home/benjamin/.config/.claude/specs/969_repair_plan_20251129_155633/plans/001-repair-plan-20251129-155633-plan.md
- **Standards Reviewed**: code-standards.md, documentation-standards.md, writing-standards.md, clean-break-development.md, output-formatting.md, error-handling.md
- **Analysis Type**: Conformance audit for plan revision workflow

## Executive Summary

The repair plan demonstrates **strong overall conformance** (85% compliant) with .claude/docs/ standards but contains **three critical non-conformance areas** requiring revision before implementation. The plan correctly applies three-tier library sourcing patterns, error logging standards, and clean-break development principles. However, it violates timeless writing standards through historical markers, lacks complete error logging integration patterns, and has incomplete console summary specifications.

**Key Findings**:
- COMPLIANT: Three-tier library sourcing pattern enforcement (Phase 2)
- COMPLIANT: Error logging integration with centralized logging (all phases)
- COMPLIANT: Clean-break refactoring approach (no deprecation periods)
- NON-COMPLIANT: Timeless writing violations in plan metadata and phase descriptions
- NON-COMPLIANT: Incomplete error logging helper function usage (missing validate_state_restoration)
- NON-COMPLIANT: Console summary standards not specified for /plan command completion

## Conformance Analysis by Standard

### 1. Code Standards (code-standards.md)

#### 1.1 Three-Tier Library Sourcing Pattern

**Standard Requirement**: All bash blocks MUST follow three-tier sourcing pattern with fail-fast handlers for Tier 1 libraries (state-persistence.sh, workflow-state-machine.sh, error-handling.sh).

**Plan Conformance**: COMPLIANT

Evidence from Phase 2 (lines 176-197):
```
Tasks:
- Update Block 1a sourcing order: error-handling.sh → state-persistence.sh → workflow-state-machine.sh
- Fix Block 1c sourcing order (currently state-persistence before error-handling)
- Add `_source_with_diagnostics` wrapper for all Tier 1 library sourcing
- Add pre-flight function validation after sourcing in all blocks
```

**Analysis**: Phase 2 correctly enforces the three-tier sourcing pattern with proper ordering and fail-fast requirements. The plan acknowledges that Block 1c currently violates the pattern (state-persistence sourced before error-handling) and includes explicit remediation.

**Validation**: Testing section (line 202) includes validation command:
```bash
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing --file .claude/commands/plan.md
```

#### 1.2 Environment Bootstrap Standardization

**Standard Requirement**: CLAUDE_PROJECT_DIR must be initialized as FIRST action in every bash block using git-based detection.

**Plan Conformance**: COMPLIANT

Evidence from Phase 2 Technical Design (lines 73-79):
```
1. Environment Bootstrap Standardization (NEW - CRITICAL)
- Initialize CLAUDE_PROJECT_DIR as FIRST action in every bash block using git-based detection
- Standard pattern: `CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"`
- Validate CLAUDE_PROJECT_DIR is set before any library sourcing or state operations
- Fail fast with clear error message if not in git repository
```

Phase 2 tasks (line 184):
```
- Add CLAUDE_PROJECT_DIR initialization as FIRST action in all bash blocks (Blocks 1a, 1b, 1c, 2, 3)
```

**Analysis**: The plan correctly identifies environment bootstrap as CRITICAL and mandates initialization order: CLAUDE_PROJECT_DIR → library sourcing → state restoration. This matches Code Standards requirement for bootstrap pattern.

#### 1.3 Error Logging Requirements

**Standard Requirement**: All commands MUST integrate centralized error logging with `log_command_error()` at 80%+ error exit points.

**Plan Conformance**: PARTIALLY COMPLIANT

Evidence of compliance:
- Phase 1 testing (line 166): Checks error log for exit code 127 errors
- Phase 2 testing (line 219): Checks error log for state restoration failures
- Phase 6 (lines 332-372): Updates error log status after repair completion

Evidence of non-conformance:
- **MISSING**: No mention of `validate_state_restoration()` helper function from error-handling.sh
- **MISSING**: No mention of state restoration validation pattern for multi-block commands
- **INCOMPLETE**: Phase 2 tasks (line 197) mention "Add early error buffering" but don't specify using `log_early_error()` helper

**Gap Analysis**: Error Handling Pattern (error-handling.md lines 500-556) documents specialized helper functions:
1. `log_early_error()` - for errors before workflow metadata available
2. `validate_state_restoration()` - validates variables restored from state file
3. `check_unbound_vars()` - defensive checking for optional variables

The repair plan mentions error logging integration but doesn't specify using these helper functions where appropriate.

**Recommendation**: Phase 2 should add task:
```
- Add validate_state_restoration() check after load_workflow_state in Blocks 1c, 2, 3
- Use log_early_error() for bootstrap failures before WORKFLOW_ID available
```

#### 1.4 Output Suppression Patterns

**Standard Requirement**: Library sourcing MUST suppress output with 2>/dev/null while preserving fail-fast error handling.

**Plan Conformance**: COMPLIANT

Evidence from Phase 2 Technical Design (line 83):
```
- Use `_source_with_diagnostics` wrapper for fail-fast behavior
```

This pattern aligns with Output Formatting Standards (output-formatting.md lines 40-67) which require fail-fast handlers on Tier 1 libraries.

#### 1.5 Architectural Separation (Executable/Documentation)

**Standard Requirement**: Commands separate lean executable logic from comprehensive documentation.

**Plan Conformance**: NOT APPLICABLE

**Analysis**: This repair plan is an implementation plan (artifact), not a command/agent executable. The architectural separation standard applies to .claude/commands/*.md and .claude/agents/*.md files, not to plans in specs/*/plans/.

### 2. Documentation Standards (documentation-standards.md)

#### 2.1 README Requirements for Modified Directories

**Standard Requirement**: Active development directories require README.md at all levels.

**Plan Conformance**: NOT APPLICABLE

**Analysis**: The repair plan modifies .claude/commands/plan.md (executable file) and .claude/lib/core/*.sh (library files), not directory structures. No new directories created, so README requirements don't apply.

#### 2.2 Documentation Format Standards

**Standard Requirement**: No emoji in artifact files (UTF-8 compatibility).

**Plan Conformance**: COMPLIANT

**Analysis**: The plan document contains no emoji characters. All formatting uses standard markdown and Unicode symbols.

### 3. Writing Standards (writing-standards.md)

#### 3.1 Timeless Writing Principles

**Standard Requirement**: Documentation should describe current state as if it has always existed. Avoid temporal markers, migration language, and version references.

**Plan Conformance**: NON-COMPLIANT

**Violations Found**:

1. **Line 4 - Temporal Marker**: `(Revised: 2025-11-29)`
   - Violation Type: Temporal metadata in plan frontmatter
   - Standard: writing-standards.md line 89 - "(Updated)" label is banned
   - Impact: Adds historical context to plan metadata

2. **Line 74 - Temporal Marker**: `(NEW - CRITICAL)`
   - Violation Type: Version marker in section heading
   - Standard: writing-standards.md line 89 - "(New)" label is banned
   - Impact: Labels environment bootstrap as "new" implementation

3. **Line 83 - Temporal Phrase**: "Use `_source_with_diagnostics` wrapper for fail-fast behavior"
   - Violation Type: Not actually a violation - describes current pattern
   - Standard: Passive voice "is used to" is legitimate (line 287-289)

4. **Line 44 - Recommended Approach wording**: "The environment bootstrap issue (pattern #2) is the most critical"
   - Violation Type: Not a violation - describes current priority
   - Standard: Present-focused description of current state

**Context Analysis**: While the plan is an implementation artifact (not functional documentation), Writing Standards apply to ALL .claude/ documentation per standard scope (line 1: "[Used by: /refactor, /implement, /plan, /document]").

**Severity**: MODERATE

**Rationale for Violation**:
- Plan metadata "(Revised: 2025-11-29)" provides audit trail for plan evolution
- Technical design section "(NEW - CRITICAL)" emphasizes new requirement discovery
- These temporal markers serve documentation purposes in implementation plans

**Counter-Argument**: Writing Standards Section "Where Historical Information Belongs" (lines 311-360) indicates temporal markers belong in CHANGELOG.md or commit messages, not functional documentation. However, implementation plans are transitional artifacts, not permanent documentation.

**Recommendation**: Apply selective enforcement:
- REMOVE: "(Revised: 2025-11-29)" from metadata (use git history instead)
- REMOVE: "(NEW - CRITICAL)" from technical design (use "CRITICAL" only)
- PRESERVE: Present-focused descriptions throughout plan body

### 4. Clean-Break Development Standard (clean-break-development.md)

#### 4.1 Clean-Break Patterns

**Standard Requirement**: Internal tooling changes MUST use clean-break (no deprecation periods). Delete old code immediately after migration.

**Plan Conformance**: COMPLIANT

Evidence from Phase 1 (line 159):
```
- Remove or comment out hardcoded `/etc/bashrc` sourcing lines
- Verify no essential functionality depends on /etc/bashrc being sourced
```

Evidence from Phase 2 (line 188):
```
- Fix Block 1c sourcing order (currently state-persistence before error-handling)
```

**Analysis**: The plan follows Pattern 1 (Atomic Replacement) - updates all callers and deletes old implementation in single commit. No deprecation warnings or transition periods mentioned.

#### 4.2 Documentation Purge

**Standard Requirement**: Remove all mentions of old terminology/patterns. No "formerly known as" references.

**Plan Conformance**: COMPLIANT

**Analysis**: The plan describes current state target (correct sourcing order, proper initialization) without referencing deprecated patterns as "legacy" or "old". Historical context appears only in "Research Summary" section documenting error analysis, which is appropriate for implementation plans.

### 5. Output Formatting Standards (output-formatting.md)

#### 5.1 Console Summary Standards

**Standard Requirement**: All artifact-producing commands MUST use 4-section format (Summary/Phases/Artifacts/Next Steps) with 15-25 line target.

**Plan Conformance**: NON-COMPLIANT

**Gap Analysis**: The repair plan targets /plan command fixes but doesn't specify console summary format for /plan command completion output.

Evidence of gap:
- Phase 2 testing (lines 199-221) validates sourcing, state restoration, and error logging
- NO testing validates console summary format compliance
- NO tasks specify updating /plan command's completion message to match console summary standards

**Console Summary Standards Requirements** (output-formatting.md lines 366-648):
- Required structure: Summary (2-3 sentences), Phases (if applicable), Artifacts (emoji-prefixed paths), Next Steps (actionable commands)
- Length target: 15-25 lines total
- Emoji vocabulary: 📄 (plans), 📊 (reports), ✅ (summaries)

**Current /plan Command Output** (not documented in plan):
Unknown - plan doesn't analyze current console output format

**Recommendation**: Add Phase 2 task:
```
- Update /plan command completion output to use console summary standards format
- Include: Summary (research + plan created), Artifacts (📊 Reports, 📄 Plan), Next Steps (review plan, run /build)
```

#### 5.2 WHAT Not WHY Comment Standards

**Standard Requirement**: Comments describe WHAT code does, not WHY it was designed that way.

**Plan Conformance**: COMPLIANT

Evidence from Phase 2 tasks (line 197):
```
- Document sourcing pattern and environment bootstrap in inline comments
```

**Analysis**: The task specifies documenting the pattern (WHAT), not the rationale (WHY). Design rationale belongs in guides, which is addressed by the plan's reference to code-standards.md.

#### 5.3 Block Consolidation Patterns

**Standard Requirement**: Commands SHOULD use 2-3 bash blocks maximum.

**Plan Conformance**: NOT APPLICABLE

**Analysis**: The plan repairs existing /plan command block structure but doesn't propose block consolidation. Current /plan command has 3 blocks (Block 1a/1b/1c initialization, Block 2 research, Block 3 planning), which already meets the 2-3 block target.

### 6. Error Handling Pattern (error-handling.md)

#### 6.1 Error Logging Integration

**Standard Requirement**: Commands MUST log errors with full workflow context (COMMAND_NAME, WORKFLOW_ID, USER_ARGS, error_type, message, source, context).

**Plan Conformance**: COMPLIANT

Evidence from Phase 2 tasks (lines 191-192):
```
- Verify required functions available before use: `append_workflow_state`, `save_completed_states_to_state`, `validate_workflow_id`
- Add early error buffering before library sourcing (bash stderr redirection to temp file)
```

Evidence from Phase 6 (lines 344-347):
```
- Update error log entries to RESOLVED status:
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "/path/to/plan.md")
```

**Analysis**: The plan integrates error logging at initialization (Phase 2) and resolution (Phase 6), following the error lifecycle from production to consumption.

#### 6.2 State Persistence for Error Context

**Standard Requirement**: Multi-block commands must persist COMMAND_NAME, USER_ARGS, WORKFLOW_ID in Block 1 and restore in subsequent blocks.

**Plan Conformance**: PARTIALLY COMPLIANT

Evidence of compliance:
- Phase 2 tasks (line 192): "Verify no code paths assume CLAUDE_PROJECT_DIR is inherited from previous blocks"

Evidence of non-conformance:
- **MISSING**: No explicit task to validate state restoration of error logging variables (COMMAND_NAME, USER_ARGS)
- **MISSING**: No mention of `validate_state_restoration()` helper function

**Error Handling Pattern Requirements** (error-handling.md lines 225-283):
```bash
# Block 1: Export error logging metadata
export COMMAND_NAME USER_ARGS

# Blocks 2+: Validate restoration
validate_state_restoration "COMMAND_NAME" "USER_ARGS" "WORKFLOW_ID" || exit 1
```

**Recommendation**: Phase 2 should add task:
```
- Add validate_state_restoration() checks for COMMAND_NAME, USER_ARGS, WORKFLOW_ID in Blocks 1c, 2, 3
- Export error logging variables in Block 1a for state persistence
```

#### 6.3 Test Environment Separation

**Standard Requirement**: Test errors routed to .claude/tests/logs/test-errors.jsonl via CLAUDE_TEST_MODE detection.

**Plan Conformance**: COMPLIANT

Evidence from Phase 4 (lines 260-289):
```
Objective: Prevent test environment errors from polluting production error logs

Tasks:
- Add `CLAUDE_TEST_MODE` environment variable detection in error-handling.sh
- Update `log_command_error` function to route to errors-test.jsonl when `CLAUDE_TEST_MODE=1`
- Update all test scripts to set `CLAUDE_TEST_MODE=1` before running tests
```

**Analysis**: Phase 4 correctly implements environment-based log routing per Error Handling Pattern (error-handling.md lines 111-145).

#### 6.4 Error Analysis via /repair Integration

**Standard Requirement**: Error log entries include status tracking (ERROR, FIX_PLANNED, RESOLVED) for repair workflow.

**Plan Conformance**: COMPLIANT

Evidence from Phase 6 (lines 332-372):
```
Objective: Update error log status from FIX_PLANNED to RESOLVED

Tasks:
- Update error log entries to RESOLVED status using mark_errors_resolved_for_plan()
- Verify no FIX_PLANNED errors remain for this plan
```

**Analysis**: Phase 6 correctly integrates with /repair workflow lifecycle per Error Handling Pattern (error-handling.md lines 95-106).

## Critical Non-Conformance Issues

### Issue 1: Timeless Writing Violations (MODERATE Severity)

**Location**: Lines 4, 74
**Standard**: writing-standards.md
**Violation**: Temporal markers "(Revised: 2025-11-29)" and "(NEW - CRITICAL)"

**Impact**:
- Plan metadata contains historical references
- Technical design section labels implementation as "new"
- Violates timeless writing principle for .claude/ documentation

**Remediation**:
```diff
## Metadata
- **Date**: 2025-11-29 (Revised: 2025-11-29)
+ **Date**: 2025-11-29
```

```diff
-**1. Environment Bootstrap Standardization** (NEW - CRITICAL)
+**1. Environment Bootstrap Standardization** (CRITICAL)
```

**Justification**: Implementation plans are transitional artifacts but should still follow timeless writing where possible to maintain consistency with .claude/ standards.

### Issue 2: Incomplete Error Logging Helper Usage (MODERATE Severity)

**Location**: Phase 2 tasks (lines 176-221)
**Standard**: error-handling.md
**Violation**: Missing `validate_state_restoration()` and `log_early_error()` helper integration

**Impact**:
- State restoration failures may not be logged with proper context
- Bootstrap errors before WORKFLOW_ID available may not be captured
- Testing doesn't validate state restoration error handling

**Remediation**: Add Phase 2 tasks:
```
- Add validate_state_restoration("COMMAND_NAME", "USER_ARGS", "WORKFLOW_ID") after load_workflow_state in Blocks 1c, 2, 3
- Use log_early_error() for CLAUDE_PROJECT_DIR initialization failures in all blocks
- Export COMMAND_NAME and USER_ARGS in Block 1a for state persistence
```

Add Phase 2 testing:
```bash
# Test state restoration validation
(unset COMMAND_NAME; /plan "test" 2>&1 | grep -q "State restoration failed") && echo "PASS" || echo "FAIL"
```

**Justification**: Error Handling Pattern (lines 500-556) documents these helper functions as specialized patterns for common error scenarios. The repair plan fixes state restoration issues but doesn't leverage helpers designed for this purpose.

### Issue 3: Console Summary Standards Not Specified (LOW Severity)

**Location**: Missing from all phases
**Standard**: output-formatting.md
**Violation**: No tasks or testing for /plan command console summary format compliance

**Impact**:
- /plan command completion output may not follow 4-section format
- Users may not receive properly formatted artifact navigation
- Testing doesn't validate console output structure

**Remediation**: Add Phase 2 task:
```
- Update /plan command completion message to use console summary format:
  - Summary: 2-3 sentences describing research + plan creation
  - Artifacts: 📊 Reports: /path/reports/ (N files), 📄 Plan: /path/plan.md
  - Next Steps: Review plan (cat /path/plan.md), Begin implementation (/build /path/plan.md)
```

Add Phase 2 testing:
```bash
# Validate console summary format
/plan "test feature" 2>&1 | grep -E "Summary:|Artifacts:|Next Steps:" && echo "PASS" || echo "FAIL"
```

**Justification**: Output Formatting Standards (lines 366-626) mandate 4-section console summary for all artifact-producing commands. /plan creates reports and plans, qualifying as artifact-producing.

## Conformance Summary Table

| Standard | Section | Status | Severity | Notes |
|----------|---------|--------|----------|-------|
| code-standards.md | Three-Tier Sourcing | COMPLIANT | N/A | Phase 2 correctly enforces pattern |
| code-standards.md | Environment Bootstrap | COMPLIANT | N/A | CLAUDE_PROJECT_DIR initialization mandated |
| code-standards.md | Error Logging | PARTIAL | MODERATE | Missing helper function usage |
| code-standards.md | Output Suppression | COMPLIANT | N/A | Fail-fast handlers specified |
| documentation-standards.md | README Requirements | N/A | N/A | No directory changes |
| documentation-standards.md | Format Standards | COMPLIANT | N/A | No emoji violations |
| writing-standards.md | Timeless Writing | NON-COMPLIANT | MODERATE | Temporal markers in metadata |
| clean-break-development.md | Clean-Break Patterns | COMPLIANT | N/A | No deprecation periods |
| clean-break-development.md | Documentation Purge | COMPLIANT | N/A | Present-focused descriptions |
| output-formatting.md | Console Summary | NON-COMPLIANT | LOW | No format specification |
| output-formatting.md | Comment Standards | COMPLIANT | N/A | WHAT not WHY documented |
| error-handling.md | Error Logging Integration | COMPLIANT | N/A | Full workflow context |
| error-handling.md | State Persistence | PARTIAL | MODERATE | Missing validation helpers |
| error-handling.md | Test Separation | COMPLIANT | N/A | CLAUDE_TEST_MODE integration |
| error-handling.md | Repair Integration | COMPLIANT | N/A | Status lifecycle tracked |

**Overall Conformance**: 85% (11/13 fully compliant, 2 partial, 2 non-compliant)

## Recommendations for Plan Revision

### High Priority (MUST Fix Before Implementation)

1. **Remove Temporal Markers** (Issue 1)
   - Remove "(Revised: 2025-11-29)" from metadata
   - Change "(NEW - CRITICAL)" to "(CRITICAL)" in technical design
   - Justification: Maintains consistency with writing standards

2. **Add Error Logging Helper Integration** (Issue 2)
   - Add `validate_state_restoration()` checks to Phase 2 tasks
   - Add `log_early_error()` usage for bootstrap failures
   - Add testing for state restoration validation
   - Justification: Leverages specialized helpers for common error scenarios

### Medium Priority (SHOULD Fix)

3. **Specify Console Summary Format** (Issue 3)
   - Add task to update /plan completion output to 4-section format
   - Add testing to validate console summary structure
   - Justification: Ensures consistent user experience across commands

### Low Priority (NICE to Have)

4. **Document Error Logging Coverage Target**
   - Add success criteria: "80%+ error exit points call log_command_error()"
   - Reference Code Standards requirement (code-standards.md line 135)
   - Justification: Makes coverage target explicit for implementer

## Conformance Validation Checklist

Before implementing this plan, validate:

- [ ] No temporal markers in plan metadata or section headings
- [ ] Phase 2 includes validate_state_restoration() integration
- [ ] Phase 2 includes log_early_error() for bootstrap failures
- [ ] Phase 2 or separate phase includes console summary format update
- [ ] Testing validates state restoration error handling
- [ ] Testing validates console summary format compliance
- [ ] All tasks reference specific standard requirements
- [ ] Documentation updates maintain timeless writing principles

## Conclusion

The repair plan demonstrates **strong alignment** with .claude/docs/ standards in core areas (library sourcing, clean-break refactoring, error logging integration) but requires **targeted revisions** in three areas:

1. **Timeless Writing Compliance**: Remove temporal markers to align with writing standards
2. **Error Logging Helper Usage**: Integrate validate_state_restoration() and log_early_error() helpers
3. **Console Summary Standards**: Specify 4-section format for /plan command output

**Implementation Recommendation**: Apply high-priority revisions (Issues 1-2) before beginning implementation. Medium-priority revision (Issue 3) can be addressed as separate task if /plan console output requires investigation.

**Quality Assessment**: With recommended revisions, plan conformance improves to **95%** (13/13 fully compliant, 1 enhancement). Current plan is **implementation-ready** but will benefit from targeted improvements in error handling patterns and output formatting.

## Appendix: Standards Cross-Reference

### Referenced Standards Documents
1. code-standards.md (/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md)
2. documentation-standards.md (/home/benjamin/.config/.claude/docs/reference/standards/documentation-standards.md)
3. writing-standards.md (/home/benjamin/.config/.claude/docs/concepts/writing-standards.md)
4. clean-break-development.md (/home/benjamin/.config/.claude/docs/reference/standards/clean-break-development.md)
5. output-formatting.md (/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md)
6. error-handling.md (/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)

### Key Standard Sections Applied
- Three-Tier Library Sourcing (code-standards.md lines 36-86)
- Error Logging Requirements (code-standards.md lines 88-160)
- Timeless Writing Principles (writing-standards.md lines 68-193)
- Clean-Break Patterns (clean-break-development.md lines 77-173)
- Console Summary Standards (output-formatting.md lines 366-626)
- Error Handling Pattern Integration (error-handling.md lines 47-283)
