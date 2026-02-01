---
description: Run Lean build with automatic error repair
allowed-tools: Read, Write, Edit, Bash, mcp__lean-lsp__lean_build
argument-hint: [--clean] [--max-retries N] [--dry-run] [--module NAME]
---

# /lake Command

Run `lake build` with automatic repair of common errors. Iteratively builds, parses errors, and applies mechanical fixes until the build succeeds or max retries are reached.

## Syntax

```
/lake [options]
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--clean` | Run `lake clean` before building | false |
| `--max-retries N` | Maximum auto-fix iterations | 3 |
| `--dry-run` | Show what would be fixed without applying changes | false |
| `--module NAME` | Build specific module only (e.g., `Logos.Layer0.Basic`) | (all) |

## Auto-Fixable Errors

The skill automatically fixes these common error types:

| Error Type | Detection Pattern | Fix Strategy |
|------------|-------------------|--------------|
| Missing pattern match cases | `error: Missing cases:\n{case1}\n{case2}` | Add `\| {case} => sorry` branches |
| Unused variable | `warning: unused variable '{name}'` | Rename to `_{name}` |
| Unused import | `warning: unused import '{module}'` | Remove import line |

Errors not in this list are reported but not auto-fixed.

## Execution

**MCP Safety**: Do not call `lean_diagnostic_messages` or `lean_file_outline` - they hang. Delegate to skills.

**EXECUTE NOW**: Follow these steps in sequence. Do not just describe what should happen - actually perform each step.

### STEP 1: Parse Arguments

**EXECUTE NOW**: Parse the command arguments to extract flags.

```
# Default values
clean=false
max_retries=3
dry_run=false
module=""

# Parse flags from $ARGUMENTS
```

Track:
- `--clean` → set clean=true
- `--dry-run` → set dry_run=true
- `--max-retries N` → set max_retries=N
- `--module NAME` → set module=NAME

**On success**: **IMMEDIATELY CONTINUE** to STEP 2.

---

### STEP 2: Run Initial Build

**EXECUTE NOW**: Run the initial build (with clean if requested).

If `clean=true`:
```bash
lake clean
```

Then run the build:
```bash
lake build $module 2>&1
```

Capture the output and exit code.

**If build succeeds (exit code 0, no error: lines)**:
```
Lake Build Complete
===================

Build succeeded on first attempt.
No fixes needed.
```
**STOP** - execution complete.

**If build has errors**: **IMMEDIATELY CONTINUE** to STEP 3.

---

### STEP 3: Parse and Fix Errors (Loop)

**EXECUTE NOW**: Initialize the repair loop.

```
retry_count=0
fix_log=[]
previous_error_hash=""
```

**EXECUTE NOW**: Begin the repair loop. For each iteration:

#### 3A: Parse Build Errors

Extract errors from build output using pattern:
```
^(.+\.lean):(\d+):(\d+): (error|warning): (.+)$
```

Create error records with: file, line, column, severity, message

#### 3B: Classify Errors

For each error, check if auto-fixable:

| Pattern | Fix Type |
|---------|----------|
| `Missing cases:` | missing_cases |
| `unused variable '{name}'` | unused_variable |
| `unused import '{module}'` | unused_import |
| Other | UNFIXABLE |

#### 3C: Check Stop Conditions

**STOP** the loop if ANY of these are true:
1. No fixable errors remain (only unfixable errors)
2. `retry_count >= max_retries`
3. Same errors repeated (cycle detection via hash comparison)

If stopping, **IMMEDIATELY CONTINUE** to STEP 4.

#### 3D: Apply Fixes

**If dry_run=true**: Add each proposed fix to preview list, do NOT apply changes.

**If dry_run=false**: **EXECUTE NOW** - For each fixable error, apply the fix:

- **Missing cases**: Read file, find last match case, insert `| {CaseName} => sorry` branches
- **Unused variable**: Read file, rename `{name}` to `_{name}` at the declaration
- **Unused import**: Read file, remove the import line (only clean single-import lines)

Log each fix to `fix_log`.

#### 3E: Rebuild and Continue Loop

```bash
retry_count=$((retry_count + 1))
lake build $module 2>&1
```

If build succeeds: **IMMEDIATELY CONTINUE** to STEP 4.
If build has errors: **Go back to 3A** (loop continues).

---

### STEP 4: Report Results

**EXECUTE NOW**: Generate the appropriate report based on outcome.

