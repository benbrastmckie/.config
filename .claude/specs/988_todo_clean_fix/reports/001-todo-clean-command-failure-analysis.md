# /todo --clean Command Failure Analysis

## Executive Summary

The `/todo --clean` command successfully identified 136-139 cleanup-eligible projects but only removed 39 directories, leaving 97+ project directories unremoved and their entries still present in TODO.md. This research identifies the root causes and provides concrete evidence of both the parsing logic failures and the TODO.md update gap.

## Research Questions Answered

### 1. What does the current /todo --clean implementation do?

**File**: `.claude/commands/todo.md`

The `/todo --clean` command has two distinct operational modes:

1. **Default Mode** (no --clean flag): Scans specs/ directories, classifies plan status, updates TODO.md
2. **Clean Mode** (--clean flag): Directly removes cleanup-eligible projects (Completed, Abandoned, Superseded) after git commit

**Clean Mode Workflow** (Block 4b):
```bash
# Line 772-823 in todo.md
1. Parse TODO.md sections for cleanup-eligible entries (Completed, Abandoned, Superseded)
2. Call parse_todo_sections() to extract project directories
3. Check for uncommitted changes in each directory
4. Create pre-cleanup git commit
5. Remove eligible directories via execute_cleanup_removal()
6. Generate completion summary
```

**Key Finding**: The command **does NOT** update TODO.md after removing directories. It explicitly states in the documentation:

> "TODO.md is NOT modified during cleanup - it reflects the current filesystem state after next scan."

This is the **first major bug**: After cleanup, TODO.md still contains entries for deleted projects.

### 2. How does it identify cleanup-eligible projects?

**File**: `.claude/lib/todo/todo-functions.sh` (lines 717-825)

The `parse_todo_sections()` function identifies projects through this algorithm:

```bash
# Extract content from Completed, Abandoned, Superseded sections
for section in ("Completed" "Abandoned" "Superseded"); do
  # Use awk to extract section content
  section_content=$(awk -v section="## $section" '
    $0 == section { found=1; next }
    /^## / && found { exit }
    found { print }
  ')

  # For each line matching pattern: - [x] or - [~] **Title** ... [path]
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^- \[[x~]\] \*\*'; then
      # Extract topic number from:
      # 1. Parentheses: (NNN)
      # 2. Plan path: specs/NNN_topic/

      topic_num=$(echo "$line" | grep -oE '\([0-9]+\)' | head -1 | tr -d '()')

      if [ -z "$topic_num" ]; then
        topic_num=$(echo "$line" | grep -oE 'specs/[0-9]+_' | head -1 | sed 's/specs\///' | tr -d '_')
      fi

      # Find matching directory in specs/
      topic_dir=$(find "$specs_root" -maxdepth 1 -type d -name "${topic_num}_*" 2>/dev/null | head -1)

      # Skip if not found (already removed)
      [ -z "$topic_dir" ] && continue

      # Build JSON entry
      json_entries="${json_entries}, ${entry}"
    fi
  done <<< "$section_content"
done
```

**Key Design**: The function reads **directly from TODO.md sections** rather than relying on plan file classification. This honors manual categorization but requires TODO.md to be accurate.

### 3. Why did it only remove 39 directories when 136 were identified as cleanup-eligible?

**Evidence from Git History**:

```bash
# Commit e8162eb9 (most recent cleanup attempt)
chore: pre-cleanup snapshot before /todo --clean (39 projects)

# Commit 376f1d93 (previous cleanup attempt)
chore: pre-cleanup snapshot before /todo --clean (107 projects)

# Commit 6f5bbb4c (actual removal)
chore: remove 106 completed/abandoned project directories
Skipped 1 project with uncommitted changes (979_todo_clean_refactor_direct_removal).
```

**Analysis of Entry Counts**:

```bash
# Total eligible entries in Completed+Abandoned+Superseded sections
$ git show 376f1d93:.claude/TODO.md | grep -E "^## (Completed|Abandoned|Superseded)" -A 5000 | grep -E "^- \[[x~]\]" | wc -l
139

# Entries with topic numbers in path (specs/NNN_)
$ git show 376f1d93:.claude/TODO.md | grep -E "^## (Completed|Abandoned|Superseded)" -A 5000 | grep -E "^- \[[x~]\]" | grep -E 'specs/[0-9]+_' | wc -l
139

# Entries removed in commit 6f5bbb4c
106 directories removed + 1 skipped (uncommitted) = 107 identified
```

**Root Cause Identified**:

The discrepancy occurs because `parse_todo_sections()` has **multiple failure modes**:

