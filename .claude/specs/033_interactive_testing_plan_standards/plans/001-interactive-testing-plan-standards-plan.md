# Implementation Plan: Non-Interactive Testing Standards

## Metadata
- **Date**: 2025-12-08
- **Feature**: Establish standards for non-interactive testing phases in implementation plans
- **Status**: [COMPLETE]
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Non-Interactive Testing Standards](/home/benjamin/.config/.claude/specs/033_interactive_testing_plan_standards/reports/001-non-interactive-testing-standards.md), [Plan Command Analysis](/home/benjamin/.config/.claude/specs/033_interactive_testing_plan_standards/reports/002-plan-command-analysis.md), [Documentation Standards Integration](/home/benjamin/.config/.claude/specs/033_interactive_testing_plan_standards/reports/003-documentation-standards-integration.md)

## Overview

This plan establishes comprehensive standards for non-interactive testing in implementation plans, ensuring all test phases can be executed automatically without manual intervention. The implementation creates a new standard document, extends existing standards, implements validation tooling, and integrates with planning commands through agent behavioral guidelines and standards injection mechanisms.

## Success Criteria

- [x] Non-interactive testing standard document created at `.claude/docs/reference/standards/non-interactive-testing-standard.md` with complete requirements, validation rules, and integration points
- [x] Plan Metadata Standard extended with automated execution workflow extension documenting required test automation fields
- [x] Testing Protocols updated with non-interactive execution requirements section including automation patterns and anti-pattern detection
- [x] Command Authoring Standards updated with non-interactive testing integration patterns and format_standards_for_prompt() example
- [x] Validation script `validate-non-interactive-tests.sh` implemented with ERROR-level enforcement for interactive anti-patterns
- [x] Plan-architect agent behavioral guidelines updated to generate test phases with automation metadata
- [x] CLAUDE.md index updated with non_interactive_testing section and cross-references
- [x] All validation tests pass including pre-commit hook integration and pattern detection accuracy

## Phase Structure

### Phase 1: Create Core Standard Document [COMPLETE]

**Objective**: Establish the foundational non-interactive testing standard document with complete requirements specification.

**Dependencies**: None

**Tasks**:

1. Create non-interactive testing standard document
   - [x] Create file at `.claude/docs/reference/standards/non-interactive-testing-standard.md`
   - [x] Add standard metadata section (Date, Version, Status, Enforcement Level: ERROR)
   - [x] Write executive summary defining non-interactive testing requirements and scope
   - [x] Document required automation metadata fields: `automation_type` (automated/manual), `validation_method` (programmatic/visual), `skip_allowed` (boolean), `artifact_outputs` (array)
   - [x] Define validation contract specifications: exit code semantics (0=success, non-zero=failure), artifact schema requirements (JSON/XML test reports), success criteria expressions
   - [x] Document interactive anti-patterns with detection regex: "manual", "skip", "if needed", "verify visually", "inspect output", "optional", "check results"
   - [x] Specify integration requirements for plan-architect agent, format_standards_for_prompt() function, and pre-commit validation
   - [x] Add enforcement mechanisms section referencing validate-non-interactive-tests.sh validator
   - [x] Include practical examples: automated test phase with correct metadata, anti-pattern examples with corrections
   - [x] Add cross-references to testing-protocols.md, plan-metadata-standard.md, command-authoring.md

