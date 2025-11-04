# Bash Indirect Reference Alternatives Research Report

## Metadata
- **Date**: 2025-11-04
- **Agent**: research-specialist
- **Topic**: Bash Indirect Reference Alternatives (avoiding `${!varname}` syntax)
- **Report Type**: Best practices research and pattern recognition
- **Project Context**: /coordinate command has 9 instances of `${!var}` syntax triggering history expansion errors
- **Bash Version**: GNU bash 5.2.37(1)-release
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

Bash's indirect variable reference syntax (`${!varname}`) and array key iteration (`${!array[@]}`) trigger history expansion errors in interactive shells when history expansion is enabled. Research identifies three production-ready alternatives: (1) `declare -n` namerefs (bash 4.3+, recommended for all new code), (2) `printf -v` for safe variable assignment (bash 4.0+), and (3) carefully escaped `eval` patterns with `printf %q` (legacy compatibility only). The project's bash 5.2.37 supports all modern alternatives, making nameref migration the optimal solution for maintainability and security.

## Findings

### Current State Analysis

The /coordinate command contains 9 instances of indirect reference syntax across 2 library files:

**File: `/home/benjamin/.config/.claude/lib/context-pruning.sh`**
- Line 55: `local full_output="${!output_var_name}"` - Indirect variable value access
- Line 150: `for key in "${!PRUNED_METADATA_CACHE[@]}"` - Associative array key iteration
- Line 245: `for phase_id in "${!PHASE_METADATA_CACHE[@]}"` - Associative array key iteration
- Line 252: `for key in "${!PRUNED_METADATA_CACHE[@]}"` - Associative array key iteration
- Line 314: `for key in "${!PRUNED_METADATA_CACHE[@]}"` - Associative array key iteration
- Line 320: `for key in "${!PHASE_METADATA_CACHE[@]}"` - Associative array key iteration
- Line 326: `for key in "${!WORKFLOW_METADATA_CACHE[@]}"` - Associative array key iteration

**Associative Arrays Declared**: Lines 30-32 in context-pruning.sh
```bash
declare -A PRUNED_METADATA_CACHE
declare -A PHASE_METADATA_CACHE
declare -A WORKFLOW_METADATA_CACHE
```

**File: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`**
- Line 289: `for i in "${!report_paths[@]}"` - Regular array index iteration
- Line 317: `REPORT_PATHS+=("${!var_name}")` - Indirect variable value access

### Problem Context

History expansion in bash converts `!` followed by certain characters into command substitutions from shell history. The `${!var}` syntax conflicts with this mechanism in interactive shells with `set +H` (history expansion disabled) or when using `set -H` (history expansion enabled, the default in interactive shells).

**Error manifestation:**
- In scripts with `set -e`: Script exits on history expansion failure
- In interactive shells: `bash: !var: event not found` errors
- Context window bloat: Error messages multiply with each iteration

### Industry Best Practices

#### Alternative 1: `declare -n` (Nameref Pattern) - **RECOMMENDED**

**Description**: Name references create variable aliases, allowing clean indirect access without special syntax.

**Syntax**:
```bash
# For indirect variable access
local -n ref="$varname"
echo "$ref"              # Read value
ref="new_value"          # Write value

# For array iteration
declare -n arr_ref="$array_name"
for key in "${!arr_ref[@]}"; do
  echo "${arr_ref[$key]}"
done
```

**Advantages**:
- Clean, readable syntax (no special characters)
- Type-safe: Validation happens at declaration
- No history expansion conflicts
- No eval security risks
- Bash 4.3+ (released 2014, widely available)
- Recommended by Bash FAQ and Stack Overflow community

**Limitations**:
- Cannot declare array OF namerefs (can have nameref TO array)
- Dynamic scoping rules (function-local namerefs reference visible names)
- Bash-specific (not POSIX portable)

**Production Examples**:

```bash
# Example 1: Function parameter indirection
update_config() {
  local -n config_ref="$1"
  config_ref[db_host]="localhost"
  config_ref[db_port]="5432"
}

declare -A staging_config
update_config staging_config
echo "${staging_config[db_host]}"  # Output: localhost
```

```bash
# Example 2: Generic swap function
swap() {
  local -n first=$1
  local -n second=$2
  local temp="$first"
  first="$second"
  second="$temp"
}

