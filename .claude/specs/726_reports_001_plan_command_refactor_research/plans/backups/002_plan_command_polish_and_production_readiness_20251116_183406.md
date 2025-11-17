# Plan Command Polish and Production Readiness

## Metadata
- **Date**: 2025-11-16
- **Feature**: Complete /plan command polish work for production readiness
- **Scope**: Documentation extraction, test suite, user guide, automated validation
- **Estimated Phases**: 4
- **Estimated Hours**: 10-15
- **Structure Level**: 0
- **Complexity Score**: 68
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Parent Plan**: [001_reports_001_plan_command_refactor_research_plan.md](./001_reports_001_plan_command_refactor_research_plan.md)
- **Dependencies**: Requires completed Phase 0-7 from parent plan

## Overview

The /plan command core implementation is complete (8/8 phases, 17/21 success criteria). This plan addresses the remaining 4 success criteria required for production readiness:

1. **Standard 14 Compliance**: Extract documentation to reduce command file from 985 to <250 lines
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
- `/home/benjamin/.config/.claude/commands/plan.md` (985 lines) ⚠️ Exceeds target
- `/home/benjamin/.config/.claude/lib/validate-plan.sh` (440 lines) ✓ Complete

**Git History**:
```
b98675d4 - Phases 0-2 foundation
930c2088 - Phase 3 research delegation
823d4c75 - Phases 4-7 validation & finalization
76986baf - Plan review & status documentation
```

## Success Criteria

- [ ] Command file reduced to <250 lines (Standard 14 compliance)
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

### Phase 1: Standard 14 Compliance - Documentation Extraction
dependencies: []

**Objective**: Extract comprehensive documentation from plan.md to guide file, reducing command to <250 lines while preserving all functionality

**Complexity**: High (8/10)

**Tasks**:
- [ ] **ANALYZE**: Identify documentation vs. execution content in current plan.md (985 lines)
- [ ] **CLASSIFY**: Categorize all content:
  - Keep in command: Bash execution blocks, essential inline comments, error messages
  - Move to guide: Overview text, detailed explanations, Standard N rationale, examples
- [ ] **CREATE**: Initialize plan-command-guide.md with structure:
  - Overview and purpose
  - Usage examples (simple, complex, with reports)
  - Phase-by-phase explanation
  - Feature analysis criteria
  - Research delegation workflow
  - Validation process
  - Expansion evaluation
  - Standards compliance reference
  - Troubleshooting section
  - Agent integration guide
- [ ] **EXTRACT**: Move documentation content preserving context:
  - Phase 0: Orchestrator initialization explanation
  - Phase 1: Feature analysis and LLM classification details
  - Phase 1.5: Research delegation topic generation logic
  - Phase 2: Standards discovery process
  - Phase 3: Plan creation behavioral injection
  - Phase 4: Validation library integration
  - Phase 5: Expansion evaluation criteria
  - Phase 6: Presentation and next steps
- [ ] **REDUCE**: Minimize inline comments in plan.md:
  - Keep: Critical execution markers (EXECUTE NOW, YOU MUST)
  - Keep: Standard N compliance tags
  - Keep: Error diagnostic templates
  - Remove: Detailed explanations of "why"
  - Remove: Multi-line comment blocks
  - Replace: Long comments with "See guide: Section X.Y"
- [ ] **CROSS-REFERENCE**: Add bidirectional links:
  - Command → Guide: "See plan-command-guide.md §3.2 for details"
  - Guide → Command: "Implementation: plan.md lines 123-145"
- [ ] **VERIFY**: Confirm command file ≤250 lines
- [ ] **VALIDATE**: Run command to ensure no functionality lost
- [ ] **TEST**: Execute with multiple feature descriptions to verify behavior unchanged

**Expected Duration**: 2-3 hours

**Phase 1 Completion Requirements**:
- [ ] plan.md reduced to ≤250 lines
- [ ] plan-command-guide.md created with comprehensive documentation
- [ ] Bidirectional cross-references in place
- [ ] Functionality verification passed
- [ ] Git commit: `refactor(726): extract documentation per Standard 14`

### Phase 2: Test Suite Creation
dependencies: [1]

**Objective**: Create comprehensive test suite with ≥80% coverage for plan.md and validate-plan.sh

**Complexity**: High (7/10)

**Tasks**:
- [ ] **CREATE**: Test file at `.claude/tests/test_plan_command.sh`
- [ ] **SETUP**: Test infrastructure:
  - Source test utilities if available
  - Set CLAUDE_SPECS_ROOT="/tmp/test_plan_$$"
  - Set CLAUDE_PROJECT_DIR to test directory
  - Create cleanup trap: `trap cleanup EXIT`
