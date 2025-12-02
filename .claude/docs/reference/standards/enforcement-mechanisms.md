# Enforcement Mechanisms Reference

## Purpose

This document serves as the **single source of truth** for all standards enforcement tools in the .claude/ system. It provides:

- Complete inventory of validation tools and their capabilities
- Mapping between standards documents and enforcement scripts
- Pre-commit and CI/CD integration patterns
- Guidelines for adding new enforcement mechanisms

## Enforcement Tool Inventory

| Script | Location | Checks Performed | Severity | Pre-Commit |
|--------|----------|------------------|----------|------------|
| check-library-sourcing.sh | scripts/lint/ | Bash three-tier sourcing pattern, fail-fast handlers | ERROR | Yes |
| lint_error_suppression.sh | tests/utilities/ | Error suppression anti-patterns, deprecated state paths | ERROR | Yes |
| lint_bash_conditionals.sh | tests/utilities/ | Preprocessing-unsafe bash conditionals | ERROR | Yes |
| lint-task-invocation-pattern.sh | scripts/ | Task tool invocation patterns, imperative directives | ERROR | Yes |
| validate-hard-barrier-compliance.sh | scripts/ | Hard barrier subagent delegation pattern | ERROR | Yes |
| validate-readmes.sh | scripts/ | README structure, required sections | WARNING | Yes (quick) |
| validate-links.sh | scripts/ | Internal link validity, broken references | WARNING | Yes (quick) |
| validate-agent-behavioral-file.sh | scripts/ | Agent frontmatter/behavior consistency | WARNING | Manual |

### Severity Levels

- **ERROR**: Blocking - commit will be rejected, must be fixed before proceeding
- **WARNING**: Informational - commit proceeds but issues should be addressed

## Tool Descriptions

### check-library-sourcing.sh

**Purpose**: Validates that bash blocks in commands follow the three-tier sourcing pattern.

**Checks Performed**:
1. **Bare error suppression detection**: Flags `source ... 2>/dev/null` without fail-fast handler for critical libraries
2. **Defensive type checks**: Warns when critical functions are called without preceding `type` checks

**Critical Libraries Monitored**:
- `state-persistence.sh`
- `workflow-state-machine.sh`
- `error-handling.sh`

**Exit Codes**:
- `0`: No errors (warnings may be present)
- `1`: Errors found (violations that must be fixed)

**Usage**:
```bash
# Check all commands
bash .claude/scripts/lint/check-library-sourcing.sh

# Check specific files
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/build.md .claude/commands/plan.md
```