2. Validate standard document structure
   - [x] Run `bash .claude/scripts/validate-readmes.sh .claude/docs/reference/standards/` to verify README integration
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/non-interactive-testing-standard.md` to verify all cross-reference links
   - [x] Verify document follows established standards format by comparing structure to plan-metadata-standard.md

**Validation**:
```bash
# Verify file exists and has required sections
test -f /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
grep -q "## Metadata" /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
grep -q "## Required Automation Fields" /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
grep -q "## Validation Contracts" /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
grep -q "## Interactive Anti-Patterns" /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
grep -q "## Integration Points" /home/benjamin/.config/.claude/docs/reference/standards/non-interactive-testing-standard.md || exit 1
```

### Phase 2: Extend Existing Standards Documentation [COMPLETE]

**Objective**: Update plan metadata standard, testing protocols, and command authoring standards with non-interactive testing integration.

**Dependencies**: Phase 1 (requires core standard document for cross-referencing)

**Tasks**:

1. Extend Plan Metadata Standard with automation workflow extension
   - [x] Open `.claude/docs/reference/standards/plan-metadata-standard.md` for editing
   - [x] Locate "Workflow Extensions" section (approximately line 100-120)
   - [x] Add new subsection "Automated Execution Contexts" documenting test automation metadata fields
   - [x] Specify when automation fields are required: complexity >= 3, multi-phase test workflows, CI/CD integration scenarios
   - [x] Document field validation rules: automation_type enum validation, artifact_outputs array format, skip_allowed boolean constraint
   - [x] Add cross-reference to non-interactive-testing-standard.md with absolute path
   - [x] Include example metadata block showing plan with automation fields

2. Update Testing Protocols with non-interactive execution section
   - [x] Open `.claude/docs/reference/standards/testing-protocols.md` for editing
   - [x] Add major section "Non-Interactive Execution Requirements" after existing coverage section
   - [x] Document automation patterns: script-based test execution, programmatic validation, artifact generation requirements
   - [x] Specify validation contracts: exit code handling, test report schemas (JUnit XML, JSON), coverage data formats
   - [x] Define anti-pattern detection rules with regex patterns and remediation guidance
   - [x] Add examples of compliant vs non-compliant test phases with explanations
   - [x] Cross-reference non-interactive-testing-standard.md and command integration points

3. Update Command Authoring Standards with integration patterns
   - [x] Open `.claude/docs/reference/standards/command-authoring.md` for editing
   - [x] Locate "Plan Metadata Standard Integration" section (approximately line 340-380)
   - [x] Add subsection "Non-Interactive Testing Standard Integration" with parallel structure
   - [x] Document format_standards_for_prompt() extension for testing standards injection
   - [x] Provide code example from /create-plan showing standards injection implementation
   - [x] Specify when commands should inject testing standards: /create-plan, /lean-plan, /repair, /debug workflows
   - [x] Add troubleshooting guidance for standards injection failures

4. Validate documentation updates
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/plan-metadata-standard.md` to verify new cross-references
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/testing-protocols.md` to verify section links
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/command-authoring.md` to verify integration examples
   - [x] Verify all three updated standards follow documentation format by comparing to existing standards structure

**Validation**:
```bash
# Verify all three standards updated with non-interactive testing content
grep -q "Automated Execution Contexts" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md || exit 1
grep -q "Non-Interactive Execution Requirements" /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md || exit 1
grep -q "Non-Interactive Testing Standard Integration" /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md || exit 1

# Verify cross-references to new standard exist
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md || exit 1
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md || exit 1
```

### Phase 3: Implement Validation Tooling [COMPLETE]

**Objective**: Create automated validator script for detecting interactive anti-patterns in implementation plans.

**Dependencies**: Phase 1 (requires anti-pattern definitions from core standard)

**Tasks**:

1. Create validation script structure
   - [x] Create file at `.claude/scripts/validate-non-interactive-tests.sh` with standard bash script header
   - [x] Add three-tier library sourcing pattern: source validation-utils.sh, error-handling.sh, and state-persistence.sh with fail-fast handlers
   - [x] Implement command-line argument parsing supporting `--file <path>`, `--directory <path>`, `--staged` (git staged files only)
   - [x] Add usage documentation in script header with examples
   - [x] Initialize error logging with ensure_error_log_exists and COMMAND_NAME="/validate-non-interactive-tests"

