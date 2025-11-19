# Scope Reduction Analysis for Two-Step Argument Pattern Migration

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Plan revision to migrate ONLY 4 commands to two-step pattern
- **Report Type**: codebase analysis

## Executive Summary

This report analyzes the reduced scope for two-step argument pattern migration, targeting only 4 commands: /build, /research-report, /research-plan, and /research-revise. This represents a 50% reduction from the previous 8-command plan. Analysis shows all 4 commands use straightforward argument patterns with the research-* commands at Low complexity (single primary argument) and /build at High complexity (positional + flags). The library design remains valid for 4 commands, though can be simplified. Estimated implementation time reduces from 8-12 hours to 4-6 hours, with significantly reduced risk due to exclusion of mode-detection commands (/expand, /collapse) and complex flag commands (/setup, /convert-docs).

## Findings

### 1. Commands to Migrate (4 Commands)

The following 4 commands will be migrated to the two-step pattern:

| Command | File | Argument Pattern | Complexity |
|---------|------|------------------|------------|
| `/build` | build.md:70 | `PLAN_FILE="$1"` + `STARTING_PHASE="${2:-1}"` + flags | High |
| `/research-report` | research-report.md:29 | `WORKFLOW_DESCRIPTION="$1"` | Low |
| `/research-plan` | research-plan.md:30 | `FEATURE_DESCRIPTION="$1"` | Low |
| `/research-revise` | research-revise.md:30 | `REVISION_DESCRIPTION="$1"` | Medium |

#### Detailed Argument Analysis

**1. /build (build.md:70-86)**
```bash
# Parse arguments
PLAN_FILE="$1"
STARTING_PHASE="${2:-1}"
DRY_RUN="false"

shift 2 2>/dev/null || shift $# 2>/dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN="true"; shift ;;
    *) shift ;;
  esac
done
```
- **Primary argument**: PLAN_FILE (required)
- **Secondary argument**: STARTING_PHASE (optional, default 1)
- **Flags**: --dry-run only
- **Complexity**: High due to positional args + flag parsing
- **Auto-resume logic**: Searches for most recent plan if no argument provided

**2. /research-report (research-report.md:29-60)**
```bash
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

# Parse optional --complexity flag
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```
- **Primary argument**: WORKFLOW_DESCRIPTION (required)
- **Embedded flag**: --complexity (parsed from within description string)
- **Complexity**: Low - single argument with inline flag extraction

**3. /research-plan (research-plan.md:30-61)**
```bash
FEATURE_DESCRIPTION="$1"

if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  exit 1
fi

# Parse optional --complexity flag (same pattern as research-report)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"
if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```
- **Primary argument**: FEATURE_DESCRIPTION (required)
- **Embedded flag**: --complexity (parsed from within description string)
- **Complexity**: Low - identical pattern to research-report

**4. /research-revise (research-revise.md:30-80)**
```bash
REVISION_DESCRIPTION="$1"

if [ -z "$REVISION_DESCRIPTION" ]; then
  echo "ERROR: Revision description with plan path required"
  exit 1
fi

# Parse optional --complexity flag
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"
if [[ "$REVISION_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi

# Extract existing plan path from revision description
EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)
```
- **Primary argument**: REVISION_DESCRIPTION (required)
- **Embedded flag**: --complexity
- **Path extraction**: Extracts .md file path from description using regex
- **Complexity**: Medium - requires path extraction from description

### 2. Commands Now Excluded (4 Commands)

The following 4 commands were in the previous 8-command plan but are now excluded:

| Command | File | Reason for Exclusion |
|---------|------|----------------------|
| `/fix` | fix.md:30 | Deferred to reduce scope despite low complexity |
| `/expand` | expand.md | Mode detection logic adds complexity (auto vs specific) |
| `/collapse` | collapse.md | Mode detection logic adds complexity (auto vs specific) |
| `/setup` | setup.md:31 | Complex flag parsing (--cleanup, --dry-run, --validate, --analyze, --apply-report, --enhance-with-docs) |
| `/convert-docs` | convert-docs.md | Directory arguments + optional flags |

