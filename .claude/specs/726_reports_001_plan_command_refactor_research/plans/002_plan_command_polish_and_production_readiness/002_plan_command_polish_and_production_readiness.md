# Plan Command Polish and Production Readiness

## Metadata
- **Date**: 2025-11-16
- **Feature**: Complete /plan command polish work for production readiness
- **Scope**: Documentation extraction, test suite, user guide, automated validation
- **Estimated Phases**: 4
- **Estimated Hours**: 10-15
- **Structure Level**: 1
- **Expanded Phases**: [1, 2]
- **Complexity Score**: 68
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Parent Plan**: [001_reports_001_plan_command_refactor_research_plan.md](./001_reports_001_plan_command_refactor_research_plan.md)
- **Dependencies**: Requires completed Phase 0-7 from parent plan

## Overview

The /plan command core implementation is complete (8/8 phases, 17/21 success criteria). This plan addresses the remaining 4 success criteria required for production readiness:

1. **Standard 14 Compliance**: Extract documentation to reduce command file size while maintaining functionality (target: minimize through documentation extraction, not strict line limit)
2. **Test Suite**: Create comprehensive test coverage (≥80%)
3. **Documentation Guide**: User-facing documentation with examples and troubleshooting
4. **Automated Validation**: Script to verify Standard 14 compliance

## Current State

**Completed Work** (from parent plan):
- ✅ All 8 implementation phases (orchestration, analysis, delegation, validation, presentation)
- ✅ validate-plan.sh library (440 lines, 6 validation functions)
- ✅ Full standards compliance (Standards 0, 11, 12, 13, 15, 16)
- ✅ Graceful degradation and error handling
- ✅ State persistence and caching

**Files**:
- `/home/benjamin/.config/.claude/commands/plan.md` (985 lines) → Target: Reduce through documentation extraction
- `/home/benjamin/.config/.claude/lib/validate-plan.sh` (440 lines) ✓ Complete

**Git History**:
```
b98675d4 - Phases 0-2 foundation
930c2088 - Phase 3 research delegation
823d4c75 - Phases 4-7 validation & finalization
76986baf - Plan review & status documentation
```

## Success Criteria

- [ ] Command file documentation extracted to guide (Standard 14 compliance - prioritize functionality over strict line limit)
- [ ] Comprehensive guide exists at `.claude/docs/guides/plan-command-guide.md`
- [ ] Bidirectional cross-references between command and guide
- [ ] Test suite exists at `.claude/tests/test_plan_command.sh`
- [ ] Test coverage ≥80% for plan.md and validate-plan.sh
- [ ] Test isolation using CLAUDE_SPECS_ROOT override
- [ ] Cleanup traps in all tests
- [ ] Automated validation script at `.claude/lib/validate_executable_doc_separation.sh`
- [ ] All tests pass
- [ ] Documentation includes usage examples, workflows, troubleshooting
- [ ] No functionality lost during documentation extraction

## Implementation Phases

### Phase 1: Standard 14 Compliance - Documentation Extraction (High Complexity)
dependencies: []
**Status**: PENDING

**Objective**: Extract comprehensive documentation from plan.md to guide file, reducing command size through documentation removal while preserving all functionality (functionality takes priority over strict line limits)

**Summary**: Systematically extract documentation from 985-line plan.md command file to separate guide file. Analyze and classify content, create structured guide with 12 sections, extract phase-by-phase explanations, minimize inline comments while preserving critical execution markers, add bidirectional cross-references, and verify functionality preservation. Target: meaningful reduction through doc extraction without compromising features.

**Duration**: 2-3 hours

For detailed tasks and implementation, see [Phase 1 Details](phase_1_standard_14_compliance_documentation_extraction.md)

### Phase 2: Test Suite Creation (High Complexity)
dependencies: [1]
**Status**: PENDING

**Objective**: Create comprehensive test suite with ≥80% coverage for plan.md and validate-plan.sh