2. Implement anti-pattern detection logic
   - [x] Define regex patterns array for interactive anti-patterns: `manual`, `skip`, `if needed`, `verify visually`, `inspect output`, `optional`, `check results`
   - [x] Implement scan_plan_file() function accepting plan file path parameter
   - [x] Extract test phase sections using awk pattern matching on "### Phase.*Test" or "### Phase.*Validation"
   - [x] Apply regex patterns to test phase content and collect matches with line numbers
   - [x] Generate violation reports including file path, line number, matched pattern, context snippet (3 lines)
   - [x] Implement severity classification: ERROR for explicit interactive directives, WARNING for ambiguous patterns

3. Implement validation reporting
   - [x] Create format_validation_report() function outputting structured results
   - [x] Include summary statistics: total files scanned, violations found, ERROR count, WARNING count
   - [x] Format individual violations with file path, line number, violation type, and remediation suggestion
   - [x] Implement exit code logic: exit 1 if ERROR-level violations found, exit 0 for clean or WARNING-only results
   - [x] Add --json flag support for machine-readable output format

4. Integrate with enforcement framework
   - [x] Add validate-non-interactive-tests.sh to validate-all-standards.sh with --non-interactive-tests flag
   - [x] Update `.claude/docs/reference/standards/enforcement-mechanisms.md` with validator documentation
   - [x] Add validator to enforcement mechanisms table with ERROR severity classification
   - [x] Document bypass procedure and justification requirements in enforcement-mechanisms.md

5. Test validation script functionality
   - [x] Create test fixture at `.claude/tests/fixtures/plans/interactive-anti-patterns-test.md` with known violations
   - [x] Create test fixture at `.claude/tests/fixtures/plans/compliant-test-phases.md` with correct patterns
   - [x] Run validator against anti-patterns fixture: `bash .claude/scripts/validate-non-interactive-tests.sh --file .claude/tests/fixtures/plans/interactive-anti-patterns-test.md` and verify exit code 1
   - [x] Run validator against compliant fixture: `bash .claude/scripts/validate-non-interactive-tests.sh --file .claude/tests/fixtures/plans/compliant-test-phases.md` and verify exit code 0
   - [x] Test --staged flag with git staged file simulation
   - [x] Test --json output format and verify JSON schema validity
   - [x] Verify all regex patterns detect intended anti-patterns using test fixtures

**Validation**:
```bash
# Verify script exists and has correct permissions
test -x /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh || exit 1

# Verify three-tier sourcing pattern compliance
bash /home/benjamin/.config/.claude/scripts/check-library-sourcing.sh /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh || exit 1

# Run validator against test fixtures and verify correct detection
bash /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh --file /home/benjamin/.config/.claude/tests/fixtures/plans/interactive-anti-patterns-test.md
test $? -eq 1 || exit 1

bash /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh --file /home/benjamin/.config/.claude/tests/fixtures/plans/compliant-test-phases.md
test $? -eq 0 || exit 1

# Verify integration with validate-all-standards.sh
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --non-interactive-tests || exit 1
```

### Phase 4: Update Agent Behavioral Guidelines [COMPLETE]

**Objective**: Modify plan-architect agent to generate test phases with non-interactive automation metadata.

**Dependencies**: Phase 1 (requires standard document for agent reference)

**Tasks**:

1. Update plan-architect behavioral guidelines
   - [x] Open `.claude/agents/plan-architect.md` for editing
   - [x] Locate test phase generation section (approximately line 300-350)
   - [x] Add explicit requirement: "All test phases MUST include automation metadata fields"
   - [x] Document required fields in test phase template: automation_type, validation_method, skip_allowed, artifact_outputs
   - [x] Add anti-pattern prohibition list: NEVER use "skip for now", "manually verify", "optional testing", "if needed"
   - [x] Specify automation-first patterns: use script execution commands, programmatic validation assertions, artifact generation
   - [x] Include test phase template example with correct automation metadata
   - [x] Add cross-reference to non-interactive-testing-standard.md

