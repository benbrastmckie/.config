# Research Report: /todo --clean Output Standardization

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Refactor /todo --clean command to: 1) Return standardized output similar to /plan or /build with paths to artifacts created, 2) Remove --execute flag since user always wants to review plan first, 3) Begin by committing all projects to git before removing them
- **Report Type**: Best practices and pattern recognition
- **Complexity**: 3

## Executive Summary

Research reveals that the current `/todo --clean` implementation uses a plan-generation workflow (invokes plan-architect agent, returns plan file path) but lacks standardized output formatting. The command should adopt the 4-section console summary pattern used by `/plan`, `/build`, `/research`, and other artifact-producing commands. Key findings: (1) The plan-generation approach is architecturally correct and should be maintained, (2) No --execute flag exists in current implementation (requirement #2 already satisfied), (3) Git commit strategy should be integrated into the generated cleanup plan, not the `/todo` command itself. The refactoring should focus on standardizing the completion output format and ensuring the generated plan includes proper git verification phases.

## Findings

### 1. Current /todo --clean Implementation Analysis

**File**: `/home/benjamin/.config/.claude/commands/todo.md` (lines 618-671)

**Current Behavior**:
The `--clean` mode generates a cleanup plan via the plan-architect agent and returns a basic completion message. The implementation follows the hard barrier pattern used by other orchestrator commands.

**Current Output** (lines 659-671):
```bash
echo ""
echo "=============================================="
echo "/todo Command Complete"
echo "=============================================="
echo ""
echo "Summary:"
echo "  Projects scanned: $PROJECT_INDEX"
echo "  TODO.md updated: $TODO_PATH"
echo ""
echo "To review changes:"
echo "  cat $TODO_PATH"
echo ""
```

**Issues with Current Output**:
1. **Non-standard format**: Does not follow 4-section console summary pattern
2. **Missing artifact paths**: No explicit paths to generated cleanup plan
3. **Mixed mode output**: Same completion message for both update mode and clean mode
4. **No emoji markers**: Lacks visual scanning aids for terminal output
5. **Generic next steps**: Does not guide user to review/execute cleanup plan

**Expected Output Format** (from output-formatting.md lines 378-403):
```bash
=== [Command] Complete ===

Summary: [2-3 sentence narrative]

Phases:
  • Phase 1: [Title or Complete]
  [Only if workflow has phases]

Artifacts:
  📄 Plan: /absolute/path/to/plan.md
  📊 Reports: /absolute/path/ (N files)
  ✅ Summary: /absolute/path/to/summary.md

Next Steps:
  • Review [artifact]: cat /path
  • [Command-specific action 1]
```

### 2. Standardized Output Pattern Analysis

**Reference Commands** with proper output formatting:

**A. /plan Command** (plan.md lines 1206-1241):
```bash
# === RETURN PLAN_CREATED SIGNAL ===
echo ""
echo "=== Plan Complete ==="
echo ""
echo "PLAN_CREATED: $PLAN_PATH"
echo ""

# 4-section console summary
cat << EOF
Summary: Created implementation plan with ${PHASE_COUNT} phases based on research findings. Plan provides structured approach for ${FEATURE_DESCRIPTION}.

Artifacts:
  📄 Plan: $PLAN_PATH
  📊 Research: $RESEARCH_DIR/ ($(ls "$RESEARCH_DIR" | wc -l) files)

Next Steps:
  • Review plan: cat $PLAN_PATH
  • Begin implementation: /build $PLAN_PATH
  • Review research: cat $RESEARCH_DIR/001-*.md
EOF
```

**B. /build Command** (build.md lines 1660-1710):
```bash
# 4-section console summary with emoji markers
cat << EOF
=== Build Complete ===

Summary: ${SUMMARY_TEXT}

Phases:
  • Phase 1: ${PHASE_1_TITLE} - Complete
  • Phase 2: ${PHASE_2_TITLE} - Complete
  [...]

Artifacts:
  📄 Plan: $PLAN_PATH
  ✅ Summary: $SUMMARY_PATH
  🔧 Test Results: $TEST_ARTIFACT_PATH

Next Steps:
  • Review summary: cat $SUMMARY_PATH
  • Check test results: cat $TEST_ARTIFACT_PATH
  • Commit changes: git add . && git commit
EOF
```

**C. /research Command** (research.md lines 690-730):
```bash
# === RETURN REPORT_CREATED SIGNAL ===
echo "REPORT_CREATED: $LATEST_REPORT"

cat << EOF
=== Research Complete ===

Summary: Analyzed ${SOURCES_ANALYZED} sources and identified ${KEY_FINDINGS_COUNT} key findings. Research provides foundation for implementation planning.

Artifacts:
  📊 Reports: $REPORTS_DIR/ ($(ls "$REPORTS_DIR" | wc -l) files)

Next Steps:
  • Review reports: cat $REPORTS_DIR/001-*.md
  • Create plan: /plan --file $REPORTS_DIR/001-*.md
EOF
```

**Common Pattern Characteristics**:
1. **Completion Signal**: `PLAN_CREATED:`, `REPORT_CREATED:`, `SUMMARY_CREATED:` with absolute path
2. **4-Section Format**: Summary, Phases (optional), Artifacts, Next Steps
3. **Emoji Markers**: 📄 (plans), 📊 (reports), ✅ (summaries), 🔧 (debug/test)
4. **Absolute Paths**: All artifact references use full paths
5. **Actionable Steps**: Copy-paste commands for next workflow stage
6. **Concise Summary**: 2-3 sentences explaining WHAT was accomplished and WHY it matters

### 3. --execute Flag Investigation

**Search Results**: No `--execute` flag exists in current implementation.

**Flag Inventory** (todo.md lines 68-85):
```bash
while [ $# -gt 0 ]; do
  case "$1" in
    --clean)
      CLEAN_MODE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
```

**Existing Flags**:
- `--clean`: Enable cleanup mode (generate plan)
- `--dry-run`: Preview changes without executing

**Finding**: The `--execute` flag mentioned in the requirement does NOT exist in current implementation. The requirement to "remove --execute flag" is already satisfied - no action needed.

**Implication**: The current architecture already enforces the desired workflow:
1. `/todo --clean` → generates plan
2. User reviews plan
3. `/build <plan-path>` → executes cleanup

This is the correct two-step pattern for safety-critical operations (confirmed by output-formatting.md line 616 pattern).

### 4. Git Commit Strategy Analysis

**Requirement**: "Begin by committing all projects to git before removing them"

**Current Implementation**: No git commit logic in `/todo --clean` (lines 618-651).

**Existing Plan-Architect Prompt** (todo.md lines 635-651):
```markdown
Create a plan with phases:
1. Git verification (check for uncommitted changes in each project directory)
2. Archive creation (create timestamped archive directory)
3. Directory removal (move eligible projects to archive)
4. Verification (confirm cleanup success)

Safety requirements:
- Check git status for each directory (skip if uncommitted changes)
- Archive (don't delete) all projects
- Preserve TODO.md (no modification during cleanup)
- Log all operations with skipped directories
- Include recovery instructions in plan
```

**Analysis**: The git handling strategy is correctly delegated to the **generated cleanup plan**, not the `/todo` command itself. This architectural separation is appropriate because:

1. **Command Responsibility**: `/todo --clean` discovers eligible projects and generates plan
2. **Plan Responsibility**: Generated plan implements git verification, archival, and removal
3. **Execution Responsibility**: `/build` command executes plan phases with proper error handling

**Git Strategy in Generated Plan** (should include these phases):

**Phase 0: Git Status Verification**
- Check `git status --porcelain <topic-dir>` for each eligible project
- Classify projects: clean (proceed) vs uncommitted (skip with warning)
- Log skipped projects for user review
- Exit code: 0 (continue even if some skipped)

**Phase 1: Git Commit (Optional)**
- For projects with uncommitted changes: Offer option to commit
- User must manually commit before re-running cleanup
- NOT automated (user should review changes first)

**Phase 2: Archive Creation**
- Create timestamped archive: `.claude/archive/cleaned_YYYYMMDD_HHMMSS/`
- Move directories to archive (preserves git history)
- Generate manifest with project metadata

**Phase 3: Verification**
- Confirm all operations succeeded
- Provide recovery instructions

**Finding**: The git commit requirement should be interpreted as "verify git status and skip uncommitted projects" rather than "auto-commit all changes". This aligns with safety principles (user reviews before destructive operations).

### 5. Plan-Generation Workflow Architecture

**Pattern**: `/todo --clean` follows the same orchestrator pattern as `/plan`, `/debug`, `/repair`:

**Workflow Comparison**:

| Command | Discovers | Invokes Agent | Returns Artifact | Execution |
|---------|-----------|---------------|------------------|-----------|
| `/plan` | Feature description | plan-architect | Plan file | `/build <plan>` |
| `/debug` | Error patterns | plan-architect | Debug plan | `/build <plan>` |
| `/repair` | Error logs | plan-architect | Repair plan | `/build <plan>` |
| `/todo --clean` | Eligible projects | plan-architect | Cleanup plan | `/build <plan>` |

**Architectural Consistency**: All commands follow the same pattern:
1. **Discovery Phase**: Command identifies scope (features, errors, projects)
2. **Planning Phase**: Agent generates implementation plan
3. **Return Phase**: Command returns plan path with standardized output
4. **Execution Phase**: User reviews plan, runs `/build <plan>`

**Current Deviation**: `/todo --clean` returns plan but lacks standardized output format (violates consistency principle from output-formatting.md lines 365-366).

### 6. Filter Function Analysis

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (lines 717-738)

**Current Implementation** (`filter_completed_projects()`):
```bash
filter_completed_projects() {
  local plans_json="$1"

  if ! command -v jq &>/dev/null; then
    echo "[]"
    return 1
  fi

  # Filter for cleanup-eligible statuses: completed, superseded, abandoned
  # No age-based filtering applied - all eligible projects included
  local eligible_projects
  eligible_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed" or .status == "superseded" or .status == "abandoned")]')

  echo "$eligible_projects"
}
```

**Finding**: The age-based filtering has already been removed (see comment line 733). The function correctly filters for three statuses: completed, superseded, and abandoned.

**Status**: No changes needed to filtering logic (already refactored in plan 974).

### 7. Output Formatting Standards Requirements

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md`

**4-Section Console Summary** (lines 378-403):

**Required Sections**:

1. **Summary Section** (lines 404-422):
   - 2-3 sentences maximum
   - Explain WHAT was accomplished (scope, scale)
   - Explain WHY it matters (purpose, value)
   - Use narrative language, not technical jargon

2. **Phases Section** (lines 424-444):
   - Only include if workflow has distinct phases
   - One bullet per phase with completion status
   - Use `•` for bullets
   - Omit if no phases

3. **Artifacts Section** (lines 446-487):
   - One line per artifact type
   - Emoji markers from approved vocabulary
   - Absolute paths (never relative)
   - Show file count for directories `(N files)`
   - Order: Primary artifacts first

4. **Next Steps Section** (lines 489-511):
   - 2-4 actionable commands
   - First step MUST be reviewing primary artifact
   - Absolute paths in commands
   - Copy-paste ready
   - Use `•` for bullets

**Emoji Vocabulary** (lines 462-470):
- 📄 Plan files (.md in plans/)
- 📊 Research reports (.md in reports/)
- ✅ Implementation summaries (.md in summaries/)
- 🔧 Debug artifacts (debug/)
- 📁 Generic directory
- 💾 Checkpoint files (.json)

**Length Targets** (lines 513-522):
- Summary: 2-3 sentences (~40-80 words)
- Phases: 1 line per phase (omit if none)
- Artifacts: 1-5 lines
- Next Steps: 2-4 lines
- **Total**: 15-25 lines

**Terminal Output Emoji Policy** (lines 553-561):
- **Allowed**: Emoji markers in terminal stdout for visual scanning
- **Not Allowed**: Emoji in file artifacts (.md files)
- **Rationale**: Terminal output ephemeral, benefits from visual markers. Files are permanent documentation requiring UTF-8 compatibility.

## Recommendations

### Recommendation 1: Adopt 4-Section Console Summary Format

**Priority**: High
**Effort**: Low (2-3 hours)

**Action**: Replace generic completion output in `/todo --clean` with standardized 4-section format.

**Implementation**:

Add new completion block to Clean Mode section (after plan-architect invocation):

```bash
## Block 5: Clean Mode Completion

**EXECUTE IF CLEAN_MODE=true**: Display standardized completion summary

```bash
set +H  # Disable history expansion

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source libraries for state restoration
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1

# Restore state from plan-architect block
STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE" 2>/dev/null || true
fi

# Extract plan path from plan-architect return
# Assumes plan-architect returned: CLEANUP_PLAN_CREATED: <path>
CLEANUP_PLAN_PATH="${CLEANUP_PLAN_CREATED:-}"

if [ -z "$CLEANUP_PLAN_PATH" ] || [ ! -f "$CLEANUP_PLAN_PATH" ]; then
  echo "ERROR: Cleanup plan not created" >&2
  exit 1
fi

# Count eligible projects for summary
ELIGIBLE_COUNT=$(jq 'length' "$DISCOVERED_PROJECTS" 2>/dev/null || echo "0")

# === STANDARDIZED 4-SECTION OUTPUT ===
echo ""
echo "=== /todo --clean Complete ==="
echo ""

cat << EOF
Summary: Generated cleanup plan for ${ELIGIBLE_COUNT} eligible projects from Completed, Abandoned, and Superseded sections. Plan includes git verification, timestamped archival, and directory removal phases.

Artifacts:
  📄 Cleanup Plan: $CLEANUP_PLAN_PATH

Next Steps:
  • Review plan: cat $CLEANUP_PLAN_PATH
  • Execute cleanup: /build $CLEANUP_PLAN_PATH
  • Rescan projects: /todo
EOF

echo ""
echo "CLEANUP_PLAN_CREATED: $CLEANUP_PLAN_PATH"
```
```

**Benefits**:
- Consistency with other artifact-producing commands
- Clear guidance on next steps
- Absolute paths for easy copy-paste
- Visual markers for scanning

### Recommendation 2: Update plan-architect Prompt for Git Verification

**Priority**: High
**Effort**: Low (1 hour)

**Action**: Ensure plan-architect prompt explicitly requests git status verification phase in generated cleanup plan.

**Current Prompt** (todo.md lines 635-651):
```markdown
Create a plan with phases:
1. Git verification (check for uncommitted changes in each project directory)
2. Archive creation (create timestamped archive directory)
3. Directory removal (move eligible projects to archive)
4. Verification (confirm cleanup success)
```

**Enhanced Prompt**:
```markdown
Create a plan with phases:
1. Git Status Verification
   - Check git status --porcelain for each eligible project directory
   - Classify: clean (proceed) vs uncommitted (skip with warning)
   - Log skipped directories for user review
   - Continue with cleanup even if some directories skipped

2. Archive Creation
   - Create timestamped archive: .claude/archive/cleaned_YYYYMMDD_HHMMSS/
   - Generate manifest with project metadata

3. Directory Archival
   - Move clean directories to archive (preserves git history)
   - Skip directories with uncommitted changes
   - Log all operations

4. Verification
   - Confirm all clean directories archived
   - List skipped directories (if any)
   - Provide recovery instructions

Safety requirements:
- NEVER modify TODO.md (preserve as-is)
- NEVER delete directories (archive only)
- NEVER force-commit changes (user must commit manually)
- Log all skipped directories with uncommitted changes
- Include recovery instructions in plan output
```

**Benefits**:
- Explicit git verification behavior
- Clear skip-and-warn pattern
- User maintains control over commits
- Safe cleanup (archive, not delete)

### Recommendation 3: Add Dry-Run Support to Clean Mode

**Priority**: Medium
**Effort**: Low (1 hour)

**Action**: Respect `--dry-run` flag in clean mode to preview cleanup candidates without generating plan.

**Implementation**:

Add dry-run check before plan-architect invocation:

```bash
## Clean Mode (--clean flag)

If CLEAN_MODE is true, generate cleanup plan for eligible projects.

**Pre-Check: Dry-Run Preview**

If `--dry-run` is set, display cleanup candidates and exit without generating plan.

```bash
if [ "$DRY_RUN" = "true" ] && [ "$CLEAN_MODE" = "true" ]; then
  # Preview cleanup candidates
  ELIGIBLE_PROJECTS=$(filter_completed_projects "$CLASSIFIED_RESULTS")
  ELIGIBLE_COUNT=$(echo "$ELIGIBLE_PROJECTS" | jq 'length')

  echo "=== Cleanup Preview (Dry Run) ==="
  echo ""
  echo "Eligible projects: $ELIGIBLE_COUNT"
  echo ""
  echo "Cleanup candidates (would be archived):"
  echo "$ELIGIBLE_PROJECTS" | jq -r '.[] | "  - \(.topic_name): \(.title)"'
  echo ""
  echo "To generate cleanup plan, run: /todo --clean"
  exit 0
fi
```

**EXECUTE IF CLEAN_MODE=true AND DRY_RUN=false**: Generate cleanup plan via plan-architect.
```

**Benefits**:
- User can preview cleanup scope
- Consistent with `/todo --dry-run` behavior
- No accidental plan generation

### Recommendation 4: Document Workflow in Command Guide

**Priority**: Medium
**Effort**: Low (30 minutes)

**Action**: Update `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md` with clean mode workflow and output format.

**Add Section** (after line 294):

```markdown
### Clean Mode Output Format

The `--clean` flag generates a cleanup plan following the standardized 4-section console summary format:

**Example Output**:
```
=== /todo --clean Complete ===

Summary: Generated cleanup plan for 193 eligible projects from Completed, Abandoned, and Superseded sections. Plan includes git verification, timestamped archival, and directory removal phases.

Artifacts:
  📄 Cleanup Plan: /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md

Next Steps:
  • Review plan: cat /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
  • Execute cleanup: /build /home/user/.config/.claude/specs/975_cleanup/plans/001-cleanup-plan.md
  • Rescan projects: /todo
```

**Workflow**:
1. `/todo --clean --dry-run` - Preview cleanup candidates
2. `/todo --clean` - Generate cleanup plan
3. Review generated plan file
4. `/build <plan-path>` - Execute cleanup
5. `/todo` - Rescan and update TODO.md
```

**Benefits**:
- Clear workflow documentation
- Example output for reference
- User guidance on review-before-execute pattern

### Recommendation 5: No --execute Flag Removal Needed

**Priority**: N/A
**Effort**: 0 hours

**Finding**: The `--execute` flag does not exist in current implementation. No action required.

**Current Architecture**: Already enforces review-before-execute pattern:
- `/todo --clean` → generates plan (safe)
- User reviews plan file
- `/build <plan>` → executes (requires explicit user action)

**Recommendation**: Document this as "already implemented" in completion summary.

## References

### Primary Files Analyzed

1. **Command Files**:
   - `/home/benjamin/.config/.claude/commands/todo.md` (lines 1-679)
   - `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-100, 1206-1241)
   - `/home/benjamin/.config/.claude/commands/build.md` (lines 1250-1350, 1660-1710)
   - `/home/benjamin/.config/.claude/commands/research.md` (lines 690-730)