**Summary**: Build comprehensive test suite with 8 test groups covering all aspects of /plan command functionality. Create test infrastructure with isolation (CLAUDE_SPECS_ROOT override), implement 40+ test cases (argument parsing, feature analysis, research delegation, standards discovery, plan creation, validation, expansion evaluation, integration tests), verify ≥80% coverage, ensure test isolation with cleanup traps, and document test usage. All tests must pass with no production directory pollution.

**Duration**: 4-6 hours

For detailed tasks and implementation, see [Phase 2 Details](phase_2_test_suite_creation.md)

### Phase 3: Documentation Guide Creation
dependencies: [1]

**Objective**: Create comprehensive user-facing documentation with examples, workflows, and troubleshooting

**Complexity**: Medium (6/10)

**Tasks**:
- [ ] **STRUCTURE**: Create guide outline in plan-command-guide.md:
  - 1. Overview and Purpose
  - 2. Quick Start
  - 3. Usage Examples
  - 4. Feature Analysis
  - 5. Research Delegation
  - 6. Plan Validation
  - 7. Expansion Evaluation
  - 8. Standards Compliance
  - 9. Troubleshooting
  - 10. Advanced Topics
  - 11. Agent Integration
  - 12. API Reference
- [ ] **SECTION 1**: Overview and Purpose
  - Explain what /plan command does
  - Key features and capabilities
  - When to use vs. when to use /implement, /expand, /research
  - Architecture diagram (text-based)
- [ ] **SECTION 2**: Quick Start
  - Installation/setup (if needed)
  - Basic usage: `/plan "feature description"`
  - What to expect (output, files created)
  - Next steps after plan creation
- [ ] **SECTION 3**: Usage Examples
  - Example 1: Simple feature (no research)
    - Command: `/plan "Add button to UI"`
    - Expected output
    - Generated plan preview
  - Example 2: Complex feature (with research)
    - Command: `/plan "Migrate authentication to OAuth2"`
    - Research delegation output
    - Generated plan with research integration
  - Example 3: With existing research reports
    - Command: `/plan "Refactor plugin system" /path/to/report1.md /path/to/report2.md`
    - Report integration process
  - Example 4: Multi-word feature descriptions
    - Quoting requirements
    - Special character handling
- [ ] **SECTION 4**: Feature Analysis
  - LLM classification process
  - Complexity scoring (1-10 scale)
  - Heuristic fallback algorithm
  - Keyword detection
  - Research delegation triggers
- [ ] **SECTION 5**: Research Delegation
  - When research is triggered (complexity ≥7)
  - Topic generation logic
  - Keyword-based topic selection
  - Parallel agent invocation
  - Metadata extraction and context reduction
  - Graceful degradation on failures
- [ ] **SECTION 6**: Plan Validation
  - Validation library overview
  - 8 required metadata fields
  - Standards compliance checks
  - Test phase requirements
  - Documentation task requirements
  - Dependency validation
  - Error vs. warning interpretation
- [ ] **SECTION 7**: Expansion Evaluation
  - When expansion is recommended
  - Complexity thresholds
  - Benefits of expansion
  - Using /expand command
- [ ] **SECTION 8**: Standards Compliance
  - Standard 0: Imperative language
  - Standard 11: Agent invocation
  - Standard 12: Behavioral injection
  - Standard 13: Path handling
  - Standard 15: Library sourcing
  - Standard 16: Return code verification
- [ ] **SECTION 9**: Troubleshooting
  - Common issues and solutions:
    - "File not found" errors
    - "Relative path" errors
    - "Validation failed" errors
    - "Research delegation failed" warnings
    - "Plan too small" warnings
  - Debug mode instructions
  - Log file locations
  - How to report bugs
- [ ] **SECTION 10**: Advanced Topics
  - Custom complexity thresholds
  - Research topic customization
  - Validation customization
  - Integration with CI/CD
  - Batch plan generation
- [ ] **SECTION 11**: Agent Integration
  - Plan-architect agent structure
  - Research-specialist agent requirements
  - Behavioral injection pattern
  - Context passing conventions
  - Return signal format
- [ ] **SECTION 12**: API Reference
  - Command-line arguments
  - Environment variables
  - State file format
  - Validation report JSON schema
  - Exit codes