**Note**: /fix has Low complexity but is excluded to achieve the requested 4-command scope. It could be added back easily.

### 3. Updated Time/Effort Estimates

| Category | Previous Plan (8 cmds) | Reduced Scope (4 cmds) | Reduction |
|----------|------------------------|------------------------|-----------|
| Phase 1: Library | 3-4 hours | 3-4 hours | None |
| Phase 2: Testing | 2-3 hours | 1.5-2 hours | 25-33% |
| Phase 3: Simple | 1 hour (3 cmds) | 30 min (0 cmds) | 100% |
| Phase 4: Medium+ | 3-4 hours (5 cmds) | 1.5-2 hours (4 cmds) | 50% |
| Phase 5: Docs | 2-3 hours | 1.5-2 hours | 25% |
| **Total** | **8-12 hours** | **4-6 hours** | **50%** |

### 4. Library Design Simplifications

The `argument-capture.sh` library design can be simplified for 4 commands:

**Retained Functions**:
- `capture_argument_part1()` - Required for all 4 commands
- `capture_argument_part2()` - Required for all 4 commands
- `cleanup_argument_files()` - Required

**Potential Simplifications**:
1. **No mode detection patterns needed**: /expand and /collapse excluded
2. **Simpler flag handling**: Only --dry-run (build) and --complexity (embedded in description)
3. **No complex multi-positional args**: /setup with 6+ flags excluded
4. **Consistent pattern**: All 4 commands have single primary argument

**Library Still Valid**: The core two-step pattern remains exactly as designed. The library functions work identically for 4 commands as for 8.

### 5. Phase Structure for 4 Commands

The plan phases should be restructured for 4 commands:

**Phase 1: Foundation - Library Creation** (unchanged)
- Create argument-capture.sh library
- No changes needed

**Phase 2: Testing - Library Test Suite** (reduced)
- Fewer test cases needed
- Can remove tests for mode detection patterns
- Can simplify concurrent execution tests

**Phase 3: Research Commands Migration** (new phase combining simple commands)
- /research-report (Low complexity)
- /research-plan (Low complexity)
- /research-revise (Medium complexity)

**Phase 4: Build Command Migration** (high complexity isolated)
- /build (High complexity with auto-resume)

**Phase 5: Documentation Updates** (reduced)
- Fewer examples needed
- Update documentation to reflect 4-command scope

### 6. Risk Analysis for Reduced Scope

| Risk Factor | 8-Command Risk | 4-Command Risk | Impact |
|-------------|----------------|----------------|--------|
| Regression in workflows | Medium | Low | Only 4 commands affected |
| Mode detection issues | Medium | None | /expand, /collapse excluded |
| Complex flag handling | High | Low | Only --dry-run in /build |
| User friction | Medium | Low | Fewer commands to learn |
| Testing effort | High | Medium | Fewer patterns to test |
| Implementation time | Medium | Low | 4-6 hours vs 8-12 hours |

### 7. Argument Pattern Consistency

All 4 commands share a consistent pattern:

```bash
PRIMARY_ARGUMENT="$1"

if [ -z "$PRIMARY_ARGUMENT" ]; then
  echo "ERROR: Argument required"
  exit 1
fi

# Embedded flag extraction (for --complexity)
if [[ "$PRIMARY_ARGUMENT" =~ --flag[[:space:]]+([value]) ]]; then
  FLAG_VALUE="${BASH_REMATCH[1]}"
  PRIMARY_ARGUMENT=$(echo "$PRIMARY_ARGUMENT" | sed 's/--flag[[:space:]]*[value]//' | xargs)
fi
```

This consistency simplifies:
- Library design
- Testing patterns
- Documentation examples
- User education

## Recommendations

### Recommendation 1: Restructure Plan into 4 Phases

Consolidate the plan from 5 phases to 4 phases:

