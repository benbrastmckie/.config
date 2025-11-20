# Plan Revision Insights for Error Analysis and Repair

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Plan conformance to .claude/docs/ standards
- **Report Type**: plan revision research
- **Workflow**: Revise workflow for error analysis repair plan

## Executive Summary

The existing plan (001_error_analysis_repair_plan.md) is well-structured with appropriate phasing and detailed technical design, but requires moderate revisions to fully conform to .claude/docs/ standards. The plan currently lacks explicit test/production error segregation architectural alignment, does not reference the existing error-handling pattern documentation comprehensively, and proposes metadata enhancements (severity, user, hostname) without evaluating whether these align with existing error classification taxonomy. The plan should be revised to integrate with existing error handling patterns, align cleanup/rotation features with documented standards, and ensure all new features extend rather than diverge from established error logging architecture.

## Findings

### Current State Analysis

#### Plan Structure Assessment

The plan follows standard plan structure with:
- Complete metadata section (Date, Feature, Scope, Estimated Phases/Hours, Standards File, Status, Structure Level, Complexity Score, Research Reports)
- Overview section explaining implementation goals
- Research Summary linking to error analysis report
- Success Criteria with checkboxes
- Technical Design with architecture overview and component interactions
- 5 implementation phases with dependencies, complexity ratings, tasks, testing, and expected durations
- Testing Strategy section
- Documentation Requirements section
- Dependencies and Risk Mitigation sections

**Location**: /home/benjamin/.config/.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md:1-380

This structure conforms to Directory Protocols standards for plan organization.

#### Standards Referenced in Plan

The plan references:
- CLAUDE.md standards file (line 9)
- Error analysis report (line 14)

**Gap**: The plan does not explicitly reference the key .claude/docs/ standards that apply to this implementation:
- Error Handling Pattern (.claude/docs/concepts/patterns/error-handling.md)
- Library API Reference - Error Handling (.claude/docs/reference/library-api/error-handling.md)
- Code Standards (.claude/docs/reference/standards/code-standards.md)

#### Error Logging Architecture Alignment

**Existing Standards** (.claude/docs/concepts/patterns/error-handling.md):
- Centralized JSONL error log at `$CLAUDE_PROJECT_DIR/.claude/data/logs/errors.jsonl` (line 11)
- Standard JSONL schema with fields: timestamp, command, workflow_id, user_args, error_type, error_message, source, stack, context (lines 72-87)
- Automatic rotation at 10MB threshold with 5 backup files (lines 167-184)
- Error classification taxonomy with 7 standard types (lines 49-65)

**Plan Proposals**:
1. **Test/Production Segregation**: Plan proposes routing test errors to `test-errors.jsonl` using context detection (lines 49-74, 110-136)
   - **Alignment Status**: EXTENDS existing pattern (new file, new routing logic)
   - **Missing**: No reference to how this integrates with existing `ensure_error_log_exists()` and `log_command_error()` functions

2. **Error Log Cleanup Utility**: Plan proposes `cleanup_error_logs.sh` script (lines 139-170)
   - **Alignment Status**: COMPLEMENTS existing pattern (new utility)
   - **Directory**: Correctly placed in scripts/ per Directory Organization Standards
   - **Missing**: No reference to existing query_errors() functionality for filtering

3. **Log Rotation Implementation**: Plan proposes size-based and date-based rotation (lines 173-205)
   - **Alignment Status**: MODIFIES existing pattern (already has rotation at line 167-184 of error-handling.md)
   - **Conflict**: Existing standard already defines 10MB threshold with 5 backups. Plan proposes "configurable rotation threshold" (line 180) and "rotation mode configuration" (line 184) which may diverge from standard.
   - **Missing**: No acknowledgment of existing rotate_error_log() function (error-handling.md:151-170 in library-api reference)

4. **Enhanced Metadata**: Plan proposes adding severity, environment, user, hostname fields (lines 206-238)
   - **Alignment Status**: MODIFIES existing schema (lines 72-87 of error-handling.md)
   - **Conflict**: Existing schema already defined. Adding fields requires schema evolution strategy.
   - **Missing**: No evaluation of whether severity field duplicates existing error_type classification

### Standards Conformance Analysis

#### Error Handling Pattern Conformance

**Requirement** (error-handling.md:89-145): Commands must integrate error logging in three places: initialization, error points, and subagent errors.

**Plan Gap**: Phase 1 tasks (lines 117-125) modify log_command_error() but don't verify backward compatibility with all existing callers. The plan states "Preserve backward compatibility - existing callers work without changes" (line 125) but doesn't specify HOW this is achieved.

**Recommendation**: Add verification step to identify all log_command_error() callers and test them after modification.