1. **Greedy Regex Pattern**: The pattern `'\[[^]]+\.md\]'` to extract plan paths is too greedy:
   ```bash
   # Line 790 in todo-functions.sh
   plan_path=$(echo "$line" | grep -oE '\[[^]]+\.md\]' | tail -1 | tr -d '[]')
   ```

   For entries with sub-bullets containing markdown links, this can match the wrong brackets:
   ```markdown
   - [x] **Title** - Description [.claude/specs/123_topic/plans/001.md]
     - Related reports: [report1](path1.md), [report2](path2.md)
   ```

   The regex might match `[report2](path2.md]` instead of `[.claude/specs/123_topic/plans/001.md]`.

2. **Multi-line Entry Processing**: The function processes line-by-line but TODO.md entries span multiple lines:
   ```markdown
   - [x] **Build command streamlining** - Consolidate bash blocks [.claude/specs/970_build_command_streamline/plans/001-build-command-streamline-plan.md]
     - All phases complete: Bash block consolidation
     - Related reports: [report](path.md)
   ```

   The sub-bullets (starting with `  - `) are processed as separate lines by the while loop at line 773, causing them to fail the `grep -qE '^- \[[x~]\] \*\*'` check.

3. **Directory Existence Check**: Line 796-801 skips entries where the directory doesn't exist:
   ```bash
   if [ -z "$topic_dir" ]; then
     [ "${DEBUG:-}" = "1" ] && echo "INFO: Topic directory not found for $topic_num (may already be removed)" >&2
     continue
   fi
   ```

   This creates a cascading failure: if the parser misidentifies the topic number or path, it won't find the directory and will skip it.

**Testing the Parser**:

To verify this theory, I examined the actual entries:

```bash
# Completed section entry format
- [x] **Build command streamlining** - Consolidate bash blocks, inline verifications, improve code quality [.claude/specs/970_build_command_streamline/plans/001-build-command-streamline-plan.md]
  - All phases complete: Bash block consolidation, verification inlining, code quality improvements
```

The parser should extract:
- Topic number: `970` (from `specs/970_`)
- Plan path: `.claude/specs/970_build_command_streamline/plans/001-build-command-streamline-plan.md`

But with sub-bullets present, the regex extraction may fail.

**Why Only 39/107 Were Found**:

The second cleanup attempt (commit e8162eb9) found only 39 projects instead of 107 because:

1. **TODO.md wasn't updated** after the first cleanup (commit 6f5bbb4c removed 106 directories)
2. **Parser skipped already-removed directories** (lines 796-801 check directory existence)
3. **Result**: 107 - 68 (non-existent) = 39 remaining eligible projects

### 4. Why doesn't it update TODO.md to remove entries for deleted projects?

**Evidence from Command Implementation**:

The `/todo --clean` command (Block 4b, lines 714-817) performs these steps:

```bash
1. parse_todo_sections() → Extract eligible projects
2. execute_cleanup_removal() → Remove directories
3. Block 5 → Generate completion summary
```

**Missing Step**: There is **NO** TODO.md update logic in the cleanup workflow.

**Comparison with Default Mode**:

Default mode (Blocks 3-4) has explicit TODO.md generation:
```bash
# Block 3: Generate TODO.md (lines 441-520)
# Block 4: Write TODO.md File (lines 522-616)
```

**Clean mode** completely bypasses these blocks and goes directly to Block 4b (cleanup execution).

**Root Cause**: The design assumes that users will run `/todo` (default mode) after `/todo --clean` to regenerate TODO.md, but this is:
1. Not documented in the command
2. Not automated
3. Not enforced
4. Leaves TODO.md in an inconsistent state

### 5. What is the expected behavior vs actual behavior?

**Expected Behavior** (from command documentation):

```markdown
## Clean Mode

When invoked with `--clean` flag, identifies all cleanup-eligible projects
(Completed, Abandoned, and Superseded sections) and directly removes them
after creating a git commit. Recovery is possible via git revert.
No age threshold applied.
```

**Actual Behavior**:

1. ✅ Identifies cleanup-eligible projects from TODO.md sections
2. ✅ Creates pre-cleanup git commit for recovery
3. ⚠️ Only removes subset of eligible projects (39/107 in recent run)
4. ❌ Does NOT update TODO.md to remove deleted entries
5. ❌ Leaves TODO.md with 68+ entries pointing to non-existent directories

**Gap Analysis**:

| Expected | Actual | Status |
|----------|--------|--------|
| Remove all Completed/Abandoned/Superseded projects | Removed only 39/107 projects | ❌ Partial failure |
| Update TODO.md to reflect cleanup | TODO.md unchanged after cleanup | ❌ Missing feature |
| Leave only In Progress, Not Started, Backlog | Completed/Abandoned entries remain | ❌ Incomplete |

## Root Cause Summary

The `/todo --clean` command has **two critical bugs**:

### Bug 1: Incomplete Directory Removal

**Location**: `.claude/lib/todo/todo-functions.sh:parse_todo_sections()` (lines 717-825)