**Related Standard**: [code-standards.md](code-standards.md#mandatory-bash-block-sourcing-pattern)

### lint_error_suppression.sh

**Purpose**: Detects error suppression patterns that hide failures and reduce error visibility.

**Checks Performed**:
1. **State persistence suppression**: Flags `save_completed_states_to_state 2>/dev/null` or `|| true`
2. **Library sourcing suppression**: Warns on unhandled library sourcing errors
3. **State file verification**: Warns when state saves lack verification
4. **Deprecated state paths**: Flags use of `.claude/data/states/` or `.claude/data/workflows/`

**Exit Codes**:
- `0`: No anti-patterns detected
- `1`: Anti-patterns found
- `2`: Script error

**Usage**:
```bash
bash .claude/tests/utilities/lint_error_suppression.sh
```

**Related Standard**: [code-standards.md](code-standards.md#mandatory-patterns), [bash-block-execution-model.md](../../concepts/bash-block-execution-model.md#anti-patterns-reference)

### lint_bash_conditionals.sh

**Purpose**: Detects preprocessing-unsafe bash conditionals that cause "event not found" errors.

**Checks Performed**:
1. **Negated double brackets**: Flags `if [[ ! condition ]]` patterns
2. **Documents safe patterns**: Single bracket file tests `if [ ! -f ... ]` are safe

**Exit Codes**:
- `0`: No violations found
- `1`: Violations found

**Usage**:
```bash
bash .claude/tests/utilities/lint_bash_conditionals.sh
```

**Related Standard**: [bash-block-execution-model.md](../../concepts/bash-block-execution-model.md#anti-patterns-reference), [bash-tool-limitations.md](../../troubleshooting/bash-tool-limitations.md)

### lint-task-invocation-pattern.sh

**Purpose**: Validates Task tool invocations have mandatory imperative directives. Prevents pseudo-code syntax and instructional text patterns that cause delegation bypass.

**Checks Performed**:
1. **Naked Task blocks**: Detects `Task {` without "EXECUTE NOW: USE the Task tool" or "EXECUTE IF...Task tool" within 5 lines before
2. **Instructional text patterns**: Detects "Use the Task tool to invoke..." comments without actual Task block within 10 lines after
3. **Incomplete directives**: Detects "EXECUTE NOW: Invoke..." without "USE the Task tool" phrase

**Exit Codes**:
- `0`: No violations (all Task invocations have imperative directives)
- `1`: Violations found (ERROR-level)

**Usage**:
```bash
# Check all commands
bash .claude/scripts/lint-task-invocation-pattern.sh

# Check specific file
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/build.md

# Check staged files (pre-commit mode)
bash .claude/scripts/lint-task-invocation-pattern.sh --staged
```

**Exclusions**:
- README.md files (documentation)
- docs/ directory (documentation examples)

**Example Violations**:

```markdown
# ❌ VIOLATION: Naked Task block
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}

# ❌ VIOLATION: Instructional text without Task block
Use the Task tool to invoke the research-specialist agent.

# ❌ VIOLATION: Incomplete directive
**EXECUTE NOW**: Invoke the research-specialist agent.
Task { ... }

# ✅ CORRECT: Imperative directive
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.
Task { ... }
```

**Related Standards**:
- [command-authoring.md](command-authoring.md#task-tool-invocation-patterns)
- [hard-barrier-subagent-delegation.md](../../concepts/patterns/hard-barrier-subagent-delegation.md#task-invocation-requirements)

### validate-hard-barrier-compliance.sh

**Purpose**: Validates commands implement the hard barrier subagent delegation pattern.

**Checks Performed**:
1. **Block structure**: Verifies Na/Nb/Nc pattern (e.g., 4a/4b/4c)
2. **CRITICAL BARRIER labels**: Execute blocks must have explicit barrier labels
3. **Task invocations**: Execute blocks contain Task tool invocations
4. **Fail-fast verification**: Verify blocks use `exit 1` on failures
5. **Error logging**: Verify blocks call `log_command_error`
6. **Checkpoint reporting**: Setup and verify blocks report checkpoints
7. **State transitions**: Setup blocks call `sm_transition`
8. **Variable persistence**: Setup blocks use `append_workflow_state`
9. **Recovery instructions**: Verify blocks include recovery guidance
10. **Delegation warnings**: Execute blocks include "CANNOT be bypassed" warning

**Exit Codes**:
- `0`: All commands 100% compliant
- `1`: One or more compliance failures

**Usage**:
```bash
# Validate all orchestrator commands
bash .claude/scripts/validate-hard-barrier-compliance.sh

# Validate specific command
bash .claude/scripts/validate-hard-barrier-compliance.sh --command revise

# Verbose output
bash .claude/scripts/validate-hard-barrier-compliance.sh --verbose
```

**Related Standard**: [hard-barrier-subagent-delegation.md](../../concepts/patterns/hard-barrier-subagent-delegation.md)

### validate-readmes.sh

**Purpose**: Validates README.md files have required structure and sections.

**Checks Performed**:
1. **Required sections**: Purpose, Module Documentation (for active directories)
2. **Navigation links**: Parent/child directory links present
3. **Directory classification compliance**: Appropriate README presence per classification

**Exit Codes**:
- `0`: All READMEs valid
- `1`: Validation failures found

**Usage**:
```bash
# Full validation
bash .claude/scripts/validate-readmes.sh

# Quick validation (staged files only)
bash .claude/scripts/validate-readmes.sh --quick
```

**Related Standard**: [documentation-standards.md](documentation-standards.md)

### validate-links.sh / validate-links-quick.sh

**Purpose**: Validates internal markdown links point to existing files.

**Checks Performed**:
1. **File existence**: Target files exist
2. **Anchor validity**: Section anchors exist in target files
3. **Relative path resolution**: Links resolve correctly from source location

**Exit Codes**:
- `0`: All links valid
- `1`: Broken links found

**Usage**:
```bash
# Full validation
bash .claude/scripts/validate-links.sh

# Quick validation (faster, subset of checks)
bash .claude/scripts/validate-links-quick.sh
```

**Related Standard**: [code-standards.md](code-standards.md#link-conventions)

### validate-agent-behavioral-file.sh

**Purpose**: Validates agent behavioral files for internal contradictions.

**Checks Performed**:
1. **Tool/instruction consistency**: `allowed-tools: None` agents don't have bash execution instructions
2. **Model appropriateness**: Haiku agents don't have complex execution tools
3. **Timeout alignment**: Classification agents have short timeouts
4. **State persistence patterns**: No-tool agents use output-based state persistence

**Exit Codes**:
- `0`: Validation passed (warnings may be present)
- `1`: Critical errors found

**Usage**:
```bash
bash .claude/scripts/validate-agent-behavioral-file.sh .claude/agents/research-specialist.md
```

**Related Standard**: [agent-behavioral-guidelines.md](agent-behavioral-guidelines.md)

## Standards-to-Tool Mapping

This matrix shows which enforcement tools verify each standard document:

| Standard Document | Enforcement Tools |
|-------------------|-------------------|
| code-standards.md | check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh, validate-links.sh |
| output-formatting.md | lint_error_suppression.sh |
| documentation-standards.md | validate-readmes.sh |
| command-authoring.md | check-library-sourcing.sh, lint-task-invocation-pattern.sh, validate-agent-behavioral-file.sh |
| agent-behavioral-guidelines.md | validate-agent-behavioral-file.sh |
| bash-block-execution-model.md | check-library-sourcing.sh, lint_bash_conditionals.sh |
| hard-barrier-subagent-delegation.md | validate-hard-barrier-compliance.sh, lint-task-invocation-pattern.sh |

## Pre-Commit Integration

The pre-commit hook at `.claude/hooks/pre-commit` runs critical validators on staged files:

```bash
# Current pre-commit behavior:
# 1. Run check-library-sourcing.sh on staged .claude/commands/*.md
# 2. Run lint_error_suppression.sh on staged command files
# 3. Run lint_bash_conditionals.sh on staged command files
# 4. Run lint-task-invocation-pattern.sh on staged command files
# 5. Run validate-links-quick.sh on staged .md files
# 6. Run validate-readmes.sh --quick on staged README.md files
```

### Bypass Mechanism

To bypass pre-commit checks (use sparingly, document justification):

```bash
git commit --no-verify -m "Emergency fix: [justification]"
```

**Warning**: Bypassing pre-commit checks should be rare and documented. Violations will be caught in CI/CD.

### Installation

```bash
# Symlink (recommended - stays updated)
ln -sf ../../.claude/hooks/pre-commit .git/hooks/pre-commit

# Direct copy (requires manual updates)
cp .claude/hooks/pre-commit .git/hooks/pre-commit
```

## CI/CD Integration (Future-Ready)

When CI/CD is configured, the unified validation script can be integrated:

```yaml
# Example GitHub Actions workflow
validate-standards:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run Standards Validation
      run: bash .claude/scripts/validate-all-standards.sh --all
```

## Unified Validation

The `validate-all-standards.sh` script orchestrates all validators:

```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run specific validator categories
bash .claude/scripts/validate-all-standards.sh --sourcing    # Library sourcing only
bash .claude/scripts/validate-all-standards.sh --readme      # README validation only
bash .claude/scripts/validate-all-standards.sh --links       # Link validation only

# Staged files mode (for pre-commit)
bash .claude/scripts/validate-all-standards.sh --staged

# Dry run (show what would be checked)
bash .claude/scripts/validate-all-standards.sh --all --dry-run
```

## Adding New Enforcement

To add a new validation mechanism:

### 1. Create the Validator Script

Location: `.claude/scripts/lint/` for linters, `.claude/tests/utilities/` for utility validators

Requirements:
- Clear usage documentation in header comments
- Exit code `0` for pass, `1` for fail
- Human-readable output with file:line references
- Color output support (with terminal detection)

### 2. Update This Document

Add entry to:
- Enforcement Tool Inventory table
- Tool Descriptions section
- Standards-to-Tool Mapping matrix

### 3. Integrate with Pre-Commit (if blocking)

Update `.claude/hooks/pre-commit` or `validate-all-standards.sh` to include the new validator.

### 4. Update Related Standards

Cross-reference the enforcement tool in the standard document it validates.

## Troubleshooting

### Linter Reports False Positive

1. Verify the pattern is actually compliant with the standard
2. If truly false positive, file issue with specific example
3. Temporary bypass: `git commit --no-verify` with justification

### Pre-Commit Hook Not Running

```bash
# Check hook is installed and executable
ls -la .git/hooks/pre-commit

# Reinstall if needed
ln -sf ../../.claude/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Validator Script Not Found

Verify paths in pre-commit hook match actual script locations:

```bash
# Expected locations
.claude/scripts/lint/check-library-sourcing.sh
.claude/scripts/validate-readmes.sh
.claude/scripts/validate-links-quick.sh
.claude/tests/utilities/lint_error_suppression.sh
.claude/tests/utilities/lint_bash_conditionals.sh
```

## Navigation

- Parent: [Standards Reference](README.md)
- Related: [Code Standards](code-standards.md), [Documentation Standards](documentation-standards.md)
- Concepts: [Bash Block Execution Model](../../concepts/bash-block-execution-model.md)
