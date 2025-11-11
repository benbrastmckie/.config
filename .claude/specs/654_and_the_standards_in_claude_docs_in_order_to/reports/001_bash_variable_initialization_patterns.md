# Bash Variable Initialization Patterns for Subprocess Isolation Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Bash variable initialization patterns for subprocess isolation and state persistence
- **Report Type**: Best practices and pattern analysis
- **Complexity Level**: 2

## Executive Summary

The `/coordinate` workflow scope persistence bug (Spec 653) stems from bash subprocess isolation combined with direct variable initialization in libraries. When `workflow-state-machine.sh` is re-sourced in subsequent bash blocks, lines 66-77 directly assign empty strings (`WORKFLOW_SCOPE=""`), overwriting values loaded from state files. Option 1 (conditional initialization using `WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"`) is the optimal solution: minimal change, aligns with existing .claude/ patterns, preserves `set -u` safety, and follows bash best practices for library re-sourcing scenarios.

## Findings

### 1. Current State Analysis

#### Bug Mechanics (from coordinate.md investigation)

**Root Cause Sequence** (lines 82-128 in coordinate.md, lines 66-77 in workflow-state-machine.sh):

1. **Block 1**: Workflow description saved before library sourcing (line 84: `SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"`)
2. **Block 1**: Libraries sourced (line 92: `source workflow-state-machine.sh`)
3. **Block 1**: Variables initialized by `sm_init()` (line 124), values saved to state file (lines 121-129)
4. **Block 2+**: Libraries re-sourced FIRST (line 250-270: source libraries)
5. **Block 2+**: State loaded AFTER (line 276: `load_workflow_state "$WORKFLOW_ID"`)
6. **Problem**: Direct initialization at lines 66-77 in workflow-state-machine.sh overwrites parent environment before state loading

**Specific Variables Affected** (workflow-state-machine.sh:66-77):
```bash
# Line 66: Direct assignment
CURRENT_STATE="${STATE_INITIALIZE}"

# Line 72: Direct assignment
TERMINAL_STATE="${STATE_COMPLETE}"

# Lines 75-77: Direct assignment (THE BUG)
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""
COMMAND_NAME=""
```

**Evidence from coordinate.md**:
- Line 83 comment: "Libraries pre-initialize WORKFLOW_DESCRIPTION='' which overwrites parent value"
- Line 84 workaround: `SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"` before library sourcing
- This workaround only protects WORKFLOW_DESCRIPTION in Block 1, not WORKFLOW_SCOPE in Block 2+

#### Existing Conditional Initialization Usage in .claude/

**No examples found** of `VAR="${VAR:-}"` pattern in library initialization. Search results show:

1. **Function parameters**: 50+ uses of `local param="${1:-}"` for safe parameter access
   - Examples: template-integration.sh:40, context-metrics.sh:42, verification-helpers.sh functions

2. **Environment variable detection**: `${CLAUDE_PROJECT_DIR:-}` used in conditionals
   - state-persistence.sh:82, detect-project-dir.sh:22
   - Pattern: `if [ -z "${VAR:-}" ]; then VAR="default"; fi`

3. **No file-scope variable initialization** with conditional pattern currently exists

**Readonly Variables** (40+ instances found):
- Used for constants only (STATE_INITIALIZE, STATE_RESEARCH, color codes, paths)
- No readonly variables need preservation across re-sourcing
- Lines 36-43 in workflow-state-machine.sh: 8 readonly state constants

#### Source Guard Pattern Analysis

**Consistent pattern across all libraries** (20+ files examined):
```bash
# Pattern used in all .claude/lib/*.sh files
if [ -n "${LIBRARY_NAME_SOURCED:-}" ]; then
  return 0  # Skip re-execution of initialization code
fi
export LIBRARY_NAME_SOURCED=1
```

**Key insight**: Source guards prevent FUNCTION re-definition but do NOT prevent VARIABLE re-initialization because:
- Variable assignments execute BEFORE the guard check
- Guard only affects code AFTER the `export LIBRARY_NAME_SOURCED=1` line
- Lines 66-77 in workflow-state-machine.sh execute on every source, even with guard

**Example from workflow-state-machine.sh:20-23**:
```bash
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0  # Functions not redefined
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1
# BUT: Lines 66-77 ALREADY EXECUTED before this guard
```

### 2. Parameter Expansion Patterns

#### The Four Expansion Operators

**From GNU Bash Manual and Stack Overflow research:**

| Pattern | Behavior | Use Case |
|---------|----------|----------|
| `${VAR:-word}` | Substitute `word` if VAR unset or null | Default values without assignment |
| `${VAR:=word}` | Assign and substitute `word` if unset/null | Initialize with default |
| `${VAR:?message}` | Error and exit if VAR unset or null | Require variable be set |
| `${VAR:+word}` | Substitute `word` only if VAR is set | Conditional behavior when set |