1. **Phase 1**: Foundation - Library Creation (3-4 hours)
2. **Phase 2**: Testing - Library Test Suite (1.5-2 hours)
3. **Phase 3**: Research Commands Migration - all 3 research-* commands (1-1.5 hours)
4. **Phase 4**: Build Command Migration + Documentation (1.5-2 hours)

**Priority**: P0 - Required for plan revision
**Total Time**: 4-6 hours

### Recommendation 2: Update Success Criteria for 4 Commands

Revise success criteria to:
- [ ] argument-capture.sh library created and tested
- [ ] /research-report migrated and tested
- [ ] /research-plan migrated and tested
- [ ] /research-revise migrated and tested
- [ ] /build migrated and tested
- [ ] Documentation updated to reflect 4-command scope
- [ ] All existing tests pass

**Priority**: P0 - Required for plan revision

### Recommendation 3: Simplify Test Suite for 4 Commands

Reduce test cases to match actual patterns needed:
- Remove mode detection tests (no /expand, /collapse)
- Remove multi-flag tests (no /setup)
- Keep: basic capture, embedded flag extraction, path extraction
- Keep: concurrent execution safety
- Keep: special character handling

**Priority**: P1 - Reduces testing effort

### Recommendation 4: Document Future Migration Path

Add a section to the plan explaining:
- 4 commands excluded (/fix, /expand, /collapse, /setup, /convert-docs)
- Why they can be added later (after 4-command migration proves stable)
- Estimated additional effort for each excluded command

**Priority**: P2 - Helps future planning

### Recommendation 5: Consider Adding /fix Back

The /fix command has Low complexity (identical to research-* commands) and would:
- Add only 15-30 minutes of implementation time
- Provide 5 migrated commands (better coverage)
- Be the simplest possible command to migrate

**Priority**: P3 - Optional scope increase

### Recommendation 6: Create Minimal Documentation

With only 4 commands:
- No need for comprehensive migration guide
- Update command-authoring-standards.md with library reference
- Add simple example in bash-block-execution-model.md
- Skip creating separate two-step-argument-capture-guide.md

**Priority**: P2 - Reduces documentation effort

## Summary Table

| Category | Previous Plan | Reduced Scope | Difference |
|----------|---------------|---------------|------------|
| Commands to migrate | 8 | 4 | -4 (50%) |
| Low complexity | 3 | 2 | -1 |
| Medium complexity | 4 | 1 | -3 |
| High complexity | 1 | 1 | 0 |
| Estimated hours | 8-12 | 4-6 | -50% |
| Risk level | Low-Medium | Low | Reduced |
| Phases | 5 | 4 | -1 |

## References

### Commands to Migrate (4)
- `/home/benjamin/.config/.claude/commands/build.md:70-86` - High complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-report.md:29-60` - Low complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-plan.md:30-61` - Low complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-revise.md:30-80` - Medium complexity, RETAINED

### Commands Excluded (4 additional from previous plan)
- `/home/benjamin/.config/.claude/commands/fix.md:30-56` - Low complexity, EXCLUDED (scope reduction)
- `/home/benjamin/.config/.claude/commands/expand.md:59-100` - Medium complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/collapse.md:80-100` - Medium complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/setup.md:31-61` - Medium complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/convert-docs.md` - Medium complexity, EXCLUDED

### Related Plan and Reports
- `/home/benjamin/.config/.claude/specs/760_since_reliability_is_paramount_the_two_step_method/plans/001_since_reliability_is_paramount_the_two_s_plan.md` - Original plan to be revised
- `/home/benjamin/.config/.claude/specs/760_since_reliability_is_paramount_the_two_step_method/reports/001_two_step_pattern_systematic_implementation.md` - Initial research (13 commands)
- `/home/benjamin/.config/.claude/specs/760_since_reliability_is_paramount_the_two_step_method/reports/002_command_exclusion_analysis.md` - Previous exclusion analysis (8 commands)

### Canonical Reference
- `/home/benjamin/.config/.claude/commands/coordinate.md:18-92` - Two-step pattern implementation reference

### Documentation to Update
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:365-443` - Argument patterns
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:934` - Two-step example
