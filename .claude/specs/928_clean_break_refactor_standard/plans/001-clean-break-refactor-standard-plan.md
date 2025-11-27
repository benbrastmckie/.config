# Clean-Break Development Standard Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Clean-Break Development Standard
- **Scope**: Create and integrate a comprehensive standard enforcing clean-break refactoring practices to eliminate technical debt from backwards compatibility code
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 35
- **Research Reports**:
  - [Clean-Break Development Standard Research](../reports/001_clean_break_development_standard.md)

## Overview

This plan implements a formal Clean-Break Development Standard that prioritizes code coherence and quality over backwards compatibility. The standard provides decision criteria, technical patterns, anti-patterns, and enforcement mechanisms to ensure refactors produce unified, high-quality code free from technical debt.

The clean-break philosophy already exists partially in writing-standards.md (lines 23-45), but lacks formalization for code refactoring. This implementation creates a standalone standard document, integrates it with existing standards infrastructure, and establishes enforcement mechanisms consistent with the project's linter-based validation approach.

## Research Summary

Key findings from the research report inform this implementation:

- **Existing Philosophy**: Writing-standards.md contains clean-break philosophy (lines 23-45) but applies only to documentation, not code refactoring
- **Technical Debt Evidence**: Codebase contains migration templates, deprecated paths, and version-specific handling that clean-break enforcement would prevent
- **Decision Criteria**: Clean-break is appropriate for internal tooling with controlled consumers where all callers can be updated atomically
- **Anti-Patterns Identified**: Legacy comments, fallback code blocks, version detection, wrapper functions, and persistent migration helpers
- **Enforcement Model**: Existing linter infrastructure (check-library-sourcing.sh, lint_error_suppression.sh) provides template for clean-break enforcement

Recommended approach: Create standalone standard document following existing standards documentation patterns, integrate with CLAUDE.md via section reference, and optionally add linter enforcement for anti-pattern detection.

## Success Criteria

- [x] Clean-Break Development Standard document created at `.claude/docs/reference/standards/clean-break-development.md`
- [x] CLAUDE.md contains `clean_break_development` section with reference to standard
- [x] Writing-standards.md updated with cross-reference clarifying code vs. documentation scope
- [x] Standard includes decision tree for clean-break vs. gradual migration
- [x] Standard documents at least 4 clean-break patterns with examples
- [x] Standard documents at least 6 anti-patterns with detection criteria
- [x] Standard includes exception process documentation
- [x] All existing tests pass after changes

## Technical Design

### Architecture Overview

The clean-break standard integrates with existing standards infrastructure:

```
CLAUDE.md
    |
    +-- <!-- SECTION: clean_break_development -->
    |       References: .claude/docs/reference/standards/clean-break-development.md
    |
    +-- <!-- SECTION: code_standards -->
            References: .claude/docs/reference/standards/code-standards.md
                        (cross-references clean-break-development.md)

.claude/docs/concepts/writing-standards.md
    |
    +-- Development Philosophy > Clean-Break Refactors
            (adds scope note referencing clean-break-development.md for code patterns)
```

### Document Structure

The new standard document follows the established pattern from code-standards.md and documentation-standards.md:

1. **Header Section**: Title, [Used by:] metadata
2. **Philosophy and Rationale**: Why clean-break is preferred for internal systems
3. **Decision Tree**: When to apply clean-break vs. gradual migration
4. **Clean-Break Patterns**: Atomic Replacement, Interface Unification, State Machine Evolution, Documentation Purge
5. **Anti-Patterns**: What to avoid with detection criteria
6. **Enforcement**: Future linter integration points
7. **Exceptions and Escalation**: How to document exceptions when gradual migration is required
8. **Integration**: References to related standards

### CLAUDE.md Integration

New section inserted after `code_standards` section, before `code_quality_enforcement`:

```markdown
<!-- SECTION: clean_break_development -->
## Clean-Break Development Standard
[Used by: /refactor, /implement, /plan, all development commands]

See [Clean-Break Development Standard](.claude/docs/reference/standards/clean-break-development.md) for complete guidelines.

**Quick Reference**:
- Internal tooling changes: ALWAYS use clean-break (no deprecation periods)
- State machine/workflow changes: Atomic migration, then delete old code
- Interface changes: Unified implementation, no compatibility wrappers
- Documentation: Already enforced via Writing Standards
<!-- END_SECTION: clean_break_development -->
```

## Implementation Phases

### Phase 1: Create Standard Document [COMPLETE]
dependencies: []

**Objective**: Create the comprehensive clean-break development standard document

**Complexity**: Medium

Tasks:
- [x] Create `.claude/docs/reference/standards/clean-break-development.md` with complete structure
- [x] Write Philosophy and Rationale section explaining why clean-break is preferred for internal systems
- [x] Write Decision Tree section with formal decision criteria (4 questions from research)
- [x] Document 4 clean-break patterns: Atomic Replacement, Interface Unification, State Machine Evolution, Documentation Purge
- [x] Document 6+ anti-patterns with detection criteria: legacy comments, fallback blocks, version detection, wrapper functions, migration helpers, temporary compatibility code
- [x] Write Enforcement section with linter integration points (for future implementation)
- [x] Write Exceptions and Escalation section with exception process and bypass mechanism
- [x] Add Integration section with references to related standards (writing-standards.md, code-standards.md, refactoring-methodology.md)

Testing:
```bash
# Verify file created with required sections
test -f ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: File exists"
grep -q "## Philosophy and Rationale" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Philosophy section"
grep -q "## Decision Tree" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Decision tree"
grep -q "## Clean-Break Patterns" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Patterns section"
grep -q "## Anti-Patterns" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Anti-patterns section"
grep -q "## Enforcement" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Enforcement section"
grep -q "## Exceptions" ".claude/docs/reference/standards/clean-break-development.md" && echo "PASS: Exceptions section"
```

**Expected Duration**: 4 hours

### Phase 2: Integrate with CLAUDE.md [COMPLETE]
dependencies: [1]

**Objective**: Add clean_break_development section to CLAUDE.md for discoverability

**Complexity**: Low

Tasks:
- [x] Add `<!-- SECTION: clean_break_development -->` section to CLAUDE.md after `code_standards` section
- [x] Include [Used by:] metadata listing relevant commands (/refactor, /implement, /plan)
- [x] Write Quick Reference with 4-point summary
- [x] Verify CLAUDE.md section markers are properly formatted

Testing:
```bash
# Verify CLAUDE.md integration
grep -q "SECTION: clean_break_development" "/home/benjamin/.config/CLAUDE.md" && echo "PASS: Section marker"
grep -q "END_SECTION: clean_break_development" "/home/benjamin/.config/CLAUDE.md" && echo "PASS: End marker"
grep -q "Clean-Break Development Standard" "/home/benjamin/.config/CLAUDE.md" && echo "PASS: Title present"
grep -q "\[Used by:" "/home/benjamin/.config/CLAUDE.md" | grep -q "refactor" && echo "PASS: Used-by metadata"
```

**Expected Duration**: 1 hour

### Phase 3: Update Writing Standards Cross-Reference [COMPLETE]
dependencies: [1]

**Objective**: Add scope clarification to writing-standards.md distinguishing documentation vs. code patterns

**Complexity**: Low

Tasks:
- [x] Add scope note after line 45 in writing-standards.md clarifying documentation vs. code scope
- [x] Add link to clean-break-development.md for code refactoring patterns
- [x] Verify existing content in Clean-Break Refactors section is preserved
- [x] Ensure cross-reference uses correct relative path from writing-standards.md location

Testing:
```bash
# Verify writing-standards.md update
grep -q "clean-break-development.md" ".claude/docs/concepts/writing-standards.md" && echo "PASS: Cross-reference added"
grep -q "Scope Note\|code refactoring" ".claude/docs/concepts/writing-standards.md" && echo "PASS: Scope clarification"
# Verify original content preserved
grep -q "Prioritize coherence over compatibility" ".claude/docs/concepts/writing-standards.md" && echo "PASS: Original content preserved"
```