**Colon significance**: Omitting the colon tests ONLY for unset, not null:
- `${VAR:-default}`: Triggers on unset OR empty string (`VAR=""`)
- `${VAR-default}`: Triggers ONLY on unset (not on `VAR=""`)

#### Best Practice: `${VAR:-}` for Safe Conditionals

**Pattern**: `VAR="${VAR:-}"`

**Semantics**:
- If VAR is unset: Initialize to empty string
- If VAR is set (including empty string): Preserve existing value
- Safe with `set -u`: No "unbound variable" error

**Comparison to alternatives**:

```bash
# Direct assignment (CURRENT BEHAVIOR - CAUSES BUG)
WORKFLOW_SCOPE=""
# Problem: ALWAYS overwrites, loses state file value

# Conditional block (VERBOSE)
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  WORKFLOW_SCOPE=""
fi
# Problem: 3 lines per variable, 15 lines for 5 variables

# Conditional initialization (RECOMMENDED)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
# Benefits: 1 line, preserves value, set -u safe
```

#### Set -u Compatibility

**From "Bash Strict Mode" and Stack Overflow research:**

The `set -u` option causes immediate exit on unbound variable access. The `:-` operator is the idiomatic solution:

**Problem with direct access under set -u**:
```bash
set -u
echo "$UNDEFINED_VAR"  # ERROR: UNDEFINED_VAR: unbound variable
```

**Solution with conditional expansion**:
```bash
set -u
VALUE="${UNDEFINED_VAR:-default}"  # ✓ No error, VALUE="default"
```

**Application to library re-sourcing**:
```bash
# In library file with set -u enabled:
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
# First sourcing: WORKFLOW_SCOPE unset → initialize to ""
# Re-sourcing: WORKFLOW_SCOPE="research-and-plan" → preserve value
```

### 3. Solution Option Analysis

#### Option 1: Conditional Variable Initialization (RECOMMENDED)

**Change**: Modify workflow-state-machine.sh lines 66-77:

```bash
# Current (direct assignment):
CURRENT_STATE="${STATE_INITIALIZE}"
TERMINAL_STATE="${STATE_COMPLETE}"
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""
COMMAND_NAME=""

# Proposed (conditional initialization):
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"
```

**Pros**:
- ✓ Minimal change (5 lines modified)
- ✓ Preserves existing values across re-sourcing
- ✓ Safe with `set -u` (no unbound variable errors)
- ✓ Aligns with bash-block-execution-model.md save-before-source pattern
- ✓ No changes to coordinate.md required
- ✓ No risk of circular dependencies
- ✓ Idiomatic bash pattern (documented in GNU manual)
- ✓ Easy rollback (single commit revert)

**Cons**:
- ⚠ Introduces new pattern to .claude/ (no existing examples)
- ⚠ Requires documentation explaining the pattern

**Complexity**: Low (5-line change, extensive test coverage exists)

**Risk**: Very Low (well-understood bash feature, source guards remain unchanged)

#### Option 2: Move load_workflow_state Before Library Sourcing

**Change**: Reorder coordinate.md bash blocks to load state before sourcing libraries.

**Proposed sequence**:
```bash
# Current order (PROBLEMATIC):
source workflow-state-machine.sh  # Initializes variables
load_workflow_state "$WORKFLOW_ID"  # Restores from file (TOO LATE)

# Proposed order:
source state-persistence.sh  # Load persistence functions only
load_workflow_state "$WORKFLOW_ID"  # Restore variables from file
source workflow-state-machine.sh  # Functions loaded, variables preserved
```

**Pros**:
- ✓ No library changes required
- ✓ Explicit load order makes state restoration obvious

**Cons**:
- ✗ Requires sourcing state-persistence.sh FIRST (circular dependency risk)
- ✗ workflow-state-machine.sh depends on workflow-detection.sh (lines 95-97)
- ✗ Complex dependency chain: persistence → detection → state machine
- ✗ Changes required in 11 bash blocks in coordinate.md (error-prone)
- ✗ May break other commands using state machine library
- ✗ Violates existing library loading conventions

**Complexity**: Medium-High (11 bash blocks × dependency verification)

**Risk**: Medium (potential breaking changes to other commands)

#### Option 3: Remove Variable Initialization from Library

**Change**: Move all variable initialization from file scope into `sm_init()` function only.

**Proposed**:
```bash
# Current: Variables initialized at file scope (lines 66-77)
CURRENT_STATE="${STATE_INITIALIZE}"
WORKFLOW_SCOPE=""
# ...

# Proposed: NO file-scope initialization
# Only initialize in sm_init():
sm_init() {
  CURRENT_STATE="${STATE_INITIALIZE}"
  WORKFLOW_SCOPE=""
  # ...
}
```