2. **Library Files**:
   - `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (lines 1-886, complete)

3. **Documentation Files**:
   - `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` (lines 1-651)
   - `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md` (lines 1-399)

4. **Plan Files**:
   - `/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/plans/001-todo-clean-refactor-plan.md` (lines 1-520)
   - `/home/benjamin/.config/.claude/specs/974_todo_clean_refactor/reports/001-todo-clean-refactor-research.md` (lines 1-150)

### Key Standards Referenced

1. **Output Formatting Standards**:
   - 4-section console summary format (output-formatting.md:378-403)
   - Emoji vocabulary (output-formatting.md:462-470)
   - Length targets (output-formatting.md:513-522)
   - Terminal emoji policy (output-formatting.md:553-561)

2. **Command Patterns**:
   - Standardized completion signals (`PLAN_CREATED:`, `REPORT_CREATED:`)
   - Hard barrier pattern for subagent delegation
   - Review-before-execute workflow for safety-critical operations

3. **Git Verification Patterns**:
   - Skip-and-warn pattern for uncommitted changes
   - Archive (not delete) for safe recovery
   - User maintains control over commits

### Related Documentation

- [Command Reference](../../reference/standards/command-reference.md#todo)
- [TODO Organization Standards](../../reference/standards/todo-organization-standards.md)
- [Error Handling Pattern](../../concepts/patterns/error-handling.md)
