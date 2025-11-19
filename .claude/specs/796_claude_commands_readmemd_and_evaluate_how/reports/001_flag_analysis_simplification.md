# Command Flag Analysis and Simplification Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Command flag evaluation for simplification and consistency
- **Report Type**: codebase analysis

## Executive Summary

Analysis of 11 commands across the .claude/commands directory reveals 12 distinct flags with significant redundancy and inconsistent usage patterns. The `--file` and `--complexity` flags show good uniformity across 4 commands each, while `--dry-run`, `--auto-mode`, and `--threshold` have limited single-command usage that could be consolidated or eliminated. Key recommendations include standardizing `--file` for all description-based commands, consolidating complexity defaults, removing `--auto-mode` in favor of positional argument detection, and potentially making `--dry-run` universal across all mutating commands.

## Findings

### 1. Complete Flag Inventory by Command

| Command | Flags Used | Essential? | Notes |
|---------|-----------|------------|-------|
| `/plan` | `--file <path>`, `--complexity 1-4` | Yes/Yes | Core workflow command |
| `/research` | `--file <path>`, `--complexity 1-4` | Yes/Yes | Mirrors /plan pattern |
| `/debug` | `--file <path>`, `--complexity 1-4` | Yes/Yes | Mirrors /plan pattern |
| `/revise` | `--complexity 1-4` | Yes | Missing --file (should add) |
| `/build` | `--dry-run` | Moderate | Preview mode for safety |
| `/setup` | `--cleanup`, `--dry-run`, `--threshold`, `--validate`, `--analyze`, `--apply-report <path>`, `--enhance-with-docs` | Mixed | Most complex flag set |
| `/expand` | `--auto-mode` | Low | Could be inferred from arg count |
| `/collapse` | (none) | N/A | No flags |
| `/convert-docs` | `--use-agent` | Low | Could use mode keywords instead |
| `/coordinate` | (none) | N/A | No flags |
| `/optimize-claude` | (none) | N/A | Intentionally simple |

### 2. Flag Usage Analysis

#### 2.1 `--file <path>` (HIGH ESSENTIAL)

**Used by**: `/plan`, `/research`, `/debug` (lines 69-91 in each)

**Purpose**: Load command description from a file instead of inline argument. Archives original file to `{topic_path}/prompts/` for traceability.

**Implementation Pattern** (consistent across commands):
```bash
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate and read file
  DESCRIPTION=$(cat "$ORIGINAL_PROMPT_FILE_PATH")
fi
```

**Essentiality Assessment**: HIGH
- Enables long prompt handling (overcomes terminal character limits)
- Provides traceability through archiving
- Consistent implementation across commands

**Issue**: Missing from `/revise` command which also accepts descriptions

---

#### 2.2 `--complexity 1-4` (HIGH ESSENTIAL)

**Used by**: `/plan` (default: 3), `/research` (default: 2), `/debug` (default: 2), `/revise` (default: 2)

**Purpose**: Set research depth level for investigation phases.

**Implementation Pattern** (plan.md:55-66):
```bash
DEFAULT_COMPLEXITY=3  # varies by command
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```

**Essentiality Assessment**: HIGH
- Directly affects research thoroughness and execution time
- Well-documented behavior per level
- Consistent defaults documented in README.md:303-316

**Issue**: Default inconsistency - /plan uses 3, others use 2. This is intentional but could confuse users.

---

#### 2.3 `--dry-run` (MODERATE ESSENTIAL)

**Used by**: `/build`, `/setup --cleanup`

**Purpose**: Preview mode showing what would be done without making changes.

**Implementation in /build** (build.md:96-104):
```bash
for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
  esac
done
```

**Implementation in /setup** (setup.md:37):
```bash
--dry-run) DRY_RUN=true ;;
```

**Essentiality Assessment**: MODERATE
- Valuable safety feature for destructive operations
- Only used by 2 commands
- Could benefit from standardization across all mutating commands

**Issue**: Not available on `/implement`, `/coordinate`, or other potentially destructive commands

---

#### 2.4 `--auto-mode` (LOW ESSENTIAL)

**Used by**: `/expand`

**Purpose**: Enable non-interactive JSON output for agent coordination.

**Implementation** (expand.md:527-541):
```bash
AUTO_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--auto-mode" ]]; then
    AUTO_MODE=true
  else
    ARGS+=("$arg")
  fi
done
```

**Essentiality Assessment**: LOW
- Only used by one command
- Could be inferred from context (agent invocation vs user invocation)
- JSON output mode could be detected by presence of calling agent

**Recommendation**: REMOVE - Mode can be inferred from argument count (1 arg = auto mode, 3 args = explicit mode)

---

#### 2.5 `--threshold` (LOW ESSENTIAL)

**Used by**: `/setup --cleanup`

**Purpose**: Set aggressiveness level for CLAUDE.md cleanup (aggressive|balanced|conservative).

**Implementation** (setup.md:38):
```bash
--threshold) shift; THRESHOLD="$1"; shift ;;
```

**Essentiality Assessment**: LOW
- Only used with cleanup mode
- Adds complexity to an already complex command
- Could default to balanced and rarely need changing

**Recommendation**: Consider removing or making it a separate cleanup mode option

---

#### 2.6 `--use-agent` (LOW ESSENTIAL)

**Used by**: `/convert-docs`

**Purpose**: Force agent mode for comprehensive 5-phase workflow with validation.

**Implementation** (convert-docs.md:205-214):
```bash
if [[ "$user_request" =~ --use-agent ]]; then
  agent_mode=true
fi
# Also triggers on keywords
if echo "$user_request" | grep -qiE "detailed logging|quality reporting|verify tools"; then
  agent_mode=true
fi
```