---

**Requirement** (error-handling.md:167-184): Automatic rotation at 10MB with 5 backups.

**Plan Conflict**: Phase 3 (lines 180-187) proposes "configurable rotation threshold (default: 10MB)" and "rotation mode configuration (size, date, or both)" which introduces variability not in existing standard.

**Recommendation**: Either:
1. Justify why configurable rotation is necessary (current standard is fixed)
2. Update error-handling.md standard to reflect new configurability
3. Remove configurability and keep 10MB fixed threshold

---

**Requirement** (error-handling.md:46-65): Standard error type taxonomy with 7 types.

**Plan Extension**: Phase 4 (lines 214-215) adds calculate_severity() function to map error_type to severity level (low/medium/high/critical).

**Analysis**: This is a NEW dimension (severity) separate from error_type. Not documented in existing standards.

**Recommendation**: Clarify relationship between error_type and severity. Consider whether severity is derivable from error_type or is independent metadata.

#### Library API Conformance

**Requirement** (library-api/error-handling.md:34-95): log_command_error() has 7 parameters with specific types and constraints.

**Plan Gap**: Phase 1 (lines 117-125) and Phase 4 (lines 214-221) modify this function but don't update the signature documentation.

**Recommendation**: Add documentation update task to Phase 5 to update library-api/error-handling.md with new parameters or behavior.

---

**Requirement** (library-api/error-handling.md:151-170): rotate_error_log() function exists with defined behavior.

**Plan Conflict**: Phase 3 (lines 177-202) proposes implementing rotation functions but doesn't acknowledge existing rotate_error_log().

**Recommendation**: Clarify whether Phase 3 EXTENDS existing rotation or REPLACES it. Reference existing function.

#### Code Standards Conformance

**Requirement** (code-standards.md:8): Error handling must integrate centralized error logging and follow defensive programming patterns.

**Plan Conformance**: Plan correctly extends centralized error logging system.

---

**Requirement** (code-standards.md:33-63): Output suppression patterns for clean Claude Code display.

**Plan Gap**: Phase 2 cleanup utility (lines 139-170) and Phase 3 rotation (lines 173-205) don't specify output formatting.

**Recommendation**: Add output formatting requirements to cleanup script (single summary line, suppress verbose operations per code-standards.md:49-51).

---

**Requirement** (code-standards.md:89-99): Internal links must use relative paths from current file location.

**Plan Gap**: Phase 5 documentation tasks (lines 251-256) don't specify link format validation.

**Recommendation**: Add link validation task using `.claude/scripts/validate-links-quick.sh` after documentation updates.

#### Directory Organization Conformance

**Requirement** (directory-organization.md:22-48): scripts/ contains standalone CLI tools with argument parsing.

**Plan Conformance**: Phase 2 (lines 139-170) correctly places cleanup_error_logs.sh in scripts/ directory with CLI arguments (--dry-run, --filter-tests, --since).

---

**Requirement** (directory-organization.md:51-78): lib/ contains sourced function libraries.

**Plan Conformance**: Phase 1 (lines 117-125), Phase 3 (lines 177-202), and Phase 4 (lines 214-221) correctly modify lib/core/error-handling.sh.

### Missing Standard Considerations

#### Test/Production Segregation Context Detection

**Plan Proposal** (lines 54-56): Detect execution context using $0 variable analysis (check for "test_" prefix and "/tests/" path).

**Missing Standards Analysis**:
- No existing standard for context detection in error-handling.md
- No existing test vs production environment classification
- environment field (line 122) is new metadata dimension

**Recommendation**: This is a WELL-MOTIVATED CHANGE to standards. The plan should:
1. Document the context detection algorithm as a new pattern in error-handling.md
2. Define environment taxonomy (test, production, development) in error-handling pattern documentation
3. Explain why this segregation improves error analysis (test pollution elimination)

#### Error Metadata Schema Evolution

**Plan Proposal** (lines 206-238): Add severity, user, hostname fields to error log entries.

**Missing Standards Analysis**:
- Existing schema (error-handling.md:72-87) doesn't include these fields
- No schema versioning strategy documented
- No guidance on backward compatibility with old entries (which lack these fields)

**Recommendation**: The plan should:
1. Define schema version field (e.g., "schema_version": 2) to distinguish old/new entries
2. Document how query_errors() handles mixed schema versions
3. Specify whether old entries are migrated or coexist with new entries
4. Update error-handling.md with schema evolution strategy

#### Severity vs Error Type Relationship

**Plan Proposal** (lines 214-215): calculate_severity() maps error_type to severity level.