- [ ] **POLISH**: Review and refine
  - Add table of contents with links
  - Ensure consistent formatting
  - Add cross-references to command file
  - Spell check and grammar review
  - Code examples syntax highlighting

**Expected Duration**: 3-4 hours

**Phase 3 Completion Requirements**:
- [ ] Guide file created with all sections
- [ ] Examples tested and verified
- [ ] Cross-references to command file
- [ ] Table of contents with working links
- [ ] Git commit: `docs(726): add comprehensive plan command guide`

### Phase 4: Automated Validation Script
dependencies: [1]

**Objective**: Create automated script to verify Standard 14 compliance (executable/doc separation)

**Complexity**: Low (4/10)

**Tasks**:
- [ ] **CREATE**: Script at `.claude/lib/validate_executable_doc_separation.sh`
- [ ] **IMPLEMENT**: validate_line_count() function
  - Read command file
  - Count non-blank, non-comment lines
  - Report current line count (informational, not pass/fail)
  - Compare to baseline (985 lines) and calculate reduction percentage
  - Output: Line count, reduction percentage, and trend analysis
- [ ] **IMPLEMENT**: validate_guide_exists() function
  - Check for guide file existence
  - Verify guide file is not empty (≥1000 bytes recommended)
  - Return 0 if exists and sufficient, 1 otherwise
  - Output: File path and size
- [ ] **IMPLEMENT**: validate_cross_references() function
  - Search command for guide references (pattern: "See.*guide")
  - Search guide for command references (pattern: "plan.md")
  - Count bidirectional references
  - Return 0 if ≥3 references each direction (reduced threshold for flexibility), 1 otherwise
  - Output: Reference count and examples
- [ ] **IMPLEMENT**: validate_no_duplication() function
  - Extract code blocks from guide
  - Check if code blocks exist in command file
  - Flag any duplicated bash blocks (>10 lines)
  - Return 0 if no duplication, 1 if duplication found
  - Output: Duplication report
- [ ] **IMPLEMENT**: generate_compliance_report() function
  - Run all validation functions
  - Combine results into JSON report
  - Include: pass/fail status, line counts, reference counts, issues
  - Return 0 if all checks pass, 1 if any fail
- [ ] **IMPLEMENT**: Main validation entry point
  - Accept command file path as argument
  - Auto-detect guide file path
  - Run all validations
  - Output summary report
  - Exit with appropriate code
- [ ] **DOCUMENT**: Add usage instructions
  - Header comment with purpose
  - Usage examples
  - Return code documentation
  - Integration with CI/CD
- [ ] **TEST**: Verify script functionality
  - Test with compliant command/guide pair
  - Test with large command file (baseline measurement)
  - Test with missing guide
  - Test with insufficient cross-references
  - Test with duplicated content
- [ ] **INTEGRATE**: Add to project validation
  - Document in Testing Protocols
  - Add to CI/CD if applicable
  - Reference from CLAUDE.md

**Expected Duration**: 1-2 hours

**Phase 4 Completion Requirements**:
- [ ] Script created with all validation functions
- [ ] Tests passing
- [ ] Documentation complete
- [ ] Git commit: `feat(726): add automated Standard 14 validation`

## Testing Requirements

### Test Coverage
- Test suite must achieve ≥80% coverage for:
  - `/home/benjamin/.config/.claude/commands/plan.md`
  - `/home/benjamin/.config/.claude/lib/validate-plan.sh`
- Coverage measured by lines executed vs. total executable lines

### Test Isolation
- All tests use `CLAUDE_SPECS_ROOT="/tmp/test_plan_$$"` override
- No production directory pollution allowed
- Cleanup trap removes all test artifacts
- Tests must be idempotent (can run multiple times)

### Test Categories
1. Unit tests: Individual functions and components
2. Integration tests: End-to-end workflows
3. Edge case tests: Error conditions, boundary values
4. Regression tests: Previously identified bugs

## Documentation Requirements

### Guide File Structure
- Clear table of contents with section links
- Consistent formatting (Markdown)
- Code examples with syntax highlighting
- Cross-references to command file (bidirectional)
- Examples tested and verified working