**Expected Duration**: 0.5 hours

### Phase 4: Validation and Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Validate all changes, run tests, and ensure integration is complete

**Complexity**: Low

Tasks:
- [x] Run link validation to ensure all cross-references resolve correctly
- [x] Run existing test suite to verify no regressions
- [x] Verify standards README.md lists the new standard document
- [x] Validate CLAUDE.md section order is correct (clean_break_development after code_standards)
- [x] Manual review of standard document for completeness against research recommendations

Testing:
```bash
# Link validation
bash .claude/scripts/validate-links-quick.sh

# Test suite
bash .claude/tests/run_all_tests.sh

# README check
grep -q "clean-break-development" ".claude/docs/reference/standards/README.md" && echo "PASS: Listed in README" || echo "INFO: May need README update"

# Section order verification
awk '/SECTION: code_standards/,/SECTION: clean_break_development/ {print NR": "$0}' "/home/benjamin/.config/CLAUDE.md" | head -5
```

**Expected Duration**: 2.5 hours

**Note**: Phase dependencies enable parallel execution when using `/implement`.
- Empty `[]` = no dependencies (runs in first wave)
- `[1]` = depends on Phase 1 (runs after Phase 1 completes)
- Phases 2 and 3 can run in parallel after Phase 1 completes

## Testing Strategy

### Unit Testing
- Verify standard document contains all required sections
- Verify CLAUDE.md section markers are properly formatted
- Verify cross-references resolve to valid files

### Integration Testing
- Run link validation script to ensure all internal links work
- Run existing test suite to verify no regressions from CLAUDE.md changes
- Verify grep patterns can detect anti-patterns documented in standard

### Validation Commands
```bash
# Complete validation
bash .claude/scripts/validate-all-standards.sh --all

# Link-specific validation
bash .claude/scripts/validate-links-quick.sh

# Standards structure validation
for f in ".claude/docs/reference/standards/clean-break-development.md"; do
  echo "Checking: $f"
  [ -f "$f" ] && echo "  EXISTS" || echo "  MISSING"
done
```

## Documentation Requirements

### New Documentation
- `.claude/docs/reference/standards/clean-break-development.md` - The primary deliverable

### Documentation Updates
- `/home/benjamin/.config/CLAUDE.md` - Add clean_break_development section
- `.claude/docs/concepts/writing-standards.md` - Add scope clarification cross-reference
- `.claude/docs/reference/standards/README.md` - Add entry for new standard (if exists)

### Documentation Standards Compliance
- Follow existing standards document pattern (code-standards.md template)
- Use [Used by:] metadata for discoverability
- Include Quick Reference in CLAUDE.md section
- No emojis in file content per project standards

## Dependencies

### Prerequisites
- Research report completed: `/home/benjamin/.config/.claude/specs/928_clean_break_refactor_standard/reports/001_clean_break_development_standard.md`
- CLAUDE.md file exists and is properly formatted with section markers
- Writing-standards.md exists at expected path

### External Dependencies
None - all changes are within the .claude/ system

### Risk Mitigation
- **Risk**: CLAUDE.md section ordering breaks other references
  - **Mitigation**: Insert section in alphabetical order with surrounding sections, verify section markers are complete

- **Risk**: Cross-references create circular dependencies
  - **Mitigation**: Use unidirectional references (CLAUDE.md -> standard, writing-standards -> standard)

- **Risk**: Linter enforcement too aggressive for existing code
  - **Mitigation**: Enforcement section documents future linter work as optional, not immediate requirement

## Future Enhancements

The following items are documented in the standard but not implemented in this plan:

1. **lint_backward_compat.sh** - Linter to detect backwards compatibility anti-patterns
2. **Pre-commit hook integration** - Add to pre-commit validation pipeline
3. **Refactoring methodology integration** - Update refactoring-methodology.md to reference clean-break standard

These are tracked as P3 items per research recommendations and can be implemented in a follow-up plan.