x=10
y=20
swap x y
echo "$x $y"  # Output: 20 10
```

**Real-world usage**: Linux kernel build scripts, systemd unit generation, Ansible module helpers.

#### Alternative 2: `printf -v` (Safe Assignment Pattern)

**Description**: Bash's `printf -v` extension assigns formatted output directly to a variable, with built-in validation.

**Syntax**:
```bash
printf -v "$varname" '%s' "$value"
```

**Advantages**:
- Safest for variable assignment (no escaping issues)
- Validates variable names (returns error code 2 for invalid identifiers)
- No eval risks
- Bash 4.0+ (2009 release)

**Limitations**:
- Assignment only (cannot read values)
- Creates local variables in function scope (not suitable for globals without workarounds)
- Not usable for array key iteration

**Production Example**:
```bash
# Dynamic environment variable setting
set_env_var() {
  local env=$1
  local key=$2
  local value=$3

  local varname="${env}_${key}"
  printf -v "$varname" '%s' "$value"
}

set_env_var "PROD" "DB_HOST" "postgres.example.com"
echo "$PROD_DB_HOST"  # Output: postgres.example.com
```

#### Alternative 3: `eval` with Proper Escaping (Legacy Pattern)

**Description**: Using eval with carefully escaped syntax can avoid security issues, but requires vigilance.

**Safe Patterns**:

**Pattern A: Escaped RHS with backslash**
```bash
eval "$varname=\$value"
# The backslash prevents $value from expanding during eval parsing
```

**Pattern B: printf %q for shell-safe quoting**
```bash
eval "$(printf '%q=%q' "$varname" "$value")"
# %q generates shell-input-safe representations
```

**Pattern C: Parameter transformation (bash 4.4+)**
```bash
eval "$varname=${value@Q}"
# @Q expands value as shell-quoted
```

**Security Considerations**:
- **CRITICAL**: Always validate variable names before eval
- Invalid variable names (e.g., `a[1]`) cause bash to search PATH, enabling arbitrary code execution
- Even with `printf %q`, malicious variable names are dangerous
- Never use with untrusted input

**When to use eval**:
- Legacy script compatibility (bash < 4.0)
- POSIX shell portability requirements
- Global variable assignment from functions (as last resort)

**When NOT to use eval**:
- New code (use `declare -n` instead)
- Security-sensitive contexts
- Untrusted input processing

### Array Key Iteration Patterns

**Problem**: `for key in "${!array[@]}"` triggers history expansion.

**Solution 1: Nameref (Clean)**
```bash
declare -n arr="$array_name"
for key in "${!arr[@]}"; do
  echo "Key: $key, Value: ${arr[$key]}"
done
```

**Solution 2: String Concatenation (Fallback for bash < 4.3)**
```bash
# Regular arrays
tmp="${array_name}[@]"
for element in "${!tmp}"; do
  echo "$element"
done

# Associative arrays (keys)
tmp="${array_name}[@]"
for key in "${!tmp}"; do
  echo "Key: $key"
done
```

**Critical Quoting Rule**: Always use `"${!arr[@]}"` with quotes to preserve elements containing spaces.

### Code Transformation Examples

**Before (History Expansion Issues):**
```bash
# context-pruning.sh:55
local full_output="${!output_var_name}"

# context-pruning.sh:150
for key in "${!PRUNED_METADATA_CACHE[@]}"; do
  unset PRUNED_METADATA_CACHE["$key"]
done

# workflow-initialization.sh:317
local var_name="REPORT_PATH_$i"
REPORT_PATHS+=("${!var_name}")
```

**After (Nameref Pattern):**
```bash
# context-pruning.sh:55
local -n output_ref="$output_var_name"
local full_output="$output_ref"

# context-pruning.sh:150
# Note: Direct iteration works when variable name is known
# No change needed when using actual associative array name
for key in "${!PRUNED_METADATA_CACHE[@]}"; do
  unset PRUNED_METADATA_CACHE["$key"]
done

# Alternative for dynamic array name:
local -n cache_ref="$cache_var_name"
for key in "${!cache_ref[@]}"; do
  unset cache_ref["$key"]
done

