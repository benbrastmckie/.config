# Test Phase Templates

Reusable templates for creating non-interactive test phases in implementation plans.

## Purpose

These templates provide standardized patterns for test phases that comply with the [Non-Interactive Testing Standard](../../../docs/reference/standards/non-interactive-testing-standard.md). All templates include:

- **Automation metadata fields** (automation_type, validation_method, skip_allowed, artifact_outputs)
- **Programmatic validation** with exit code checks
- **Machine-readable artifacts** (JUnit XML, LCOV, JSON reports)
- **Framework-specific examples** for multiple languages/tools
- **Anti-pattern prohibitions** to avoid manual intervention requirements

## Available Templates

### Unit Testing
**File**: [automated-unit-tests.md](automated-unit-tests.md)
**Use For**: Focused tests on individual modules/functions with coverage validation
**Artifacts**: test-results.xml, coverage.lcov, coverage-summary.json

### Integration Testing
**File**: [automated-integration-tests.md](automated-integration-tests.md)
**Use For**: Component interaction validation with environment setup/teardown
**Artifacts**: integration-test-results.xml, integration-coverage.lcov, test-logs.txt

### Validation Checks
**File**: [automated-validation-checks.md](automated-validation-checks.md)
**Use For**: Static analysis, linting, type checking, code quality validation
**Artifacts**: lint-results.json, static-analysis-report.xml, type-check-results.txt

### Coverage Analysis
**File**: [coverage-analysis.md](coverage-analysis.md)
**Use For**: Comprehensive coverage measurement with threshold validation
**Artifacts**: coverage.lcov, coverage-summary.json, coverage-report.html, coverage-badge.svg

## Usage Guide

### 1. Select Appropriate Template

Choose template based on test phase type:
- Unit tests → `automated-unit-tests.md`
- Integration tests → `automated-integration-tests.md`
- Linting/static analysis → `automated-validation-checks.md`
- Coverage validation → `coverage-analysis.md`

### 2. Customize Template Variables

Each template has customization variables marked with `[VARIABLE_NAME]`:

```markdown
# Example from automated-unit-tests.md
[TEST_COMMAND] → npm test
[THRESHOLD] → 80
[ARTIFACT_PATH] → .claude/specs/042/outputs/
[COVERAGE_SUMMARY_PATH] → ./coverage/coverage-summary.json
```

### 3. Select Framework-Specific Implementation

Templates include examples for multiple frameworks:
- **JavaScript/TypeScript**: Jest, Mocha, Vitest
- **Python**: pytest, unittest, nose2
- **Rust**: cargo test, cargo-tarpaulin
- **Lua**: busted, luacov

Copy the relevant example and adapt to your project.

### 4. Verify Anti-Pattern Compliance

Check that your test phase does NOT include prohibited phrases:
- ❌ "manually verify"
- ❌ "skip for now"
- ❌ "if needed"
- ❌ "verify visually"
- ❌ "inspect output"
- ❌ "optional"
- ❌ "check results"

All validation must be programmatic with exit codes.

## Template Structure Reference

All templates follow this structure:

```markdown
### Phase N: [Test Type] [NOT STARTED]

**Objective**: [Clear test phase goal]

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: [array of test artifacts]

**Dependencies**: [Phase dependencies]

**Tasks**:
1. Task category
   - [ ] Specific task with command
   - [ ] Validation with exit code check
   - [ ] Artifact generation

**Validation**:
```bash
# Programmatic validation script
[COMMAND] || exit 1
```
```

## Integration with Plan Architect

The plan-architect agent automatically uses these templates when generating test phases. Templates are referenced via behavioral guidelines in [plan-architect.md](../../plan-architect.md).

**Agent Integration Points**:
1. Agent reads template during plan generation
2. Customizes variables based on project context
3. Validates automation metadata compliance
4. Includes framework-specific commands from project standards

## Validation

All test phases using these templates are validated by:
- [validate-non-interactive-tests.sh](../../../scripts/validate-non-interactive-tests.sh) - Anti-pattern detection
- [validate-all-standards.sh](../../../scripts/validate-all-standards.sh) - Unified validation framework

Run validation before committing plans:

```bash
# Validate specific plan
bash .claude/scripts/validate-non-interactive-tests.sh --file path/to/plan.md

# Validate all staged plans
bash .claude/scripts/validate-non-interactive-tests.sh --staged

# Validate as part of comprehensive standards check
bash .claude/scripts/validate-all-standards.sh --all
```

## Customization Guidelines

### Adding Framework Examples

To add a new framework example to a template:

1. Identify the test phase type (unit, integration, validation, coverage)
2. Open the corresponding template file
3. Add framework-specific example under "Framework-Specific Examples" section
4. Include framework name, test command, coverage command, and artifact paths
5. Ensure example follows automation-first patterns (no manual steps)

### Creating New Templates

To create a new test phase template:

1. Copy structure from existing template
2. Define clear objective and automation metadata
3. Break down tasks into programmatic steps with exit code validation
4. Include validation script demonstrating automation
5. Add framework-specific examples for at least 2-3 common frameworks
6. Document customization variables
7. List anti-patterns to avoid
8. Update this README with new template entry

## Cross-References

- [Non-Interactive Testing Standard](../../../docs/reference/standards/non-interactive-testing-standard.md) - Complete automation requirements
- [Testing Protocols](../../../docs/reference/standards/testing-protocols.md) - Test discovery and coverage standards
- [Plan Metadata Standard](../../../docs/reference/standards/plan-metadata-standard.md) - Automation metadata field specifications
- [Plan Architect Agent](../../plan-architect.md) - Agent behavioral guidelines for test phase generation
- [Command Authoring Standards](../../../docs/reference/standards/command-authoring.md) - Standards injection integration patterns

## Support

For template usage questions or issues:
1. Check template README (this file)
2. Review [Non-Interactive Testing Standard](../../../docs/reference/standards/non-interactive-testing-standard.md)
3. Examine existing plans in `.claude/specs/` for real-world examples
4. Consult [Testing Protocols](../../../docs/reference/standards/testing-protocols.md) for test strategy guidance