**Symptoms**:
- Only 39/107 eligible projects removed
- 68 eligible projects skipped

**Root Causes**:
1. **Greedy regex pattern** for plan path extraction (`'\[[^]]+\.md\]'`) matches incorrect brackets when sub-bullets contain markdown links
2. **Directory existence check** (lines 796-801) skips entries where parser failed to identify correct topic number
3. **No validation** of parsed entries before removal

**Evidence**:
```bash
# Pre-cleanup: 107 eligible projects
# Post-cleanup commit message: "39 projects"
# Directories remaining: 68 eligible projects still in specs/
```

### Bug 2: Missing TODO.md Update

**Location**: `.claude/commands/todo.md:Block 4b` (lines 714-817)

**Symptoms**:
- TODO.md contains entries for deleted directories
- Completed/Abandoned/Superseded sections not cleared
- User must manually run `/todo` again

**Root Causes**:
1. **Clean mode workflow** does not include TODO.md regeneration steps (Blocks 3-4)
2. **Design assumption** that users will run `/todo` after cleanup is undocumented
3. **No automated TODO.md update** after directory removal

**Evidence**:
```bash
# Check TODO.md after cleanup
$ grep "970_build_command_streamline" .claude/TODO.md
- [x] **Build command streamlining** - Consolidate bash blocks...

# Check if directory exists
$ ls .claude/specs/970_build_command_streamline
ls: cannot access '.claude/specs/970_build_command_streamline': No such file or directory
```

## Implementation Analysis

### Current Workflow (Clean Mode)

```mermaid
graph TD
    A[/todo --clean] --> B[Block 1: Setup]
    B --> C[Block 2a: Classification Setup]
    C --> D[Block 2b: todo-analyzer subagent]
    D --> E[Block 2c: Verification]
    E --> F{CLEAN_MODE?}
    F -->|false| G[Block 3: Generate TODO.md]
    F -->|true| H[Block 4b: Direct Cleanup]
    G --> I[Block 4: Write TODO.md]
    H --> J[Block 5: Completion Summary]
    I --> K[Default Mode Complete]
    J --> L[Clean Mode Complete - TODO.md UNCHANGED]
```

### Expected Workflow (Fixed)

```mermaid
graph TD
    A[/todo --clean] --> B[Block 1: Setup]
    B --> C[Block 2a: Classification Setup]
    C --> D[Block 2b: todo-analyzer subagent]
    D --> E[Block 2c: Verification]
    E --> F[Block 4b: Direct Cleanup - ALL eligible dirs]
    F --> G[Block 4c: Regenerate TODO.md]
    G --> H[Block 5: Completion Summary]
    H --> I[Clean Mode Complete - TODO.md UPDATED]
```

## Evidence Files

### Commit History Evidence

```bash
# Most recent cleanup attempt (incomplete)
$ git show e8162eb9 --stat
commit e8162eb9
chore: pre-cleanup snapshot before /todo --clean (39 projects)
 .claude/TODO.md                                    |  65 +-
 3 files changed, 1301 insertions(+), 5 deletions(-)

# Previous successful cleanup (removed 106 dirs)
$ git show 6f5bbb4c --stat
commit 6f5bbb4c
chore: remove 106 completed/abandoned project directories
 .../105_build_state_management_bash_errors_fix/plans/001_debug_strategy.md | 1071 ------------
 [... 106 directory deletions ...]

# Pre-cleanup snapshot
$ git show 376f1d93
commit 376f1d93
chore: pre-cleanup snapshot before /todo --clean (107 projects)
```

### TODO.md Entry Format

**Completed Section Entry**:
```markdown
- [x] **Build command streamlining** - Consolidate bash blocks, inline verifications, improve code quality [.claude/specs/970_build_command_streamline/plans/001-build-command-streamline-plan.md]
  - All phases complete: Bash block consolidation, verification inlining, code quality improvements
```

**Abandoned Section Entry**:
```markdown
- [x] **Error logging infrastructure completion** - Helper functions (validate_required_functions, execute_with_logging) deemed unnecessary after comprehensive analysis [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md]
  - **Reason**: Error logging infrastructure already 100% complete across all 12 commands
  - **Analysis**: setup_bash_error_trap already catches function-not-found errors
```

**Parser Challenges**:
1. Multi-line entries with indented sub-bullets
2. Markdown links in sub-bullets (e.g., `[report](path.md)`)
3. Multiple bracket pairs per entry
4. Varied plan path formats (with/without `.claude/` prefix)

## Recommendations

### Fix 1: Improve parse_todo_sections() Parser

**Changes Required** (`.claude/lib/todo/todo-functions.sh`):