2. Create test phase template library
   - [x] Create directory `.claude/agents/templates/test-phases/` for reusable templates
   - [x] Create template `automated-unit-tests.md` with compliant unit test phase structure
   - [x] Create template `automated-integration-tests.md` with integration test orchestration
   - [x] Create template `automated-validation-checks.md` with linter and static analysis patterns
   - [x] Create template `coverage-analysis.md` with coverage report generation and threshold validation
   - [x] Add template README documenting usage and customization guidance
   - [x] Cross-reference templates in plan-architect.md behavioral guidelines

3. Extend lean-plan-architect for Lean-specific patterns
   - [x] Open `.claude/agents/lean-plan-architect.md` for editing
   - [x] Locate proof validation section (approximately line 250-300)
   - [x] Document Lean compiler as automated test oracle pattern
   - [x] Add requirement: proof validation phases must use `lake build` with exit code checking
   - [x] Specify artifact requirements: Lean compiler output, proof verification logs
   - [x] Add example Lean test phase with automation metadata
   - [x] Cross-reference non-interactive-testing-standard.md

4. Validate agent behavioral guideline updates
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/agents/plan-architect.md` to verify cross-references
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/agents/lean-plan-architect.md` to verify Lean-specific links
   - [x] Verify template directory structure matches documentation standards using validate-readmes.sh
   - [x] Review test phase template content for compliance with non-interactive testing standard

**Validation**:
```bash
# Verify agent behavioral guidelines updated
grep -q "automation metadata fields" /home/benjamin/.config/.claude/agents/plan-architect.md || exit 1
grep -q "NEVER use.*skip for now" /home/benjamin/.config/.claude/agents/plan-architect.md || exit 1
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/agents/plan-architect.md || exit 1

# Verify test phase template library exists
test -d /home/benjamin/.config/.claude/agents/templates/test-phases || exit 1
test -f /home/benjamin/.config/.claude/agents/templates/test-phases/automated-unit-tests.md || exit 1
test -f /home/benjamin/.config/.claude/agents/templates/test-phases/README.md || exit 1

# Verify Lean-specific updates
grep -q "lake build.*exit code" /home/benjamin/.config/.claude/agents/lean-plan-architect.md || exit 1
```

### Phase 5: Integrate with Planning Commands [COMPLETE]

**Objective**: Update /create-plan and /lean-plan commands to inject non-interactive testing standards into plan generation workflow.

**Dependencies**: Phase 1, Phase 4 (requires standard document and agent guideline updates)

**Tasks**:

1. Extend format_standards_for_prompt() function
   - [x] Open `.claude/lib/workflow/validation-utils.sh` for editing
   - [x] Locate format_standards_for_prompt() function definition (approximately line 45-67)
   - [x] Add non_interactive_testing_standards parameter with default value
   - [x] Implement standards file reading for non-interactive-testing-standard.md
   - [x] Extract key requirements section (Required Automation Fields, Anti-Patterns) for injection
   - [x] Format extracted content for agent prompt context with clear section headers
   - [x] Add error handling for missing standards file with graceful degradation
   - [x] Update function documentation with new parameter usage

2. Update /create-plan command integration
   - [x] Open `.claude/commands/create-plan.md` for editing
   - [x] Locate plan-architect agent delegation section (approximately line 200-250)
   - [x] Add non-interactive testing standards injection before agent invocation
   - [x] Call format_standards_for_prompt() with non_interactive_testing_standards="$CLAUDE_DOCS/reference/standards/non-interactive-testing-standard.md"
   - [x] Include formatted standards in "Workflow-Specific Context" section of agent prompt
   - [x] Add checkpoint message: "Injecting non-interactive testing standards into plan generation workflow"
   - [x] Update command documentation in command header with testing standards integration note

3. Update /lean-plan command integration
   - [x] Open `.claude/commands/lean-plan.md` for editing
   - [x] Locate lean-plan-architect agent delegation section (approximately line 150-200)
   - [x] Add non-interactive testing standards injection with Lean-specific context
   - [x] Specify Lean compiler validation patterns in standards injection
   - [x] Include proof verification automation requirements in agent prompt
   - [x] Add checkpoint message: "Injecting non-interactive testing standards (Lean-specific patterns)"
   - [x] Update command documentation with Lean testing automation note