**On Success (build passed)**:
```
Lake Build Complete
===================

Build succeeded after {retry_count} iterations.

Fixes applied:
{for each fix in fix_log:}
- {file}:{line} - {description}

All modules built successfully.
```

**On Max Retries or Unfixable Errors**:
```
Lake Build Partial
==================

Max retries ({max_retries}) reached. Build not yet passing.

Fixes applied ({retry_count} iterations):
{for each fix in fix_log:}
- {file}:{line} - {description}

Remaining errors (unfixable):
{list unfixable_errors}

Recommendation: Fix the remaining errors manually, then run /lake again.
```

**On Dry Run**:
```
Lake Build Dry Run
==================

Would apply {count} fixes:

{for each proposed fix:}
{index}. {file}:{line}
   Error: {message}
   Fix: {description}

No changes made (dry run mode).
```

**If unfixable_errors exist and dry_run=false**: **IMMEDIATELY CONTINUE** to STEP 5.
**Otherwise**: **Execution complete.**

---

### STEP 5: Create Tasks for Unfixable Errors (Optional)

**EXECUTE NOW**: If unfixable errors remain and dry_run=false, offer to create tasks.

This step only runs when:
- Build did not fully succeed
- There are unfixable errors remaining
- User is not in dry-run mode

#### 5A: Group Errors by File

Group the unfixable errors by source file:
```
file_groups = {}
for each error in unfixable_errors:
    file = error.file
    if file not in file_groups:
        file_groups[file] = []
    file_groups[file].append(error)
```

Count: `{len(file_groups)}` files with unfixable errors

#### 5B: Confirm with User

**EXECUTE NOW**: Display summary and ask for confirmation using AskUserQuestion.

Display:
```
Task Creation Opportunity
=========================

{len(file_groups)} files have unfixable errors:

{for file, errors in file_groups:}
- {file}: {len(errors)} error(s)
  - {error.severity}: {error.message[:60]}...

Would you like to create tasks for these errors?
Each file will get one task with a linked error report.
```

**Use AskUserQuestion** with options:
- "Yes, create tasks"
- "No, skip task creation"

**If user selects "No"**:
```
Skipping task creation.
Run /lake again after fixing errors manually.
```
**STOP** - execution complete.

**If user selects "Yes"**: **IMMEDIATELY CONTINUE** to 5C.

#### 5C: Create Tasks and Error Reports

**EXECUTE NOW**: For each file group, check for existing tasks and create new tasks where needed.

Initialize tracking arrays:
```bash
skipped_files=()
created_tasks=()
```

For each `(file, errors)` in `file_groups`:

**First, check for existing task**:
```bash
base_name=$(basename "$file" .lean | tr '[:upper:]' '[:lower:]')
existing_task=$(jq -r --arg source "$file" --arg basename "$base_name" '
  .active_projects[] |
  select((.source == $source) or (.project_name | contains("fix_build_errors_" + $basename))) |
  .project_number' specs/state.json | head -1)

if [ -n "$existing_task" ]; then
  echo "Skipping $file - existing task #$existing_task"
  skipped_files+=("$file:$existing_task")
  continue
fi
```

**If no existing task**, proceed with task creation:

1. **Get next task number**:
   ```bash
   next_num=$(jq -r '.next_project_number' specs/state.json)
   ```

2. **Generate slug**:
   ```bash
   slug="fix_build_errors_$(basename "$file" .lean | tr '[:upper:]' '[:lower:]')"
   ```

3. **Create task directory**:
   ```bash
   mkdir -p "specs/${next_num}_${slug}/reports"
   ```

4. **Write error report** to `specs/${next_num}_${slug}/reports/error-report-{DATE}.md`:
   ```markdown
   # Build Error Report: Task #{next_num}

   **Generated**: {ISO_DATE}
   **Source file**: {file}
   **Error count**: {len(errors)} errors

   ## Errors

   {for i, error in enumerate(errors):}
   ### Error {i+1}: Line {error.line}
   **Type**: {error.severity}
   **Column**: {error.column}
   **Message**:
   ```
   {error.message}
   ```

   ## Suggested Approach

   Review each error and apply appropriate fixes.
   Run /lake after fixing to verify the build passes.
   ```