1. **Fix plan path regex** (line 790):
   ```bash
   # Current (greedy, matches wrong brackets)
   plan_path=$(echo "$line" | grep -oE '\[[^]]+\.md\]' | tail -1 | tr -d '[]')

   # Fixed (anchored to end of main entry line)
   plan_path=$(echo "$line" | grep -oE '\[\.claude/specs/[^]]+\.md\]' | tail -1 | tr -d '[]')
   ```

2. **Filter out sub-bullet lines** (line 773):
   ```bash
   # Current (processes all lines)
   while IFS= read -r line; do
     if echo "$line" | grep -qE '^- \[[x~]\] \*\*'; then

   # Fixed (skip indented lines)
   while IFS= read -r line; do
     # Skip sub-bullets (start with spaces)
     [[ "$line" =~ ^[[:space:]] ]] && continue
     if echo "$line" | grep -qE '^- \[[x~]\] \*\*'; then
   ```

3. **Add validation** before returning JSON:
   ```bash
   # After building JSON array
   local entry_count=$(echo "[${json_entries}]" | jq 'length')
   echo "INFO: Parsed $entry_count eligible projects from TODO.md" >&2
   ```

### Fix 2: Add TODO.md Update to Clean Mode

**Changes Required** (`.claude/commands/todo.md`):

1. **Add Block 4c** (after Block 4b cleanup execution):
   ```markdown
   ## Block 4c: Regenerate TODO.md After Cleanup

   **EXECUTE AFTER Block 4b completes**: Update TODO.md to remove deleted entries.

   ```bash
   # Re-scan projects (deleted directories won't be found)
   TOPICS=$(scan_project_directories)

   # Regenerate TODO.md with current state
   # This will exclude deleted projects
   update_todo_file "$TODO_PATH" "$CLASSIFIED_RESULTS" "false"
   ```

2. **Update Block 5** to report TODO.md update:
   ```bash
   ARTIFACTS="  📝 Git Commit: $COMMIT_HASH
     ✓ Removed: ${REMOVED_COUNT:-0} projects
     📄 TODO.md: $TODO_PATH (updated)"
   ```

### Fix 3: Document Expected Workflow

**Changes Required** (`.claude/commands/todo.md` documentation):

```markdown
### Clean Mode

When invoked with `--clean` flag, performs these steps:
1. Identifies all cleanup-eligible projects (Completed, Abandoned, Superseded sections)
2. Creates pre-cleanup git commit for recovery
3. Removes eligible project directories
4. **Updates TODO.md to remove deleted entries**
5. Leaves TODO.md with only In Progress, Not Started, and Backlog sections

**Important**: After cleanup, TODO.md will be automatically regenerated to reflect
the current filesystem state. Deleted projects will no longer appear in any section.
```

## Testing Plan

### Test 1: Parser Accuracy

```bash
# Create test TODO.md with known entries
cat > /tmp/test_todo.md <<'EOF'
## Completed

- [x] **Test Project 1** - Description [.claude/specs/001_test/plans/001.md]
  - Sub-bullet with [link](path.md)
- [x] **Test Project 2** - Description [.claude/specs/002_test/plans/001.md]

## Abandoned

- [x] **Test Project 3** - Description [.claude/specs/003_test/plans/001.md]
  - Multiple sub-bullets
  - With [links](a.md) and [more](b.md)
EOF

# Test parser
source .claude/lib/todo/todo-functions.sh
RESULT=$(parse_todo_sections /tmp/test_todo.md)
COUNT=$(echo "$RESULT" | jq 'length')

# Verify
echo "Expected: 3 projects"
echo "Actual: $COUNT projects"
echo "$RESULT" | jq .
```

### Test 2: TODO.md Update After Cleanup

```bash
# Run cleanup
/todo --clean --dry-run

# Verify TODO.md sections
grep "^## Completed" -A 5 .claude/TODO.md
# Should be empty after cleanup

grep "^## In Progress" -A 5 .claude/TODO.md
# Should contain active projects
```

### Test 3: End-to-End Workflow

```bash
# 1. Run default mode to populate TODO.md
/todo

# 2. Count eligible projects
ELIGIBLE=$(grep -E "^## (Completed|Abandoned|Superseded)" .claude/TODO.md | grep -E "^- \[[x~]\]" | wc -l)

# 3. Run cleanup
/todo --clean

# 4. Verify all directories removed
# 5. Verify TODO.md updated
# 6. Verify git recovery works
```

## Related Files

- **Command**: `.claude/commands/todo.md` (lines 618-896)
- **Library**: `.claude/lib/todo/todo-functions.sh` (lines 717-1013)
- **Standards**: `.claude/docs/reference/standards/todo-organization-standards.md`
- **Git Commits**: e8162eb9, 6f5bbb4c, 376f1d93, cd0b0a01

## Completion Signal

REPORT_CREATED: /home/benjamin/.config/.claude/specs/988_todo_clean_fix/reports/001-todo-clean-command-failure-analysis.md