**Pros**:
- ✓ Clean separation: file scope for constants, function scope for state
- ✓ No re-initialization on re-sourcing

**Cons**:
- ✗ Breaks all code that reads variables before calling sm_init()
- ✗ Requires `set -u` exception: `${WORKFLOW_SCOPE:-}` in every access
- ✗ Audit required: All 20+ commands using state machine library
- ✗ High risk of "unbound variable" errors in edge cases
- ✗ May break checkpoint recovery (variables expected to exist)

**Complexity**: High (audit 20+ commands, update all variable accesses)

**Risk**: High (potential breaking changes across entire codebase)

### 4. Best Practices from External Sources

#### GNU Bash Manual (Shell Parameter Expansion)

**Official documentation** confirms `${parameter:-word}` is the standard pattern:

> "If parameter is unset or null, the expansion of word is substituted. Otherwise, the value of parameter is substituted."

**Key insight**: This pattern explicitly supports "preserve if set, initialize if unset" semantics.

#### Unix & Linux Stack Exchange (122845)

**Best practice for library initialization**:

> "This notation is particularly useful in Red Hat scripts and system administration tools where scripts need sensible defaults but still permit runtime customization through environment variables—avoiding hardcoded values while maintaining reasonable fallbacks."

**Application**: Library variables should allow parent environment override without requiring explicit conditionals.

#### Bash Strict Mode (redsymbol.net)

**Pattern for set -u compatibility**:

> "The solution is to use parameter default values; bash has a syntax for declaring a default value using the ':-' operator. For example, `${1:-default}` prevents unbound variable errors."

**Recommendation**: All variable accesses in strict mode scripts should use conditional expansion when variable may be unset.

#### Stack Overflow Consensus (10+ threads analyzed)

**Common pattern for library re-sourcing**:

1. Source guards prevent function re-definition
2. Variable initialization should be conditional: `VAR="${VAR:-default}"`
3. Temporary disable `set -u` is anti-pattern (loses safety guarantees)
4. `:-` operator is idiomatic and well-understood across bash community

## Recommendations

### Primary Recommendation: Implement Option 1

**Action**: Modify `.claude/lib/workflow-state-machine.sh` lines 66-77 to use conditional initialization.

**Rationale**:
1. **Minimal Risk**: Single-file change, 5 lines modified
2. **Idiomatic Bash**: Follows GNU manual best practices
3. **Future-Proof**: Works with any re-sourcing scenario, not just coordinate.md
4. **Maintainable**: Pattern is self-documenting with inline comments
5. **Testable**: Existing test suite validates behavior (test_state_management.sh)

**Implementation**:
```bash
# In .claude/lib/workflow-state-machine.sh, modify lines 66-77:

# Current state of the state machine (preserve across re-sourcing)
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Array of completed states (preserve across re-sourcing)
# Note: Arrays cannot use conditional initialization, but they're
# re-initialized by sm_init() so this is not problematic
declare -ga COMPLETED_STATES=()

# Terminal state for this workflow (preserve across re-sourcing)
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"

# Workflow configuration (preserve across subprocess boundaries)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"
```

### Secondary Recommendations

#### 1. Document the Pattern in bash-block-execution-model.md

Add new pattern section:

```markdown
## Pattern 7: Conditional Variable Initialization for Re-sourcing

**Problem**: Library variables initialized at file scope get reset when library
is re-sourced in new subprocess, even with source guards.

**Solution**: Use conditional initialization to preserve existing values:

```bash
# Preserve value across subprocess boundaries
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"
```

**Why This Works**:
- Source guards prevent function re-definition
- Conditional initialization preserves variable values
- Safe with `set -u` (no unbound variable errors)
- Idiomatic bash pattern (GNU manual recommended)

**When to Use**:
- State machine variables that persist across bash blocks
- Configuration values loaded from state files
- Any variable that should survive library re-sourcing

**Case Study**: /coordinate WORKFLOW_SCOPE bug (Spec 653/654)
```

#### 2. Remove SAVED_WORKFLOW_DESC Workaround

Once Option 1 is implemented, coordinate.md lines 84-85 can be removed:

```bash
# Line 84-85: NO LONGER NEEDED
# SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
# export SAVED_WORKFLOW_DESC

# Line 124: Use direct variable
sm_init "$WORKFLOW_DESCRIPTION" "coordinate"  # Not $SAVED_WORKFLOW_DESC
```

**Rationale**: Conditional initialization eliminates need for workaround.

#### 3. Consider Library-Wide Audit (Low Priority)

Review all `.claude/lib/*.sh` files for similar issues:

- Search pattern: `^[A-Z_]+="[^$]` (direct string assignments)
- Identify variables that should persist across re-sourcing
- Apply conditional initialization pattern where appropriate