**Missing Clarity**:
- Is severity DERIVED from error_type (deterministic mapping)?
- Or is severity INDEPENDENT metadata (can vary for same error_type)?
- What is the severity mapping? (Plan says "state_error=medium, validation_error=low, agent_error=high, etc." at line 215 but doesn't provide complete mapping)

**Recommendation**: The plan should:
1. Provide complete severity mapping table (all 7 error types → severity levels)
2. Clarify whether mapping is hardcoded or configurable
3. Explain use case for severity (filtering? prioritization? alerting?)

### Well-Motivated Changes to Standards

The plan proposes changes that are justified by the error analysis report findings:

1. **Test/Production Segregation** (Priority: High, Effort: Low per report)
   - **Justification**: Error analysis found all 3 examined errors were test-generated (report line 24)
   - **Impact**: Prevents test errors from obscuring production issues
   - **Standards Update Needed**: Add environment field to JSONL schema in error-handling.md

2. **Error Log Cleanup Utility** (Priority: Medium, Effort: Low per report)
   - **Justification**: Need to clean existing test pollution from production logs
   - **Impact**: One-time and ongoing cleanup capability
   - **Standards Update Needed**: None (new utility, doesn't modify existing patterns)

3. **Enhanced Metadata** (Priority: Low, Effort: Low per report)
   - **Justification**: Enable richer analysis and filtering
   - **Impact**: Better error attribution and analysis capabilities
   - **Standards Update Needed**: Update JSONL schema in error-handling.md, add schema versioning

4. **Log Rotation Enhancement** (Priority: Low, Effort: Medium per report)
   - **Justification**: Enable more flexible rotation strategies
   - **Impact**: Better log management for different deployment scenarios
   - **Standards Update Needed**: Decide whether to make rotation configurable or keep fixed

## Recommendations

### Recommendation 1: Add Explicit Standards References

**Priority**: High
**Effort**: Low (15 minutes)

Add a "Standards Alignment" section to the plan after the Technical Design section, explicitly referencing:
- `.claude/docs/concepts/patterns/error-handling.md` - Core pattern being extended
- `.claude/docs/reference/library-api/error-handling.md` - API being modified
- `.claude/docs/reference/standards/code-standards.md` - Error handling requirements
- `.claude/docs/concepts/directory-organization.md` - File placement standards

This makes standards conformance explicit and reviewable.

**Example format**:
```markdown
## Standards Alignment

This implementation extends the following established patterns:

### Error Handling Pattern
Reference: .claude/docs/concepts/patterns/error-handling.md

**Current Standard**: Centralized JSONL log at errors.jsonl with 10MB rotation
**Extension**: Add test-errors.jsonl for test/production segregation
**Justification**: Test pollution identified in error analysis (all 3 errors were test-generated)

### Library API
Reference: .claude/docs/reference/library-api/error-handling.md

**Modified Functions**: log_command_error(), rotate_error_log()
**Backward Compatibility**: Existing 7-parameter signature preserved, new fields optional
**New Functions**: detect_execution_context(), calculate_severity()
```

### Recommendation 2: Clarify Backward Compatibility Strategy

**Priority**: High
**Effort**: Medium (30 minutes)

Phase 1 claims "Preserve backward compatibility - existing callers work without changes" (line 125) but doesn't specify the mechanism.

Add explicit backward compatibility design:
1. **Function Signature**: Keep log_command_error() 7-parameter signature unchanged
2. **Auto-Detection**: New fields (environment, severity, user, hostname) are auto-populated inside function
3. **Schema Coexistence**: Old log entries (without new fields) and new entries (with new fields) coexist
4. **Query Handling**: query_errors() handles missing fields gracefully (jq 'select(.severity // "unknown")')

Add verification task to Phase 1:
```markdown
- [ ] Identify all log_command_error() callers (grep -r "log_command_error" .claude/)
- [ ] Verify each caller still works after modification (no signature changes required)
- [ ] Test mixed schema queries (old entries without severity + new entries with severity)
```

### Recommendation 3: Resolve Log Rotation Configurability Decision

**Priority**: Medium
**Effort**: Medium (30 minutes)

The plan proposes "configurable rotation threshold" (line 180) which conflicts with existing fixed 10MB standard (error-handling.md:167).

Make explicit decision:

**Option A: Keep Fixed Rotation (Simpler, Standards-Compliant)**
- Remove "configurable rotation threshold" from Phase 3
- Keep existing 10MB / 5 backups policy
- Only add date-based rotation as alternative mode
- Update plan to acknowledge existing rotate_error_log() function

**Option B: Add Configurability (More Flexible, Requires Standards Update)**
- Add rotation_config.sh with user-configurable settings
- Define reasonable bounds (min 1MB, max 100MB)
- Update error-handling.md to document new configurability
- Explain why configurability is necessary (different deployment scenarios)

Recommendation: **Choose Option A** unless there is concrete evidence that different deployments need different rotation thresholds. The error analysis report doesn't identify rotation threshold as a problem.

### Recommendation 4: Define Complete Severity Mapping

**Priority**: Medium
**Effort**: Low (15 minutes)

Phase 4 proposes severity field but only provides examples: "state_error=medium, validation_error=low, agent_error=high, etc." (line 215).

Add complete mapping table to Technical Design section:

```markdown
### Severity Mapping Table

| Error Type           | Severity Level | Rationale                          |
|----------------------|----------------|-------------------------------------|
| validation_error     | low            | User input issue, easily fixable    |
| parse_error          | low            | Output format issue, retryable      |
| state_error          | medium         | Workflow disruption, requires debug |
| file_error           | medium         | I/O issue, may be transient         |
| timeout_error        | medium         | Performance issue, retryable        |
| agent_error          | high           | Subagent failure, blocks workflow   |
| execution_error      | high           | General failure, investigation needed|
```

Specify whether this mapping is:
- **Hardcoded** in calculate_severity() (deterministic)
- **Configurable** via configuration file (customizable)

Recommendation: **Hardcoded** for simplicity and consistency.

### Recommendation 5: Add Schema Versioning Strategy

**Priority**: Medium
**Effort**: Medium (30 minutes)

Adding new fields (severity, environment, user, hostname) to JSONL schema creates mixed-version entries.

Add schema versioning design to Technical Design section:

```markdown
### Schema Evolution Strategy

**Version 1 (Current)**:
- Fields: timestamp, command, workflow_id, user_args, error_type, error_message, source, stack, context

**Version 2 (New)**:
- Additional fields: severity, environment, user, hostname
- Backward compatible: Old entries remain valid, new entries have additional fields

**Query Compatibility**:
- query_errors() uses jq with default values: `select(.severity // "unknown")`
- /errors command displays severity if present, omits if absent
- No migration required: old and new entries coexist

**Schema Version Field** (Optional):
- Consider adding explicit "schema_version": 2 field to new entries
- Enables future migrations and analytics
```

### Recommendation 6: Update Documentation Requirements

**Priority**: Medium
**Effort**: Low (20 minutes)

Phase 5 documentation tasks (lines 251-256) should be expanded to include:

```markdown
- [ ] Update error-handling.md with test/production segregation pattern
- [ ] Update error-handling.md with environment field documentation
- [ ] Update error-handling.md with severity field and mapping table
- [ ] Update error-handling.md with enhanced metadata schema (user, hostname)
- [ ] Update error-handling.md JSONL schema section with schema v2
- [ ] Update library-api/error-handling.md with new functions (detect_execution_context, calculate_severity)
- [ ] Update library-api/error-handling.md with modified function behaviors
- [ ] Validate all internal links using .claude/scripts/validate-links-quick.sh
- [ ] Update /errors command guide with new query examples (--log-file for test errors)
- [ ] Update /errors command guide with severity filtering examples
```

### Recommendation 7: Reference Existing Functions

**Priority**: Low
**Effort**: Low (10 minutes)

Phase 3 proposes implementing rotation without acknowledging existing rotate_error_log() function (library-api/error-handling.md:151-170).

Update Phase 3 tasks to:
```markdown
- [ ] Review existing rotate_error_log() function implementation
- [ ] Extend rotate_error_log() to support date-based rotation (currently size-only)
- [ ] Add rotate_by_date() function for date-based rotation
- [ ] Update rotation logic to support both size and date modes
```

This makes clear the implementation EXTENDS existing functionality rather than creating from scratch.

## References

### Standards Documentation
- /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md - Error handling pattern definition (lines 1-630)
- /home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md - Error handling API reference (lines 1-680)
- /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md - Code standards including error handling (lines 1-118)
- /home/benjamin/.config/.claude/docs/concepts/directory-organization.md - Directory placement standards (lines 1-276)

### Plan and Research
- /home/benjamin/.config/.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md - Plan under revision (lines 1-380)
- /home/benjamin/.config/.claude/specs/841_error_analysis_repair/reports/001_error_analysis.md - Referenced in plan metadata (line 14)

### Key Standards Sections
- Error JSONL schema: error-handling.md:72-87
- Log rotation policy: error-handling.md:167-184
- Error type taxonomy: error-handling.md:49-65
- log_command_error() API: library-api/error-handling.md:34-95
- rotate_error_log() API: library-api/error-handling.md:151-170
- Code standards error handling: code-standards.md:8
- Output suppression patterns: code-standards.md:33-63
- Directory organization for scripts: directory-organization.md:22-48
