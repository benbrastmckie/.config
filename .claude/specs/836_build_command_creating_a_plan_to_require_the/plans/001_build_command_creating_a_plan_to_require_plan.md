# Build Command Summary Link Requirements Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Enforce summary links to plans in /build workflow (simplified)
- **Scope**: Update implementation-executor template and /build validation to require plan links only
- **Estimated Phases**: 2
- **Estimated Hours**: 0.75
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 15.0
- **Research Reports**:
  - [Build Command Summary Link Requirements](../reports/001_build_command_summary_link_requirements.md)
  - [Summary Link Simplification](../reports/002_summary_link_simplification.md)

## Overview

The /build command currently creates implementation summaries but does not consistently enforce linking to the plans that informed the implementation. This simplified plan implements consistent plan link requirements in summaries through minimal template updates and validation.

The enhancement ensures traceability from summaries to plans (which already link to reports), creating a complete traceability chain: Summary → Plan → Reports. This approach avoids redundant linking while maintaining full context preservation.

## Research Summary

Key findings from research reports:

**Original Gap Identified** (Report 001):
- Implementation-executor summary template lacks consistent plan linking
- No validation ensures summaries include plan links
- Some existing summaries link to plans, but not all

**Simplification Analysis** (Report 002):
- Direct Summary → Reports linking creates unnecessary complexity (5 phases, 2.5 hours)
- Plans already link to reports in metadata, creating complete traceability chain
- 35+ existing summaries show no report links (proven pattern works)
- Co-located directory structure (specs/{NNN_topic}/) makes navigation trivial
- Traceability chain Summary → Plan → Reports is sufficient

**Recommended Approach**:
1. Update implementation-executor template to require plan link in metadata
2. Add simple validation to /build checking for plan link
3. Update best practices documentation to reflect simplified pattern

This reduces implementation from 5 phases to 2 phases while maintaining full traceability.

## Success Criteria

- [ ] Implementation-executor template includes mandatory plan link in metadata
- [ ] Template shows relative path format (../plans/NNN_plan.md)
- [ ] /build validation checks for plan link in summaries
- [ ] Validation warnings emitted if plan link missing (non-blocking)
- [ ] Best practices documentation updated to reflect simplified pattern
- [ ] Test /build creates summary with plan link
- [ ] Relative paths used for portability (../plans/)

## Technical Design

### Architecture

**Simplified Traceability Chain**:
```
Summary → Plan → Reports
   |
   └─ Plan link in metadata (required)
           |
           └─ Plan already contains report links in metadata
```

**Implementation Flow**:
```
/build command
  ↓
  1. Pass plan_path to implementer-coordinator (existing)
  ↓
  2. Implementation-executor generates summary with:
     - Plan link in metadata section (new requirement)
  ↓
  3. /build validates summary contains plan link
     - Warning if plan link missing (non-blocking)
```

### Template Updates

**Implementation-Executor Summary Template** (around line 177):

Update the Metadata section to include mandatory plan link:
```markdown
## Metadata
- **Date**: YYYY-MM-DD HH:MM
- **Plan**: [Plan Title](../plans/NNN_plan.md)
- **Executor Instance**: [N of M]
- **Context Exhaustion**: [Yes/No]
- **Phases Completed**: [N/M]
- **Git Commits**: [list of hashes]
```

The plan path is provided to implementation-executor by implementer-coordinator, so no discovery is needed.

### Validation Strategy

**Validation Checks** (/build Block 4, completion):
```bash
# Validate summary includes plan link
if [ -f "$SUMMARY_PATH" ]; then
  if ! grep -q "^\*\*Plan\*\*:" "$SUMMARY_PATH" 2>/dev/null; then
    echo "⚠ WARNING: Summary missing plan link" >&2
  fi
fi
```

**Backward Compatibility**:
- Existing summaries without plan links remain valid
- Warning informs but does not block workflow completion
- Enables gradual migration to new standard

### Path Format

**Relative Paths for Portability**:
- From: `specs/{NNN_topic}/summaries/001_summary.md`
- To plan: `../plans/001_plan.md`

This ensures links remain valid when projects are moved or cloned. Reports are accessible via the plan's metadata section.

## Implementation Phases

### Phase 1: Update Implementation-Executor Template and Validation [COMPLETE]
dependencies: []

**Objective**: Add plan link requirement to template and validation to /build

**Complexity**: Low