**Estimated scope**: 10-15 libraries, 30-50 variables

**Priority**: P2 (not blocking, no other known bugs)

#### 4. Add Test Coverage for Conditional Initialization

Extend `.claude/tests/test_state_machine_persistence.sh`:

```bash
test_conditional_initialization_preserves_values() {
  # Test that re-sourcing with existing value preserves it
  WORKFLOW_SCOPE="test-value"
  source .claude/lib/workflow-state-machine.sh

  if [ "$WORKFLOW_SCOPE" = "test-value" ]; then
    echo "✓ Conditional initialization preserved value"
    return 0
  else
    echo "✗ Value was overwritten: $WORKFLOW_SCOPE"
    return 1
  fi
}

test_conditional_initialization_initializes_when_unset() {
  # Test that first sourcing initializes to empty string
  unset WORKFLOW_SCOPE
  source .claude/lib/workflow-state-machine.sh

  if [ -z "$WORKFLOW_SCOPE" ]; then
    echo "✓ Conditional initialization set default"
    return 0
  else
    echo "✗ Unexpected value: $WORKFLOW_SCOPE"
    return 1
  fi
}
```

### Migration Strategy

**Phase 0**: Pre-implementation validation
1. Create reproduction test (verify bug exists)
2. Document current behavior in test suite
3. Review Plan 001 in Spec 653

**Phase 1**: Implement conditional initialization (1-2 hours)
1. Modify workflow-state-machine.sh lines 66-77
2. Add inline comments explaining pattern
3. Run existing test suite (test_state_management.sh)
4. Manual test with coordinate.md (research-and-plan workflow)

**Phase 2**: Documentation update (30 minutes)
1. Add Pattern 7 to bash-block-execution-model.md
2. Update coordinate-command-guide.md troubleshooting section
3. Add case study reference in workflow-state-machine.sh header

**Phase 3**: Cleanup workarounds (30 minutes)
1. Remove SAVED_WORKFLOW_DESC from coordinate.md
2. Test removal doesn't break anything
3. Update comments in coordinate.md

**Phase 4**: Extended validation (1 hour)
1. Run all /coordinate workflow scopes
2. Verify state persistence across all bash blocks
3. Check no regressions in /orchestrate, /supervise

**Total estimated time**: 3-4 hours

### Risk Mitigation

**Rollback plan**: Single commit revert
```bash
git revert <commit-sha>
# Restores direct initialization, bug returns but no new breakage
```

**Validation criteria**:
- ✓ All existing tests pass (test_state_management.sh: 127 tests)
- ✓ research-and-plan workflow stops after planning phase
- ✓ full-implementation workflow completes all phases
- ✓ No "unbound variable" errors with set -u enabled
- ✓ State file contains correct WORKFLOW_SCOPE value

**Monitoring**: Watch for issues in first 24 hours post-deployment
- Check .claude/data/logs/adaptive-planning.log for unexpected errors
- Monitor test suite pass rate
- Review any bug reports related to workflow scope

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:66-77` - Variable initialization (bug location)
2. `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:20-23` - Source guard pattern
3. `/home/benjamin/.config/.claude/commands/coordinate.md:82-128` - Initialization sequence (Block 1)
4. `/home/benjamin/.config/.claude/commands/coordinate.md:270-276` - State loading sequence (Block 2+)
5. `/home/benjamin/.config/.claude/lib/state-persistence.sh:9-12` - Source guard example
6. `/home/benjamin/.config/.claude/lib/state-persistence.sh:82-84` - CLAUDE_PROJECT_DIR conditional detection
7. `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
8. `/home/benjamin/.config/.claude/specs/653_coordinate_workflow_scope_persistence_bug/plans/001_fix_workflow_scope_persistence.md` - Bug analysis and solution options

### Pattern Analysis

9. **50+ instances** of `local param="${1:-}"` pattern across .claude/lib/ (function parameter safety)
10. **40+ instances** of `readonly` variables (constants only, not re-sourced state)
11. **20+ libraries** using source guard pattern consistently
12. **0 instances** of conditional initialization at file scope (new pattern for .claude/)

### External References

13. GNU Bash Manual - Shell Parameter Expansion: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
14. Unix Stack Exchange Q122845 - Using "${a:-b}" for variable assignment in scripts
15. Bash Strict Mode (redsymbol.net) - set -u compatibility patterns
16. Stack Overflow - Multiple threads on parameter expansion best practices (2024-2025)
17. Opensource.com - "An introduction to parameter expansion in Bash"
18. nixCraft - "How To Use Bash Parameter Substitution Like A Pro"

### Test Files

19. `.claude/tests/test_state_management.sh` - Existing state machine test suite (127 tests)
20. `.claude/tests/test_state_machine_persistence.sh` - New test file (to be created, 8 tests planned)