### Guide Content
- Overview and quick start
- Usage examples (simple, complex, with reports)
- Feature analysis explanation
- Research delegation workflow
- Validation process
- Troubleshooting section
- Agent integration guide
- API reference

## Success Metrics

### Quantitative
- Command file: Reduced from 985 lines baseline (target: meaningful reduction through doc extraction, functionality preserved)
- Guide file: ≥2000 lines comprehensive documentation
- Test coverage: ≥80%
- Cross-references: ≥3 bidirectional links (quality over quantity)
- All tests passing: 100%

### Qualitative
- Documentation clarity (can new user understand and use?)
- Code maintainability (minimal inline comments, clear execution flow)
- Test reliability (no flaky tests, clear assertions)
- Error messages helpful (diagnostic information included)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Functionality broken during doc extraction | Medium | High | Thorough testing after each extraction, git commits at checkpoints |
| Test coverage insufficient | Low | Medium | Systematic test group creation, coverage measurement |
| Documentation unclear | Medium | Medium | User testing, examples verification |
| Insufficient documentation extraction | Low | Medium | Systematic extraction, focus on clarity over arbitrary limits |

## Rollback Strategy

If issues occur during implementation:

```bash
# Phase 1 rollback (doc extraction broken)
git log --oneline -5  # Find commit before extraction
git checkout <commit-hash> -- .claude/commands/plan.md
git commit -m "revert: rollback doc extraction due to functionality break"

# Phase 2 rollback (test failures)
rm .claude/tests/test_plan_command.sh
git checkout HEAD -- .claude/tests/test_plan_command.sh

# Phase 3 rollback (doc issues)
rm .claude/docs/guides/plan-command-guide.md
git checkout HEAD -- .claude/docs/guides/plan-command-guide.md

# Complete rollback
git reset --hard <last-good-commit>
```

## Dependencies

### External
- jq (JSON parsing in tests)
- bash 4.0+ (associative arrays)
- git (version control)

### Internal
- All libraries from parent plan:
  - detect-project-dir.sh
  - workflow-state-machine.sh
  - state-persistence.sh
  - error-handling.sh
  - verification-helpers.sh
  - unified-location-detection.sh
  - complexity-utils.sh
  - metadata-extraction.sh
  - validate-plan.sh

## Notes

**Complexity Calculation**:
```
Tasks: 80 tasks
Phases: 4 phases
Hours: 12.5 estimated hours
Dependencies: 3 phase dependencies

Score = (80 × 0.3) + (4 × 1.0) + (12.5 × 0.1) + (3 × 2.0)
Score = 24 + 4 + 1.25 + 6 = 35.25

Adjusted for technical writing complexity: 35.25 × 1.9 = 68
```

**Why Level 0 Structure**:
- Complexity score 68 is below Level 1 threshold (50-200 typically expands)
- All phases are well-defined and sequential
- Documentation extraction is primarily mechanical
- Test creation follows established patterns

**Estimated vs. Actual**:
Parent plan estimated 17-21 hours, completed in 6-8 hours. This polish work is more predictable (less research, more execution), so estimate should be accurate.

**Integration with Parent Plan**:
This plan completes the 4 remaining success criteria from parent plan:
- Success criterion 2: Standard 14 compliance (Phase 1)
- Success criterion 14: Test suite (Phase 2)
- Success criterion 19: Documentation guide (Phase 3)
- Success criterion 20: Automated validation (Phase 4)

After completion, parent plan will be 21/21 criteria (100% complete).

## Revision History

- **2025-11-16**: Revised to allow command file >250 lines while still pursuing documentation extraction. Changes: (1) Removed strict 250-line limit from Phase 1 objective and success criteria, (2) Changed validation function to report line count informatively rather than pass/fail, (3) Updated success metrics to prioritize functionality over arbitrary line limits, (4) Reduced cross-reference threshold from ≥5 to ≥3 for flexibility, (5) Updated risk assessment to reflect focus on clarity over limits. Rationale: Preserving full functionality is more important than meeting an arbitrary line count target; Standard 14 intent (separation of concerns) is better served by comprehensive documentation extraction than by compromising features.