**Essentiality Assessment**: LOW
- Keyword detection already triggers agent mode
- Flag is redundant with natural language alternatives
- Could be simplified to keyword-only detection

**Recommendation**: REMOVE - Keywords provide more intuitive triggering

---

#### 2.7 Setup Command Flags (MIXED ESSENTIAL)

The `/setup` command has the most complex flag set:

| Flag | Essential | Notes |
|------|-----------|-------|
| `--cleanup` | High | Core functionality |
| `--validate` | High | Useful standalone operation |
| `--analyze` | Moderate | Creates basic report |
| `--apply-report <path>` | Low | Rarely used, manual process |
| `--enhance-with-docs` | Low | Delegates to /orchestrate |

**Recommendation**: Consider splitting /setup into:
- `/setup` - Basic generation
- `/setup-cleanup` - Cleanup with dry-run/threshold
- `/setup-validate` - Validation only
- `/setup-analyze` - Analysis only

---

### 3. Flag Consistency Analysis

#### Consistent Patterns (Good)

1. **Flag format**: All use `--flag-name` format consistently
2. **Value flags**: Use `--flag <value>` pattern consistently
3. **Boolean flags**: Simple presence/absence detection

#### Inconsistent Patterns (Needs Improvement)

1. **--file missing from /revise**: Should support long prompts like /plan, /research, /debug
2. **No --dry-run on /coordinate**: Would benefit from preview mode
3. **--auto-mode only on /expand**: /collapse should have it too for symmetry

### 4. Complexity vs Usability Trade-offs

| Command | Flag Count | Complexity Score | Usability Score |
|---------|------------|------------------|-----------------|
| `/optimize-claude` | 0 | Low | High |
| `/collapse` | 0 | Low | High |
| `/coordinate` | 0 | Low | High |
| `/plan` | 2 | Low | High |
| `/research` | 2 | Low | High |
| `/debug` | 2 | Low | High |
| `/revise` | 1 | Low | High |
| `/build` | 1 | Low | High |
| `/expand` | 1 | Low | High |
| `/convert-docs` | 1 | Low | High |
| `/setup` | 7 | High | Low |

## Recommendations

### Priority 1: Remove Low-Essential Flags (Simplification)

1. **Remove `--auto-mode` from /expand**
   - Rationale: Mode can be inferred from argument count
   - Implementation: `/expand <path>` = auto mode, `/expand phase|stage <path> <num>` = explicit mode
   - Impact: Reduces flag count, simplifies usage

2. **Remove `--use-agent` from /convert-docs**
   - Rationale: Keywords already trigger agent mode
   - Implementation: Keep keyword detection only
   - Impact: Reduces flag count, more intuitive usage

3. **Remove `--threshold` from /setup**
   - Rationale: Rarely changed from default, adds complexity
   - Implementation: Default to balanced, power users can edit config
   - Impact: Simplifies cleanup mode

### Priority 2: Standardize Core Flags (Consistency)

4. **Add `--file` to /revise**
   - Rationale: Maintains consistency with /plan, /research, /debug
   - Implementation: Copy --file handling block from plan.md
   - Impact: Complete flag parity across description-based commands

5. **Standardize `--dry-run` across mutating commands**
   - Rationale: Safety feature should be universal
   - Commands to add: /coordinate, /expand, /collapse
   - Impact: Consistent safety net for all destructive operations

### Priority 3: Refactor Complex Commands (Structural)

6. **Simplify /setup command**
   - Option A: Remove --apply-report and --enhance-with-docs (delegate to /orchestrate)
   - Option B: Split into separate commands: /setup, /setup-cleanup, /setup-validate
   - Rationale: 7 flags is too complex for one command
   - Impact: Better usability, clearer command purpose

### Priority 4: Documentation Updates (Clarity)

7. **Add flag quick-reference table to README.md**
   - Include: Flag name, supported commands, default values
   - Rationale: Current documentation is spread across sections
   - Impact: Easier user discovery

8. **Document complexity level impacts**
   - Add: Expected execution time per level
   - Add: Research output size per level
   - Rationale: Help users choose appropriate complexity

### Flags to KEEP Unchanged

| Flag | Reason to Keep |
|------|----------------|
| `--file` | High utility, consistent implementation |
| `--complexity` | Direct user control over research depth |
| `--dry-run` | Essential safety feature (but standardize) |
| `--cleanup` | Core /setup functionality |
| `--validate` | Useful standalone operation |
| `--analyze` | Enables research-driven updates |

### Summary of Recommended Changes

| Change Type | Flags Affected | Commands Affected |
|-------------|----------------|-------------------|
| Remove | `--auto-mode`, `--use-agent`, `--threshold` | /expand, /convert-docs, /setup |
| Add | `--file` | /revise |
| Standardize | `--dry-run` | /coordinate, /expand, /collapse |
| Simplify | Multiple | /setup (split or reduce) |

**Net Result**: Reduce total unique flags from 12 to 8, while improving consistency and usability.

## References

### Command Files Analyzed

- `/home/benjamin/.config/.claude/commands/plan.md` (lines 55-91: flag parsing)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 54-90: flag parsing)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 39-75: flag parsing)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 82-96: complexity only)
- `/home/benjamin/.config/.claude/commands/build.md` (lines 90-109: argument parsing)
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 29-60: mode detection)
- `/home/benjamin/.config/.claude/commands/expand.md` (lines 527-577: mode detection)
- `/home/benjamin/.config/.claude/commands/collapse.md` (lines 413-445: mode detection)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 205-214: mode detection)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-42: no flags)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-42: no flags)
- `/home/benjamin/.config/.claude/commands/README.md` (lines 271-398: Common Flags documentation)
