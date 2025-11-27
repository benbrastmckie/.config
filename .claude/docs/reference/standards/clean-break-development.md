# Clean-Break Development Standard

[Used by: /refactor, /implement, /plan, all development commands]

This standard governs when and how to apply clean-break refactoring patterns to eliminate technical debt from backwards compatibility code. Clean-break refactoring prioritizes code coherence and quality over maintaining backwards compatibility.

## Table of Contents

- [Philosophy and Rationale](#philosophy-and-rationale)
- [Decision Tree](#decision-tree)
- [Clean-Break Patterns](#clean-break-patterns)
- [Anti-Patterns](#anti-patterns)
- [Enforcement](#enforcement)
- [Exceptions and Escalation](#exceptions-and-escalation)
- [Integration](#integration)

## Philosophy and Rationale

### Why Clean-Break is Preferred

For internal tooling and AI-driven systems where all consumers are controlled, clean-break refactoring provides significant advantages:

1. **Code Coherence**: Unified implementations without compatibility layers reduce cognitive load
2. **Reduced Technical Debt**: No accumulation of migration helpers, fallback code, or version-specific handling
3. **Faster Evolution**: Requirements change faster than deprecation cycles; clean-break enables rapid iteration
4. **Lower Maintenance Cost**: Studies indicate unrefined code can lead to maintenance costs increasing by 80% over time

### When Clean-Break is Appropriate

Clean-break refactoring is the default approach for:

- **Internal tooling with controlled consumers**: All callers can be updated atomically
- **AI-driven systems**: Legacy patterns interfere with new capabilities
- **Rapid evolution contexts**: Requirements change faster than deprecation cycles can accommodate
- **Small application scope**: Migration complexity is low; complete refactoring is more efficient

### When Clean-Break is NOT Appropriate

Use gradual migration with deprecation periods for:

- **External API consumers**: Cannot be migrated atomically by the team
- **Data integrity requirements**: Migration period needed for validation
- **Multi-team coordination**: Changes span organizational boundaries
- **System size risk**: Atomic migration carries unacceptable risk

## Decision Tree

Use this decision tree to determine the appropriate refactoring approach:

```
1. Is this an internal system with controlled consumers?
   NO  --> Use gradual migration with deprecation
   YES --> Continue to 2

2. Can all callers be updated in a single PR/commit?
   NO  --> Consider splitting into smaller atomic changes
   YES --> Continue to 3

3. Does maintaining backwards compatibility add >20 lines of code?
   YES --> Use clean-break (delete old code)
   NO  --> Consider clean-break anyway (simpler is better)

4. Is there a data migration component?
   YES --> Use atomic migration script, then clean-break
   NO  --> Use clean-break directly
```

### Decision Criteria Summary

| Factor | Clean-Break | Gradual Migration |
|--------|-------------|-------------------|
| Consumer control | All internal | External consumers |
| Caller update scope | Single atomic change | Multi-release cycle |
| Compatibility code size | >20 lines | Minimal overhead |
| Data migration | One-time script | Rolling migration |

## Clean-Break Patterns

### Pattern 1: Atomic Replacement

**When to use**: Single-responsibility changes affecting isolated components

**Pattern**:
1. Create new implementation with clean design
2. Update all callers in single commit/PR
3. Delete old implementation immediately
4. No deprecation warnings or transition period

**Example**:
```bash
# BEFORE: Old caching implementation
source "${LIB_DIR}/legacy-cache.sh"
cache_data "$key" "$value"

# AFTER: New caching implementation (single commit)
source "${LIB_DIR}/cache.sh"
set_cache "$key" "$value"

# Old file deleted in same commit - no deprecation period
```

**Commit Pattern**:
```
refactor: replace legacy-cache with unified cache API

- Update all 12 callers to use new cache.sh interface
- Delete legacy-cache.sh (no longer needed)
- No backwards compatibility code introduced
```

### Pattern 2: Interface Unification

**When to use**: Multiple implementations doing the same thing

**Pattern**:
1. Identify canonical implementation
2. Migrate all callers to canonical interface
3. Delete redundant implementations
4. No backward-compatible wrappers

**Example**:
```bash
# BEFORE: Three different logging functions
log_debug "$message"      # From debug-utils.sh
write_log "$level" "$msg" # From logger.sh
echo "[INFO] $message"    # Inline pattern

# AFTER: Single canonical interface
log_message "debug" "$message"  # From unified-logger.sh
log_message "info" "$message"
log_message "error" "$message"

# All three legacy patterns deleted - not wrapped
```

**Anti-pattern to Avoid**:
```bash
# WRONG: Wrapper maintaining both interfaces
log_debug() {
  log_message "debug" "$@"  # Wrapper perpetuates legacy API
}
```

### Pattern 3: State Machine Evolution

**When to use**: Workflow or state machine changes

**Pattern**:
1. Define new state machine completely
2. Convert checkpoint format atomically (migration script runs once)
3. Remove old state handling code
4. No dual-state-machine support

**Example**:
```bash
# Migration script (runs once during upgrade)
#!/bin/bash
for checkpoint in .claude/data/checkpoints/*.json; do
  # Convert old format to new format
  jq '.version = "2.0" | .states = .phases' "$checkpoint" > "${checkpoint}.new"
  mv "${checkpoint}.new" "$checkpoint"
done
echo "Migration complete - old format no longer supported"

# All code handling old format is deleted after migration
```

**Checkpoint**: After migration script runs successfully, all code referencing old format is deleted.

### Pattern 4: Documentation Purge

**When to use**: Terminology or concept changes

**Pattern**:
1. Update all references to new terminology
2. Remove all mentions of old terminology
3. Update CLAUDE.md and all docs atomically
4. No "formerly known as" references

**Example**:
```markdown
# BEFORE: Mixed terminology
The system uses "phases" for workflow steps.
Note: "phases" were previously called "stages" in v1.0.

# AFTER: Clean terminology
The system uses "phases" for workflow steps.

# No historical reference - documentation reads as if "phases" always existed
```

**Application**: This pattern is already enforced for documentation via [Writing Standards](../../concepts/writing-standards.md). This standard extends the principle to code.

## Anti-Patterns

The following patterns indicate backwards compatibility creep and should be avoided:

### Anti-Pattern 1: Legacy Comments

**Detection**: Comments containing "legacy", "deprecated", "old", "backward compat"

**Example**:
```bash
# WRONG: Legacy comment persisting in code
# Legacy: support old checkpoint format (remove in v3.0)
if [[ -f "$old_checkpoint" ]]; then
  migrate_old_format "$old_checkpoint"
fi
```

**Fix**: Delete the old format handling; run migration script once instead.

### Anti-Pattern 2: Fallback Code Blocks

**Detection**: Fallback patterns like `|| fallback_to_old_method()`

**Example**:
```bash
# WRONG: Fallback to old implementation
result=$(new_parser "$input") || result=$(old_parser "$input")
```

**Fix**: Update all callers to new parser; delete old parser entirely.

### Anti-Pattern 3: Version Detection

**Detection**: Conditional logic based on version numbers

**Example**:
```bash
# WRONG: Version-specific behavior
if [[ "$VERSION" -lt 2 ]]; then
  use_old_authentication
else
  use_new_authentication
fi
```

**Fix**: Migrate all instances to new authentication; delete old code.

### Anti-Pattern 4: Wrapper Functions

**Detection**: Functions that delegate to both old and new implementations

**Example**:
```bash
# WRONG: Wrapper maintaining both interfaces
authenticate() {
  if [[ -n "$USE_LEGACY_AUTH" ]]; then
    legacy_authenticate "$@"
  else
    modern_authenticate "$@"
  fi
}
```

**Fix**: Delete legacy_authenticate; update authenticate to call modern implementation directly.

### Anti-Pattern 5: Migration Helpers

**Detection**: Helper functions that persist beyond one release cycle

**Example**:
```bash
# WRONG: Persistent migration helper
migrate_config_v1_to_v2() {
  # This function has been here for 6 months
  ...
}

# Kept "in case someone still has v1 config"
```

**Fix**: Run migration once; delete helper function; document in CHANGELOG.

### Anti-Pattern 6: Temporary Compatibility Code

**Detection**: "Temporary" code without expiration or removal date

**Example**:
```bash
# WRONG: "Temporary" code without expiration
# Temporary: support both old and new config formats
if [[ -f "config.yaml" ]]; then
  load_yaml_config
elif [[ -f "config.json" ]]; then
  load_json_config  # Old format - temporary support
fi
```

**Fix**: Migrate all configs to YAML; delete JSON support.

### Detection Commands

Use these commands to scan for anti-patterns:

```bash
# Scan for legacy/deprecated comments
grep -rn "legacy\|deprecated\|backward.compat\|backwards.compat" \
  --include="*.sh" --include="*.md" .claude/lib/ .claude/commands/

# Scan for fallback patterns
grep -rn "||.*old\|||.*legacy\|||.*fallback" \
  --include="*.sh" .claude/lib/ .claude/commands/

# Scan for version detection
grep -rn "VERSION.*-lt\|VERSION.*<\|version.*less" \
  --include="*.sh" .claude/lib/ .claude/commands/

# Scan for migration helpers
grep -rn "migrate_.*_to_\|convert_.*_to_\|upgrade_.*_to_" \
  --include="*.sh" .claude/lib/
```

## Enforcement

### Current Enforcement

Clean-break principles are enforced through:

1. **Code Review**: PRs introducing backwards compatibility code require justification
2. **Writing Standards**: Documentation enforcement via timeless writing policy
3. **Manual Audit**: Periodic scans using detection commands above

### Future Enforcement (Planned)

A dedicated linter can be implemented to automate anti-pattern detection:

**lint_backward_compat.sh** (future):
- Flag legacy/deprecated comments in code
- Detect fallback patterns
- Identify version-specific code branches
- Severity levels: ERROR for lib/, WARNING for commands/

**Pre-commit Integration** (future):
```bash
# Add to .git/hooks/pre-commit
bash .claude/scripts/lint/lint_backward_compat.sh
```

### Bypass Mechanism

When backwards compatibility is genuinely required (see Exceptions below), bypass the standard with explicit documentation:

```bash
# clean-break-exception: External API boundary - consumers cannot be migrated atomically
# Expiration: 2025-06-01 (tracked in issue #123)
if [[ -n "$LEGACY_API_SUPPORT" ]]; then
  ...
fi
```

## Exceptions and Escalation

### Legitimate Exception Categories

1. **External API boundaries**: Consumers outside team control cannot be migrated atomically
2. **Data format migration periods**: Large datasets require rolling migration for validation
3. **Security patches**: Critical fixes may need backward-compatible deployment for rapid rollout

### Exception Documentation Requirements

All exceptions MUST include:

1. **Justification**: Why clean-break cannot be applied
2. **Expiration date**: When compatibility code will be removed
3. **Tracking issue**: Link to issue tracking removal
4. **Bypass comment**: `# clean-break-exception: [reason]` in code

**Example Exception**:
```bash
# clean-break-exception: External webhook consumers need 30-day migration window
# Expiration: 2025-07-15
# Tracking: https://github.com/org/repo/issues/456
accept_legacy_webhook_format() {
  ...
}
```

### Exception Escalation Process

1. **Identify need**: Determine why clean-break cannot be applied
2. **Document justification**: Write clear reason in PR description
3. **Set expiration**: Choose removal date (maximum 90 days for internal, 180 days for external)
4. **Create tracking issue**: Issue must include removal plan
5. **Add bypass comment**: Use `# clean-break-exception:` format in code
6. **Schedule removal**: Add calendar reminder for expiration date

## Integration

### Related Standards

This standard integrates with existing project standards:

| Standard | Relationship |
|----------|--------------|
| [Writing Standards](../../concepts/writing-standards.md) | Clean-break philosophy for documentation (complementary) |
| [Code Standards](code-standards.md) | Coding conventions and architectural requirements |
| [Refactoring Methodology](../../guides/patterns/refactoring-methodology.md) | Step-by-step refactoring workflow |
| [Enforcement Mechanisms](enforcement-mechanisms.md) | Pre-commit hook integration model |

### Writing Standards Scope Clarification

The [Writing Standards](../../concepts/writing-standards.md) document covers clean-break philosophy for **documentation**:
- Temporal markers
- Migration language
- Version references

This standard (Clean-Break Development) covers clean-break patterns for **code**:
- Implementation patterns
- Anti-patterns
- Enforcement mechanisms

### CLAUDE.md Reference

This standard is referenced in CLAUDE.md under the `clean_break_development` section. Developers encounter the standard when:

- Running `/refactor` command
- Running `/implement` command
- Running `/plan` command
- Reviewing code standards

## Quick Reference

### Decision Checklist

- [ ] Internal system with controlled consumers? Use clean-break
- [ ] Can update all callers atomically? Use clean-break
- [ ] Compatibility code >20 lines? Use clean-break
- [ ] Data migration needed? Run migration script once, then clean-break

### Clean-Break Workflow

1. Create new implementation
2. Update all callers (single commit)
3. Delete old implementation (same commit)
4. No deprecation warnings

### Anti-Pattern Scan

```bash
grep -rn "legacy\|deprecated\|fallback.*old" --include="*.sh" .claude/
```

### Exception Format

```bash
# clean-break-exception: [reason]
# Expiration: YYYY-MM-DD
# Tracking: [issue URL]
```