Tasks:
- [x] Read current implementation-executor.md template (around line 177)
- [x] Add mandatory "Plan" field to Metadata section with relative link format
- [x] Update STEP 4 instructions to require plan link in all summaries
- [x] Add validation block to /build command (after line 876)
- [x] Implement grep check for "**Plan**:" pattern in summary
- [x] Emit non-blocking warning if plan link missing
- [x] Test validation with compliant and non-compliant summaries

Testing:
```bash
# Verify template update
grep -A 5 "^## Metadata" /home/benjamin/.config/.claude/agents/implementation-executor.md | grep "Plan"

# Test validation logic
SUMMARY_PATH="/home/benjamin/.config/.claude/specs/833_claude_scripts_directory_to_identify_if_any/summaries/001_cleanup_implementation_summary.md"
grep -q "^\*\*Plan\*\*:" "$SUMMARY_PATH" && echo "✓ Plan link found" || echo "⚠ Plan link missing"
```

**Expected Duration**: 0.5 hours

### Phase 2: Update Documentation Standards [COMPLETE]
dependencies: [1]

**Objective**: Update best practices to reflect simplified traceability pattern

**Complexity**: Low

Tasks:
- [x] Update orchestration-best-practices.md Phase 6 template (around line 807-821)
- [x] Remove "Report Integration" requirement from summary template
- [x] Update integration checklist to reference traceability chain
- [x] Add "Artifact Traceability" section to directory-protocols.md (after line 199)
- [x] Document Summary → Plan → Reports navigation pattern
- [x] Explain why direct report links are unnecessary
- [x] Add example showing relative path format

Testing:
```bash
# Verify best practices updated
grep -A 10 "Phase 6: Documentation" /home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-best-practices.md

# Verify traceability documentation added
grep -q "Artifact Traceability" /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md
```

**Expected Duration**: 0.25 hours

## Testing Strategy

### Unit Testing
- Test validation logic with compliant summaries (with plan links)
- Test validation logic with non-compliant summaries (missing plan links)
- Test relative path format generation
- Verify warning messages are clear and actionable

### Integration Testing
1. Create test topic with plan (specs/{NNN_test}/)
2. Run /build on test plan
3. Verify summary generated with plan link in metadata
4. Verify relative path format (../plans/NNN_plan.md)
5. Verify link resolves correctly from summaries/ directory

### Validation Testing
- Run /build on existing summaries (verify backward compatibility)
- Manually remove plan link from summary (verify warning emitted)
- Verify warning is non-blocking (workflow completes)

### Regression Testing
- Verify existing /build workflows still complete successfully
- Verify backward compatibility with summaries lacking plan links
- Verify non-blocking warnings don't fail workflow completion

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` (add plan link to template)
- `/home/benjamin/.config/.claude/commands/build.md` (add validation logic)
- `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestration-best-practices.md` (simplify Phase 6)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (add traceability section)

### New Content
- Artifact Traceability section explaining Summary → Plan → Reports pattern
- Example metadata section showing plan link format
- Validation warning documentation
- Rationale for simplified approach (avoid redundant linking)

## Dependencies

### External Dependencies
- None (uses existing bash utilities: grep)

### Library Dependencies
- None (validation is simple grep check)

### File Dependencies
- Plans must exist in specs/{NNN_topic}/plans/ (existing requirement)
- Summaries generated in specs/{NNN_topic}/summaries/
- Topic directory structure must follow directory-protocols.md

## Risk Assessment

### Low Risk
- Template updates (Phase 1): Isolated change, adds one metadata field
- Validation (Phase 1): Simple grep check, non-blocking warning
- Documentation updates (Phase 2): Informational only

### Mitigation Strategies
- Non-blocking warnings maintain backward compatibility
- Clear warning messages guide users to add plan links
- Simple implementation reduces potential failure points
- No complex discovery logic to maintain

## Notes

**Simplification Rationale**: The original plan proposed adding both plan and report links to summaries with discovery mechanisms (5 phases, 2.5 hours). Research revealed this creates unnecessary complexity since:
- Plans already link to reports in metadata (complete traceability exists)
- Topic-based directory structure co-locates all artifacts (easy navigation)
- 35+ existing summaries show no report links (proven pattern)
- Summary → Plan → Reports chain is sufficient for full traceability

**Backward Compatibility**: Existing summaries without plan links remain valid. Validation warnings inform but do not fail workflows, enabling gradual migration.

**Relative Paths**: Using ../plans/ ensures portability across systems and prevents breaking links when projects move or are cloned.

**Implementation Simplicity**: This approach requires only:
- One metadata field addition to template
- One grep validation check
- Documentation updates explaining the pattern

Total: 2 phases, 0.75 hours (70% time savings vs original plan).