4. Test command integration with plan generation
   - [x] Create test feature specification at `.claude/tests/fixtures/test-feature-spec.md`
   - [x] Run `/create-plan test-feature-spec.md --complexity 3` and capture output plan path
   - [x] Verify generated plan includes automation metadata fields in test phases using grep
   - [x] Verify generated plan passes validate-non-interactive-tests.sh validation
   - [x] Run `/lean-plan "implement proof automation" --complexity 3` and capture output plan path
   - [x] Verify Lean plan includes compiler-based validation with exit code checking
   - [x] Verify Lean plan passes validator with no interactive anti-patterns
   - [x] Clean up test artifacts in .claude/tests/fixtures/

**Validation**:
```bash
# Verify format_standards_for_prompt() extension
grep -q "non_interactive_testing_standards" /home/benjamin/.config/.claude/lib/workflow/validation-utils.sh || exit 1

# Verify command integration
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/commands/create-plan.md || exit 1
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/commands/lean-plan.md || exit 1

# Functional test: generate plan and validate
PLAN_PATH=$(bash -c "cd /home/benjamin/.config && echo '.claude/tests/fixtures/test-output-plan.md'")
# Note: Actual plan generation requires Claude invocation, validation tests use pre-generated fixture
bash /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh --file "$PLAN_PATH" || exit 1
```

### Phase 6: Update CLAUDE.md Index and Quick References [COMPLETE]

**Objective**: Add non-interactive testing section to CLAUDE.md and update quick reference documentation.

**Dependencies**: Phase 1, Phase 2, Phase 3, Phase 4, Phase 5 (requires all components for comprehensive cross-referencing)

**Tasks**:

1. Add CLAUDE.md standards section
   - [x] Open `/home/benjamin/.config/CLAUDE.md` for editing
   - [x] Locate code_standards section (approximately line 150-180)
   - [x] Add new section after code_standards: `<!-- SECTION: non_interactive_testing -->`
   - [x] Add section title: "## Non-Interactive Testing Standards"
   - [x] Add usage metadata: "[Used by: /create-plan, /lean-plan, /implement, /debug, /repair]"
   - [x] Write section summary: standards purpose, enforcement level, integration points
   - [x] Add quick reference subsection with automation metadata fields and anti-pattern list
   - [x] Add cross-reference link to full standard: "See [Non-Interactive Testing Standard](.claude/docs/reference/standards/non-interactive-testing-standard.md)"
   - [x] Add section closing marker: `<!-- END_SECTION: non_interactive_testing -->`

2. Update command patterns quick reference
   - [x] Open `.claude/docs/reference/command-patterns-quick-reference.md` for editing
   - [x] Add new section "Non-Interactive Test Phase Template" after validation patterns section
   - [x] Provide copy-paste template showing test phase with automation metadata
   - [x] Include template variants: unit tests, integration tests, validation checks, coverage analysis
   - [x] Add anti-pattern examples with corrections showing before/after transformation
   - [x] Cross-reference non-interactive-testing-standard.md for complete specification

3. Add hierarchical agents example
   - [x] Open `.claude/docs/concepts/hierarchical-agents-examples.md` for editing
   - [x] Add Example 9: "Plan-Architect Non-Interactive Test Generation"
   - [x] Document agent delegation flow: /create-plan → plan-architect with standards injection
   - [x] Show test phase generation with automation metadata fields
   - [x] Include validation step showing anti-pattern detection
   - [x] Add performance context: enabler for automated execution without manual intervention
   - [x] Cross-reference agent behavioral guidelines and standards document

4. Update standards directory README
   - [x] Open `.claude/docs/reference/standards/README.md` for editing
   - [x] Locate standards catalog table (alphabetically ordered)
   - [x] Add row for non-interactive-testing-standard.md with description and enforcement level
   - [x] Verify alphabetical ordering maintained in catalog
   - [x] Update standards count in README header section

