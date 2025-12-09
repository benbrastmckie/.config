# Automated Validation Checks Template

Use this template for validation phases that run linters, static analysis, and code quality checks.

## Template Structure

```markdown
### Phase N: Automated Validation Checks [NOT STARTED]

**Objective**: Execute static analysis, linting, and code quality validation with automated fix application where possible.

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["lint-results.json", "static-analysis-report.xml", "type-check-results.txt"]

**Dependencies**: Phase N-1 (implementation complete)

**Tasks**:

1. Run linter validation
   - [ ] Execute linter with project configuration: `[LINT_COMMAND]`
   - [ ] Validate exit code 0 (no linting errors)
   - [ ] Generate lint report in JSON format for artifact storage
   - [ ] Auto-fix formatting issues where possible: `[LINT_FIX_COMMAND]`

2. Execute static analysis
   - [ ] Run static analysis tool: `[STATIC_ANALYSIS_COMMAND]`
   - [ ] Validate no critical or high severity issues found
   - [ ] Generate static analysis report in machine-readable format
   - [ ] Check code complexity metrics against thresholds

3. Validate type checking (if applicable)
   - [ ] Run type checker: `[TYPE_CHECK_COMMAND]`
   - [ ] Validate exit code 0 (no type errors)
   - [ ] Capture type check output for artifact storage
   - [ ] Verify all public APIs have type annotations

4. Check code style compliance
   - [ ] Run code formatter in check mode: `[FORMAT_CHECK_COMMAND]`
   - [ ] Validate all files formatted according to project standards
   - [ ] Generate diff report for any formatting violations

**Validation**:
```bash
# Run linter with auto-fix
[LINT_FIX_COMMAND] || true  # Don't fail on auto-fix errors

# Run linter validation (must pass)
[LINT_COMMAND] --format json > lint-results.json
LINT_EXIT=$?
test $LINT_EXIT -eq 0 || { echo "ERROR: Linting failed"; cat lint-results.json; exit 1; }

# Run static analysis
[STATIC_ANALYSIS_COMMAND] --output static-analysis-report.xml
ANALYSIS_EXIT=$?
test $ANALYSIS_EXIT -eq 0 || { echo "ERROR: Static analysis found issues"; exit 1; }

# Run type checking (if applicable)
[TYPE_CHECK_COMMAND] > type-check-results.txt 2>&1
TYPE_EXIT=$?
test $TYPE_EXIT -eq 0 || { echo "ERROR: Type checking failed"; cat type-check-results.txt; exit 1; }

# Validate formatting
[FORMAT_CHECK_COMMAND]
FORMAT_EXIT=$?
test $FORMAT_EXIT -eq 0 || { echo "ERROR: Code formatting violations found"; exit 1; }

echo "✓ All validation checks passed"
```
```

## Customization Variables

Replace these placeholders when using the template:

- `[LINT_COMMAND]`: Linter command (e.g., `eslint src/`, `pylint src/`, `cargo clippy`)
- `[LINT_FIX_COMMAND]`: Linter auto-fix command (e.g., `eslint --fix src/`, `black src/`, `cargo fmt`)
- `[STATIC_ANALYSIS_COMMAND]`: Static analysis tool (e.g., `sonarqube-scanner`, `bandit`, `cargo audit`)
- `[TYPE_CHECK_COMMAND]`: Type checker command (e.g., `tsc --noEmit`, `mypy src/`, `flow check`)
- `[FORMAT_CHECK_COMMAND]`: Formatter check command (e.g., `prettier --check .`, `black --check src/`, `cargo fmt --check`)

## Framework-Specific Examples

### JavaScript/TypeScript (ESLint + Prettier + TypeScript)
```bash
# Auto-fix
eslint --fix src/
prettier --write src/

# Validate
eslint src/ --format json > lint-results.json
prettier --check src/
tsc --noEmit > type-check-results.txt
```

### Python (pylint + black + mypy)
```bash
# Auto-fix
black src/

# Validate
pylint src/ --output-format=json > lint-results.json
black --check src/
mypy src/ > type-check-results.txt
```

### Rust (clippy + fmt)
```bash
# Auto-fix
cargo fmt

# Validate
cargo clippy --all-targets --all-features -- -D warnings
cargo fmt -- --check
```

### Lua (luacheck + stylua)
```bash
# Auto-fix
stylua .

# Validate
luacheck . --formatter plain --codes > lint-results.txt
stylua --check .
```

## Anti-Patterns to Avoid

DO NOT use these phrases in validation phases:
- "Run linter and manually review warnings"
- "Skip validation checks if time constrained"
- "Optionally run static analysis"
- "Visually inspect linter output for errors"
- "Check formatting and fix issues manually if needed"

ALWAYS use automated validation with exit code checks and artifact generation.