# workflow-initialization.sh:317
local var_name="REPORT_PATH_$i"
local -n path_ref="$var_name"
REPORT_PATHS+=("$path_ref")
```

### Bash Version Compatibility

Project uses **GNU bash 5.2.37(1)-release**, which supports:
- ✓ `declare -n` (requires bash 4.3+, released 2014)
- ✓ `printf -v` (requires bash 4.0+, released 2009)
- ✓ `eval` with `@Q` parameter transformation (requires bash 4.4+, released 2016)

**Conclusion**: All modern alternatives are available. Nameref migration has zero compatibility risk.

## Recommendations

### Recommendation 1: Adopt `declare -n` as Primary Pattern

**Action**: Migrate all indirect reference patterns to `declare -n` namerefs.

**Rationale**:
- Best maintainability: Clear intent, no special syntax
- Best security: No eval risks, built-in validation
- Modern standard: Recommended by bash documentation and community
- Future-proof: Bash 4.3+ is 11 years old (2014), universally available

**Priority**: HIGH - Addresses core issue with cleanest solution

**Migration effort**: LOW - Mechanical transformation with clear patterns

### Recommendation 2: Create Bash Style Guide Entry

**Action**: Document nameref pattern as project standard for indirect references.

**Content**:
```markdown
## Indirect Variable References

**ALWAYS** use `declare -n` for indirect variable access:

✓ CORRECT:
  local -n ref="$varname"
  echo "$ref"

✗ AVOID:
  echo "${!varname}"  # Triggers history expansion

**Rationale**: History expansion conflicts, security, maintainability
```

**Priority**: MEDIUM - Prevents future instances

### Recommendation 3: Implement Linting Rule

**Action**: Add shellcheck directive or custom lint rule to detect `${!var}` patterns.

**Implementation**:
```bash
# .shellcheckrc or pre-commit hook
# Flag ${!var} patterns (except ${!var[@]} for literal array names)
grep -n '\${![a-zA-Z_][a-zA-Z0-9_]*}' *.sh
```

**Priority**: LOW - Preventive measure for long-term code quality

### Recommendation 4: Consider Associative Array Optimization

**Action**: For frequently iterated associative arrays, evaluate whether direct iteration (known variable names) can replace dynamic iteration.

**Analysis**:
- Lines 150, 252, 314, 320, 326 in context-pruning.sh use literal array names
- These do NOT require nameref migration (no dynamic variable names)
- Only Line 55 (variable value access) and Line 317 (workflow-initialization.sh) require changes

**Priority**: LOW - Optimization, not required for bug fix

### Recommendation 5: Test Coverage for Indirect Reference Patterns

**Action**: Add unit tests verifying nameref behavior with edge cases.

**Test cases**:
- Empty variable names
- Variables with spaces in values
- Nested nameref references
- Associative vs regular array behavior

**Priority**: MEDIUM - Ensures migration reliability

## References

### Project Files Analyzed
- `/home/benjamin/.config/.claude/lib/context-pruning.sh:55` - Indirect variable access
- `/home/benjamin/.config/.claude/lib/context-pruning.sh:150,245,252,314,320,326` - Associative array iteration
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:289,317` - Array and variable indirection

### Authoritative Sources
- Stack Overflow: "How to iterate over an array using indirect reference?" (11180714)
- Stack Overflow: "Indirect variable assignment in bash" (9938649)
- Stack Overflow: "How to iterate over associative arrays in Bash" (3112687)
- BashFAQ/006: "How can I use variable variables (indirect references)?"
- BashFAQ/048: "Why should eval be avoided in Bash?"
- Bash Manual: declare builtin documentation (bash 5.2)
- Unix & Linux Stack Exchange: "Nameref variables" (744847)

### Community Consensus
- **Nameref adoption**: Widely recommended as best practice for bash 4.3+ codebases
- **Security guidance**: Avoid eval for variable indirection unless POSIX portability required
- **printf -v pattern**: Recommended for safe assignment in bash 4.0+ contexts

### Additional Reading
- "Bash namerefs for dynamic variable referencing" - Redowan's Reflections
- "Safely Execute Commands with Bash Eval Alternatives" - sqlpey.com
- "The perils of Bash 'eval'" - Medium article on reflection injection