5. **Update state.json** with new task:
   ```bash
   jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg slug "$slug" \
      --arg source "$file" \
      --argjson error_count $error_count \
      --arg report_path "specs/${next_num}_${slug}/reports/error-report-{DATE}.md" \
      '.next_project_number = (.next_project_number + 1) |
       .active_projects = [{
         "project_number": .next_project_number - 1,
         "project_name": $slug,
         "status": "not_started",
         "language": "lean",
         "priority": "high",
         "source": $source,
         "created": $ts,
         "last_updated": $ts,
         "artifacts": [{
           "type": "error_report",
           "path": $report_path,
           "summary": ("Build error report with " + ($error_count | tostring) + " errors")
         }]
       }] + .active_projects' \
      specs/state.json > /tmp/state.json && mv /tmp/state.json specs/state.json
   ```

6. **Update TODO.md** - Add entry in High Priority section:
   ```markdown
   ### {next_num}. Fix build errors in {basename(file)}
   - **Effort**: 1-2 hours
   - **Status**: [NOT STARTED]
   - **Priority**: High
   - **Language**: lean
   - **Source**: {file}

   **Description**: Fix {error_count} build errors in {file}. See error report for details.
   ```

**After all tasks processed**:
```
Tasks Created
=============

{If skipped_files not empty:}
Files skipped (existing tasks):
- {file}: Task #{existing_task_number}

{If created_tasks not empty:}
Created {len(created_tasks)} tasks:
- Task #{task_num}: Fix build errors in {basename(file)}

{If no tasks created and no files skipped:}
No tasks created.

Run /implement {task_num} to work on each task.
```

**Execution complete.**

---

**For detailed fix algorithms** (pattern matching, edge cases, safety rules):
See @.claude/skills/skill-lake-repair/SKILL.md

## Examples

### Basic Build with Auto-Repair

```bash
# Build and automatically fix mechanical errors
/lake
```

### Clean Rebuild

```bash
# Clean build artifacts first, then build with repair
/lake --clean
```

### Preview Mode

```bash
# Show what would be fixed without modifying files
/lake --dry-run
```

### Module-Specific Build

```bash
# Build only the specified module
/lake --module Logos.Layer1.Soundness
```

### Extended Retries

```bash
# Allow more fix iterations for complex cascading errors
/lake --max-retries 5
```

## Output

### Success

```
Lake Build Complete
===================

Build succeeded after 2 iterations.

Fixes applied:
- Logos/Layer1/Completeness.lean:45 - Added 2 missing match cases
- Logos/Layer0/Basic.lean:23 - Renamed unused variable 'h' to '_h'

All modules built successfully.
```

### Partial Success (Max Retries)

```
Lake Build Partial
==================

Max retries (3) reached. Build not yet passing.

Fixes applied (2 iterations):
- Logos/Layer1/Completeness.lean:45 - Added 2 missing match cases

Remaining errors (unfixable):
- Logos/Layer1/Soundness.lean:89:15: error: Type mismatch
    expected: Model.Valid M φ
    found:    Frame.Valid F φ

Recommendation: Fix the type error manually, then run /lake again.
```

### Dry Run

```
Lake Build Dry Run
==================

Would apply 3 fixes:

1. Logos/Layer1/Completeness.lean:45
   Error: Missing cases: Formula.implies, Formula.iff
   Fix: Add 2 match cases with sorry placeholders

2. Logos/Layer0/Basic.lean:23
   Warning: unused variable 'h'
   Fix: Rename to '_h'

3. Logos/Layer0/Basic.lean:5
   Warning: unused import 'Mathlib.Data.Nat.Basic'
   Fix: Remove import line

No changes made (dry run mode).
```

### No Errors

```
Lake Build Complete
===================

Build succeeded on first attempt.
No fixes needed.
```

## Stop Conditions

The repair loop stops when:

1. **Build succeeds**: All modules compile without errors
2. **Max retries reached**: Default 3 iterations
3. **No fixable errors**: All remaining errors are unfixable types
4. **Same errors repeated**: Fixes didn't resolve the errors (infinite loop prevention)

## Safety

- All fixes use `sorry` placeholders that compile but indicate incomplete work
- Git provides full undo capability (`git checkout -- path/to/file`)
- Original code is never deleted, only modified
- Use `--dry-run` to preview changes before applying
- Unused import removal is conservative (only removes the specific line)

## Troubleshooting

### Build hangs or times out

The `lake build` command may take a long time for large projects. Consider:
- Using `--module` to build specific modules
- Running `lake build` directly to see real-time output

### Fixes create new errors

This can happen when auto-fixes interact unexpectedly. The skill tracks whether the same errors recur and stops to prevent infinite loops. Review the changes and adjust manually if needed.

### MCP tool unavailable

If the `lean_build` MCP tool fails, the skill falls back to `lake build` via Bash.