5. Validate documentation index updates
   - [x] Run `bash .claude/scripts/validate-links-quick.sh /home/benjamin/.config/CLAUDE.md` to verify new section cross-references
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/command-patterns-quick-reference.md` to verify template links
   - [x] Run `bash .claude/scripts/validate-links-quick.sh .claude/docs/concepts/hierarchical-agents-examples.md` to verify example links
   - [x] Run `bash .claude/scripts/validate-readmes.sh .claude/docs/reference/standards/` to verify README catalog update
   - [x] Verify CLAUDE.md section markers properly formatted using grep pattern matching

**Validation**:
```bash
# Verify CLAUDE.md section added
grep -q "<!-- SECTION: non_interactive_testing -->" /home/benjamin/.config/CLAUDE.md || exit 1
grep -q "Non-Interactive Testing Standards" /home/benjamin/.config/CLAUDE.md || exit 1
grep -q "<!-- END_SECTION: non_interactive_testing -->" /home/benjamin/.config/CLAUDE.md || exit 1

# Verify quick reference updates
grep -q "Non-Interactive Test Phase Template" /home/benjamin/.config/.claude/docs/reference/command-patterns-quick-reference.md || exit 1

# Verify hierarchical agents example added
grep -q "Example 9.*Plan-Architect Non-Interactive Test Generation" /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md || exit 1

# Verify standards README catalog updated
grep -q "non-interactive-testing-standard.md" /home/benjamin/.config/.claude/docs/reference/standards/README.md || exit 1
```

### Phase 7: Integration Testing and Validation [COMPLETE]

**Objective**: Perform comprehensive integration testing of all components and validate standards enforcement.

**Dependencies**: Phase 1, Phase 2, Phase 3, Phase 4, Phase 5, Phase 6 (requires all implementation phases complete)

**Tasks**:

1. Run comprehensive standards validation
   - [x] Execute `bash .claude/scripts/validate-all-standards.sh --all` to run full validation suite
   - [x] Verify all validators pass including new validate-non-interactive-tests.sh integration
   - [x] Execute `bash .claude/scripts/validate-all-standards.sh --non-interactive-tests` to test category-specific invocation
   - [x] Verify ERROR-level enforcement for interactive anti-patterns in sample plans
   - [x] Test --staged flag with git staged file simulation for pre-commit scenario

2. Test end-to-end plan generation workflow
   - [x] Create test specification: "Implement user authentication with password hashing and session management"
   - [x] Run `/create-plan "Implement user authentication" --complexity 3` and capture generated plan path
   - [x] Verify generated plan includes test phases with automation metadata using grep patterns
   - [x] Run validator against generated plan: `validate-non-interactive-tests.sh --file <plan-path>`
   - [x] Verify validator passes with exit code 0 (no violations)
   - [x] Inspect generated plan test phases for correct automation_type, validation_method, skip_allowed, artifact_outputs fields
   - [x] Verify no interactive anti-patterns present in any test phase

3. Test Lean-specific plan generation workflow
   - [x] Run `/lean-plan "prove commutative property of addition" --complexity 3` and capture Lean plan path
   - [x] Verify Lean plan includes compiler-based validation phases with `lake build` commands
   - [x] Run validator against Lean plan and verify compliance
   - [x] Verify proof validation phases specify exit code checking and artifact outputs (compiler logs)
   - [x] Inspect for Lean-specific automation patterns (compiler as test oracle)

4. Test anti-pattern detection accuracy
   - [x] Create test plan fixture with known interactive anti-patterns at each severity level
   - [x] Run validator in verbose mode capturing detailed violation reports
   - [x] Verify all 7 anti-pattern regex patterns detected (manual, skip, if needed, verify visually, inspect output, optional, check results)
   - [x] Verify line numbers and context snippets accurate in violation reports
   - [x] Test false positive rate by scanning 20 existing compliant plans and verifying clean results

5. Test validator integration with pre-commit hooks
   - [x] Stage test plan file with interactive anti-patterns using `git add`
   - [x] Run pre-commit hook manually: `bash .git/hooks/pre-commit` (or pre-commit framework if installed)
   - [x] Verify commit blocked with ERROR-level violations from validate-non-interactive-tests.sh
   - [x] Stage corrected plan file with compliant test phases
   - [x] Re-run pre-commit hook and verify commit allowed
   - [x] Document bypass procedure with justification requirement

6. Test standards injection in command workflows
   - [x] Add debug logging to format_standards_for_prompt() function to trace injection
   - [x] Run /create-plan with logging enabled and capture standards injection output
   - [x] Verify non-interactive-testing-standard.md content extracted and formatted correctly
   - [x] Verify agent receives formatted standards in prompt context
   - [x] Test graceful degradation when standards file missing (simulate by temporarily renaming)
   - [x] Restore standards file and verify normal operation resumed

7. Validate documentation completeness and accuracy
   - [x] Run full link validation across all updated documentation: `validate-links-quick.sh .claude/docs/`
   - [x] Verify all cross-references resolve to existing files and sections
   - [x] Check for broken links in CLAUDE.md section markers
   - [x] Review all documentation examples for accuracy against implemented code
   - [x] Verify template library files match documented usage patterns

**Validation**:
```bash
# Comprehensive standards validation
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all || exit 1
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --non-interactive-tests || exit 1