- [ ] **TEST GROUP 1**: Argument Parsing and Validation
  - Test: Single-word feature description
  - Test: Multi-word quoted feature description
  - Test: Feature with special characters
  - Test: Empty feature description (should error)
  - Test: Absolute path validation (reject relative paths)
  - Test: Multiple report paths
  - Test: Non-existent report paths (should warn)
  - Test: Help flag display
- [ ] **TEST GROUP 2**: Feature Analysis (LLM Classification)
  - Test: Low complexity feature (complexity ≤3)
  - Test: Medium complexity feature (complexity 4-6)
  - Test: High complexity feature (complexity ≥7)
  - Test: Architecture keywords trigger research
  - Test: Heuristic fallback when LLM unavailable
  - Test: JSON output validation
  - Test: Complexity score caching to state
- [ ] **TEST GROUP 3**: Research Delegation
  - Test: Research skipped for low complexity
  - Test: Research triggered for high complexity
  - Test: Topic generation (2-4 topics based on complexity)
  - Test: Keyword-based topic selection
  - Test: Report path pre-calculation (absolute paths)
  - Test: Directory creation (lazy creation)
  - Test: Placeholder report generation
  - Test: Metadata extraction and caching
  - Test: Graceful degradation on agent failure
- [ ] **TEST GROUP 4**: Standards Discovery
  - Test: CLAUDE.md upward search
  - Test: Minimal CLAUDE.md creation if missing
  - Test: Standards path caching
- [ ] **TEST GROUP 5**: Plan Creation
  - Test: Plan path pre-calculation
  - Test: Topic directory allocation
  - Test: Plan file creation
  - Test: File size verification (≥500 bytes)
  - Test: Phase count verification (≥3)
  - Test: Checkbox count verification (≥10)
  - Test: Fail-fast on missing plan file
- [ ] **TEST GROUP 6**: Plan Validation (validate-plan.sh)
  - Test: validate_metadata() with complete metadata
  - Test: validate_metadata() with missing fields
  - Test: validate_standards_compliance() with CLAUDE.md reference
  - Test: validate_standards_compliance() without reference
  - Test: validate_test_phases() with testing protocols
  - Test: validate_documentation_tasks() with doc policy
  - Test: validate_phase_dependencies() with valid dependencies
  - Test: validate_phase_dependencies() with circular dependencies
  - Test: validate_phase_dependencies() with self-dependencies
  - Test: validate_phase_dependencies() with forward references
  - Test: generate_validation_report() JSON structure
- [ ] **TEST GROUP 7**: Expansion Evaluation
  - Test: No expansion for low complexity
  - Test: Expansion recommended for high complexity
  - Test: Expansion recommended for many phases
- [ ] **TEST GROUP 8**: Integration Tests
  - Test: End-to-end simple feature (no research)
  - Test: End-to-end complex feature (with research)
  - Test: End-to-end with provided report paths
  - Test: Validation failure handling
  - Test: State persistence across phases
- [ ] **COVERAGE**: Verify ≥80% coverage:
  - Calculate lines executed vs. total lines
  - Identify untested code paths
  - Add tests for edge cases
- [ ] **ISOLATION**: Verify test isolation:
  - No production directory pollution
  - All test artifacts in /tmp/test_plan_$$
  - Cleanup trap removes all test files
  - Tests can run in any order
  - Tests can run in parallel
- [ ] **DOCUMENT**: Add test documentation:
  - Header comment explaining test purpose
  - Usage instructions
  - Coverage report interpretation

**Expected Duration**: 4-6 hours

**Phase 2 Completion Requirements**:
- [ ] Test file created with all test groups
- [ ] Coverage ≥80% verified
- [ ] Test isolation verified (no production pollution)
- [ ] All tests passing
- [ ] Git commit: `test(726): add comprehensive test suite for plan command`

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
  - Return 0 if ≤250, 1 if >250
  - Output: Line count and pass/fail status
- [ ] **IMPLEMENT**: validate_guide_exists() function
  - Check for guide file existence
  - Verify guide file is not empty (≥1000 bytes recommended)
  - Return 0 if exists and sufficient, 1 otherwise
  - Output: File path and size
- [ ] **IMPLEMENT**: validate_cross_references() function
  - Search command for guide references (pattern: "See.*guide")
  - Search guide for command references (pattern: "plan.md")
  - Count bidirectional references
  - Return 0 if ≥5 references each direction, 1 otherwise
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
  - Test with non-compliant command (>250 lines)
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
- Command file: ≤250 lines (target: 200-230 lines)
- Guide file: ≥2000 lines comprehensive documentation
- Test coverage: ≥80%
- Cross-references: ≥5 bidirectional links
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
| Standard 14 target missed | Low | High | Incremental extraction, line count monitoring |

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