# End-to-end workflow validation (using pre-generated test fixtures)
bash /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh --file /home/benjamin/.config/.claude/tests/fixtures/plans/compliant-full-workflow.md || exit 1

# Anti-pattern detection accuracy test
bash /home/benjamin/.config/.claude/scripts/validate-non-interactive-tests.sh --file /home/benjamin/.config/.claude/tests/fixtures/plans/all-anti-patterns.md
test $? -eq 1 || exit 1

# Documentation link validation
bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh /home/benjamin/.config/.claude/docs/ || exit 1
bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh /home/benjamin/.config/CLAUDE.md || exit 1

# Verify pre-commit integration exists in enforcement documentation
grep -q "validate-non-interactive-tests.sh" /home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md || exit 1
```

## Dependencies

```
Phase 1 (Core Standard) → Phase 2 (Documentation Extensions)
Phase 1 (Core Standard) → Phase 3 (Validation Tooling)
Phase 1 (Core Standard) → Phase 4 (Agent Guidelines)
Phase 1 (Core Standard) → Phase 5 (Command Integration)
Phase 4 (Agent Guidelines) → Phase 5 (Command Integration)
Phase 1-5 (All Components) → Phase 6 (Documentation Index)
Phase 1-6 (All Implementation) → Phase 7 (Integration Testing)
```

## Risk Assessment

**Medium Risk**: Integration with existing plan-architect agent behavior may require iteration to achieve correct automation metadata generation patterns. Mitigation: comprehensive test fixtures and validation during Phase 7.

**Low Risk**: Anti-pattern regex detection may have false positives/negatives requiring pattern refinement. Mitigation: extensive testing against existing plan corpus (67 topics) during Phase 3 and Phase 7.

**Low Risk**: Standards injection via format_standards_for_prompt() may have performance impact with large standards files. Mitigation: extract only key requirements sections, not full standard document.

## Rollback Plan

If critical issues discovered during integration testing (Phase 7):

1. Revert agent behavioral guideline changes (plan-architect.md, lean-plan-architect.md)
2. Disable validator in validate-all-standards.sh by commenting out --non-interactive-tests integration
3. Document rollback in git commit message with issue details
4. Create rollback spec for investigation and remediation

Changes are additive (new files, extended sections), not destructive, enabling safe rollback without data loss.

## Notes

- This implementation follows established standards patterns from plan-metadata-standard.md and testing-protocols.md
- Validator follows enforcement-mechanisms.md framework with ERROR-level violations blocking commits
- Agent integration uses metadata-only passing pattern for 95% context reduction
- All automation patterns support wave-based parallel execution through phase dependencies
- Standards enable full automated execution of implementation plans without manual intervention gates
